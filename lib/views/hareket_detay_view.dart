import 'package:flutter/material.dart';
import 'package:hane/theme/app_theme.dart';

class HareketDetayView extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const HareketDetayView({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    // Determine colors based on transaction type
    Color typeColor;
    IconData typeIcon;
    Color amountColor;
    Color headerBackgroundColor;
    
    if (transaction['type'] == 'gider') {
      typeColor = context.colors.danger;
      typeIcon = Icons.arrow_upward_rounded;
      amountColor = context.colors.danger;
      headerBackgroundColor = const Color(0xFFFEF2F2); // very light red tint
    } else if (transaction['type'] == 'tahsilat') {
      typeColor = context.colors.success;
      typeIcon = Icons.arrow_downward_rounded;
      amountColor = context.colors.success;
      headerBackgroundColor = const Color(0xFFF0FDF4); // very light green tint
    } else { // transfer
      typeColor = context.colors.accent;
      typeIcon = Icons.swap_horiz_rounded;
      amountColor = context.colors.accent;
      headerBackgroundColor = const Color(0xFFEFF6FF); // very light blue tint
    }

    return Scaffold(
      backgroundColor: context.colors.scaffold,
      appBar: AppBar(
        backgroundColor: context.colors.scaffold,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.chevron_left_rounded, color: context.colors.textPrimary, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Hareket Detayı',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.colors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz_rounded, color: context.colors.textPrimary, size: 28),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100), // bottom padding for sticky buttons
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: headerBackgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: typeColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(typeIcon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction['category'] ?? 'BİLİNMİYOR',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: typeColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                transaction['title'] ?? '',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: context.colors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              transaction['amount'] ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: amountColor,
                              ),
                            ),
                          ],
                        ),
                        if (transaction['subtitle'] != null && transaction['subtitle'].isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              transaction['subtitle'],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: context.colors.textPrimary,
                              ),
                            ),
                          ),
                        if (transaction['details'] != null && transaction['details'].isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              transaction['details'],
                              style: TextStyle(
                                fontSize: 12,
                                color: context.colors.textPrimary, // Made slightly darker like the image
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 14, color: context.colors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              transaction['date']?.replaceAll('\n', ' • ') ?? '',
                              style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Details List
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.border.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  _buildDetailRow(context, Icons.sell_outlined, 'Kategori', transaction['details'] ?? 'Diğer'),
                  Divider(color: context.colors.border.withOpacity(0.5), height: 1),
                  _buildDetailRow(context, Icons.sell_outlined, 'Alt Kategori', transaction['details'] ?? 'Diğer'),
                  Divider(color: context.colors.border.withOpacity(0.5), height: 1),
                  _buildDetailRow(
                    context, 
                    Icons.person_outline_rounded, 
                    'Alıcı / Kişi', 
                    transaction['subtitle'] ?? '-', 
                    showTrailing: true,
                  ),
                  Divider(color: context.colors.border.withOpacity(0.5), height: 1),
                  _buildDetailRow(context, Icons.domain_rounded, 'Proje', transaction['project'] ?? '-'),
                  Divider(color: context.colors.border.withOpacity(0.5), height: 1),
                  _buildDetailRowWithTrailingWidget(
                    context, 
                    Icons.account_balance_wallet_outlined, 
                    'Ödeme Kaynağı', 
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          transaction['account'] ?? '-',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.colors.textPrimary),
                        ),
                        if (transaction['accountIcon'] != null) ...[
                          const SizedBox(width: 8),
                          Icon(transaction['accountIcon'], size: 16, color: context.colors.success),
                        ],
                      ],
                    )
                  ),
                  Divider(color: context.colors.border.withOpacity(0.5), height: 1),
                  _buildDetailRowWithTrailingWidget(
                    context, 
                    Icons.calendar_today_rounded, 
                    'Tutar', 
                    Text(
                      transaction['amount'] ?? '',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: amountColor),
                    )
                  ),
                  Divider(color: context.colors.border.withOpacity(0.5), height: 1),
                  _buildDetailRowWithTrailingWidget(
                    context, 
                    Icons.description_outlined, 
                    'Belge / Fatura', 
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.colors.surfaceVariant,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.insert_drive_file, size: 14, color: context.colors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                'avans-slip.pdf',
                                style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.download_rounded, size: 18, color: context.colors.textSecondary),
                      ],
                    )
                  ),
                  Divider(color: context.colors.border.withOpacity(0.5), height: 1),
                  _buildDetailRow(
                    context, 
                    Icons.format_quote_rounded, 
                    'Not', 
                    'Kapıcıya avans ödemesi yapıldı.' // Mocked note
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // İşlem Geçmişi
            Text(
              'İŞLEM GEÇMİŞİ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.border.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  _buildHistoryRow(context, '25.04.2024', 'Avans Ödemesi', '-₺10.000'),
                  Divider(color: context.colors.border.withOpacity(0.5), height: 1),
                  _buildHistoryRow(context, '15.04.2024', 'Avans Ödemesi', '-₺10.000'),
                  Divider(color: context.colors.border.withOpacity(0.5), height: 1),
                  _buildHistoryRow(context, '05.04.2024', 'Avans Ödemesi', '-₺5.000'),
                  Divider(color: context.colors.border.withOpacity(0.5), height: 1),
                  _buildHistoryRow(context, '25.03.2024', 'Avans Ödemesi', '-₺10.000'),
                  Divider(color: context.colors.border.withOpacity(0.5), height: 1),
                  _buildHistoryRow(context, '15.03.2024', 'Avans Ödemesi', '-₺10.000'),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Toplam Bakiye
            Text(
              'TOPLAM BAKİYE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.border.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text('Toplam Avans', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.colors.brand)),
                        const SizedBox(height: 8),
                        Text('₺25.000', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.colors.accent)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40, color: context.colors.border.withOpacity(0.5)),
                  Expanded(
                    child: Column(
                      children: [
                        Text('Kesintiler', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.colors.brand)),
                        const SizedBox(height: 8),
                        Text('₺10.000', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.colors.success)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40, color: context.colors.border.withOpacity(0.5)),
                  Expanded(
                    child: Column(
                      children: [
                        Text('Kalan Bakiye', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.colors.brand)),
                        const SizedBox(height: 8),
                        Text('₺15.000', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.colors.danger)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      
      // Bottom Action Buttons
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Düzenle', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colors.accent,
                    side: BorderSide(color: context.colors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Sil', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value, {bool showTrailing = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.colors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.colors.textPrimary),
          ),
          if (showTrailing) ...[
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, size: 16, color: context.colors.textSecondary),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRowWithTrailingWidget(BuildContext context, IconData icon, String label, Widget trailingWidget) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.colors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
            ),
          ),
          trailingWidget,
        ],
      ),
    );
  }

  Widget _buildHistoryRow(BuildContext context, String date, String title, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              date,
              style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              title,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.colors.textPrimary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              amount,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.colors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
