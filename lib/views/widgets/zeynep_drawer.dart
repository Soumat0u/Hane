import 'package:flutter/material.dart';
import 'package:hano/views/widgets/zeynep_logo.dart';

class ZeynepDrawer extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const ZeynepDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<ZeynepDrawer> createState() => _ZeynepDrawerState();
}

class _ZeynepDrawerState extends State<ZeynepDrawer> {
  int _hoveredIndex = -1;

  final List<DrawerItemData> _drawerItems = [
    DrawerItemData(title: 'Anasayfa', activeIcon: Icons.home_rounded, inactiveIcon: Icons.home_outlined, tabIndex: 0),
    DrawerItemData(title: 'Kasa', activeIcon: Icons.account_balance_wallet_rounded, inactiveIcon: Icons.account_balance_wallet_outlined, tabIndex: 1),
    DrawerItemData(title: 'Projeler', activeIcon: Icons.construction_rounded, inactiveIcon: Icons.construction_outlined, tabIndex: 3),
    DrawerItemData(title: 'Borç / Alacak', activeIcon: Icons.receipt_long_rounded, inactiveIcon: Icons.receipt_long_outlined, tabIndex: 0), // maps to dashboard metric
    DrawerItemData(title: 'Finansman Gücü', activeIcon: Icons.shield_rounded, inactiveIcon: Icons.shield_outlined, tabIndex: 0), // maps to dashboard metric
    DrawerItemData(title: 'Raporlar', activeIcon: Icons.analytics_rounded, inactiveIcon: Icons.analytics_outlined, tabIndex: 0),
    DrawerItemData(title: 'Ayarlar', activeIcon: Icons.settings_rounded, inactiveIcon: Icons.settings_outlined, tabIndex: 4), // maps to profile/settings tab
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      // Procedural Logo
                      const ZeynepLogo(),
                      const SizedBox(height: 24),
                      // Drawer Items List
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: List.generate(_drawerItems.length, (index) {
                            final item = _drawerItems[index];
                            final isSelected = widget.selectedIndex == item.tabIndex && index < 3;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: InkWell(
                                onTap: () {
                                  Navigator.pop(context); // Close drawer
                                  widget.onItemSelected(item.tabIndex); // Route to appropriate tab
                                },
                                onHover: (isHovered) {
                                  setState(() {
                                    _hoveredIndex = isHovered ? index : -1;
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  curve: Curves.easeInOut,
                                  transform: Matrix4.translationValues(
                                    (!isSelected && _hoveredIndex == index) ? 6.0 : 0.0,
                                    0.0,
                                    0.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF032B5E)
                                        : (_hoveredIndex == index
                                            ? const Color(0x14032B5E)
                                            : Colors.transparent),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12.0,
                                    horizontal: 16.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected ? item.activeIcon : item.inactiveIcon,
                                        color: isSelected
                                            ? Colors.white
                                            : (_hoveredIndex == index
                                                ? const Color(0xFF032B5E)
                                                : const Color(0xFF475569)),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        item.title,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : (_hoveredIndex == index
                                                  ? const Color(0xFF032B5E)
                                                  : const Color(0xFF475569)),
                                          fontSize: 16,
                                          fontWeight: isSelected || _hoveredIndex == index
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const Spacer(),
                      // Procedural Construction Illustration
                      const SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: ConstructionPainter(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ConstructionPainter extends CustomPainter {
  const ConstructionPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final linePaint = Paint()
      ..color = const Color(0x14032B5E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final thickPaint = Paint()
      ..color = const Color(0x33032B5E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final solidPaint = Paint()
      ..color = const Color(0x0A032B5E)
      ..style = PaintingStyle.fill;

    // 1. Draw Grid lines
    const double gridSize = 20.0;
    for (double x = 0; x < w; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), linePaint);
    }
    for (double y = 0; y < h; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(w, y), linePaint);
    }

    // 2. Draw building structures under construction (skyscrapers on the left/middle)
    final double b1Left = w * 0.08;
    final double b1Right = w * 0.38;
    final double b1Height = h * 0.75;
    final double b1Base = h;

    canvas.drawRect(
      Rect.fromLTRB(b1Left, b1Base - b1Height * 0.5, b1Right, b1Base),
      solidPaint,
    );

    const double cols = 4;
    final double colWidth = (b1Right - b1Left) / cols;
    for (int i = 0; i <= cols; i++) {
      double cx = b1Left + i * colWidth;
      canvas.drawLine(Offset(cx, b1Base - b1Height), Offset(cx, b1Base), thickPaint);
    }

    const double floors = 8;
    final double floorHeight = b1Height / floors;
    for (int i = 0; i <= floors; i++) {
      double cy = b1Base - i * floorHeight;
      canvas.drawLine(Offset(b1Left, cy), Offset(b1Right, cy), thickPaint);
    }

    for (int i = 4; i < floors; i++) {
      double cy1 = b1Base - i * floorHeight;
      double cy2 = b1Base - (i + 1) * floorHeight;
      for (int j = 0; j < cols; j++) {
        double cx1 = b1Left + j * colWidth;
        double cx2 = b1Left + (j + 1) * colWidth;
        canvas.drawLine(Offset(cx1, cy1), Offset(cx2, cy2), linePaint);
        canvas.drawLine(Offset(cx2, cy1), Offset(cx1, cy2), linePaint);
      }
    }

    // Building 2 (middle background)
    final double b2Left = w * 0.35;
    final double b2Right = w * 0.60;
    final double b2Height = h * 0.90;

    canvas.drawRect(
      Rect.fromLTRB(b2Left, b1Base - b2Height * 0.3, b2Right, b1Base),
      solidPaint,
    );

    const double cols2 = 3;
    final double colWidth2 = (b2Right - b2Left) / cols2;
    for (int i = 0; i <= cols2; i++) {
      double cx = b2Left + i * colWidth2;
      canvas.drawLine(Offset(cx, b1Base - b2Height), Offset(cx, b1Base), thickPaint);
    }

    const double floors2 = 10;
    final double floorHeight2 = b2Height / floors2;
    for (int i = 0; i <= floors2; i++) {
      double cy = b1Base - i * floorHeight2;
      canvas.drawLine(Offset(b2Left, cy), Offset(b2Right, cy), thickPaint);
    }

    // 3. Draw Tower Crane (right side)
    final double craneX = w * 0.72;
    final double craneBase = h;
    final double craneHeight = h * 0.85;
    final double craneJibLeft = w * 0.28;
    final double craneJibRight = w * 0.92;

    const double mastWidth = 10.0;
    final double ml = craneX - mastWidth / 2;
    final double mr = craneX + mastWidth / 2;
    canvas.drawLine(Offset(ml, craneBase), Offset(ml, craneBase - craneHeight), thickPaint);
    canvas.drawLine(Offset(mr, craneBase), Offset(mr, craneBase - craneHeight), thickPaint);

    const double latticeSpacing = 16.0;
    double curY = craneBase;
    while (curY > craneBase - craneHeight) {
      double nextY = curY - latticeSpacing;
      if (nextY < craneBase - craneHeight) nextY = craneBase - craneHeight;
      canvas.drawLine(Offset(ml, curY), Offset(mr, nextY), linePaint);
      canvas.drawLine(Offset(mr, curY), Offset(ml, nextY), linePaint);
      curY = nextY;
    }

    final double jibY = craneBase - craneHeight;
    canvas.drawLine(Offset(craneJibLeft, jibY), Offset(craneJibRight, jibY), thickPaint);
    final double cabinTopY = jibY - 10.0;
    canvas.drawLine(Offset(craneX, cabinTopY), Offset(craneJibRight, jibY), linePaint);
    canvas.drawLine(Offset(craneX, cabinTopY), Offset(craneJibLeft, jibY), linePaint);

    for (double cx = craneJibLeft; cx < craneJibRight; cx += 20.0) {
      canvas.drawLine(Offset(cx, jibY), Offset(cx + 10.0, cabinTopY), linePaint);
      canvas.drawLine(Offset(cx + 10.0, cabinTopY), Offset(cx + 20.0, jibY), linePaint);
    }

    canvas.drawRect(Rect.fromLTWH(craneX - 6, jibY - 6, 12, 6), solidPaint);
    canvas.drawRect(Rect.fromLTWH(craneX - 6, jibY - 6, 12, 6), thickPaint);

    final double hookX = w * 0.48;
    final double hookY = jibY + h * 0.3;
    canvas.drawLine(Offset(hookX, jibY), Offset(hookX, hookY), linePaint);
    
    final hookPath = Path()
      ..moveTo(hookX, hookY)
      ..quadraticBezierTo(hookX - 3, hookY + 3, hookX, hookY + 5)
      ..quadraticBezierTo(hookX + 3, hookY + 3, hookX + 2, hookY + 1);
    canvas.drawPath(hookPath, thickPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DrawerItemData {
  final String title;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final int tabIndex;

  DrawerItemData({
    required this.title,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.tabIndex,
  });
}
