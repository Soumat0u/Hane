import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:hane/theme/app_theme.dart';
import 'package:hane/theme/responsive.dart';
import 'package:provider/provider.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/models/account.dart';
import 'package:hane/models/financial_transaction.dart';
import 'package:hane/models/finance_entities.dart';
import 'package:hane/views/widgets/bank_logo.dart';
import 'package:hane/utils/thousands_formatter.dart';

class YeniIslemScreen extends StatefulWidget {
  final String initialType;
  final String? initialProject;
  final FinancialTransaction? initialTransaction;
  final VoidCallback? onBack;

  const YeniIslemScreen({
    super.key,
    this.initialType = 'Ödeme',
    this.initialProject,
    this.initialTransaction,
    this.onBack,
  });

  @override
  State<YeniIslemScreen> createState() => _YeniIslemScreenState();
}

// Proje dropdown'ında "hiçbir proje seçilmedi" durumunu temsil eden sabit.
// Genel şirket giderleri projesiz olabilir (bkz. FinancialTransaction.projectId).
const String kNoProjectOption = 'Genel (Proje Yok)';

class _YeniIslemScreenState extends State<YeniIslemScreen> {
  // General Selection State
  String _selectedType = 'Ödeme';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialTransaction?.type ?? widget.initialType;
    _isIncome = _selectedType == 'Tahsilat' || _selectedType == 'Gelir' || _selectedType == 'Satış';
    
