/// ⚠️ DEPRECATED SERVICE - DATABASE SERVICE
/// Este archivo es legacy y ha sido completamente reemplazado por:
/// - ApiService (lib/services/api_service.dart)
/// - Todos los providers ahora usan ApiService en lugar de SQLite local
///
/// La base de datos MySQL está centralizada en el backend Node.js
/// en: http://localhost:3000/api
///
/// Este archivo será eliminado en la próxima limpieza.

@Deprecated('Use ApiService instead - all data now goes through REST API')
class DatabaseService {
  @Deprecated('Use ApiService instead')
  static Future<void> initDatabase() async {
    throw Exception(
      'DatabaseService is deprecated. Use ApiService with MySQL instead.',
    );
  }
}
