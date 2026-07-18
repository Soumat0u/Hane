import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hane/theme/app_theme.dart';
import 'package:hane/theme/responsive.dart';
import 'package:provider/provider.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/models/account.dart';
import 'package:hane/views/widgets/bank_logo.dart';
import 'package:hane/utils/thousands_formatter.dart';

class YeniHesapView extends StatefulWidget {
  final String? initialType;
  final bool lockType;
  final Account? account;
  const YeniHesapView({super.key, this.initialType, this.lockType = false, this.account});

  @override
  State<YeniHesapView> createState() => _YeniHesapViewState();
}

class _YeniHesapViewState extends State<YeniHesapView> {
  final _formKey = GlobalKey<FormState>();
  
  String _selectedType = 'Banka'; // 'Banka', 'Kredi Kartı', 'Nakit'
  String? _selectedBank;
  final List<String> _banks = [
    'Ziraat Bankası',
    'Garanti BBVA',
    'Halkbank',
    'Akbank',
    'Yapı Kredi',
    'İş Bankası',
    'VakıfBank',
    'QNB Finansbank',
    'DenizBank',
    'TEB',
    'Kuveyt Türk',
    'Enpara',
    'Şekerbank',
    'ING',
    'Fibabanka',
    'Albaraka Türk',
    'Odeabank',
    'Alternatif Bank',
    'Anadolubank',
    'HSBC',
    'Türkiye Finans',
    'Diğer'
  ];
  
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _ibanController = TextEditingController();
  
