import 'package:intl/intl.dart';

/// Ortak para/sayı formatlama yardımcıları.
/// Para birimi sembolü ayardan (SettingsProvider.currencySymbol) veya
/// kaydın kendi currency alanından gelebilir.

const Map<String, String> kCurrencySymbols = {
  'TRY': '₺',
  'USD': '\$',
  'EUR': '€',
};

String currencySymbolOf(String code) => kCurrencySymbols[code] ?? '₺';

/// Tutarı verilen sembolle biçimlendirir (ondalıksız, tr_TR binlik ayraç).
String formatCurrency(num value, {String symbol = '₺', int decimalDigits = 0}) {
  return NumberFormat.currency(
    locale: 'tr_TR',
    symbol: symbol,
    decimalDigits: decimalDigits,
  ).format(value);
}

/// Para birimi koduna göre biçimlendirir (₺/$/€).
String formatAmount(num value, String currencyCode, {int decimalDigits = 0}) {
  return formatCurrency(value, symbol: currencySymbolOf(currencyCode), decimalDigits: decimalDigits);
}

/// Geriye uyumluluk için varsayılan ₺ formatlayıcı.
final NumberFormat currencyFormat =
    NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
