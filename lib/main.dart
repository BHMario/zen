import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:zen/theme/theme.dart';
import 'package:zen/providers/providers.dart';
import 'package:zen/screens/home_screen.dart';
import 'package:zen/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
      ],
      child: MaterialApp(
        title: 'Zen - Personal Productivity',
        theme: ZenTheme.lightTheme,
        darkTheme: ZenTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const _HomeWrapper(),
      ),
    );
  }
}

class _HomeWrapper extends StatefulWidget {
  const _HomeWrapper();

  @override
  State<_HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<_HomeWrapper> {
  late AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = context.read<AuthProvider>();
    // Usar Future.microtask para evitar setState durante build
    Future.microtask(() => _authProvider.checkAuthStatus());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          // Mostrar splash screen mientras se verifica la sesión
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (authProvider.isAuthenticated) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

