import 'package:flutter/material.dart';
import 'package:hane/theme/app_theme.dart';

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;
  const _OnboardingPageData({required this.icon, required this.title, required this.description});
}

const List<_OnboardingPageData> _kPages = [
  _OnboardingPageData(
    icon: Icons.account_balance_wallet_rounded,
    title: 'Kasanızı Tek Yerden Yönetin',
    description: 'Nakit, banka ve kredi kartı hesaplarınızı tek ekranda takip edin, her hareketi anında görün.',
  ),
  _OnboardingPageData(
    icon: Icons.apartment_rounded,
    title: 'Projelerinizi Takip Edin',
    description: 'Her projenin bütçesini, giderini ve gelirini ayrı ayrı izleyin; harcama yüzdesini tek bakışta görün.',
  ),
  _OnboardingPageData(
    icon: Icons.repeat_rounded,
    title: 'Tekrarlayan Ödemeleri Unutmayın',
    description: 'Kira, abonelik gibi düzenli işlemleri bir kez tanımlayın; vadesi gelince otomatik oluşsun, size bildirilsin.',
  ),
  _OnboardingPageData(
    icon: Icons.people_alt_rounded,
    title: 'Cari Hesaplarınızı Kontrol Altında Tutun',
    description: 'Müşteri ve tedarikçilerinizle olan alacak-borç durumunuzu net şekilde görün.',
  ),
];

/// Kullanıcı hesaba ilk girdiğinde (firma profili henüz boşken) gösterilen,
/// kaydırmalı tanıtım ekranı. [onDone] tamamlanınca/atlanınca çağrılır.
class OnboardingWelcomeView extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingWelcomeView({super.key, required this.onDone});

  @override
  State<OnboardingWelcomeView> createState() => _OnboardingWelcomeViewState();
}

class _OnboardingWelcomeViewState extends State<OnboardingWelcomeView> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLastPage => _index == _kPages.length - 1;

  void _next() {
    if (_isLastPage) {
      widget.onDone();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: TextButton(
                  onPressed: widget.onDone,
                  child: Text('Atla', style: TextStyle(color: context.colors.textSecondary, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _kPages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _buildPage(context, _kPages[i]),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_kPages.length, (i) => _buildDot(context, i == _index)),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.brand,
                    foregroundColor: context.colors.surface,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _isLastPage ? 'Başlayalım' : 'İleri',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context, _OnboardingPageData page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: context.colors.accentBg,
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 56, color: context.colors.accent),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: context.colors.textPrimary),
          ),
          const SizedBox(height: 14),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, color: context.colors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(BuildContext context, bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 22 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? context.colors.brand : context.colors.border,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
