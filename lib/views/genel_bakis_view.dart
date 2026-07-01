import 'package:flutter/material.dart';

import 'package:hane/theme/app_theme.dart';
import 'package:hane/theme/responsive.dart';
import 'package:provider/provider.dart';
import 'package:hane/utils/formatters.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/models/project.dart';
import 'package:hane/models/financial_transaction.dart';

class GenelBakisScreen extends StatelessWidget {
  const GenelBakisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SafeArea(
      child: Consumer<FinanceProvider>(
        builder: (context, fp, child) {
          if (fp.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final totalBalance = fp.getVarlikKasa();
          // Gerçek verilerden hesaplanır
          final double toplamBorc = fp.getTotalBorc();
          final double finansmanGucuDeger = fp.getFinansmanGucu();
          final String finansmanGucu = currencyFormat.format(finansmanGucuDeger);
          // Yaklaşan ödemeler: vade tarihi dolu Gider işlemlerinin toplamı
          final double yaklasanOdemeler = fp.allTransactions
              .where((t) => t.type == 'Gider' && t.dueDate.isNotEmpty)
              .fold(0.0, (sum, t) => sum + t.amount);

          final projects = fp.projects.take(4).toList();
          final recentTransactions = fp.allTransactions.take(5).toList();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: centeredPagePadding(context, maxContentWidth: 1000, top: 16.0, bottom: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Başlık Alanı
                Text(
                  'Genel Bakış',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).extension<AppColors>()!.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Genel bakış ve özet bilgiler',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).extension<AppColors>()!.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),

                // Dörtlü Özet Kartları
                SizedBox(
                  height: 135,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    clipBehavior: Clip.none,
                    children: [
                      _buildSummaryCard(
                        context: context,
                        title: 'Toplam Kasa',
                        amountText: currencyFormat.format(totalBalance),
                        subtitle: 'Nakit & Banka',
                        icon: Icons.account_balance_wallet_rounded,
                        iconColor: Theme.of(context).extension<AppColors>()!.success,
                        iconBgColor: context.colors.successBg,
                        textColor: Theme.of(context).extension<AppColors>()!.success,
                      ),
                      const SizedBox(width: 12),
                      _buildSummaryCard(
                        context: context,
                        title: 'Toplam Borç',
                        amountText: currencyFormat.format(toplamBorc),
                        subtitle: 'Tedarikçi & Diğer',
                        icon: Icons.account_balance_wallet_rounded,
                        iconColor: Theme.of(context).extension<AppColors>()!.danger,
                        iconBgColor: context.colors.dangerBg,
                        textColor: Theme.of(context).extension<AppColors>()!.danger,
                      ),
                      const SizedBox(width: 12),
                      _buildSummaryCard(
                        context: context,
                        title: 'Finansman Gücü',
                        amountText: finansmanGucu,
                        subtitle: finansmanGucuDeger >= 0 ? 'Pozitif' : 'Negatif',
                        icon: Icons.analytics_rounded,
                        iconColor: context.colors.accent,
                        iconBgColor: context.colors.accentBg,
                        textColor: context.colors.accent,
                      ),
                      const SizedBox(width: 12),
                      _buildSummaryCard(
                        context: context,
                        title: 'Yaklaşan Ödemeler',
                        amountText: currencyFormat.format(yaklasanOdemeler),
                        subtitle: '7 gün içinde',
                        icon: Icons.receipt_long_rounded,
                        iconColor: context.colors.purple,
                        iconBgColor: context.colors.purpleBg,
                        textColor: context.colors.purple,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Projelerim Başlık
                _buildSectionHeader(context, 'Projelerim', count: projects.length),
                const SizedBox(height: 16),

                // Projeler Listesi
                ResponsiveWrap(
                  children: projects.map((p) => _buildProjectCard(context, p, fp)).toList(),
                ),
                const SizedBox(height: 24),

                // Son Hareketler Başlık
                _buildSectionHeader(context, 'Son Hareketler'),
                const SizedBox(height: 16),

                // Son Hareketler Listesi
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).extension<AppColors>()!.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).extension<AppColors>()!.border),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < recentTransactions.length; i++) ...[
                        _buildTransactionItem(context, recentTransactions[i], fp),
                        if (i < recentTransactions.length - 1)
                          Divider(height: 1, color: Theme.of(context).extension<AppColors>()!.surfaceVariant),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required String title,
    required String amountText,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required Color textColor,
  }) {
    return Container(
      width: 130,
      decoration: BoxDecoration(
        color: Theme.of(context).extension<AppColors>()!.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).extension<AppColors>()!.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).extension<AppColors>()!.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            amountText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).extension<AppColors>()!.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Projenin kayıtlı görseli varsa onu, yoksa varsayılan asset'i döndürür.
  ImageProvider _projectImage(Project project) {
    final path = project.imagePath;
    if (path != null && path.isNotEmpty && path.startsWith('http')) {
      return NetworkImage(path);
    }
    return const AssetImage('assets/images/modern_apartment_building.png');
  }

  Widget _buildSectionHeader(BuildContext context, String title, {int? count}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).extension<AppColors>()!.textPrimary,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Text(
                '($count)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).extension<AppColors>()!.textSecondary,
                ),
              ),
            ],
          ],
        ),
        Text(
          'Tümünü Gör',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).extension<AppColors>()!.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildProjectCard(BuildContext context, Project project, FinanceProvider fp) {
    // Projenin gerçek harcaması ve gerçekleşme yüzdesi
    final harcanan = fp.getProjectTotalGider(project.id!);
    final yuzde = project.estimatedTotalCost > 0
        ? ((harcanan / project.estimatedTotalCost) * 100).clamp(0, 100).toInt()
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).extension<AppColors>()!.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).extension<AppColors>()!.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Proje görseli (varsa kayıtlı görsel, yoksa varsayılan asset)
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Theme.of(context).extension<AppColors>()!.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: _projectImage(project),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).extension<AppColors>()!.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.colors.accentBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'PRJ-00${project.id}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).extension<AppColors>()!.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: Theme.of(context).extension<AppColors>()!.textSecondary, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      project.location,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).extension<AppColors>()!.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.home_work_outlined, color: Theme.of(context).extension<AppColors>()!.textSecondary, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Konut Projesi', // Statik örnek tip
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).extension<AppColors>()!.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Harcanan ve Progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Harcanan',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).extension<AppColors>()!.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                currencyFormat.format(harcanan),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).extension<AppColors>()!.success,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    '%$yuzde',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).extension<AppColors>()!.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).extension<AppColors>()!.surfaceVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: yuzde / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).extension<AppColors>()!.success,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, FinancialTransaction t, FinanceProvider fp) {
    bool isIncome = t.type == 'Gelir' || t.type == 'Tahsilat';
    Color amountColor = isIncome ? Theme.of(context).extension<AppColors>()!.success : Theme.of(context).extension<AppColors>()!.danger;
    String amountPrefix = isIncome ? '' : '-';
    
    // Proje ismini bul
    String projectName = '';
    if (t.projectId != null) {
      final prj = fp.projects.where((p) => p.id == t.projectId).firstOrNull;
      if (prj != null) projectName = prj.name;
    }

    // İkona karar ver
    IconData iconData = Icons.receipt_long_rounded;
    Color iconColor = Theme.of(context).extension<AppColors>()!.textSecondary;
    Color iconBgColor = context.colors.surfaceVariant;
    
    if (t.category == 'Beton') {
      iconData = Icons.fire_truck_rounded;
      iconColor = context.colors.purple;
      iconBgColor = context.colors.purpleBg;
    } else if (t.category == 'Demir') {
      iconData = Icons.hardware_rounded;
      iconColor = context.colors.warning;
      iconBgColor = context.colors.warningBg;
    } else if (isIncome) {
      iconData = Icons.account_balance_wallet_rounded;
      iconColor = Theme.of(context).extension<AppColors>()!.success;
      iconBgColor = context.colors.successBg;
    } else {
      iconData = Icons.water_drop_rounded;
      iconColor = context.colors.accent;
      iconBgColor = context.colors.accentBg;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(iconData, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.description.isNotEmpty ? t.description : t.category,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).extension<AppColors>()!.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  projectName.isNotEmpty ? projectName : 'Genel',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).extension<AppColors>()!.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$amountPrefix${currencyFormat.format(t.amount)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t.date,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).extension<AppColors>()!.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
