import 'dart:convert';

/// `ApiService`'in attığı `Exception('... : {json gövdesi}')` biçimindeki
/// hatalardan, DRF'nin döndürdüğü asıl doğrulama mesajını çıkarır
/// (örn. "Bu e-posta adresi zaten kayıtlı."). Ayrıştırılamazsa [fallback] döner.
String friendlyApiErrorMessage(Object error, {required String fallback}) {
  final raw = error.toString();
  final jsonStart = raw.indexOf('{');
  if (jsonStart == -1) return fallback;
  try {
    final body = jsonDecode(raw.substring(jsonStart));
    if (body is Map) {
      for (final value in body.values) {
        if (value is List && value.isNotEmpty) return value.first.toString();
        if (value is String && value.isNotEmpty) return value;
      }
    }
  } catch (_) {
    // JSON değilse (örn. HTML hata sayfası) fallback'e düş.
  }
  return fallback;
}
