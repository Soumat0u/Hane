import 'package:flutter/material.dart';

import 'package:hane/theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../models/finance_panel.dart';

final _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

/// Bir finans paneli bölümünün (Kasa, Borçlar, vb.) detay/kırılım sayfası.
///
/// Üstte degrade toplam kartı, altında her alt grup için kalem listesi gösterir.
class PanelSectionDetailView extends StatelessWidget {
  final PanelSection section;

  const PanelSectionDetailView({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      backgroundColor: context.colors.scaffold,
      appBar: AppBar(
        backgroundColor: context.colors.scaffold,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
        title: Text(
          section.title,
          style: TextStyle(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTotalCard(context),
              const SizedBox(height: 24),
              ...section.groups.map((group) => _buildGroupCard(context, group)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.colors.brand, Color(0xFF021B3A)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0x3F032B5E),
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
                section.totalLabel,
                style: TextStyle(
                  color: context.colors.surface.withAlpha(180),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _currencyFormat.format(section.total),
                style: TextStyle(
                  color: context.colors.surface,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: section.accentColor.withAlpha(60),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(section.icon, color: context.colors.surface, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, PanelGroup group) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grup başlığı + grup toplamı
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  group.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
                Text(
                  _currencyFormat.format(group.total),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: section.accentColor,
                  ),
                ),
              ],
            ),
          ),
          // Kalemler — sadece birden fazla kalem varsa detay listesi göster
          if (group.hasBreakdown)
            Container(
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.border),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < group.items.length; i++) ...[
                    _buildItemRow(context, group.items[i]),
                    if (i < group.items.length - 1)
                      Divider(height: 1, indent: 16, endIndent: 16, color: context.colors.surfaceVariant),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemRow(BuildContext context, PanelItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: section.accentColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
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
          Text(
            _currencyFormat.format(item.amount),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
