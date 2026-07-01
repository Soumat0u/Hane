import 'package:flutter/material.dart';
import 'package:hane/theme/app_theme.dart';

class CustomBottomNavbar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const CustomBottomNavbar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: [
          BoxShadow(
            color: const Color(0x0D000000),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, 0, Icons.home_rounded, 'Genel Bakış'),
            _buildNavItem(context, 1, Icons.folder_copy_rounded, 'Projeler'),
            // Center floating '+' button
            GestureDetector(
              onTap: () => onTabSelected(2),
              child: Container(
                width: 56,
                height: 56,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [context.colors.brand, context.colors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: context.colors.accent.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
              ),
            ),
            _buildNavItem(context, 3, Icons.receipt_long_rounded, 'Hareketler'),
            _buildNavItem(context, 4, Icons.person_rounded, 'Profil'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final bool isSelected = selectedIndex == index;
    final Color color = isSelected ? context.colors.brand : context.colors.textSecondary;

    return GestureDetector(
      onTap: () => onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
