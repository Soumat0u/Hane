import 'package:flutter/material.dart';


import 'package:hane/theme/app_theme.dart';
class YardimDestekView extends StatelessWidget {
  const YardimDestekView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffold,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Yardım & Destek',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        backgroundColor: context.colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.brand),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        physics: const BouncingScrollPhysics(),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [context.colors.brand, Color(0xFF0A4B9C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: context.colors.brand.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.support_agent_rounded, color: context.colors.surface, size: 40),
                SizedBox(height: 16),
                Text(
                  'Size nasıl yardımcı olabiliriz?',
                  style: TextStyle(
                    color: context.colors.surface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Sık sorulan soruları inceleyebilir veya destek ekibimizle iletişime geçebilirsiniz.',
                  style: TextStyle(
                    color: context.colors.surface.withAlpha(178),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Sık Sorulan Sorular',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildFaqItem(context, 
            'Yeni bir projeyi nasıl eklerim?',
            'Ana ekranda "Projeler" sekmesine giderek "Yeni Proje Ekle" butonunu kullanabilirsiniz.',
          ),
          _buildFaqItem(context, 
            'Finansal raporları nasıl dışa aktarırım?',
            'Raporlar sekmesinden tarih aralığı seçtikten sonra sağ üst köşedeki indirme ikonuna tıklayarak PDF veya Excel olarak dışa aktarabilirsiniz.',
          ),
          _buildFaqItem(context,
            'Şifremi unuttum, ne yapmalıyım?',
            'Şifrenizi sıfırlamak için lütfen hesap yöneticinizle iletişime geçin.',
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: context.colors.textPrimary),
        ),
        collapsedIconColor: context.colors.textSecondary,
        iconColor: context.colors.brand,
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        children: [
          Text(
            answer,
            style: TextStyle(fontSize: 13, color: context.colors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}
