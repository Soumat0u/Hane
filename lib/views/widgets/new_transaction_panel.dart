import 'package:flutter/material.dart';

class NewTransactionPanel extends StatelessWidget {
  final ValueChanged<String> onTypeSelected;

  const NewTransactionPanel({
    super.key,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle indicator
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header Title
          const Text(
            'Yeni İşlem Türü Seçin',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 24),

          // Grid list of transaction types (3 columns x 2 rows)
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.95,
            children: [
              _buildGridItem(context, 'Ödeme', Icons.outbox_rounded, const Color(0xFFEFF6FF), const Color(0xFF3B82F6)),
              _buildGridItem(context, 'Tahsilat', Icons.move_to_inbox_rounded, const Color(0xFFECFDF5), const Color(0xFF10B981)),
              _buildGridItem(context, 'Transfer', Icons.swap_horiz_rounded, const Color(0xFFFFF7ED), const Color(0xFFF59E0B)),
              _buildGridItem(context, 'Borçlanma', Icons.account_balance_rounded, const Color(0xFFFEF2F2), const Color(0xFFEF4444)),
              _buildGridItem(context, 'Kredi Kullanımı', Icons.wallet_rounded, const Color(0xFFF5F3FF), const Color(0xFF8B5CF6)),
              _buildGridItem(context, 'Satış', Icons.assignment_turned_in_rounded, const Color(0xFFEFF6FF), const Color(0xFF032B5E)),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGridItem(
    BuildContext context,
    String label,
    IconData icon,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context); // Close bottom sheet
            onTypeSelected(label); // Invoke select callback
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF475569),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
