import 'package:flutter/services.dart';

/// Tutar alanlarında girilen sayıyı canlı olarak binlik ayraçlı gösterir
/// (Türkiye biçimi: nokta binlik ayraç, virgül ondalık ayraç — örn. 2.000.000,50).
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final cursorPos = newValue.selection.end.clamp(0, newValue.text.length);
    final beforeCursorRaw = newValue.text.substring(0, cursorPos);
    // İmleçten önceki "anlamlı" (rakam veya virgül) karakter sayısı; noktalar
    // (biçimlendirme ayracı) sayılmaz, yeniden hesaplanan konumda kullanılacak.
    final meaningfulBeforeCursor = beforeCursorRaw.replaceAll('.', '').length;

    final clean = newValue.text.replaceAll('.', '');
    final commaIndex = clean.indexOf(',');
    final hasComma = commaIndex != -1;
    String intPart;
    var decPart = '';
    if (hasComma) {
      intPart = clean.substring(0, commaIndex).replaceAll(RegExp(r'[^0-9]'), '');
      decPart = clean.substring(commaIndex + 1).replaceAll(RegExp(r'[^0-9]'), '');
      if (decPart.length > 2) decPart = decPart.substring(0, 2);
    } else {
      intPart = clean.replaceAll(RegExp(r'[^0-9]'), '');
    }
    intPart = intPart.replaceFirst(RegExp(r'^0+(?=\d)'), '');

    final buffer = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write('.');
      buffer.write(intPart[i]);
    }
    var formatted = buffer.toString();
    if (hasComma) formatted += ',$decPart';

    var newOffset = formatted.length;
    var count = 0;
    for (var i = 0; i < formatted.length; i++) {
      if (count >= meaningfulBeforeCursor) {
        newOffset = i;
        break;
      }
      if (formatted[i] != '.') count++;
      newOffset = i + 1;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newOffset.clamp(0, formatted.length)),
    );
  }
}

/// Binlik ayraçlı metni ("2.000.000,50") double'a çevirir.
double parseThousandsFormatted(String text) {
  final normalized = text.replaceAll('.', '').replaceAll(',', '.');
  return double.tryParse(normalized) ?? 0.0;
}

/// Bir sayıyı, bir denetleyiciyi (controller) başlangıçta doldururken
/// kullanılmak üzere binlik ayraçlı metne çevirir (örn. 2000000 -> "2.000.000").
String formatAmountForDisplay(num value) {
  final isNegative = value < 0;
  final intValue = value.abs().truncate();
  final hasDecimals = value.abs() - intValue > 0.0001;
  var intPart = intValue.toString();

  final buffer = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write('.');
    buffer.write(intPart[i]);
  }
  var formatted = buffer.toString();
  if (hasDecimals) {
    final decStr = (value.abs() - intValue).toStringAsFixed(2).substring(2);
    formatted += ',$decStr';
  }
  return isNegative ? '-$formatted' : formatted;
}
