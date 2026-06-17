import 'package:flutter/material.dart';


import 'package:hane/theme/app_theme.dart';
class PlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const PlaceholderPage({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.menu_rounded, color: context.colors.brand, size: 28),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: color.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 44),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Zeynep İnşaat Finans Paneli üzerinden bu sayfayla ilgili işlemler yakında aktif edilecektir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
