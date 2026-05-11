import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para manejar tokens JWT y persistencia de sesión
class TokenService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _profileImagePathKey = 'profile_image_path';
  static const String _avatarColorKey = 'avatar_bg_color';

  /// Guardar token y datos de usuario después del login
  static Future<void> saveToken({
    required String token,
    required String userId,
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userNameKey, name);
    await prefs.setString(_userEmailKey, email);
  }

  /// Obtener el token guardado
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Obtener el userId guardado
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  /// Obtener todos los datos del usuario guardados
  static Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'token': prefs.getString(_tokenKey),
      'userId': prefs.getString(_userIdKey),
      'name': prefs.getString(_userNameKey),
      'email': prefs.getString(_userEmailKey),
      'profileImagePath': prefs.getString(_profileImagePathKey),
    };
  }

  /// Guardar ruta local de foto de perfil
  static Future<void> saveProfileImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileImagePathKey, path);
  }

  /// Obtener ruta local de foto de perfil
  static Future<String?> getProfileImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileImagePathKey);
  }

  /// Eliminar foto de perfil guardada
  static Future<void> removeProfileImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileImagePathKey);
  }

  /// Guardar color de fondo del avatar
  static Future<void> saveAvatarColor(String colorHex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_avatarColorKey, colorHex);
  }

  /// Obtener color de fondo del avatar guardado
  static Future<String?> getAvatarColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_avatarColorKey);
  }

  /// Verificar si hay sesión activa
  static Future<bool> hasValidSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Limpiar token y datos de usuario (logout)
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_profileImagePathKey);
  }
}
