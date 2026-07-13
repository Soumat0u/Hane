import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Uygulama kilidi için PIN kodunu güvenli depoda (Android Keystore / iOS
/// Keychain) saklar. Sunucu tarafı kimlik doğrulamasıyla ilgisi yoktur —
/// zaten oturum açılmış uygulamayı yerelde açan bir yöntemdir (biyometrik
/// kilitle aynı amaca hizmet eder).
class PinService {
  static const _pinKey = 'app_pin_code';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static final PinService instance = PinService._init();
  PinService._init();

  Future<bool> hasPin() async {
    final value = await _secureStorage.read(key: _pinKey);
    return value != null && value.isNotEmpty;
  }

  Future<void> setPin(String pin) async {
    await _secureStorage.write(key: _pinKey, value: pin);
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _secureStorage.read(key: _pinKey);
    return stored != null && stored == pin;
  }

  Future<void> clearPin() async {
    await _secureStorage.delete(key: _pinKey);
  }
}
