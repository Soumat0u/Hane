import 'package:flutter/material.dart';

import 'package:hane/theme/app_theme.dart';
import 'package:hane/theme/responsive.dart';
import 'package:provider/provider.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/models/account.dart';
import 'package:hane/views/widgets/bank_logo.dart';

class YeniHesapView extends StatefulWidget {
  final String? initialType;
  const YeniHesapView({super.key, this.initialType});

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
    if (widget.initialType != null && ['Banka', 'Kredi Kartı', 'Nakit'].contains(widget.initialType)) {
      _selectedType = widget.initialType!;
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
      balance = double.tryParse(_balanceController.text) ?? 0.0;
      details = _ibanController.text;
    } else if (_selectedType == 'Kredi Kartı') {
      double debt = double.tryParse(_debtController.text) ?? 0.0;
      balance = -debt; // Borç eksi bakiye olarak kaydedilir
      limit = double.tryParse(_limitController.text) ?? 0.0;
      details = '**** **** **** ${_cardNumberController.text}';
    } else if (_selectedType == 'Nakit') {
      balance = double.tryParse(_balanceController.text) ?? 0.0;
    }

    final newAccount = Account(
      id: 0,
      name: _nameController.text,
      type: _selectedType,
      openingBalance: balance,
      balance: balance,
      creditLimit: limit,
      bankLogoPainter: _selectedBank ?? '',
      accountDetails: details,
      isActive: true,
    );

    try {
      final fp = Provider.of<FinanceProvider>(context, listen: false);
      await fp.createAccount(newAccount);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hesap başarıyla eklendi!'), backgroundColor: Colors.green),
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
    final colors = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        title: Text('Yeni Hesap Ekle', style: TextStyle(color: context.colors.brand, fontWeight: FontWeight.bold)),
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
                _buildTypeSelector(),
                const SizedBox(height: 24),
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
                      : Text('Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.surface)),
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
                  _ibanController.clear();
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
        _buildTextField('Güncel Bakiye (₺)', _balanceController, const TextInputType.numberWithOptions(decimal: true)),
        const SizedBox(height: 16),
        _buildTextField('IBAN', _ibanController, TextInputType.text, hint: 'TR...'),
      ],
    );
  }

  Widget _buildKrediKartiForm() {
    return Column(
      children: [
        _buildBankDropdown(),
        _buildTextField('Kart Adı (Bonus, Axess vb.)', _nameController, TextInputType.text),
        const SizedBox(height: 16),
        _buildTextField('Kart Numarası (Son 4 Hane)', _cardNumberController, TextInputType.number, maxLength: 4),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Kart Limiti (₺)', _limitController, const TextInputType.numberWithOptions(decimal: true))),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Güncel Borç (₺)', _debtController, const TextInputType.numberWithOptions(decimal: true))),
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
        _buildTextField('Güncel Bakiye (₺)', _balanceController, const TextInputType.numberWithOptions(decimal: true)),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, TextInputType type, {int? maxLength, String? hint}) {
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
            if (maxLength != null && value.length != maxLength) return '$maxLength hane giriniz';
            return null;
          },
        ),
      ],
    );
  }
}
