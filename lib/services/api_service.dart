import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'dart:io' show Platform;
import 'token_service.dart';

class ApiService {
  // URL base según la plataforma
  static String get baseUrl {
    if (kIsWeb) {
      // Web
      return 'http://127.0.0.1:3000/api';
    } else if (Platform.isAndroid) {
      // Android emulador accede al host mediante 10.0.2.2
      return 'http://10.0.2.2:3000/api';
    } else {
      // Windows, iOS, etc.
      return 'http://127.0.0.1:3000/api';
    }
  }
  static final http.Client _client = http.Client();

  /// Obtener headers con token JWT
  static Future<Map<String, String>> _getHeaders() async {
    final token = await TokenService.getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Manejar respuestas con código 401 (token expirado/inválido)
  static void _handleUnauthorized() {
    debugPrint('⚠️ Token inválido o expirado. Limpiando sesión.');
    TokenService.clearToken();
    // Aquí se podría navegar al login si fuera necesario
  }

  // ==================== AUTH ====================
  
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    required bool lopdAccepted,
  }) async {
    try {
      debugPrint('📝 Registrando usuario: $email');
      final response = await _client.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'lopd_accepted': lopdAccepted,
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint('📡 Status: ${response.statusCode}');
      debugPrint('📡 Body: ${response.body}');

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['error'] ?? 'Error en registro: ${response.statusCode}');
        } catch (e) {
          throw Exception('Error en registro: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      debugPrint('❌ Error en registro: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 Intentando login: $email');
      final response = await _client.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint('📡 Status: ${response.statusCode}');
      debugPrint('📡 Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['error'] ?? 'Error en login: ${response.statusCode}');
        } catch (e) {
          throw Exception('Error en login: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      debugPrint('❌ Error en login: $e');
      rethrow;
    }
  }

  // ==================== USERS ====================

  static Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
        return null;
      } else {
        debugPrint('⚠️ Error obteniendo usuario: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error obteniendo usuario: $e');
      return null;
    }
  }

  // ==================== TASKS ====================

  static Future<List<Map<String, dynamic>>> getTasks({String? userId}) async {
    try {
      final url = userId != null 
        ? '$baseUrl/tasks/$userId'
        : '$baseUrl/tasks';
      
      final headers = await _getHeaders();
      final response = await _client.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);
        final List<dynamic> data = decodedBody as List<dynamic>;
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
        throw Exception('Sesión expirada. Por favor, inicia sesión de nuevo.');
      } else {
        throw Exception('Error obteniendo tareas');
      }
    } catch (e) {
      debugPrint('❌ Error obteniendo tareas: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> createTask(Map<String, dynamic> taskData) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.post(
        Uri.parse('$baseUrl/tasks'),
        headers: headers,
        body: jsonEncode(taskData),
      );

      if (response.statusCode == 201) {
        debugPrint('✅ Tarea creada en servidor');
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
        throw Exception('Sesión expirada');
      } else {
        final error = jsonDecode(response.body);
        return {'error': error['error'] ?? 'Error creando tarea'};
      }
    } catch (e) {
      debugPrint('❌ Error creando tarea: $e');
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateTask({
    required String taskId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.put(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: headers,
        body: jsonEncode(updates),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Tarea actualizada en servidor');
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
        throw Exception('Sesión expirada');
      } else {
        return {'error': 'Error actualizando tarea'};
      }
    } catch (e) {
      debugPrint('❌ Error actualizando tarea: $e');
      return {'error': e.toString()};
    }
  }

  static Future<bool> deleteTask(String taskId) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.delete(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Tarea eliminada en servidor');
        return true;
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
        throw Exception('Sesión expirada');
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error eliminando tarea: $e');
      return false;
    }
  }

  // ==================== PROJECTS ====================

  static Future<List<Map<String, dynamic>>> getProjects({String? userId}) async {
    try {
      final url = userId != null 
        ? '$baseUrl/projects/$userId'
        : '$baseUrl/projects';
      
      final headers = await _getHeaders();
      final response = await _client.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
        throw Exception('Sesión expirada');
      } else {
        throw Exception('Error obteniendo proyectos');
      }
    } catch (e) {
      debugPrint('❌ Error obteniendo proyectos: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> createProject({
    required String userId,
    required String name,
    String? description,
    String? color,
    String? startDate,
    String? endDate,
    String? status,
    String? createdBy,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.post(
        Uri.parse('$baseUrl/projects'),
        headers: headers,
        body: jsonEncode({
          'user_id': userId,
          'name': name,
          'description': description,
          'color': color,
          'start_date': startDate,
          'end_date': endDate,
          'status': status ?? 'active',
          'created_by': createdBy,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
        throw Exception('Sesión expirada');
      }
      return {'error': 'Create project failed'};
    } catch (e) {
      debugPrint('❌ Exception createProject: $e');
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateProject({
    required String projectId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.put(
        Uri.parse('$baseUrl/projects/$projectId'),
        headers: headers,
        body: jsonEncode(updates),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
        throw Exception('Sesión expirada');
      }
      return {'error': 'Update project failed'};
    } catch (e) {
      debugPrint('❌ Exception updateProject: $e');
      return {'error': e.toString()};
    }
  }

  static Future<bool> deleteProject(String projectId) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.delete(
        Uri.parse('$baseUrl/projects/$projectId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
        throw Exception('Sesión expirada');
      }
      return false;
    } catch (e) {
      debugPrint('❌ Exception deleteProject: $e');
      return false;
    }
  }

  // ==================== REMINDERS ====================

  static Future<List<Map<String, dynamic>>> getReminders({String? userId}) async {
    try {
      final url = userId != null 
        ? '$baseUrl/reminders/$userId'
        : '$baseUrl/reminders';
      
      final headers = await _getHeaders();
      final response = await _client.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
        throw Exception('Sesión expirada');
      } else {
        throw Exception('Error obteniendo recordatorios');
      }
    } catch (e) {
      debugPrint('❌ Error obteniendo recordatorios: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> createReminder({
    required String userId,
    String? itemId,
    String? type,
    String? dateTime,
    String? frequency,
    String? message,
    bool? isActive,
    String? createdBy,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.post(
        Uri.parse('$baseUrl/reminders'),
        headers: headers,
        body: jsonEncode({
          'user_id': userId,
          'item_id': itemId,
          'type': type,
          'date_time': dateTime,
          'frequency': frequency,
          'message': message,
          'is_active': isActive ?? true,
          'created_by': createdBy ?? userId,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
        throw Exception('Sesión expirada');
      }
      return {'error': 'Create reminder failed'};
    } catch (e) {
      debugPrint('❌ Exception createReminder: $e');
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateReminder({
    required String reminderId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.put(
        Uri.parse('$baseUrl/reminders/$reminderId'),
        headers: headers,
        body: jsonEncode(updates),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
        throw Exception('Sesión expirada');
      }
      return {'error': 'Update reminder failed'};
    } catch (e) {
      debugPrint('❌ Exception updateReminder: $e');
      return {'error': e.toString()};
    }
  }

  static Future<bool> deleteReminder(String reminderId) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.delete(
        Uri.parse('$baseUrl/reminders/$reminderId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
        throw Exception('Sesión expirada');
      }
      return false;
    } catch (e) {
      debugPrint('❌ Exception deleteReminder: $e');
      return false;
    }
  }

  // ==================== ROUTINES ====================

  static Future<List<Map<String, dynamic>>> getRoutines({String? userId}) async {
    try {
      final url = userId != null 
        ? '$baseUrl/routines/$userId'
        : '$baseUrl/routines';
      
      final headers = await _getHeaders();
      final response = await _client.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
        throw Exception('Sesión expirada');
      } else {
        throw Exception('Error obteniendo rutinas');
      }
    } catch (e) {
      debugPrint('❌ Error obteniendo rutinas: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> createRoutine(Map<String, dynamic> routineData) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.post(
        Uri.parse('$baseUrl/routines'),
        headers: headers,
        body: jsonEncode(routineData),
      );

      if (response.statusCode == 201) {
        debugPrint('✅ Rutina creada en servidor');
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
        throw Exception('Sesión expirada');
      } else {
        return {'error': 'Error creando rutina'};
      }
    } catch (e) {
      debugPrint('❌ Error creando rutina: $e');
      return {'error': e.toString()};
    }
  }

  // ==================== GOALS ====================

  static Future<List<Map<String, dynamic>>> getGoals({String? userId}) async {
    try {
      final url = userId != null 
        ? '$baseUrl/goals/$userId'
        : '$baseUrl/goals';
      
      final headers = await _getHeaders();
      final response = await _client.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
        throw Exception('Sesión expirada');
      } else {
        throw Exception('Error obteniendo objetivos');
      }
    } catch (e) {
      debugPrint('❌ Error obteniendo objetivos: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> createGoal(Map<String, dynamic> goalData) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.post(
        Uri.parse('$baseUrl/goals'),
        headers: headers,
        body: jsonEncode(goalData),
      );

      if (response.statusCode == 201) {
        debugPrint('✅ Objetivo creado en servidor');
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
        throw Exception('Sesión expirada');
      } else {
        return {'error': 'Error creando objetivo'};
      }
    } catch (e) {
      debugPrint('❌ Error creando objetivo: $e');
      return {'error': e.toString()};
    }
  }

  // ==================== HEALTH ====================

  static Future<bool> checkHealth() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/../health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('⚠️ Servidor no disponible: $e');
      return false;
    }
  }
}
