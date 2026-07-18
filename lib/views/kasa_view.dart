import 'package:flutter/material.dart';
import 'package:hane/theme/app_theme.dart';
import 'package:hane/theme/responsive.dart';
import 'package:provider/provider.dart';
import 'package:hane/utils/formatters.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/views/kasa_detay_view.dart';
import 'package:hane/models/account.dart';
import 'package:hane/views/widgets/bank_logo.dart';
import 'package:hane/views/yeni_hesap_view.dart';
import 'package:hane/utils/thousands_formatter.dart';

class KasaScreen extends StatelessWidget {
  const KasaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffold,
      appBar: AppBar(
        title: Text('Kasa', style: TextStyle(color: context.colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: context.colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Consumer<FinanceProvider>(
          builder: (context, fp, child) {
            final kasa = fp.getTotalBalance();
            final bankAccounts = fp.accounts.where((a) => a.type == 'Banka').toList();
            final cashAccounts = fp.accounts.where((a) => a.type == 'Nakit').toList();
            final totalBankalar = bankAccounts.fold(0.0, (sum, a) => sum + a.balance);
            final totalNakit = cashAccounts.fold(0.0, (sum, a) => sum + a.balance);

            return RefreshIndicator(
              onRefresh: fp.refreshSilently,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: centeredPagePadding(context, maxContentWidth: 760, top: 8.0, bottom: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Banner
                    Container(
                      decoration: BoxDecoration(
                        color: context.colors.brand,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: const Color(0x3F032B5E), blurRadius: 10, offset: const Offset(0, 6))],
                      ),
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('TOPLAM KASA', style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              const SizedBox(height: 8),
                              Text(currencyFormat.format(kasa), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Icon(Icons.account_balance_wallet_outlined, color: Colors.white.withAlpha(160), size: 48),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // BANKALAR
                    _buildSectionHeader(context, 'BANKALAR', actions: [
                      _SectionAction(label: 'Hesap Ekle', onTap: () => _openNewAccount(context, type: 'Banka', lockType: true)),
                    ]),
                    _buildGroupList(context, bankAccounts, isBank: true),
                    const SizedBox(height: 24),

                    // NAKİT
                    _buildSectionHeader(context, 'NAKİT', actions: [
                      _SectionAction(
                        label: 'Nakit Ekle',
                        onTap: cashAccounts.isEmpty ? null : () => _showAddCashSheet(context, cashAccounts),
                      ),
                      _SectionAction(label: 'Kasa Ekle', onTap: () => _openNewAccount(context, type: 'Nakit', lockType: true)),
                    ]),
                    _buildGroupList(context, cashAccounts, iconData: Icons.payments_outlined, iconColor: Colors.green),
                    const SizedBox(height: 24),

                    // ÖZET
                    Text('ÖZET', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.colors.textSecondary, letterSpacing: 0.5)),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.colors.border)),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                      child: Column(children: [
                        _buildSummaryRow(context, 'Toplam Bankalar', totalBankalar),
                        const SizedBox(height: 12),
                        _buildSummaryRow(context, 'Nakit', totalNakit),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 12.0), child: Divider(height: 1)),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('TOPLAM KASA', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.colors.brand)),
                          Text(currencyFormat.format(kasa), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.brand)),
                        ]),
                      ]),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openNewAccount(BuildContext context, {required String type, required bool lockType}) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => YeniHesapView(initialType: type, lockType: lockType)));
  }

  void _showAddCashSheet(BuildContext context, List<Account> cashAccounts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _AddCashSheet(cashAccounts: cashAccounts),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {List<_SectionAction> actions = const []}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.colors.textSecondary, letterSpacing: 0.5)),
          Row(
            children: actions.map((a) {
              final color = a.onTap == null ? context.colors.textSecondary : context.colors.brand;
              return Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: InkWell(
                  onTap: a.onTap,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Row(children: [
                      Icon(Icons.add, size: 15, color: color),
                      const SizedBox(width: 3),
                      Text(a.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupList(BuildContext context, List<Account> accounts, {bool isBank = false, IconData? iconData, Color? iconColor}) {
    if (accounts.isEmpty) {
      return Container(
        decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.colors.border)),
        padding: const EdgeInsets.all(16.0),
        alignment: Alignment.center,
        child: Text("Kayıt bulunamadı.", style: TextStyle(color: context.colors.textSecondary)),
      );
    }
    return Container(
      decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.colors.border)),
      child: Column(children: [
        ...accounts.asMap().entries.map((entry) {
          final idx = entry.key;
          final a = entry.value;
          return Column(children: [
            _buildListItem(context: context, account: a, isBank: isBank, iconData: iconData, iconColor: iconColor, isLast: idx == accounts.length - 1),
            if (idx < accounts.length - 1) Divider(height: 1, indent: isBank ? 116 : 64, color: context.colors.surfaceVariant),
          ]);
        }),
      ]),
    );
  }

  Widget _buildListItem({required BuildContext context, required Account account, bool isBank = false, IconData? iconData, Color? iconColor, bool isLast = false}) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => KasaDetayView(account: account))),
      borderRadius: isLast
        ? const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16))
        : const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(children: [
          Container(
            width: isBank ? 90 : 38, height: 38,
            decoration: BoxDecoration(color: context.colors.scaffold, borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.all(4.0),
            child: isBank
              ? BankLogoWidget(bankName: account.bankLogoPainter.isNotEmpty ? account.bankLogoPainter : account.name, width: 85, height: 32)
              : Icon(iconData, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(account.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.colors.textPrimary))),
          Text(currencyFormat.format(account.balance), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: context.colors.textSecondary),
        ]),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, double value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.colors.textPrimary)),
      Text(currencyFormat.format(value), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
    ]);
  }
}

