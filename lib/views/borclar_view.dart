import 'package:flutter/material.dart';
import 'package:hane/theme/app_theme.dart';
import 'package:hane/theme/responsive.dart';
import 'package:provider/provider.dart';
import 'package:hane/utils/formatters.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/views/yeni_islem_view.dart';
import 'package:hane/views/cari_hesap_detay_view.dart';
import 'package:hane/views/kasa_detay_view.dart';
import 'package:hane/views/widgets/app_form.dart';

class BorclarView extends StatefulWidget {
  const BorclarView({super.key});

  @override
  State<BorclarView> createState() => _BorclarViewState();
}

class _BorclarViewState extends State<BorclarView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffold,
      appBar: AppBar(
        title: Text('Borçlar', style: TextStyle(color: context.colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: context.colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Consumer<FinanceProvider>(
          builder: (context, fp, child) {
            final borclarTotal = fp.getTotalBorc();

            // Detaylara tıklanabilsin diye gruplar, soyut PanelItem yerine doğrudan
            // gerçek kayıtlardan (Loan/Account/Contact) kuruluyor — mantık
            // fp.getTotalBorc()/_buildBorclar() ile birebir aynı.
            final krediKullanilanHesaplar = fp.accounts
                .where((a) => (a.type == 'BCH' || a.type == 'Kredi Kartı') && a.balance < 0)
                .toList();

            return RefreshIndicator(
              onRefresh: fp.refreshSilently,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: centeredPagePadding(context, maxContentWidth: 760, top: 8.0, bottom: 24.0),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Total Borç Card (Red)
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).extension<AppColors>()!.danger,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).extension<AppColors>()!.danger.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOPLAM BORÇ',
                              style: TextStyle(
                                color: Colors.white.withAlpha(180),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currencyFormat.format(borclarTotal),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: Icon(Icons.assignment_rounded, color: Colors.white.withAlpha(160), size: 48),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // BANKA BORÇLARI (krediler tıklanabilir değil — henüz bir kredi detay ekranı yok)
                  _buildSectionHeader(context, 'BANKA BORÇLARI', onNewTap: () {
                    _showNewTransaction(context);
                  }),
                  _buildGroupList(context, fp, [
                    for (final l in fp.loans)
                      _ListItemData(
                        name: l.name,
                        value: l.remaining,
                        icon: Icons.account_balance_wallet_rounded,
                        isBank: true,
                        payKind: 'loan',
                        payRef: l,
                      ),
                    for (final a in krediKullanilanHesaplar)
                      _ListItemData(
                        name: '${a.name} (kullanılan)',
                        value: a.balance.abs(),
                        icon: Icons.account_balance_wallet_rounded,
                        isBank: true,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => KasaDetayView(account: a))),
                      ),
                  ]),
                  const SizedBox(height: 24),

                  // TİCARİ BORÇLAR — tıklanınca ilgili carinin detayına gider.
                  _buildSectionHeader(context, 'TİCARİ BORÇLAR', onNewTap: () {
                    _showNewTransaction(context);
                  }),
                  _buildGroupList(context, fp, [
                    for (final c in fp.contacts.where((c) =>
                        (c.kind == 'supplier' || c.kind == 'subcontractor') && c.balance > 0))
                      _ListItemData(
                        name: c.name,
                        value: c.balance,
                        icon: Icons.engineering_rounded,
                        isBank: false,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CariHesapDetayView(contact: c))),
                        payKind: 'contact',
                        payRef: c,
                      ),
                  ]),
                  const SizedBox(height: 24),

                  // ÇEKLER (henüz bir çek detay/düzenleme ekranı yok)
                  _buildSectionHeader(context, 'ÇEKLER', onNewTap: () {
                    _showNewTransaction(context);
                  }),
                  _buildGroupList(context, fp, [
                    for (final c in fp.cheques.where((c) => c.isIssued && c.status != 'cashed'))
                      _ListItemData(
                        name: c.bankName.isNotEmpty ? '${c.bankName} çeki' : 'Çek',
                        value: c.amount,
                        icon: Icons.receipt_long_rounded,
                        isBank: false,
                        payKind: 'cheque',
                        payRef: c,
                      ),
                  ]),
                ],
              ),
            ),
          );
        },
        ),
      ),
    );
  }

  void _showNewTransaction(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
      appBar: AppBar(title: const Text('Yeni İşlem')),
      body: YeniIslemScreen(initialType: 'Borçlanma', onBack: () => Navigator.pop(context)),
    )));
  }

  Widget _buildSectionHeader(BuildContext context, String title, {required VoidCallback onNewTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: context.colors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          InkWell(
            onTap: onNewTap,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                children: [
                  Icon(Icons.add, size: 16, color: context.colors.brand),
                  const SizedBox(width: 4),
                  Text(
                    'Yeni İşlem',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.colors.brand,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupList(BuildContext context, FinanceProvider fp, List<_ListItemData> items) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: items.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('Kayıt bulunamadı.')),
            )
          : Column(
        children: [
          ...items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return Column(
              children: [
                _buildListItem(
                  context: context,
                  fp: fp,
                  item: item,
                  isLast: idx == items.length - 1,
                  isFirst: idx == 0,
                ),
                if (idx < items.length - 1)
                  Divider(height: 1, indent: 64, color: context.colors.surfaceVariant),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildListItem({
    required BuildContext context,
    required FinanceProvider fp,
    required _ListItemData item,
    bool isLast = false,
    bool isFirst = false,
  }) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.only(
        topLeft: isFirst ? const Radius.circular(16) : Radius.zero,
        topRight: isFirst ? const Radius.circular(16) : Radius.zero,
        bottomLeft: isLast ? const Radius.circular(16) : Radius.zero,
        bottomRight: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.colors.scaffold,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(4.0),
              child: Icon(item.icon, color: context.colors.brand, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(item.value),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
                if (item.payKind != null) ...[
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => _showPayDialog(context, fp, item),
                    borderRadius: BorderRadius.circular(4),
                    child: Text(
                      'Öde',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.colors.brand),
                    ),
                  ),
                ],
              ],
            ),
            if (item.onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: context.colors.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- Öde diyaloğu ---
  void _showPayDialog(BuildContext context, FinanceProvider fp, _ListItemData item) {
    final amountCtrl = TextEditingController(text: item.value.toStringAsFixed(0));
    final accounts = fp.accounts.where((a) => a.type == 'Banka' || a.type == 'Nakit').toList();
    int? selectedAccountId = accounts.isNotEmpty ? accounts.first.id : null;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Öde'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${item.name} — Kalan: ${currencyFormat.format(item.value)}',
                  style: TextStyle(color: context.colors.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: appInputDecoration(context, 'Ödenen tutar'),
              ),
              const SizedBox(height: 12),
              if (accounts.isNotEmpty)
                DropdownButtonFormField<int?>(
                  initialValue: selectedAccountId,
                  decoration: appInputDecoration(context),
                  items: accounts
                      .map((a) => DropdownMenuItem(value: a.id, child: Text('${a.name} hesabından')))
                      .toList(),
                  onChanged: (v) => setLocal(() => selectedAccountId = v),
                )
              else
                Text('Önce bir Banka/Nakit hesabı ekleyin.',
                    style: TextStyle(color: context.colors.danger, fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final amount = double.tryParse(amountCtrl.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
                      if (amount <= 0) return;
                      setLocal(() => saving = true);
                      try {
                        await fp.payDebt(
                          kind: item.payKind!,
                          ref: item.payRef!,
                          amount: amount,
                          fromAccountId: selectedAccountId,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setLocal(() => saving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Hata: $e')));
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: context.colors.brand, foregroundColor: context.colors.surface),
              child: saving
                  ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.surface))
                  : const Text('Öde'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListItemData {
  final String name;
  final double value;
  final IconData icon;
  final bool isBank;
  final VoidCallback? onTap;
  final String? payKind;
  final Object? payRef;

  _ListItemData({
    required this.name,
    required this.value,
    required this.icon,
    required this.isBank,
    this.onTap,
    this.payKind,
    this.payRef,
  });
}
