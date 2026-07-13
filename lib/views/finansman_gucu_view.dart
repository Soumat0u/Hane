import 'package:flutter/material.dart';
import 'package:hane/theme/app_theme.dart';
import 'package:hane/theme/responsive.dart';
import 'package:provider/provider.dart';
import 'package:hane/utils/formatters.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/models/account.dart';
import 'package:hane/views/yeni_islem_view.dart';
import 'package:hane/views/kasa_detay_view.dart';
import 'package:hane/views/widgets/bank_logo.dart';

class FinansmanGucuView extends StatelessWidget {
  const FinansmanGucuView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffold,
      appBar: AppBar(
        title: Text('Finansman Gücü', style: TextStyle(color: context.colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: context.colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Consumer<FinanceProvider>(
          builder: (context, fp, child) {
            // Gerçek hesap verileri: kullanıcının eklediği BCH, kredi kartı ve esnek hesaplar.
            final bchAccounts = fp.accounts.where((a) => a.type == 'BCH').toList();
            final cardAccounts = fp.accounts.where((a) => a.type == 'Kredi Kartı').toList();
            final esnekAccounts = fp.accounts.where((a) => a.type == 'Esnek').toList();

            final bchTotal = bchAccounts.fold(0.0, (sum, a) => sum + a.availableLimit);
            final cardLimitTotal = cardAccounts.fold(0.0, (sum, a) => sum + a.availableLimit);
            final esnekTotal = esnekAccounts.fold(0.0, (sum, a) => sum + a.availableLimit);
            final fTotal = bchTotal + cardLimitTotal + esnekTotal;

            return RefreshIndicator(
              onRefresh: fp.refreshSilently,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: centeredPagePadding(context, maxContentWidth: 760, top: 8.0, bottom: 24.0),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Total Finansman Gücü Card (Purple)
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).extension<AppColors>()!.purple,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).extension<AppColors>()!.purple.withValues(alpha: 0.3),
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
                              'TOPLAM FİNANSMAN GÜCÜ',
                              style: TextStyle(
                                color: Colors.white.withAlpha(180),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currencyFormat.format(fTotal), // Veya finansmanGucuTotal
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
                          child: Icon(Icons.trending_up_rounded, color: Colors.white.withAlpha(160), size: 48),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // KULLANILABİLİR BCH
                  _buildSectionHeader(context, 'KULLANILABİLİR BCH', onNewTap: () {
                    _showNewTransaction(context);
                  }),
                  _buildGroupList(
                    context,
                    bchAccounts
                        .map((a) => _ListItemData(name: a.name, value: a.availableLimit, subText: 'Kullanılabilir', account: a))
                        .toList(),
                    emptyText: 'Kayıtlı BCH limiti bulunamadı.',
                  ),
                  const SizedBox(height: 24),

                  // KART LİMİTLERİ
                  _buildSectionHeader(context, 'KART LİMİTLERİ', onNewTap: () {
                    _showNewTransaction(context);
                  }),
                  _buildCardLimits(context, cardAccounts),
                  const SizedBox(height: 24),

                  // ESNEK HESAPLAR
                  _buildSectionHeader(context, 'ESNEK HESAPLAR', onNewTap: () {
                    _showNewTransaction(context);
                  }),
                  _buildGroupList(
                    context,
                    esnekAccounts
                        .map((a) => _ListItemData(name: a.name, value: a.availableLimit, subText: 'Kullanılabilir', account: a))
                        .toList(),
                    emptyText: 'Kayıtlı esnek hesap bulunamadı.',
                  ),
                  const SizedBox(height: 24),

                  // ÖZET
                  Text(
                    'ÖZET',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: context.colors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.colors.border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    child: Column(
                      children: [
                        _buildSummaryRow(context, 'Toplam BCH', bchTotal),
                        const SizedBox(height: 12),
                        _buildSummaryRow(context, 'Toplam Kart Limitleri', cardLimitTotal),
                        const SizedBox(height: 12),
                        _buildSummaryRow(context, 'Toplam Esnek Hesaplar', esnekTotal),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(height: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TOPLAM FİNANSMAN GÜCÜ',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).extension<AppColors>()!.purple,
                              ),
                            ),
                            Text(
                              currencyFormat.format(fTotal),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).extension<AppColors>()!.purple,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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

  void _showNewTransaction(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
      appBar: AppBar(title: const Text('Yeni İşlem')),
      body: YeniIslemScreen(initialType: 'Gelir', onBack: () => Navigator.pop(context)),
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

  Widget _buildGroupList(BuildContext context, List<_ListItemData> items, {String emptyText = 'Kayıt bulunamadı.'}) {
    if (items.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.border),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Text(emptyText, style: TextStyle(color: context.colors.textSecondary, fontSize: 13)),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          ...items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return Column(
              children: [
                _buildListItem(
                  context: context,
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
    required _ListItemData item,
    bool isLast = false,
    bool isFirst = false,
  }) {
    return InkWell(
      onTap: item.account == null
          ? null
          : () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => KasaDetayView(account: item.account!)));
            },
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
              child: BankLogoWidget(bankName: item.name, width: 30, height: 30),
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
                Text(
                  item.subText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).extension<AppColors>()!.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: context.colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardLimits(BuildContext context, List<Account> cardAccounts) {
    if (cardAccounts.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.border),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Text('Kayıtlı kredi kartı bulunamadı.', style: TextStyle(color: context.colors.textSecondary, fontSize: 13)),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < cardAccounts.length; i++) ...[
            _buildCardItem(context, cardAccounts[i]),
            if (i < cardAccounts.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  Widget _buildCardItem(BuildContext context, Account account) {
    final double totalLimit = account.creditLimit;
    final double remainingLimit = account.availableLimit;
    final double usedLimit = totalLimit - remainingLimit;
    final double usedPercentage = totalLimit > 0 ? (usedLimit / totalLimit).clamp(0.0, 1.0) : 0.0;

    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => KasaDetayView(account: account)));
      },
      child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BankLogoWidget(bankName: account.bankLogoPainter.isNotEmpty ? account.bankLogoPainter : account.name, width: 46, height: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  account.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLimitColumn(context, 'Toplam Limit', totalLimit, context.colors.textPrimary),
              _buildLimitColumn(context, 'Kullanılan', usedLimit, context.colors.textPrimary),
              _buildLimitColumn(context, 'Kalan Limit', remainingLimit, Theme.of(context).extension<AppColors>()!.purple),
            ],
          ),
          const SizedBox(height: 12),
          // Progress Bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: (usedPercentage * 100).toInt().clamp(0, 100),
                  child: usedPercentage <= 0
                      ? const SizedBox()
                      : Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).extension<AppColors>()!.purple,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                ),
                Expanded(
                  flex: (100 - (usedPercentage * 100).toInt()).clamp(0, 100),
                  child: const SizedBox(),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildLimitColumn(BuildContext context, String label, double value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          currencyFormat.format(value),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.colors.textPrimary,
          ),
        ),
        Text(
          currencyFormat.format(value),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: context.colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ListItemData {
  final String name;
  final double value;
  final String subText;
  final Account? account;

  _ListItemData({required this.name, required this.value, required this.subText, this.account});
}
