import 'package:flutter/material.dart';

import 'package:hane/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/models/financial_transaction.dart';
import 'package:hane/models/finance_entities.dart';
import 'package:hane/views/kasa_view.dart';
import 'package:hane/views/widgets/bank_logo.dart';

class YeniIslemScreen extends StatefulWidget {
  final String initialType;
  final String? initialProject;
  final VoidCallback? onBack;

  const YeniIslemScreen({
    super.key,
    this.initialType = 'Ödeme',
    this.initialProject,
    this.onBack,
  });

  @override
  State<YeniIslemScreen> createState() => _YeniIslemScreenState();
}

class _YeniIslemScreenState extends State<YeniIslemScreen> {
  // General Selection State
  String _selectedType = 'Ödeme';

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    if (widget.initialProject != null) {
      if (!_projects.contains(widget.initialProject!)) {
        _projects.add(widget.initialProject!);
      }
      _selectedProject = widget.initialProject!;
    }
  }

  @override
  void didUpdateWidget(covariant YeniIslemScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialType != oldWidget.initialType) {
      setState(() {
        _selectedType = widget.initialType;
      });
    }
  }

  // --- Ödeme Form States ---
  bool _isIncome = false; // false = Gider, true = Gelir
  String _selectedProject = 'Akpınar';
  String _selectedCategory = 'Beton';
  String _selectedSource = 'Halkbank';
  bool _isSourceDropdownOpen = false;

  final TextEditingController _dateController = TextEditingController(text: '10 Haziran 2024');
  final TextEditingController _dueDateController = TextEditingController(text: 'Seçiniz');
  final TextEditingController _buyerSellerController = TextEditingController(text: 'Betoncu');
  final TextEditingController _amountController = TextEditingController(text: '250.000');
  final TextEditingController _descriptionController = TextEditingController(text: 'C25 beton ödemesi');

  List<String> _projects = ['Akpınar', 'Sarayatik', 'Edibecan', 'Yenişehir', 'Güneşli', 'Beykent'];
  final List<String> _categories = ['Beton', 'Demir', 'Hafriyat', 'İşçilik', 'Genel Gider'];

  // --- Transfer Form States ---
  String _transferTarih = '11 Haziran 2024';
  String _transferGonderen = 'Nakit Kasa';
  String _transferAlan = 'Halkbank';
  final TextEditingController _transferTutarController = TextEditingController();
  final TextEditingController _transferAciklamaController = TextEditingController();

  // --- Borclanma Form States ---
  String _borclanmaTarih = '11 Haziran 2024';
  String _borclanmaVade = 'Seçiniz';
  String _borclanmaKategori = 'Tedarikçi Borcu';
  String _borclanmaProje = 'Akpınar';
  final TextEditingController _borclanilanKisiController = TextEditingController();
  final TextEditingController _borclanmaTutarController = TextEditingController();
  final TextEditingController _borclanmaAciklamaController = TextEditingController();
  final List<String> _borclanmaKategorileri = ['Tedarikçi Borcu', 'Banka Kredisi', 'Ortaklara Borçlar', 'Diğer'];

  // --- Kredi Kullanimi Form States ---
  String _krediTarih = '11 Haziran 2024';
  String _krediBanka = 'Halkbank';
  String _krediProje = 'Akpınar';
  final TextEditingController _krediTutarController = TextEditingController();
  final TextEditingController _krediVadeController = TextEditingController();
  final TextEditingController _krediTaksitController = TextEditingController();
  final TextEditingController _krediAciklamaController = TextEditingController();

  // --- Satis Form States ---
  String _satisTarih = '11 Haziran 2024';
  String _satisProje = 'Akpınar Projesi';
  final TextEditingController _satisMusteriController = TextEditingController();
  final TextEditingController _satisBlokDaireController = TextEditingController();
  final TextEditingController _satisBedeliController = TextEditingController();
  final TextEditingController _satisPesinatController = TextEditingController();
  final TextEditingController _satisAciklamaController = TextEditingController();

  // --- Tahsilat Form States ---
  String _tahsilatTarih = '27 Mayıs 2024';
  String _tahsilatKaynagi = 'Müşteri Alacakları';
  String _tahsilatProje = 'Akpınar Projesi';
  String _tahsilatMusteri = 'Mehmet Yılmaz';
  String _tahsilatOdemeYontemi = 'Banka';
  String _tahsilatBankaHesabi = 'Halkbank - TR90 0001 2009 1234 5678 9000 01';

  final TextEditingController _tahsilatAmountController = TextEditingController(text: '1.200.000');
  final TextEditingController _tahsilatAciklamaController = TextEditingController(text: 'Daire Satışı - A Blok No:12');
  final TextEditingController _tahsilatNotController = TextEditingController();

  final List<String> _tahsilatKaynaklari = ['Müşteri Alacakları', 'Ortaklar Borç', 'Diğer Alacaklar'];
  final List<String> _tahsilatProjeler = ['Akpınar Projesi', 'Sarayatik Projesi', 'Edibecan Projesi', 'Yenişehir Projesi', 'Güneşli Projesi', 'Beykent Projesi'];
  final List<String> _tahsilatMusteriler = ['Mehmet Yılmaz', 'Ahmet Kaya', 'Caner Demir', 'Zeynep Kaya'];
  final List<String> _bankAccounts = [
    'Halkbank - TR90 0001 2009 1234 5678 9000 01',
    'Ziraat - TR67 0001 0007 2345 6789 0000 02',
    'Garanti - TR55 0008 2000 1230 0035 2987 03'
  ];


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _dueDateController.dispose();
    _buyerSellerController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _tahsilatAmountController.dispose();
    _tahsilatAciklamaController.dispose();
    _tahsilatNotController.dispose();
    
    _transferTutarController.dispose();
    _transferAciklamaController.dispose();
    
    _borclanilanKisiController.dispose();
    _borclanmaTutarController.dispose();
    _borclanmaAciklamaController.dispose();
    
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

  String _getAmountText() {
    switch (_selectedType) {
      case 'Tahsilat': return _tahsilatAmountController.text;
      case 'Transfer': return _transferTutarController.text;
      case 'Borçlanma': return _borclanmaTutarController.text;
      case 'Kredi Kullanımı': return _krediTutarController.text;
      case 'Satış': return _satisBedeliController.text;
      case 'Ödeme':
      default: return _amountController.text;
    }
  }

  String _getButtonText() {
    switch (_selectedType) {
      case 'Tahsilat': return 'TAHSİLATI KAYDET';
      case 'Transfer': return 'TRANSFERİ KAYDET';
      case 'Borçlanma': return 'BORÇLANMAYI KAYDET';
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
                padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_selectedType == 'Tahsilat')
                      _buildTahsilatForm()
                    else if (_selectedType == 'Transfer')
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
                onPressed: () async {
                  final amountText = _getAmountText().replaceAll(RegExp(r'[^0-9]'), '');
                  final amount = double.tryParse(amountText) ?? 0.0;
                  
                  final fp = Provider.of<FinanceProvider>(context, listen: false);
                  int? projectId;
                  String selectedProjectName = '';
                  
                  if (_selectedType == 'Tahsilat') {
                    selectedProjectName = _tahsilatProje;
                  } else if (_selectedType == 'Borçlanma') {
                    selectedProjectName = _borclanmaProje;
                  } else if (_selectedType == 'Kredi Kullanımı') {
                    selectedProjectName = _krediProje;
                  } else if (_selectedType == 'Satış') {
                    selectedProjectName = _satisProje;
                  } else if (_selectedType == 'Ödeme' || _selectedType == 'Gider' || _selectedType == 'Gelir') {
                    selectedProjectName = _selectedProject;
                  }

                  if (selectedProjectName.isNotEmpty) {
                    final p = fp.projects.where((p) => p.name.contains(selectedProjectName) || selectedProjectName.contains(p.name)).firstOrNull;
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

                  if (_selectedType == 'Ödeme') {
                     type = _isIncome ? 'Gelir' : 'Gider';
                     category = _selectedCategory;
                     source = _selectedSource;
                     date = _dateController.text;
                  } else if (_selectedType == 'Kredi Kullanımı') {
                     category = 'Kredi Kullanımı';
                     source = _krediBanka;
                     date = _krediTarih;
                     
                     // Ayrıca bir Kredi (Loan) kaydı oluştur
                     final l = Loan(
                       name: '$_krediBanka Kredisi',
                       principal: amount,
                       totalPayable: amount,
                     );
                     await fp.addLoan(l);
                  } else if (_selectedType == 'Borçlanma') {
                     category = 'Borçlanma';
                     source = _borclanilanKisiController.text;
                     date = _borclanmaVade;
                     
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
                     );

                     await fp.addTransaction(t);

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
                     return; // Metottan çık
                  } else if (_selectedType == 'Tahsilat') {
                     category = 'Satış';
                     source = _tahsilatBankaHesabi.split(' - ').first;
                     date = _tahsilatTarih;
                  } else if (_selectedType == 'Transfer') {
                     category = 'Transfer';
                     source = _transferGonderen;
                     dest = _transferAlan;
                     date = _transferTarih;
                  } else {
                     category = 'Diğer';
                     date = DateTime.now().toString();
                  }

                  final t = FinancialTransaction(
                    projectId: projectId,
                    type: type,
                    amount: amount,
                    date: date,
                    category: category,
                    sourceName: source,
                    destName: dest,
                  );

                  await fp.addTransaction(t);

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
                child: Text(
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

  // --- ÖDEME FORM LAYOUT ---
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
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
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

        // GELIR / GIDER Toggle
        _buildFormRow(
          label: 'GELİR / GİDER',
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isIncome = true;
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
            items: _projects,
            onChanged: (val) {
              setState(() {
                _selectedProject = val!;
              });
            },
          ),
        ),

        // KATEGORI Dropdown
        _buildFormRow(
          label: 'KATEGORİ',
          child: _buildSimpleDropdown(
            value: _selectedCategory,
            items: _categories,
            onChanged: (val) {
              setState(() {
                _selectedCategory = val!;
              });
            },
          ),
        ),

        // ODEME KAYNAGI Custom Dropdown
        Consumer<FinanceProvider>(
          builder: (context, fp, child) {
            final accounts = fp.accounts.where((a) => a.type == 'Banka' || a.type == 'Kredi Kartı' || a.type == 'Nakit').toList();
            if (accounts.isNotEmpty && !accounts.any((a) => a.name == _selectedSource)) {
               WidgetsBinding.instance.addPostFrameCallback((_) {
                 if (mounted) setState(() => _selectedSource = accounts.first.name);
               });
            }
            if (accounts.isEmpty) return const SizedBox.shrink();

            return _buildFormRow(
              label: 'ÖDEME KAYNAĞI',
              child: SizedBox(
                height: 44,
                child: DropdownButtonFormField<String>(
                  value: accounts.any((a) => a.name == _selectedSource) ? _selectedSource : (accounts.isNotEmpty ? accounts.first.name : null),
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
                  items: accounts.map((a) => a.name).toSet().map((accountName) {
                    return DropdownMenuItem<String>(
                      value: accountName,
                      child: Row(
                        children: [
                          _getSourceIcon(accountName, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              accountName,
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
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
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

        // ALICI / SATICI Text Field
        _buildFormRow(
          label: 'ALICI / SATICI',
          child: _buildTextField(
            controller: _buyerSellerController,
            hintText: 'Betoncu',
          ),
        ),

        // TUTAR Text Field
        _buildFormRow(
          label: 'TUTAR',
          child: _buildTextField(
            controller: _amountController,
            prefixText: '₺  ',
            keyboardType: TextInputType.number,
          ),
        ),


        // AÇIKLAMA Text Field
        _buildFormRow(
          label: 'AÇIKLAMA',
          child: _buildTextField(
            controller: _descriptionController,
          ),
        ),

        // FATURA EKLE File Attach Row
        Padding(
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
              IconButton(
                icon: Icon(Icons.link_rounded, color: context.colors.brand, size: 22),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dosya seçme simülasyonu aktif edildi!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- TAHSİLAT FORM LAYOUT ---
  Widget _buildTahsilatForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // TUTAR (Large input field inside a border container)
        _buildTahsilatInputRow(
          label: 'TUTAR',
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.colors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: TextField(
              controller: _tahsilatAmountController,
              keyboardType: TextInputType.number,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
              decoration: InputDecoration(
                prefixText: '₺ ',
                prefixStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.cancel_rounded, color: context.colors.textSecondary, size: 22),
                  onPressed: () {
                    _tahsilatAmountController.clear();
                  },
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // TARİH
        _buildTahsilatInputRow(
          label: 'TARİH',
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
                  _tahsilatTarih =
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
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.colors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_outlined, color: context.colors.accent, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _tahsilatTarih,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.keyboard_arrow_down_rounded, color: context.colors.textSecondary, size: 20),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // TAHSİLAT KAYNAĞI
        _buildTahsilatInputRow(
          label: 'TAHSİLAT KAYNAĞI',
          child: _buildPrefixDropdown(
            prefixIcon: Icons.person_outline_rounded,
            prefixColor: context.colors.success,
            value: _tahsilatKaynagi,
            items: _tahsilatKaynaklari,
            onChanged: (val) {
              setState(() {
                _tahsilatKaynagi = val!;
              });
            },
          ),
        ),
        const SizedBox(height: 12),

        // PROJE
        _buildTahsilatInputRow(
          label: 'PROJE',
          child: _buildPrefixDropdown(
            prefixIcon: Icons.business_center_outlined,
            prefixColor: context.colors.accent,
            value: _tahsilatProje,
            items: _tahsilatProjeler,
            onChanged: (val) {
              setState(() {
                _tahsilatProje = val!;
              });
            },
          ),
        ),
        const SizedBox(height: 12),

        // MÜŞTERİ
        _buildTahsilatInputRow(
          label: 'MÜŞTERİ',
          child: _buildPrefixDropdown(
            prefixIcon: Icons.account_circle_outlined,
            prefixColor: const Color(0xFF8B5CF6),
            value: _tahsilatMusteri,
            items: _tahsilatMusteriler,
            onChanged: (val) {
              setState(() {
                _tahsilatMusteri = val!;
              });
            },
          ),
        ),
        const SizedBox(height: 12),

        // AÇIKLAMA (Input row with bubble icon left and clean cancel right)
        _buildTahsilatInputRow(
          label: 'AÇIKLAMA',
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.colors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline_rounded, color: context.colors.textSecondary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _tahsilatAciklamaController,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel_rounded, color: Color(0xFFCBD5E1), size: 18),
                  onPressed: () {
                    _tahsilatAciklamaController.clear();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ÖDEME YÖNTEMİ
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ÖDEME YÖNTEMİ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: context.colors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            _buildPaymentMethodRow(),
          ],
        ),
        const SizedBox(height: 16),

        // BANKA HESABI dropdown (Conditional displays if 'Banka' selected)
        if (_tahsilatOdemeYontemi == 'Banka') ...[
          _buildTahsilatInputRow(
            label: 'BANKA HESABI',
            child: _buildPrefixDropdown(
              prefixIcon: Icons.account_balance_rounded,
              prefixColor: context.colors.accent,
              value: _tahsilatBankaHesabi,
              items: _bankAccounts,
              onChanged: (val) {
                setState(() {
                  _tahsilatBankaHesabi = val!;
                });
              },
            ),
          ),
          const SizedBox(height: 12),
        ],

        // NOT (İSTEĞE BAĞLI) Text Field
        _buildTahsilatInputRow(
          label: 'NOT (İSTEĞE BAĞLI)',
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.colors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            child: Row(
              children: [
                Icon(Icons.sticky_note_2_outlined, color: context.colors.textSecondary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _tahsilatNotController,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Not ekleyebilirsiniz...',
                      hintStyle: TextStyle(color: context.colors.textSecondary, fontSize: 14),
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // Row container for labels and input fields in Tahsilat form
  Widget _buildTahsilatInputRow({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: context.colors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  // Horizontal Payment Method row
  Widget _buildPaymentMethodRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMethodItem('Banka', Icons.account_balance_rounded),
        const SizedBox(width: 6),
        _buildMethodItem('Nakit', Icons.money_rounded),
        const SizedBox(width: 6),
        _buildMethodItem('Çek', Icons.text_snippet_outlined),
        const SizedBox(width: 6),
        _buildMethodItem('Kredi Kartı', Icons.credit_card_rounded),
        const SizedBox(width: 6),
        _buildMethodItem('Diğer', Icons.more_horiz_rounded),
      ],
    );
  }

  Widget _buildMethodItem(String method, IconData icon) {
    final bool isSelected = _tahsilatOdemeYontemi == method;
    final Color bgColor = isSelected ? context.colors.accentBg : context.colors.surface;
    final Color borderColor = isSelected ? context.colors.accent : context.colors.border;
    final Color color = isSelected ? context.colors.accent : context.colors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _tahsilatOdemeYontemi = method;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(
                method,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Custom Dropdown with Left Prefix Icon
  Widget _buildPrefixDropdown({
    required IconData prefixIcon,
    required Color prefixColor,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      height: 48,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: Icon(prefixIcon, color: prefixColor, size: 20),
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
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
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
            items: ['Nakit Kasa', 'Halkbank', 'Ziraat', 'Garanti', 'Akbank'],
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
            items: ['Nakit Kasa', 'Halkbank', 'Ziraat', 'Garanti', 'Akbank'],
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
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
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
            items: _projects,
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
          label: 'AÇIKLAMA',
          child: _buildTextField(
            controller: _borclanmaAciklamaController,
          ),
        ),
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
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
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
            items: ['Halkbank', 'Ziraat', 'Garanti', 'Akbank', 'İş Bankası', 'Vakıfbank'],
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
            items: _projects,
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
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
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
            items: _tahsilatProjeler, // Reusing projeler from Tahsilat
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
          ),
        ),
        _buildFormRow(
          label: 'PEŞİNAT',
          child: _buildTextField(
            controller: _satisPesinatController,
            prefixText: '₺  ',
            keyboardType: TextInputType.number,
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
  }) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
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

  // Simple Dropdown helper (Ödeme form)
  Widget _buildSimpleDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      height: 44,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(fontSize: 14, color: context.colors.textPrimary, fontWeight: FontWeight.w500),
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