  final _cardNumberController = TextEditingController();
  final _limitController = TextEditingController();
  final _debtController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _selectedType = widget.account!.type;
      _nameController.text = widget.account!.name;
      _selectedBank = widget.account!.bankLogoPainter.isNotEmpty ? widget.account!.bankLogoPainter : null;
      if (_selectedType == 'Banka') {
        _balanceController.text = formatAmountForDisplay(widget.account!.openingBalance);
        _ibanController.text = widget.account!.accountDetails;
      } else if (_selectedType == 'Kredi Kartı') {
        final cleanDetails = widget.account!.accountDetails.replaceAll(' ', '');
        if (cleanDetails.length == 16 && !cleanDetails.contains('*')) {
          final buffer = StringBuffer();
          for (var i = 0; i < cleanDetails.length; i++) {
            if (i > 0 && i % 4 == 0) buffer.write(' ');
            buffer.write(cleanDetails[i]);
          }
          _cardNumberController.text = buffer.toString();
        } else {
          _cardNumberController.text = cleanDetails.contains('*') ? '' : cleanDetails;
        }
        _limitController.text = formatAmountForDisplay(widget.account!.creditLimit);
        _debtController.text = formatAmountForDisplay(widget.account!.openingBalance.abs());
      } else if (_selectedType == 'Nakit') {
        _balanceController.text = formatAmountForDisplay(widget.account!.openingBalance);
      }
    } else {
      if (widget.initialType != null && ['Banka', 'Kredi Kartı', 'Nakit'].contains(widget.initialType)) {
        _selectedType = widget.initialType!;
      }
      _ibanController.text = 'TR';
    }
    
    if (_selectedType == 'Banka' && widget.account == null) {
      _ibanController.selection = TextSelection.collapsed(offset: _ibanController.text.length);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _ibanController.dispose();
    _cardNumberController.dispose();
    _limitController.dispose();
    _debtController.dispose();
    super.dispose();
  }

  void _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    double balance = 0.0;
    double limit = 0.0;
    String details = '';

    if (_selectedType == 'Banka') {
      balance = parseThousandsFormatted(_balanceController.text);
      details = _ibanController.text.replaceAll(' ', '');
    } else if (_selectedType == 'Kredi Kartı') {
      double debt = parseThousandsFormatted(_debtController.text);
      balance = -debt; // Borç eksi bakiye olarak kaydedilir
      limit = parseThousandsFormatted(_limitController.text);
      details = _cardNumberController.text.replaceAll(' ', ''); // Save the full 16-digit card number (no spaces)
    } else if (_selectedType == 'Nakit') {
      balance = parseThousandsFormatted(_balanceController.text);
    }

    final accountId = widget.account?.id ?? 0;
    final isEdit = widget.account != null;

    final newAccount = Account(
      id: accountId,
      name: _nameController.text,
      type: _selectedType,
      openingBalance: balance,
      balance: isEdit ? widget.account!.balance + (balance - widget.account!.openingBalance) : balance,
      creditLimit: limit,
      bankLogoPainter: _selectedBank ?? '',
      accountDetails: details,
      isActive: widget.account?.isActive ?? true,
    );

    try {
      final fp = Provider.of<FinanceProvider>(context, listen: false);
      if (isEdit) {
        await fp.updateAccount(newAccount);
      } else {
        await fp.createAccount(newAccount);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Hesap başarıyla güncellendi!' : 'Hesap başarıyla eklendi!'), 
            backgroundColor: Colors.green
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        title: Text(
          widget.account != null
              ? '${widget.account!.name} Düzenle'
              : (widget.lockType ? 'Yeni ${widget.initialType} Ekle' : 'Yeni Hesap Ekle'),
          style: TextStyle(color: context.colors.brand, fontWeight: FontWeight.bold),
        ),
        backgroundColor: context.colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.brand),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: centeredPagePadding(context, maxContentWidth: 560, horizontal: 20, top: 20, bottom: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!widget.lockType && widget.account == null) ...[
                  _buildTypeSelector(),
                  const SizedBox(height: 24),
                ],
                if (_selectedType == 'Banka') _buildBankaForm()
                else if (_selectedType == 'Kredi Kartı') _buildKrediKartiForm()
                else if (_selectedType == 'Nakit') _buildNakitForm(),
                
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: context.colors.surface, strokeWidth: 2))
                      : Text(widget.account != null ? 'Güncelle' : 'Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.surface)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: ['Banka', 'Kredi Kartı', 'Nakit'].map((type) {
          final isSelected = _selectedType == type;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = type;
                  _selectedBank = null;
                  _nameController.clear();
                  _balanceController.clear();
                  _ibanController.text = 'TR';
                  _ibanController.selection = TextSelection.collapsed(offset: 2);
                  _cardNumberController.clear();
                  _limitController.clear();
                  _debtController.clear();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? context.colors.brand : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 4, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Center(
                  child: Text(
                    type,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected ? context.colors.surface : context.colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBankDropdown() {
    return FormField<String>(
      validator: (val) => _selectedBank == null ? 'Lütfen bir banka seçiniz' : null,
      builder: (FormFieldState<String> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Banka Seçiniz',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.colors.textSecondary),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _showBankSelectionSheet(state),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: context.colors.scaffold,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: state.hasError ? Colors.red : context.colors.border),
                ),
                child: Row(
                  children: [
                    if (_selectedBank != null) ...[
                      BankLogoWidget(bankName: _selectedBank!, width: 24, height: 24),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_selectedBank!, style: TextStyle(color: context.colors.textPrimary))),
                    ] else ...[
                      Expanded(child: Text('Banka seçin', style: TextStyle(color: Colors.grey[600]))),
                    ],
                    Icon(Icons.arrow_drop_down, color: context.colors.textSecondary),
                  ],
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Text(state.errorText!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  void _showBankSelectionSheet(FormFieldState<String> state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, controller) {
            return SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Banka Seçin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.brand)),
                        IconButton(
                          icon: Icon(Icons.close, color: context.colors.textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: context.colors.border),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _banks.length,
                      itemBuilder: (context, index) {
                        final bank = _banks[index];
                        return ListTile(
                          leading: BankLogoWidget(bankName: bank, width: 32, height: 32),
                          title: Text(bank, style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.w600)),
                          onTap: () {
                            setState(() {
                              _selectedBank = bank;
                            });
                            state.didChange(bank);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBankaForm() {
    return Column(
      children: [
        _buildBankDropdown(),
        _buildTextField('Hesap / Kart Adı (Maaş Hesabı vb.)', _nameController, TextInputType.text),
        const SizedBox(height: 16),
        _buildTextField('Güncel Bakiye (₺)', _balanceController, const TextInputType.numberWithOptions(decimal: true), inputFormatters: [ThousandsSeparatorInputFormatter()]),
        const SizedBox(height: 16),
        _buildTextField('IBAN', _ibanController, TextInputType.text, inputFormatters: [_IbanInputFormatter()], minRawLength: 26),
      ],
    );
  }

  Widget _buildKrediKartiForm() {
    return Column(
      children: [
        _buildBankDropdown(),
        _buildTextField('Kart Adı (Bonus, Axess vb.)', _nameController, TextInputType.text),
        const SizedBox(height: 16),
        _buildTextField(
          'Kart Numarası (16 Hane)', 
          _cardNumberController, 
          TextInputType.number, 
          inputFormatters: [_CardNumberInputFormatter()], 
          minRawLength: 16,
          maxLength: 19
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Kart Limiti (₺)', _limitController, const TextInputType.numberWithOptions(decimal: true), inputFormatters: [ThousandsSeparatorInputFormatter()])),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Güncel Borç (₺)', _debtController, const TextInputType.numberWithOptions(decimal: true), inputFormatters: [ThousandsSeparatorInputFormatter()])),
          ],
        ),
      ],
    );
  }

  Widget _buildNakitForm() {
    return Column(
      children: [
        _buildTextField('Kasa Adı (Merkez Kasa vb.)', _nameController, TextInputType.text),
        const SizedBox(height: 16),
        _buildTextField('Güncel Bakiye (₺)', _balanceController, const TextInputType.numberWithOptions(decimal: true), inputFormatters: [ThousandsSeparatorInputFormatter()]),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, TextInputType type,
      {int? maxLength, String? hint, List<TextInputFormatter>? inputFormatters, int? minRawLength}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.colors.textSecondary),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: type,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.accent)),
            filled: true,
            fillColor: context.colors.scaffold,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Bu alan zorunludur';
            if (maxLength != null && value.length != maxLength) {
              if (label.contains('Numarası')) {
                return 'Kart numarası 16 haneli olmalıdır';
              }
              return '$maxLength hane giriniz';
            }
            if (minRawLength != null && value.replaceAll(' ', '').length < minRawLength) {
              if (label.contains('IBAN')) {
                return 'Geçerli bir IBAN giriniz';
              }
              return 'Geçerli bir kart numarası giriniz';
            }
            return null;
          },
        ),
      ],
    );
  }
}

