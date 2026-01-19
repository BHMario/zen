import 'package:crypto/crypto.dart';
import 'dart:convert';

class PasswordUtils {
  /// Genera un hash seguro de una contraseña usando SHA256
  /// En producción, considera usar bcrypt o argon2
  static String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  /// Verifica si una contraseña coincide con su hash
  static bool verifyPassword(String password, String hash) {
    final hashedPassword = hashPassword(password);
    return hashedPassword == hash;
  }

  /// Genera un salt simple (en producción, usa algo más robusto)
  static String generateSalt() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
