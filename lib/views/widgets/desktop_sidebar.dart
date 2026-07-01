import 'package:flutter/material.dart';
import 'package:hane/theme/app_theme.dart';
import 'package:hane/views/ayarlar_view.dart';
import 'package:hane/views/widgets/zeynep_drawer.dart' show DrawerItemData;
import 'package:hane/views/widgets/zeynep_logo.dart';

/// Geniş ekran (masaüstü/web) için kalıcı sol kenar menüsü.
/// Mobil bottom navbar'ın yerini alır; [ZeynepDrawer] ile aynı görsel dili kullanır.
class DesktopSidebar extends StatefulWidget {
  /// Seçili navbar sekme indeksi (0,1,3,4 — 2 "Yeni İşlem" için ayrılmıştır).
  final int selectedIndex;

  /// Bir sekme öğesine tıklanınca ilgili tab indeksiyle çağrılır.
  final ValueChanged<int> onItemSelected;

  /// "+ Yeni İşlem" butonuna basılınca çağrılır.
  final VoidCallback onNewTransaction;

  const DesktopSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onNewTransaction,
  });

  @override
  State<DesktopSidebar> createState() => _DesktopSidebarState();
}

class _DesktopSidebarState extends State<DesktopSidebar> {
  int _hoveredIndex = -1;

  // tabIndex -1 => Ayarlar (ayrı sayfaya push edilir).
  final List<DrawerItemData> _items = [
    DrawerItemData(title: 'Genel Bakış', activeIcon: Icons.home_rounded, inactiveIcon: Icons.home_outlined, tabIndex: 0),
    DrawerItemData(title: 'Projeler', activeIcon: Icons.construction_rounded, inactiveIcon: Icons.construction_outlined, tabIndex: 1),
    DrawerItemData(title: 'Hareketler', activeIcon: Icons.receipt_long_rounded, inactiveIcon: Icons.receipt_long_outlined, tabIndex: 3),
    DrawerItemData(title: 'Profil', activeIcon: Icons.person_rounded, inactiveIcon: Icons.person_outline_rounded, tabIndex: 4),
    DrawerItemData(title: 'Ayarlar', activeIcon: Icons.settings_rounded, inactiveIcon: Icons.settings_outlined, tabIndex: -1),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(right: BorderSide(color: context.colors.border)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const ZeynepLogo(),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: List.generate(_items.length, (index) => _buildItem(index)),
                  ),
                ),
              ),
            ),
            // Alt: belirgin Yeni İşlem butonu.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: widget.onNewTransaction,
                  icon: const Icon(Icons.add_rounded, size: 22),
                  label: const Text('Yeni İşlem', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.brand,
                    foregroundColor: context.colors.surface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(int index) {
    final item = _items[index];
    final isSelected = widget.selectedIndex == item.tabIndex && item.tabIndex != -1;
    final isHovered = _hoveredIndex == index;
    final Color fg = isSelected
        ? context.colors.surface
        : (isHovered ? context.colors.brand : context.colors.textSecondary);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: InkWell(
        onTap: () {
          if (item.tabIndex == -1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AyarlarView()));
          } else {
            widget.onItemSelected(item.tabIndex);
          }
        },
        onHover: (h) => setState(() => _hoveredIndex = h ? index : -1),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          transform: Matrix4.translationValues((!isSelected && isHovered) ? 6.0 : 0.0, 0.0, 0.0),
          decoration: BoxDecoration(
            color: isSelected
                ? context.colors.brand
                : (isHovered ? const Color(0x14032B5E) : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Row(
            children: [
              Icon(isSelected ? item.activeIcon : item.inactiveIcon, color: fg, size: 24),
              const SizedBox(width: 16),
              Text(
                item.title,
                style: TextStyle(
                  color: fg,
                  fontSize: 16,
                  fontWeight: isSelected || isHovered ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
