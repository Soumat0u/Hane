import 'package:flutter/material.dart';

/// EVVE İNŞAAT Finans Paneli hiyerarşisi.
///
/// Yapı: PanelSection (5 ana bölüm) → PanelGroup (alt başlıklar) → PanelItem (kalemler)
///
/// Şu an örnek (demo) verilerle besleniyor; ileride backend modellerine bağlanacak.

/// En alt seviye kalem: tek bir satır (örn. "Halkbank" → 1.250.000 ₺).
class PanelItem {
  final String name;
  final double amount;

  const PanelItem(this.name, this.amount);
}

/// Bir alt başlık (örn. "Bankalar") ve altındaki kalemler.
///
/// Tek değerli bölümler (Nakit, Borsa, Çekler vb.) tek kalemli grup olarak temsil edilir.
class PanelGroup {
  final String title;
  final List<PanelItem> items;

  const PanelGroup(this.title, this.items);

  double get total => items.fold(0.0, (sum, item) => sum + item.amount);

  /// Birden fazla kalemi varsa açılır liste gösterilir.
  bool get hasBreakdown => items.length > 1;
}

/// Ana bölüm (KASA, BORÇLAR, FİNANSMAN GÜCÜ, PROJE MALİYETLERİ, ALACAKLAR).
class PanelSection {
  final String title;
  final String totalLabel; // örn. "TOPLAM KASA"
  final IconData icon;
  final Color accentColor;
  final Color bgColor;
  final List<PanelGroup> groups;

  const PanelSection({
    required this.title,
    required this.totalLabel,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
    required this.groups,
  });

  double get total => groups.fold(0.0, (sum, group) => sum + group.total);
}
