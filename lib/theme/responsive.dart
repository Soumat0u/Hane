import 'package:flutter/widgets.dart';

/// Duyarlı (responsive) düzen yardımcıları.
///
/// Tek breakpoint mantığı ve tek ortalayıcı widget üzerinden çalışır; böylece
/// masaüstü/web düzeni tüm ekranlarda tutarlı ve tek noktadan ayarlanabilir olur.

/// Telefon üstü (tablet) eşiği.
const double kMobileBreakpoint = 600;

/// Masaüstü/geniş ekran eşiği. Bunun üstünde kalıcı kenar menü gösterilir.
const double kDesktopBreakpoint = 1000;

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Geniş ekran (masaüstü/web) düzeni mi?
  bool get isDesktop => screenWidth >= kDesktopBreakpoint;

  /// Tablet aralığı (mobil ile masaüstü arası).
  bool get isTablet => screenWidth >= kMobileBreakpoint && screenWidth < kDesktopBreakpoint;
}

/// İçeriği ortalar ve [maxWidth] ile sınırlar. Dar ekranlarda (mobil) ekran
/// zaten [maxWidth]'ten küçük olduğundan görünür bir etkisi olmaz; geniş ekranda
/// içeriğin kenarlara yapışmasını engeller.
class ResponsiveCenter extends StatelessWidget {
  final double maxWidth;
  final Widget child;

  const ResponsiveCenter({
    super.key,
    this.maxWidth = 900,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Bir kart listesini masaüstünde çok sütunlu ızgaraya, mobilde tek sütuna dizer.
///
/// Mobilde mevcut `ListView.builder` davranışını korur (tembel, kaydırmalı);
/// masaüstünde içeriği [maxWidth] ile sınırlayıp `Wrap` ile sütunlara böler.
/// [padding] yatay değeri sütun genişliği hesabında dikkate alınır.
class ResponsiveCardGrid extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final EdgeInsets padding;
  final double maxWidth;
  final double minCardWidth;
  final int maxColumns;
  final double gap;

  const ResponsiveCardGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = const EdgeInsets.only(left: 20, right: 20, bottom: 20),
    this.maxWidth = 1100,
    this.minCardWidth = 360,
    this.maxColumns = 3,
    this.gap = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (!context.isDesktop) {
      return ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: padding,
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final double avail = (constraints.maxWidth.clamp(0, maxWidth)) - padding.horizontal;
        final int cols = responsiveColumns(avail, minCardWidth: minCardWidth, maxColumns: maxColumns);
        final double cardWidth = cols <= 1 ? avail : (avail - gap * (cols - 1)) / cols;
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: padding,
          child: ResponsiveCenter(
            maxWidth: maxWidth - padding.horizontal,
            child: Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (int i = 0; i < itemCount; i++)
                  SizedBox(width: cardWidth, child: itemBuilder(context, i)),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Tam pencere (Navigator.push ile açılan) sayfalar için: masaüstünde içeriği
/// [maxContentWidth] genişliğinde ortalayan yatay padding üretir; mobilde [horizontal].
/// Büyük widget ağaçlarını sarmadan, yalnızca `padding:` değerini değiştirerek ortalama sağlar.
EdgeInsets centeredPagePadding(
  BuildContext context, {
  double maxContentWidth = 900,
  double horizontal = 20,
  double top = 0,
  double bottom = 0,
}) {
  double side = horizontal;
  if (context.isDesktop) {
    final double s = (context.screenWidth - maxContentWidth) / 2;
    if (s > horizontal) side = s;
  }
  return EdgeInsets.only(left: side, right: side, top: top, bottom: bottom);
}

/// Hazır widget listesini masaüstünde çok sütunlu `Wrap`'e, mobilde tek sütunlu
/// `Column`'a dizer. `...list.map(...)` deseniyle kurulan kart listeleri için uygundur.
/// Kartların kendi alt boşlukları (margin) korunduğundan mobil görünüm değişmez.
class ResponsiveWrap extends StatelessWidget {
  final List<Widget> children;
  final double minCardWidth;
  final int maxColumns;
  final double gap;

  const ResponsiveWrap({
    super.key,
    required this.children,
    this.minCardWidth = 360,
    this.maxColumns = 3,
    this.gap = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (!context.isDesktop) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final int cols = responsiveColumns(constraints.maxWidth, minCardWidth: minCardWidth, maxColumns: maxColumns);
        if (cols <= 1) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
        }
        final double cardWidth = (constraints.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: 0,
          children: [
            for (final child in children) SizedBox(width: cardWidth, child: child),
          ],
        );
      },
    );
  }
}

/// Verilen genişliğe göre ızgara (grid) sütun sayısını hesaplar.
/// Her kartın en az [minCardWidth] genişliğinde olmasını hedefler; sonucu
/// 1..[maxColumns] aralığına sıkıştırır.
int responsiveColumns(
  double width, {
  double minCardWidth = 340,
  int maxColumns = 3,
}) {
  if (width <= 0) return 1;
  final int cols = (width / minCardWidth).floor();
  if (cols < 1) return 1;
  if (cols > maxColumns) return maxColumns;
  return cols;
}
