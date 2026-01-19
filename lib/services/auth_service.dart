/// ⚠️ DEPRECATED SERVICE
/// Este archivo es legacy y ha sido completamente reemplazado por:
/// - AuthProvider (lib/providers/auth_provider.dart)
/// - ApiService (lib/services/api_service.dart)
///
/// Todas las operaciones de autenticación deben usar AuthProvider.
/// Ejemplos de migración:
/// ❌ OLD: await AuthService().login(email, password);
/// ✅ NEW: await authProvider.login(email, password);
///
/// Este archivo será eliminado en la próxima limpieza.

@Deprecated('Use AuthProvider with ApiService instead')
class AuthService {
  @Deprecated('Use AuthProvider.register instead')
  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required DateTime birthDate,
  }) async {
    throw Exception(
      'AuthService is deprecated. Use AuthProvider with ApiService instead.',
    );
  }

  @Deprecated('Use AuthProvider.login instead')
  Future<void> login({
    required String email,
    required String password,
  }) async {
    throw Exception(
      'AuthService is deprecated. Use AuthProvider with ApiService instead.',
    );
  }

  @Deprecated('Use ApiService instead')
  Future<void> emailExists(String email) async {
    throw Exception(
      'AuthService is deprecated. Use AuthProvider with ApiService instead.',
    );
  }
}
