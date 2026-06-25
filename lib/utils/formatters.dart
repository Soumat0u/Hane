import 'package:intl/intl.dart';

/// Ortak para/sayı formatlama yardımcıları. Uygulama yalnızca TL (₺) kullanır.

/// Tutarı ₺ ile biçimlendirir (ondalıksız, tr_TR binlik ayraç).
String formatCurrency(num value, {int decimalDigits = 0}) {
  return NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: decimalDigits,
  ).format(value);
}

/// Varsayılan ₺ formatlayıcı (tüm ekranlarda ortak kullanılır).
final NumberFormat currencyFormat =
    NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
