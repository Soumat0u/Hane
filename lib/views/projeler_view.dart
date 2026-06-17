import 'package:flutter/material.dart';

import 'package:hane/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hane/views/proje_detay_view.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/models/project.dart';
import 'package:hane/views/yeni_proje_view.dart';

final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

class ProjelerScreen extends StatelessWidget {
  const ProjelerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, financeProvider, child) {
        if (financeProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final projects = financeProvider.projects;

        return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          // Subtitle Row: "Devam Eden Projeler" & "Tümü"
          if (projects.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Devam Eden Projeler',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: context.colors.brand,
                    ),
                  ),
                  InkWell(
                    onTap: () {},
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tümü',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: context.colors.accent,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: context.colors.accent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Project Cards List
          Expanded(
            child: projects.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 6,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.add,
                              size: 40,
                              color: Colors.grey[300],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Henüz bir projeniz yok',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      return _buildProjectCard(context, project, financeProvider);
                    },
                  ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildProjectCard(BuildContext context, Project project, FinanceProvider fp) {
    final double totalCost = project.estimatedTotalCost;
    final double totalGider = fp.getProjectTotalGider(project.id!);
    final double tahsilat = fp.getProjectTotalTahsilat(project.id!);
    final double satis = fp.getProjectTotalSatis(project.id!);
    
    final int realizationPercent = totalCost > 0 ? ((totalGider / totalCost) * 100).toInt() : 0;
    final double kar = satis - totalCost;
    final int karPercent = satis > 0 ? ((kar / satis) * 100).toInt() : 0;

    final bool isZeroRealization = realizationPercent == 0;
    final Color percentColor = isZeroRealization ? context.colors.textSecondary : context.colors.success;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjeDetayView(projectName: project.name),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
          // Top Row: Thumbnail + Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project Image Thumbnail
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/modern_apartment_building.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Name, status tag, costs
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Tag
                      Container(
                        decoration: BoxDecoration(
                          color: Color(int.parse(project.statusBgColorHex.replaceFirst('#', '').replaceFirst('0xFF', '').replaceFirst('0xff', '').padLeft(8, 'f'), radix: 16)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        child: Text(
                          project.status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(int.parse(project.statusColorHex.replaceFirst('#', '').replaceFirst('0xFF', '').replaceFirst('0xff', '').padLeft(8, 'f'), radix: 16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      project.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Toplam Maliyet',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormat.format(totalCost),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              // Realization section on the far right
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Gerçekleşme',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '%$realizationPercent',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: percentColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Small progress bar indicator
                  SizedBox(
                    width: 70,
                    height: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: realizationPercent / 100.0,
                        backgroundColor: context.colors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(percentColor),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: context.colors.surfaceVariant),
          const SizedBox(height: 10),

          // Middle row: Tahsilat, Satış, Kâr columns
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatsCol('Tahsilat', currencyFormat.format(tahsilat), context.colors.textSecondary),
              _buildStatsCol('Satış', currencyFormat.format(satis), context.colors.textSecondary),
              _buildStatsCol('Kâr', '%$karPercent', karPercent > 0 ? context.colors.success : context.colors.textSecondary),
            ],
          ),
          const SizedBox(height: 8),

          // Detay button at the bottom
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProjeDetayView(projectName: project.name),
                  ),
                );
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Detay',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: context.colors.brand,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: context.colors.brand,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildStatsCol(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// Removed ProjectData
