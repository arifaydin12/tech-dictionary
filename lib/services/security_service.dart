import 'package:local_auth/local_auth.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';

class SecurityService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final encrypt.Encrypter _encrypter = encrypt.Encrypter(
    encrypt.AES(encrypt.Key.fromLength(32)),
  );

  /// Biyometrik giriş kontrolü
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// Biyometrik ile kimlik doğrulama
  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Güvenlik için kimlik doğrulaması gerekli',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      print('Biyometrik kimlik doğrulama hatası: $e');
      return false;
    }
  }

  /// Veri şifreleme
  String encryptData(String data) {
    try {
      final iv = encrypt.IV.fromLength(16);
      final encrypted = _encrypter.encrypt(data, iv: iv);
      return encrypted.base64;
    } catch (e) {
      print('Şifreleme hatası: $e');
      return data;
    }
  }

  /// Veri şifre çözme
  String decryptData(String encryptedData) {
    try {
      final iv = encrypt.IV.fromLength(16);
      final encrypted = encrypt.Encrypted.fromBase64(encryptedData);
      return _encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      print('Şifre çözme hatası: $e');
      return encryptedData;
    }
  }

  /// Hassas verileri şifrele ve kaydet
  Future<void> saveEncryptedData(String key, String value) async {
    final encrypted = encryptData(value);
    // SharedPreferences'a kaydet
    // TODO: Implement
  }

  /// Şifreli veriyi oku ve çöz
  Future<String?> getDecryptedData(String key) async {
    // SharedPreferences'tan oku
    // TODO: Implement
    return null;
  }
}