class _SectionAction {
  final String label;
  final VoidCallback? onTap;
  const _SectionAction({required this.label, this.onTap});
}

// --- Mevcut bir nakit kasasına hızlıca bakiye ekler ---
class _AddCashSheet extends StatefulWidget {
  final List<Account> cashAccounts;
  const _AddCashSheet({required this.cashAccounts});
  @override
  State<_AddCashSheet> createState() => _AddCashSheetState();
}

class _AddCashSheetState extends State<_AddCashSheet> {
  late Account _selected;
  final _amountController = TextEditingController();
  bool _saving = false;
  String _err = '';

  @override
  void initState() {
    super.initState();
    _selected = widget.cashAccounts.first;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = parseThousandsFormatted(_amountController.text.trim());
    if (amount <= 0) {
      setState(() => _err = 'Geçerli bir tutar giriniz.');
      return;
    }
    setState(() { _saving = true; _err = ''; });
    try {
      final fp = context.read<FinanceProvider>();
      final updated = Account(
        id: _selected.id,
        name: _selected.name,
        type: _selected.type,
        openingBalance: _selected.openingBalance + amount,
        balance: _selected.balance + amount,
        creditLimit: _selected.creditLimit,
        availableLimit: _selected.availableLimit,
        bankLogoPainter: _selected.bankLogoPainter,
        accountDetails: _selected.accountDetails,
        isActive: _selected.isActive,
      );
      await fp.updateAccount(updated);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() { _err = 'Kayıt başarısız: $e'; _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: context.colors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Nakit Ekle', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
          const SizedBox(height: 16),
          if (_err.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.red.withAlpha(30), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.withAlpha(80))),
              child: Text(_err, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),
          if (widget.cashAccounts.length > 1) ...[
            Text('Kasa', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.textSecondary)),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(border: Border.all(color: context.colors.border), borderRadius: BorderRadius.circular(10), color: context.colors.surface),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Account>(
                  value: _selected,
                  isExpanded: true,
                  dropdownColor: context.colors.surface,
                  style: TextStyle(color: context.colors.textPrimary, fontSize: 15),
                  onChanged: (a) { if (a != null) setState(() => _selected = a); },
                  items: widget.cashAccounts.map((a) => DropdownMenuItem(value: a, child: Text(a.name))).toList(),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text('Eklenecek Tutar (₺)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.textSecondary)),
          const SizedBox(height: 6),
          TextField(
            controller: _amountController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [ThousandsSeparatorInputFormatter()],
            decoration: InputDecoration(
              prefixText: '₺ ',
              hintText: '0',
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.colors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.colors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.colors.accent, width: 2)),
              filled: true,
              fillColor: context.colors.surface,
            ),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textPrimary),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: BorderSide(color: context.colors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: Text('İptal', style: TextStyle(color: context.colors.textPrimary)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: context.colors.accent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
