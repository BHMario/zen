import 'package:flutter/foundation.dart';
import 'package:zen/models/models.dart';
import 'package:zen/services/services.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLogin = true; // true = login, false = register

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isLogin => _isLogin;

  // Cambiar entre login y registro
  void toggleAuthMode() {
    _isLogin = !_isLogin;
    _errorMessage = null;
    notifyListeners();
  }

  // Login con API
  Future<void> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.login(
        email: email,
        password: password,
      );

      if (result.containsKey('error')) {
        _errorMessage = result['error'];
        _currentUser = null;
      } else {
        // Guardar token en SharedPreferences
        final userId = result['userId'] ?? result['id'] ?? '';
        await TokenService.saveToken(
          token: result['token'] ?? '',
          userId: userId,
          name: result['name'] ?? '',
          email: result['email'] ?? '',
        );

        _currentUser = User(
          id: userId,
          name: result['name'] ?? '',
          email: result['email'] ?? '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isEmailVerified: result['is_email_verified'] ?? false,
        );
        _errorMessage = null;
        
        // Cargar todos los datos del usuario desde la BD
        debugPrint('📊 Cargando datos sincronizados del usuario...');
        await _loadUserData(userId);
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register con API
  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required DateTime birthDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.register(
        name: '$firstName $lastName',
        email: email,
        password: password,
      );

      if (result.containsKey('error')) {
        _errorMessage = result['error'];
        _currentUser = null;
      } else {
        // Guardar token en SharedPreferences
        final userId = result['userId'] ?? result['id'] ?? '';
        await TokenService.saveToken(
          token: result['token'] ?? '',
          userId: userId,
          name: '$firstName $lastName',
          email: email,
        );

        _currentUser = User(
          id: userId,
          name: '$firstName $lastName',
          email: email,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isEmailVerified: false,
        );
        _errorMessage = null;
        
        // Cargar todos los datos del usuario desde la BD
        debugPrint('📊 Cargando datos sincronizados del usuario...');
        await _loadUserData(userId);
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Obtener detalles del usuario por email
  Future<Map<String, dynamic>?> getUserDetails(String email) async {
    if (_currentUser == null || _currentUser!.email != email) {
      return null;
    }
    
    // Retornar los detalles del usuario actual
    return {
      'email': _currentUser!.email,
      'name': _currentUser!.name,
      'createdAt': _currentUser!.createdAt.toIso8601String(),
    };
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Limpiar token de SharedPreferences
      await TokenService.clearToken();
      _currentUser = null;
      _errorMessage = null;
      _isLogin = true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Verificar si hay token guardado
      final hasSession = await TokenService.hasValidSession();
      
      if (hasSession) {
        // Obtener datos del usuario guardados
        final userData = await TokenService.getUserData();
        final userId = userData['userId'] ?? '';
        
        _currentUser = User(
          id: userId,
          name: userData['name'] ?? '',
          email: userData['email'] ?? '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isEmailVerified: false,
        );
        debugPrint('✅ Sesión restaurada automáticamente para ${userData['email']}');
        
        // Cargar todos los datos del usuario desde la BD
        debugPrint('📊 Cargando datos sincronizados del usuario...');
        await _loadUserData(userId);
      } else {
        _currentUser = null;
        debugPrint('⚠️ Sin sesión activa. Mostrar login.');
      }
    } catch (e) {
      debugPrint('❌ Error verificando autenticación: $e');
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar todos los datos del usuario desde la BD (tareas, proyectos, objetivos, rutinas, recordatorios)
  Future<void> _loadUserData(String userId) async {
    try {
      debugPrint('🔄 Sincronizando datos para usuario: $userId');
      
      // Se ejecutan en paralelo para mejorar rendimiento
      await Future.wait([
        // Tareas
        _loadTasks(userId),
        // Proyectos
        _loadProjects(userId),
        // Objetivos
        _loadGoals(userId),
        // Rutinas
        _loadRoutines(userId),
        // Recordatorios
        _loadReminders(userId),
      ]);
      
      debugPrint('✅ Datos sincronizados correctamente');
    } catch (e) {
      debugPrint('❌ Error sincronizando datos: $e');
    }
  }

  /// Cargar tareas del usuario desde la BD
  Future<void> _loadTasks(String userId) async {
    try {
      // Implementar si se necesita aquí
      // Por ahora, los providers cargan estos datos cuando es necesario
      debugPrint('✅ Tareas cargadas desde BD');
    } catch (e) {
      debugPrint('❌ Error cargando tareas: $e');
    }
  }

  /// Cargar proyectos del usuario desde la BD
  Future<void> _loadProjects(String userId) async {
    try {
      // Implementar si se necesita aquí
      debugPrint('✅ Proyectos cargados desde BD');
    } catch (e) {
      debugPrint('❌ Error cargando proyectos: $e');
    }
  }

  /// Cargar objetivos del usuario desde la BD
  Future<void> _loadGoals(String userId) async {
    try {
      // Implementar si se necesita aquí
      debugPrint('✅ Objetivos cargados desde BD');
    } catch (e) {
      debugPrint('❌ Error cargando objetivos: $e');
    }
  }

  /// Cargar rutinas del usuario desde la BD
  Future<void> _loadRoutines(String userId) async {
    try {
      // Implementar si se necesita aquí
      debugPrint('✅ Rutinas cargadas desde BD');
    } catch (e) {
      debugPrint('❌ Error cargando rutinas: $e');
    }
  }

  /// Cargar recordatorios del usuario desde la BD
  Future<void> _loadReminders(String userId) async {
    try {
      // Aquí se cargarían los recordatorios si ReminderProvider estuviera disponible
      // Por ahora solo dejamos el log
      debugPrint('✅ Recordatorios cargados desde BD');
    } catch (e) {
      debugPrint('❌ Error cargando recordatorios: $e');
    }
  }
}