    if (widget.initialTransaction != null) {
      final t = widget.initialTransaction!;
      if (t.projectId != null) {
        final fp = Provider.of<FinanceProvider>(context, listen: false);
        _selectedProject = fp.projects.where((p) => p.id == t.projectId).firstOrNull?.name ?? kNoProjectOption;
      }
      _dateController.text = _formatDate(DateTime.tryParse(t.date) ?? DateTime.now());
      _amountController.text = t.amount.toStringAsFixed(2).replaceAll('.00', '');
      _descriptionController.text = t.description;
      _buyerSellerController.text = t.contactName;
      _quantityController.text = t.quantity?.toStringAsFixed(2).replaceAll('.00', '') ?? '';
      _selectedUnit = t.unit?.isNotEmpty == true ? t.unit : null;
      if (_selectedUnit != null && !_units.contains(_selectedUnit)) {
        _selectedUnit = 'Diğer';
      }
    }
  }

  // Dropdown seçenekleri GERÇEK kullanıcı verisinden gelir (sabit demo listesi yok).
  List<String> get _projectNames =>
      Provider.of<FinanceProvider>(context, listen: false).projects.map((p) => p.name).toList();
  List<String> get _accountNames =>
      Provider.of<FinanceProvider>(context, listen: false).accounts.map((a) => a.name).toList();
  List<String> get _bankNames => Provider.of<FinanceProvider>(context, listen: false)
      .accounts
      .where((a) => a.type == 'Banka')
      .map((a) => a.name)
      .toList();
  bool _defaultsSet = false;

  @override
  void didUpdateWidget(covariant YeniIslemScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialType != oldWidget.initialType) {
      setState(() {
        _selectedType = widget.initialType;
        _isIncome = _selectedType == 'Tahsilat' || _selectedType == 'Gelir';
        _updateCategoriesForType(_isIncome);
      });
    }
  }

  // --- Ödeme Form States ---
  bool _isIncome = false; // false = Gider, true = Gelir
  String _selectedProject = kNoProjectOption;
  Category? _selectedMainCategory;
  Category? _selectedSubCategory;
  String _selectedSource = '';
  XFile? _pickedAttachment;
  bool _removeExistingAttachment = false;

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _buyerSellerController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final List<String> _units = ['Adet', 'Ton', 'Kg', 'Metre', 'm²', 'm³', 'Litre', 'Saat', 'Ay', 'Gün', 'Yıl', 'Paket', 'Kutu', 'Diğer'];
  String? _selectedUnit;

  // --- Transfer Form States ---
  String _transferTarih = '';
  String _transferGonderen = '';
  String _transferAlan = '';
  final TextEditingController _transferTutarController = TextEditingController();
  final TextEditingController _transferAciklamaController = TextEditingController();

  // --- Borclanma Form States ---
  String _borclanmaTarih = '';
  String _borclanmaVade = 'Seçiniz';
  String _borclanmaKategori = 'Tedarikçi Borcu';
  String _borclanmaProje = '';
  final TextEditingController _borclanilanKisiController = TextEditingController();
  final TextEditingController _borclanmaTutarController = TextEditingController();
  final TextEditingController _borclanmaAciklamaController = TextEditingController();
  final TextEditingController _borclanmaFaturaNoController = TextEditingController();
  final List<String> _borclanmaKategorileri = ['Tedarikçi Borcu', 'Banka Kredisi', 'Ortaklara Borçlar', 'Diğer'];

  // --- Kredi Kullanimi Form States ---
  String _krediTarih = '';
  String _krediBanka = '';
  String _krediProje = '';
  final TextEditingController _krediTutarController = TextEditingController();
  final TextEditingController _krediVadeController = TextEditingController();
  final TextEditingController _krediTaksitController = TextEditingController();
  final TextEditingController _krediAciklamaController = TextEditingController();

  // --- Satis Form States ---
  String _satisTarih = '';
  String _satisProje = '';
  final TextEditingController _satisMusteriController = TextEditingController();
  final TextEditingController _satisBlokDaireController = TextEditingController();
  final TextEditingController _satisBedeliController = TextEditingController();
  final TextEditingController _satisPesinatController = TextEditingController();
  final TextEditingController _satisAciklamaController = TextEditingController();

  DateTime get _firstDayOfMonth => DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime get _lastDayOfMonth => DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Varsayılan seçimleri bir kez gerçek kullanıcı verisinden ata.
    if (!_defaultsSet) {
      String first(List<String> l) => l.isNotEmpty ? l.first : '';
      final projects = _projectNames;
      final accounts = _accountNames;
      final banks = _bankNames;

      if (widget.initialTransaction == null) {
        // Tarih alanları bugüne varsayılansın (yalnızca yeni kayıtta — düzenlemede
        // initState() zaten işlemin gerçek tarihini set etmişti, burada ezilmemeli).
        final today = _formatDate(DateTime.now());
        _dateController.text = today;
        _transferTarih = today;
        _borclanmaTarih = today;
        _krediTarih = today;
        _satisTarih = today;
        // Varsayılan olarak proje seçili gelmesin — kullanıcı genel (projesiz)
        // bir harcama girmek isteyebilir; proje seçimi isteğe bağlı bırakılır.
        _selectedProject = widget.initialProject ?? kNoProjectOption;
      }
      _updateCategoriesForType(_isIncome);
      
      if (widget.initialTransaction != null) {
        final t = widget.initialTransaction!;
        _selectedSource = t.sourceName.isNotEmpty ? t.sourceName : (t.destName.isNotEmpty ? t.destName : first(accounts));
        // Kategoriyi eşleştir — aynı isimde hem gelir hem gider kategorisi olabileceğinden
        // (örn. "Diğer"), önce işlemin türüne (gelir/gider) uyanı tercih ediyoruz.
        final fp = Provider.of<FinanceProvider>(context, listen: false);
        final matchingCat = fp.categories.where((c) => c.name == t.category && c.isIncome == _isIncome).firstOrNull ??
            fp.categories.where((c) => c.name == t.category).firstOrNull;
        if (matchingCat != null) {
          if (matchingCat.isMain) {
            _selectedMainCategory = matchingCat;
            _selectedSubCategory = null;
          } else {
            _selectedSubCategory = matchingCat;
            _selectedMainCategory = fp.categories.where((c) => c.id == matchingCat.parentId).firstOrNull;
          }
        }
      } else {
        _selectedSource = first(accounts);
      }
      
      _transferGonderen = first(accounts);
      _transferAlan = accounts.length > 1 ? accounts[1] : first(accounts);
      _borclanmaProje = first(projects);
      _krediProje = first(projects);
      _krediBanka = first(banks);
      _satisProje = first(projects);
      _defaultsSet = true;
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _buyerSellerController.dispose();
    _amountController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();

    _transferTutarController.dispose();
    _transferAciklamaController.dispose();
    
    _borclanilanKisiController.dispose();
    _borclanmaTutarController.dispose();
    _borclanmaAciklamaController.dispose();
    _borclanmaFaturaNoController.dispose();
    
    _krediTutarController.dispose();
    _krediVadeController.dispose();
    _krediTaksitController.dispose();
    _krediAciklamaController.dispose();
    
    _satisMusteriController.dispose();
    _satisBlokDaireController.dispose();
    _satisBedeliController.dispose();
    _satisPesinatController.dispose();
    _satisAciklamaController.dispose();
    super.dispose();
  }

  static const List<String> _months = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
  ];

  // Tarihi "gün Ay yıl" (Türkçe) biçiminde döndürür.
  static String _formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  // Türkçe "gün Ay yıl" veya ISO metni her zaman "yyyy-MM-dd" ISO biçimine çevirir.
  // Backend ve tüm listeleme/özet ekranları tutarlı biçimde ayrıştırabilsin diye.
  static String _isoDate(String display) {
    final s = display.trim();
    if (s.isEmpty || s == 'Seçiniz') return DateTime.now().toIso8601String().split('T').first;
    final direct = DateTime.tryParse(s);
    if (direct != null) return direct.toIso8601String().split('T').first;
    final parts = s.split(RegExp(r'\s+'));
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final monthIdx = _months.indexOf(parts[1]) + 1;
      final year = int.tryParse(parts[2]);
      if (day != null && monthIdx > 0 && year != null) {
        return DateTime(year, monthIdx, day).toIso8601String().split('T').first;
      }
    }
    return DateTime.now().toIso8601String().split('T').first;
  }

  String _getAmountText() {
    switch (_selectedType) {
      case 'Transfer': return _transferTutarController.text;
      case 'Borçlanma': return _borclanmaTutarController.text;
      case 'Kredi Kullanımı': return _krediTutarController.text;
      case 'Satış': return _satisBedeliController.text;
      case 'Ödeme':
      case 'Tahsilat':
      default: return _amountController.text;
    }
  }

  String _getButtonText() {
    switch (_selectedType) {
      case 'Tahsilat': return 'TAHSİLATI KAYDET';
      case 'Transfer': return 'TRANSFERİ KAYDET';
      case 'Borçlanma': return 'BORCU KAYDET';
      case 'Kredi Kullanımı': return 'KREDİYİ KAYDET';
      case 'Satış': return 'SATIŞI KAYDET';
      case 'Ödeme':
      default: return 'KAYDET';
    }
  }

  Widget _getSourceIcon(String name, {double size = 18}) {
    final fp = Provider.of<FinanceProvider>(context, listen: false);
    final account = fp.accounts.where((a) => a.name == name).firstOrNull;
    if (account != null) {
      if (account.type == 'Banka' || account.type == 'Kredi Kartı' || account.type == 'BCH' || account.type == 'Esnek') {
        return BankLogoWidget(bankName: account.bankLogoPainter.isNotEmpty ? account.bankLogoPainter : account.name, width: size * 4.5, height: size * 1.5);
      } else {
        return Icon(Icons.money_rounded, color: context.colors.success, size: size);
      }
    }
    return Icon(Icons.account_balance_wallet, color: context.colors.textSecondary, size: size);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.colors.textPrimary, size: 22),
                    onPressed: () {
                      if (widget.onBack != null) {
                        widget.onBack!();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Yeni $_selectedType',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: centeredPagePadding(context, maxContentWidth: 560, horizontal: 20, top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_selectedType == 'Transfer')
                      _buildTransferForm()
                    else if (_selectedType == 'Borçlanma')
                      _buildBorclanmaForm()
                    else if (_selectedType == 'Kredi Kullanımı')
                      _buildKrediKullanimiForm()
                    else if (_selectedType == 'Satış')
                      _buildSatisForm()
                    else
                      _buildOdemeForm(),
                  ],
                ),
              ),
            ),
            
            // Bottom Save Button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: _saving ? null : () async {
                  if (_saving) return;
                  setState(() => _saving = true);
                  try {
                  final amountText = _getAmountText().replaceAll(RegExp(r'[^0-9]'), '');
                  final amount = double.tryParse(amountText) ?? 0.0;

                  final fp = Provider.of<FinanceProvider>(context, listen: false);

                  // Girdi doğrulaması: tutar ve para hareketi olan tiplerde hesap zorunlu.
                  if (amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lütfen geçerli bir tutar girin.'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  const accountRequiredTypes = {'Ödeme', 'Transfer', 'Tahsilat', 'Kredi Kullanımı'};
                  if (accountRequiredTypes.contains(_selectedType) && fp.accounts.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bu işlem için önce Kasa bölümünden bir hesap eklemelisiniz.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  int? projectId;
                  String selectedProjectName = '';

                  if (_selectedType == 'Borçlanma') {
                    selectedProjectName = _borclanmaProje;
                  } else if (_selectedType == 'Kredi Kullanımı') {
                    selectedProjectName = _krediProje;
                  } else if (_selectedType == 'Satış') {
                    selectedProjectName = _satisProje;
                  } else if (_selectedType == 'Ödeme' || _selectedType == 'Tahsilat' || _selectedType == 'Gider' || _selectedType == 'Gelir') {
                    selectedProjectName = _selectedProject;
                  }

                  if (selectedProjectName.isNotEmpty && selectedProjectName != kNoProjectOption) {
                    final p = fp.projects.where((p) => p.name == selectedProjectName).firstOrNull ??
                        fp.projects
                            .where((p) => p.name.contains(selectedProjectName) || selectedProjectName.contains(p.name))
                            .firstOrNull;
                    if (p != null) projectId = p.id;
                  }

                  if (_selectedType == 'Ödeme' && !_isIncome) {
                    final selectedAcc = fp.accounts.where((a) => a.name == _selectedSource).firstOrNull;
                    if (selectedAcc != null) {
                      double limit = (selectedAcc.type == 'Kredi Kartı' || selectedAcc.type == 'BCH' || selectedAcc.type == 'Esnek')
                          ? selectedAcc.availableLimit
                          : selectedAcc.balance;
                      
                      if (amount > limit) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Yetersiz bakiye veya limit! İşlem tutarı mevcut bakiyeden/limitten büyük olamaz.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return; // Stop save
                      }
                    }
                  }

                  String category = '';
                  String type = _selectedType;
                  String source = '';
                  String dest = '';
                  String date = '';
                  String description = '';
                  String contactName = '';

                  if (_selectedType == 'Ödeme' || _selectedType == 'Tahsilat') {
                     // Tahsilat, Ödeme ekranının gelir tarafına sabitlenmiş halidir (_isIncome her zaman true).
                     type = _isIncome ? 'Gelir' : 'Gider';
                     category = _selectedSubCategory?.name ?? _selectedMainCategory?.name ?? '';
                     // Web ile ve backend bakiye güncelleme mantığıyla uyumluluk için hesabı source_name olarak atıyoruz.
                     source = _selectedSource;
                     dest = '';
                     date = _isoDate(_dateController.text);
                     contactName = _buyerSellerController.text.trim();
                     description = _descriptionController.text.trim();
                  } else if (_selectedType == 'Kredi Kullanımı') {
                     category = 'Kredi Kullanımı';
                     source = _krediBanka;
                     date = _isoDate(_krediTarih);
                     description = _krediAciklamaController.text.trim();

                     // Ayrıca bir Kredi (Loan) kaydı oluştur (vade/taksit burada saklanır)
                     final l = Loan(
                       name: '$_krediBanka Kredisi',
                       principal: amount,
                       totalPayable: amount,
                       termMonths: int.tryParse(_krediVadeController.text) ?? 0,
                       startDate: date,
                     );
                     await fp.addLoan(l);
                  } else if (_selectedType == 'Borçlanma') {
                     category = 'Borçlanma';
                     source = _borclanilanKisiController.text;
                     date = _isoDate(_borclanmaVade);
                     
                     // Önce tedarikçiyi bul veya yarat
                     Contact? contact = fp.contacts.where((c) => c.name.toLowerCase() == _borclanilanKisiController.text.toLowerCase()).firstOrNull;
                     if (contact == null) {
                       final c = Contact(
                         name: _borclanilanKisiController.text.isEmpty ? 'Yeni Tedarikçi/Taşeron' : _borclanilanKisiController.text,
                         kind: 'supplier',
                       );
                       contact = await fp.addContact(c);
                     }
                     
                     // Backend'in balance hesaplaması "Gider - Gelir" şeklindedir (bizim borcumuz için Gider).
                     // İşlem tipini Gider yaparak balance'ı doğrudan yükseltiyoruz.
                     type = 'Gider';
                     
                     final t = FinancialTransaction(
                       projectId: projectId,
                       type: type,
                       amount: amount,
                       date: DateTime.now().toIso8601String().split('T').first,
                       dueDate: date, // _borclanmaVade is stored in date variable
                       category: category,
                       contactId: contact.id, // Cari bağlantısı
                       sourceName: source,
                       description: _borclanmaAciklamaController.text,
                       documentNo: _borclanmaFaturaNoController.text.trim(),
                     );

                      try {
                        if (_pickedAttachment != null) {
                          await fp.addTransactionWithAttachment(t, _pickedAttachment!.path);
                        } else {
                          await fp.addTransaction(t);
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: context.colors.surface, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '$_selectedType başarıyla kaydedildi!',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: context.colors.success,
                          ),
                        );
                        if (widget.onBack != null) {
                          widget.onBack!();
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                        );
                      }
                      return; // Metottan çık
                  } else if (_selectedType == 'Transfer') {
                     category = 'Transfer';
                     source = _transferGonderen;
                     dest = _transferAlan;
                     date = _isoDate(_transferTarih);
                     description = _transferAciklamaController.text.trim();
                  } else if (_selectedType == 'Satış') {
                     category = 'Satış';
                     date = _isoDate(_satisTarih);
                     contactName = _satisMusteriController.text.trim();
                     description = _satisAciklamaController.text.trim();
                     final blokDaire = _satisBlokDaireController.text.trim();
                     final pesinat = _satisPesinatController.text.trim();
                     final extras = [
                       if (blokDaire.isNotEmpty) blokDaire,
                       if (pesinat.isNotEmpty) 'Peşinat: ₺$pesinat',
                     ].join(' • ');
                     if (extras.isNotEmpty) {
                       description = description.isEmpty ? extras : '$extras • $description';
                     }
                  } else {
                     category = 'Diğer';
                     date = DateTime.now().toIso8601String().split('T').first;
                  }

                  final t = FinancialTransaction(
                    projectId: projectId,
                    type: type,
                    amount: amount,
                    date: date,
                    category: category,
                    sourceName: source,
                    destName: dest,
                    contactName: contactName,
                    description: description,
                    quantity: double.tryParse(_quantityController.text),
                    unit: _selectedUnit,
                  );

                  if (widget.initialTransaction != null) {
                    final updated = t.copyWith(id: widget.initialTransaction!.id);
                    if (_pickedAttachment != null) {
                      await fp.updateTransactionWithAttachment(updated, _pickedAttachment!.path);
                    } else if (_removeExistingAttachment) {
                      await fp.updateTransaction(updated, clearAttachment: true);
                    } else {
                      await fp.updateTransaction(updated);
                    }
                  } else if ((_selectedType == 'Ödeme' || _selectedType == 'Tahsilat') && _pickedAttachment != null) {
                    await fp.addTransactionWithAttachment(t, _pickedAttachment!.path);
                  } else {
                    await fp.addTransaction(t);
                  }

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: context.colors.surface, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '$_selectedType başarıyla kaydedildi!',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: context.colors.success,
                    ),
                  );
                  if (widget.onBack != null) {
                    widget.onBack!();
                  }
                  } catch (e) {
                    // Borçlanma gibi türlerde cari oluşturma (fp.addContact) gerçek ağ
                    // çağrısını bekler ve hata fırlatabilir; bu catch olmadan hata
                    // sessizce yutuluyor, kullanıcı hiçbir geri bildirim almadan
                    // işlem kaydedilmemiş oluyordu.
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Kaydedilemedi: $e'), backgroundColor: Colors.red),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.brand,
                  foregroundColor: context.colors.surface,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _getButtonText(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAttachment() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Kameradan Çek'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeriden Seç'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final file = await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 1600);
      if (file != null) setState(() => _pickedAttachment = file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dosya seçilemedi: $e')));
      }
    }
  }

  // --- ÖDEME / TAHSİLAT FORM LAYOUT ---
  // Tahsilat ekranı, Ödeme ekranının birebir aynısıdır; sadece Gelir/Gider seçici
  // başlangıçta Gelir'e sabitlenir (kullanıcı isterse yine değiştirebilir).
  Widget _buildOdemeForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Form Fields Grid/Column
        _buildFormRow(
          label: 'TARİH',
          child: InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: _firstDayOfMonth,
                lastDate: _lastDayOfMonth,
              );
              if (picked != null) {
                setState(() {
                  _dateController.text =
                      "${picked.day} ${[
                    'Ocak',
                    'Şubat',
                    'Mart',
                    'Nisan',
                    'Mayıs',
                    'Haziran',
                    'Temmuz',
                    'Ağustos',
                    'Eylül',
                    'Ekim',
                    'Kasım',
                    'Aralık'
                  ][picked.month - 1]} ${picked.year}";
                });
              }
            },
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.colors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _dateController.text,
                    style: TextStyle(fontSize: 14, color: context.colors.textPrimary, fontWeight: FontWeight.w500),
                  ),
                  Icon(Icons.calendar_month_outlined, color: context.colors.textSecondary, size: 20),
                ],
              ),
            ),
          ),
        ),

        // GELİR / GİDER Toggle
        _buildFormRow(
            label: 'GELİR / GİDER',
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isIncome = true;
                        _updateCategoriesForType(true);
                      });
                    },
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _isIncome ? context.colors.successBg : context.colors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isIncome ? context.colors.success : context.colors.border,
                        ),
                      ),
                      child: Text(
                        'Gelir',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _isIncome ? context.colors.success : context.colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isIncome = false;
                        _updateCategoriesForType(false);
                      });
                    },
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: !_isIncome ? context.colors.dangerBg : context.colors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: !_isIncome ? context.colors.danger : context.colors.border,
                        ),
                      ),
                      child: Text(
                        'Gider',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: !_isIncome ? context.colors.danger : context.colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // PROJE Dropdown
        _buildFormRow(
          label: 'PROJE',
          child: _buildSimpleDropdown(
            value: _selectedProject,
            items: [kNoProjectOption, ..._projectNames],
            emptyHint: 'Önce proje ekleyin',
            onChanged: (val) {
              setState(() {
                _selectedProject = val!;
              });
            },
          ),
        ),

        // ODEME KAYNAGI Custom Dropdown (hesap türüne göre gruplu)
        Consumer<FinanceProvider>(
          builder: (context, fp, child) {
            const typeOrder = ['Banka', 'Kredi Kartı', 'Nakit'];
            final grouped = <String, List<Account>>{};
            for (final type in typeOrder) {
              final list = fp.accounts.where((a) => a.type == type).toList();
              if (list.isNotEmpty) grouped[type] = list;
            }
            final accounts = grouped.values.expand((l) => l).toList();
            if (accounts.isNotEmpty && !accounts.any((a) => a.name == _selectedSource)) {
               WidgetsBinding.instance.addPostFrameCallback((_) {
                 if (mounted) setState(() => _selectedSource = accounts.first.name);
               });
            }
            if (accounts.isEmpty) return const SizedBox.shrink();

            final items = <DropdownMenuItem<String>>[];
            grouped.forEach((type, list) {
              items.add(DropdownMenuItem<String>(
                value: '__header_$type',
                enabled: false,
                child: Text(
                  type.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ));
              for (final a in list) {
                items.add(DropdownMenuItem<String>(
                  value: a.name,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Row(
                      children: [
                        _getSourceIcon(a.name, size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            a.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: context.colors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ));
              }
            });

            return _buildFormRow(
              label: _isIncome ? 'TAHSİLAT HESABI' : 'ÖDEME KAYNAĞI',
              child: SizedBox(
                height: 44,
                child: DropdownButtonFormField<String>(
                  value: accounts.any((a) => a.name == _selectedSource) ? _selectedSource : accounts.first.name,
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: context.colors.textSecondary, size: 20),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: context.colors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: context.colors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: context.colors.accent, width: 1.5),
                    ),
                  ),
                  items: items,
                  onChanged: (val) {
                    if (val != null && !val.startsWith('__header_')) {
                      setState(() {
                        _selectedSource = val;
                      });
                    }
                  },
                ),
              ),
            );
          }
        ),

        // ANA KATEGORİ Selection
        _buildFormRow(
          label: 'ANA KATEGORİ',
          child: InkWell(
            onTap: _pickAna,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.colors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedMainCategory?.name ?? 'Kategori Seçin',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _selectedMainCategory == null ? context.colors.textSecondary : context.colors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.folder_open_rounded, color: context.colors.textSecondary, size: 20),
                ],
              ),
            ),
          ),
        ),

        // ALT KATEGORİ Selection
        _buildFormRow(
          label: 'ALT KATEGORİ',
          child: InkWell(
            onTap: _selectedMainCategory == null ? null : _pickAlt,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.colors.border),
                color: _selectedMainCategory == null ? context.colors.surfaceVariant.withOpacity(0.5) : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedSubCategory?.name ?? (_selectedMainCategory == null ? 'Önce ana kategori seçin' : 'Seçiniz (opsiyonel)'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _selectedSubCategory == null ? context.colors.textSecondary : context.colors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.subdirectory_arrow_right_rounded, color: context.colors.textSecondary, size: 20),
                ],
              ),
            ),
          ),
        ),



        // ALICI / SATICI (Tahsilatta: MÜŞTERİ) Text Field
        _buildFormRow(
          label: _isIncome ? 'MÜŞTERİ' : 'ALICI / SATICI',
          child: _buildTextField(
            controller: _buyerSellerController,
            hintText: _isIncome ? 'Müşteri adı' : 'Betoncu',
          ),
        ),

        // TUTAR Text Field
        _buildFormRow(
          label: 'TUTAR',
          child: _buildTextField(
            controller: _amountController,
            prefixText: '₺  ',
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsSeparatorInputFormatter()],
          ),
        ),

        // MİKTAR (Opsiyonel)
        _buildFormRow(
          label: 'MİKTAR (Opsiyonel)',
          child: _buildTextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
          ),
        ),

        // BİRİM (Opsiyonel)
        _buildFormRow(
          label: 'BİRİM',
          child: DropdownButtonFormField<String>(
            value: _selectedUnit,
            decoration: InputDecoration(
              filled: true,
              fillColor: context.colors.surfaceVariant.withValues(alpha: 0.5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
            onChanged: (val) => setState(() => _selectedUnit = val),
          ),
        ),

        // AÇIKLAMA Text Field
        _buildFormRow(
          label: 'AÇIKLAMA',
          child: _buildTextField(
            controller: _descriptionController,
          ),
        ),

        _buildAttachmentRow(),
      ],
    );
  }

  // FATURA EKLE File Attach Row — hem Ödeme/Tahsilat hem Borçlanma formunda kullanılır.
  Widget _buildAttachmentRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              'FATURA EKLE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: context.colors.textSecondary,
              ),
            ),
          ),
          const Spacer(),
          if (_pickedAttachment != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(File(_pickedAttachment!.path), width: 32, height: 32, fit: BoxFit.cover),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.close_rounded, color: context.colors.textSecondary, size: 18),
              onPressed: () => setState(() => _pickedAttachment = null),
            ),
          ] else if (!_removeExistingAttachment &&
              widget.initialTransaction?.attachmentUrl != null &&
              widget.initialTransaction!.attachmentUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                widget.initialTransaction!.attachmentUrl!,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) =>
                    Icon(Icons.description_outlined, size: 24, color: context.colors.brand),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.close_rounded, color: context.colors.textSecondary, size: 18),
              onPressed: () => setState(() => _removeExistingAttachment = true),
            ),
          ] else
            IconButton(
              icon: Icon(Icons.link_rounded, color: context.colors.brand, size: 22),
              onPressed: () async {
                await _pickAttachment();
                if (mounted) setState(() => _removeExistingAttachment = false);
              },
            ),
        ],
      ),
    );
  }

  // --- TRANSFER FORM LAYOUT ---
  Widget _buildTransferForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFormRow(
          label: 'TARİH',
          child: InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: _firstDayOfMonth,
                lastDate: _lastDayOfMonth,
              );
              if (picked != null) {
                setState(() {
                  _transferTarih =
                      "${picked.day} ${['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'][picked.month - 1]} ${picked.year}";
                });
              }
            },
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.colors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _transferTarih,
                    style: TextStyle(fontSize: 14, color: context.colors.textPrimary, fontWeight: FontWeight.w500),
                  ),
                  Icon(Icons.calendar_month_outlined, color: context.colors.textSecondary, size: 20),
                ],
              ),
            ),
          ),
        ),
        _buildFormRow(
          label: 'GÖNDEREN',
          child: _buildSimpleDropdown(
            value: _transferGonderen,
            items: _accountNames,
            emptyHint: 'Önce hesap ekleyin',
            onChanged: (val) {
              setState(() {
                _transferGonderen = val!;
              });
            },
          ),
        ),
        _buildFormRow(
          label: 'ALICI',
          child: _buildSimpleDropdown(
            value: _transferAlan,
            items: _accountNames,
            emptyHint: 'Önce hesap ekleyin',
            onChanged: (val) {
              setState(() {
                _transferAlan = val!;
              });
            },
          ),
        ),
        _buildFormRow(
          label: 'TUTAR',
          child: _buildTextField(
            controller: _transferTutarController,
            prefixText: '₺  ',
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsSeparatorInputFormatter()],
          ),
        ),
        _buildFormRow(
          label: 'AÇIKLAMA',
          child: _buildTextField(
            controller: _transferAciklamaController,
          ),
        ),
      ],
    );
  }

  // --- BORÇLANMA FORM LAYOUT ---
  Widget _buildBorclanmaForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFormRow(
          label: 'TARİH',
          child: InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: _firstDayOfMonth,
                lastDate: _lastDayOfMonth,
              );
              if (picked != null) {
                setState(() {
                  _borclanmaTarih =
                      "${picked.day} ${['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'][picked.month - 1]} ${picked.year}";
                });
              }
            },
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.colors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _borclanmaTarih,
                    style: TextStyle(fontSize: 14, color: context.colors.textPrimary, fontWeight: FontWeight.w500),
                  ),
                  Icon(Icons.calendar_month_outlined, color: context.colors.textSecondary, size: 20),
                ],
              ),
            ),
          ),
        ),
        _buildFormRow(
          label: 'KATEGORİ',
          child: _buildSimpleDropdown(
            value: _borclanmaKategori,
            items: _borclanmaKategorileri,
            onChanged: (val) {
              setState(() {
                _borclanmaKategori = val!;
              });
            },
          ),
        ),
        _buildFormRow(
          label: 'BORÇLANILAN',
          child: _buildTextField(
            controller: _borclanilanKisiController,
            hintText: 'Kişi veya Kurum Adı',
          ),
        ),
        _buildFormRow(
          label: 'PROJE',
          child: _buildSimpleDropdown(
            value: _borclanmaProje,
            items: _projectNames,
            emptyHint: 'Önce proje ekleyin',
            onChanged: (val) {
              setState(() {
                _borclanmaProje = val!;
              });
            },
          ),
        ),
        _buildFormRow(
          label: 'TUTAR',
          child: _buildTextField(
            controller: _borclanmaTutarController,
            prefixText: '₺  ',
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsSeparatorInputFormatter()],
          ),
        ),
        _buildFormRow(
          label: 'VADE TARİHİ',
          child: InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() {
                  _borclanmaVade =
                      "${picked.day} ${['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'][picked.month - 1]} ${picked.year}";
                });
              }
            },
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.colors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _borclanmaVade,
                    style: TextStyle(
                      fontSize: 14,
                      color: _borclanmaVade == 'Seçiniz' ? context.colors.textSecondary : context.colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(Icons.calendar_month_outlined, color: context.colors.textSecondary, size: 20),
                ],
              ),
            ),
          ),
        ),
        _buildFormRow(
          label: 'FATURA NO',
          child: _buildTextField(
            controller: _borclanmaFaturaNoController,
            hintText: 'Fatura / belge numarası',
          ),
        ),
        _buildFormRow(
          label: 'AÇIKLAMA',
          child: _buildTextField(
            controller: _borclanmaAciklamaController,
          ),
        ),
        _buildAttachmentRow(),
      ],
    );
  }

  // --- KREDİ KULLANIMI FORM LAYOUT ---
  Widget _buildKrediKullanimiForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFormRow(
          label: 'TARİH',
          child: InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: _firstDayOfMonth,
                lastDate: _lastDayOfMonth,
              );
              if (picked != null) {
                setState(() {
                  _krediTarih =
                      "${picked.day} ${['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'][picked.month - 1]} ${picked.year}";
                });
              }
            },
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.colors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _krediTarih,
                    style: TextStyle(fontSize: 14, color: context.colors.textPrimary, fontWeight: FontWeight.w500),
                  ),
                  Icon(Icons.calendar_month_outlined, color: context.colors.textSecondary, size: 20),
                ],
              ),
            ),
          ),
        ),
        _buildFormRow(
          label: 'BANKA',
          child: _buildSimpleDropdown(
            value: _krediBanka,
            items: _bankNames,
            emptyHint: 'Önce banka hesabı ekleyin',
            onChanged: (val) {
              setState(() {
                _krediBanka = val!;
              });
            },
          ),
        ),
        _buildFormRow(
          label: 'PROJE',
          child: _buildSimpleDropdown(
            value: _krediProje,
            items: _projectNames,
            emptyHint: 'Önce proje ekleyin',
            onChanged: (val) {
              setState(() {
                _krediProje = val!;
              });
            },
          ),
        ),
        _buildFormRow(
          label: 'TUTAR',
          child: _buildTextField(
            controller: _krediTutarController,
            prefixText: '₺  ',
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsSeparatorInputFormatter()],
          ),
        ),
        _buildFormRow(
          label: 'VADE (AY)',
          child: _buildTextField(
            controller: _krediVadeController,
            keyboardType: TextInputType.number,
            hintText: '12',
          ),
        ),
        _buildFormRow(
          label: 'AYLIK TAKSİT',
          child: _buildTextField(
            controller: _krediTaksitController,
            prefixText: '₺  ',
            keyboardType: TextInputType.number,
          ),
        ),
        _buildFormRow(
          label: 'AÇIKLAMA',
          child: _buildTextField(
            controller: _krediAciklamaController,
          ),
        ),
      ],
    );
  }

  // --- SATIŞ FORM LAYOUT ---
  Widget _buildSatisForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFormRow(
          label: 'TARİH',
          child: InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: _firstDayOfMonth,
                lastDate: _lastDayOfMonth,
              );
              if (picked != null) {
                setState(() {
                  _satisTarih =
                      "${picked.day} ${['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'][picked.month - 1]} ${picked.year}";
                });
              }
            },
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.colors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _satisTarih,
                    style: TextStyle(fontSize: 14, color: context.colors.textPrimary, fontWeight: FontWeight.w500),
                  ),
                  Icon(Icons.calendar_month_outlined, color: context.colors.textSecondary, size: 20),
                ],
              ),
            ),
          ),
        ),
        _buildFormRow(
          label: 'PROJE',
          child: _buildSimpleDropdown(
            value: _satisProje,
            items: _projectNames,
            emptyHint: 'Önce proje ekleyin',
            onChanged: (val) {
              setState(() {
                _satisProje = val!;
              });
            },
          ),
        ),
        _buildFormRow(
          label: 'MÜŞTERİ',
          child: _buildTextField(
            controller: _satisMusteriController,
            hintText: 'Müşteri Adı Soyadı',
          ),
        ),
        _buildFormRow(
          label: 'BÖLÜM/DAİRE',
          child: _buildTextField(
            controller: _satisBlokDaireController,
            hintText: 'A Blok No: 12',
          ),
        ),
        _buildFormRow(
          label: 'SATIŞ BEDELİ',
          child: _buildTextField(
            controller: _satisBedeliController,
            prefixText: '₺  ',
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsSeparatorInputFormatter()],
          ),
        ),
        _buildFormRow(
          label: 'PEŞİNAT',
          child: _buildTextField(
            controller: _satisPesinatController,
            prefixText: '₺  ',
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsSeparatorInputFormatter()],
          ),
        ),
        _buildFormRow(
          label: 'AÇIKLAMA',
          child: _buildTextField(
            controller: _satisAciklamaController,
          ),
        ),
      ],
    );
  }

  // --- Helper Widgets ---

  // Row container for labels and input fields (Ödeme form)
  Widget _buildFormRow({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: context.colors.textSecondary,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  // Text Form Field helper (Ödeme form)
  Widget _buildTextField({
    required TextEditingController controller,
    String? hintText,
    String? prefixText,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(fontSize: 14, color: context.colors.textPrimary, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: context.colors.textSecondary, fontSize: 14),
          prefixText: prefixText,
          prefixStyle: TextStyle(color: context.colors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: context.colors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: context.colors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: context.colors.accent, width: 1.5),
          ),
        ),
      ),
    );
  }

  // Boş liste durumunda gösterilen bilgilendirme kutusu (dropdown yerine).
  Widget _buildEmptyDropdownHint(String hint) {
    return Container(
      height: 44,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colors.border),
      ),
      child: Text(
        hint,
        style: TextStyle(fontSize: 13, color: context.colors.textSecondary, fontStyle: FontStyle.italic),
      ),
    );
  }

  // Simple Dropdown helper (Ödeme form)
  Widget _buildSimpleDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String emptyHint = 'Kayıt bulunamadı',
  }) {
    if (items.isEmpty) return _buildEmptyDropdownHint(emptyHint);
    final safeValue = items.contains(value) ? value : items.first;
    return SizedBox(
      height: 44,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: safeValue,
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(fontSize: 14, color: context.colors.textPrimary, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: context.colors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: context.colors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: context.colors.accent, width: 1.5),
          ),
        ),
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: context.colors.textSecondary, size: 20),
      ),
    );
  }
  void _updateCategoriesForType(bool isIncome) {
    final fp = Provider.of<FinanceProvider>(context, listen: false);
    final mainCats = fp.categories.where((c) => c.isMain && (c.isIncome == isIncome)).toList();
    if (mainCats.isNotEmpty) {
      _selectedMainCategory = mainCats.first;
      final subCats = fp.subCategoriesOf(_selectedMainCategory!.id!);
      _selectedSubCategory = subCats.isNotEmpty ? subCats.first : null;
    } else {
      _selectedMainCategory = null;
      _selectedSubCategory = null;
    }
  }

  Future<void> _pickAna() async {
    final selected = await _showCategorySheet(
      title: 'Ana Kategori Seçin',
      isIncome: _isIncome,
    );
    if (selected != null) {
      setState(() {
        _selectedMainCategory = selected;
        _selectedSubCategory = null;
      });
    }
  }

  Future<void> _pickAlt() async {
    final fp = context.read<FinanceProvider>();
    final selected = await _showSubSheet(fp, _selectedMainCategory!);
    if (selected != null) {
      setState(() {
        _selectedSubCategory = selected;
      });
    }
  }

  Future<Category?> _showCategorySheet({
    required String title,
    required bool isIncome,
  }) {
    final Set<String> expandedGroups = {};
    final searchController = TextEditingController();
    
    final result = showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final fp = ctx.watch<FinanceProvider>();
          // Her rebuild'de canlı olarak kategorileri alıyoruz
          final grouped = fp.mainCategoriesByGroup(income: isIncome);
          final query = searchController.text.trim().toLowerCase();
          
          final filteredGrouped = <String, List<Category>>{};
          for (final entry in grouped.entries) {
            final list = entry.value.where((c) {
              final matchesMain = c.name.toLowerCase().contains(query);
              final subCats = fp.categories.where((sc) => sc.parentId == c.id);
              final matchesSub = subCats.any((sc) => sc.name.toLowerCase().contains(query));
              return matchesMain || matchesSub;
            }).toList();
            if (list.isNotEmpty) {
              filteredGrouped[entry.key] = list;
            }
          }

          return SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.7,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: context.colors.border, borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Kategori ara...',
                            prefixIcon: Icon(Icons.search, size: 20, color: context.colors.textSecondary),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.colors.border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.colors.border)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.colors.accent)),
                            filled: true,
                            fillColor: context.colors.scaffold,
                          ),
                          onChanged: (val) {
                            setSheetState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _showAddMainCategoryDialog(ctx, _isIncome, () {
                          setSheetState(() {
                            // fp.mainCategoriesByGroup returns the updated categories map from state
                            // But wait, the map passed as parameter "grouped" was built on the outer build.
                            // If we read it dynamically in filteredGrouped from fp, it will update!
                          });
                        }),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: context.colors.surfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.add, color: context.colors.accent, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: context.colors.surfaceVariant),
                Expanded(
                  child: ListView(
                    children: [
                      for (final entry in filteredGrouped.entries) ...[
                        InkWell(
                          onTap: () {
                            setSheetState(() {
                              if (expandedGroups.contains(entry.key)) {
                                expandedGroups.remove(entry.key);
                              } else {
                                expandedGroups.add(entry.key);
                              }
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: context.colors.textSecondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Icon(
                                  (query.isNotEmpty || expandedGroups.contains(entry.key))
                                      ? Icons.keyboard_arrow_down_rounded
                                      : Icons.keyboard_arrow_right_rounded,
                                  color: context.colors.textSecondary,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (query.isNotEmpty || expandedGroups.contains(entry.key))
                          for (final c in entry.value)
                            ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.fromLTRB(36, 0, 20, 0),
                              title: Text(c.name, style: TextStyle(fontSize: 14, color: context.colors.textPrimary)),
                              trailing: c.childCount > 0
                                  ? Text('${c.childCount} alt', style: TextStyle(fontSize: 11, color: context.colors.textSecondary))
                                  : null,
                              onTap: () {
                                Navigator.pop(ctx, c);
                              },
                            ),
                        Divider(height: 1, color: context.colors.surfaceVariant.withValues(alpha: 0.5)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
    // Sheet kapandıktan sonra controller'ı güvenle dispose ediyoruz
    return result.whenComplete(() => searchController.dispose());
  }

  void _showAddMainCategoryDialog(BuildContext ctx, bool isIncome, VoidCallback onCreated) {
    final nameController = TextEditingController();
    final groupController = TextEditingController();
    
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text('Yeni Ana Kategori Ekle', style: TextStyle(color: context.colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Kategori Adı',
                labelStyle: TextStyle(color: context.colors.textSecondary),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: context.colors.accent)),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: groupController,
              decoration: InputDecoration(
                labelText: 'Grup Adı (Örn: Hane, Opsiyonel)',
                labelStyle: TextStyle(color: context.colors.textSecondary),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: context.colors.accent)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('İptal', style: TextStyle(color: context.colors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final group = groupController.text.trim();
              
              try {
                final fp = ctx.read<FinanceProvider>();
                final created = await fp.createCategory(
                  name: name,
                  type: isIncome ? 'income' : 'cost',
                  group: group.isEmpty ? 'Diğer' : group,
                );
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('"${created.name}" ana kategorisi eklendi.'), backgroundColor: Colors.green),
                  );
                  onCreated();
                }
              } catch (e) {
                if (dialogCtx.mounted) {
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                    SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text('Ekle', style: TextStyle(color: context.colors.accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<Category?> _showSubSheet(FinanceProvider fp, Category ana) {
    final controller = TextEditingController();
    bool adding = false;
    bool saving = false;
    return showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          final subs = fp.subCategoriesOf(ana.id!);
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.7,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: context.colors.border, borderRadius: BorderRadius.circular(2))),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.folder_open_rounded, color: _isIncome ? context.colors.success : context.colors.danger, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text('${ana.name} • Alt Kategori',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.textPrimary), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: context.colors.surfaceVariant),
                  Expanded(
                    child: ListView(
                      children: [
                        if (subs.isEmpty && !adding)
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text('Henüz alt kategori yok. Aşağıdan ekleyebilirsiniz.',
                                style: TextStyle(color: context.colors.textSecondary, fontSize: 13)),
                          ),
                        for (final s in subs)
                          ListTile(
                            dense: true,
                            title: Text(s.name, style: TextStyle(fontSize: 14, color: context.colors.textPrimary)),
                            onTap: () => Navigator.pop(ctx, s),
                          ),
                        const SizedBox(height: 6),
                        if (adding)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: controller,
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      hintText: 'Yeni alt kategori adı',
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: saving ? null : () async {
                                    final name = controller.text.trim();
                                    if (name.isEmpty) return;
                                    setSheet(() => saving = true);
                                    try {
                                      final created = await fp.addSubCategory(name: name, parentId: ana.id!, type: ana.type);
                                      if (ctx.mounted) Navigator.pop(ctx, created);
                                    } catch (_) {
                                      setSheet(() => saving = false);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isIncome ? context.colors.success : context.colors.danger,
                                    foregroundColor: context.colors.surface,
                                    elevation: 0
                                  ),
                                  child: saving
                                      ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.surface))
                                      : const Text('Ekle'),
                                ),
                              ],
                            ),
                          )
                        else
                          ListTile(
                            dense: true,
                            leading: Icon(Icons.add_circle_outline_rounded, color: _isIncome ? context.colors.success : context.colors.danger, size: 22),
                            title: Text('Yeni alt kategori ekle',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _isIncome ? context.colors.success : context.colors.danger)),
                            onTap: () => setSheet(() => adding = true),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}

class PaymentSourceItem {
  final String name;
  final bool isBank;
  final IconData? icon;
  final Color? iconColor;

  PaymentSourceItem({
    required this.name,
    required this.isBank,
    this.icon,
    this.iconColor,
  });
}
