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
            'İletişim Kanalları',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildContactCard(context, 
            'Canlı Destek',
            'Hemen bir temsilci ile görüşün',
            Icons.chat_bubble_outline_rounded,
            context.colors.accent,
            () {},
          ),
          _buildContactCard(context, 
            'E-Posta Gönder',
            'destek@hano.com.tr',
            Icons.email_outlined,
            context.colors.success,
            () {},
          ),
          _buildContactCard(context, 
            'Bizi Arayın',
            '0850 123 45 67',
            Icons.phone_outlined,
            const Color(0xFF8B5CF6),
            () {},
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
            'Giriş ekranında bulunan "Şifremi Unuttum" bağlantısına tıklayarak e-posta adresinize sıfırlama bağlantısı gönderebilirsiniz.',
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: context.colors.textPrimary)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 13, color: context.colors.textSecondary)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: context.colors.textSecondary),
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