/// IBAN alanı için: her zaman "TR" öneki korunur, karakterler otomatik
/// büyük harfe çevrilir ve her 4 karakterde bir boşluk eklenir
/// (Türkiye IBAN'ları 26 karakterdir: TR + 24 hane).
class _IbanInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Değişmeden önceki metindeki boşluksuz karakter sayısına göre imleç konumunu takip et.
    final rawCursorIndex = newValue.selection.end;
    final rawBeforeCursor = newValue.text.substring(0, rawCursorIndex.clamp(0, newValue.text.length));
    final digitsBeforeCursor = rawBeforeCursor.replaceAll(' ', '').length;

    var raw = newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (!raw.startsWith('TR')) {
      raw = 'TR${raw.replaceFirst(RegExp(r'^T?R?'), '')}';
    }
    if (raw.length > 26) raw = raw.substring(0, 26);

    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(raw[i]);
    }
    final formatted = buffer.toString();

    // Yeni imleç konumunu, önceki boşluksuz karakter sayısına denk gelecek şekilde hesapla.
    var newOffset = 0;
    var seenDigits = 0;
    for (var i = 0; i < formatted.length; i++) {
      if (seenDigits >= digitsBeforeCursor) break;
      if (formatted[i] != ' ') seenDigits++;
      newOffset = i + 1;
    }
    newOffset = newOffset.clamp(2, formatted.length);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}

/// Kart numarası için: her 4 rakamda bir boşluk ekler (toplam 16 hane + 3 boşluk = 19 karakter).
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(' ', '').replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 16) text = text.substring(0, 16);
    
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
