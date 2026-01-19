import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zen/providers/providers.dart';
import 'package:zen/theme/zen_theme.dart';
import 'package:zen/utils/utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  
  bool _obscurePassword = true;
  DateTime? _selectedBirthDate;
  
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    try {
      // Calcular fecha inicial: 18 años atrás
      final DateTime initialDate = DateTime(
        DateTime.now().year - 18,
        DateTime.now().month,
        DateTime.now().day,
      );

      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
      );

      if (picked != null && picked != _selectedBirthDate) {
        setState(() {
          _selectedBirthDate = picked;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar fecha: $e')),
        );
      }
    }
  }

  void _handleLogin(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthProvider>().login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  }

  void _handleRegister(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedBirthDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona tu fecha de nacimiento')),
        );
        return;
      }

      context.read<AuthProvider>().register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        birthDate: _selectedBirthDate!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                // Logo y título
                _buildHeader(context),
                const SizedBox(height: 48),
                
                // Modo de autenticación
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return Column(
                      children: [
                        // Campos de registro
                        if (!authProvider.isLogin) ...[
                          TextFormField(
                            controller: _firstNameController,
                            decoration: InputDecoration(
                              hintText: 'Nombre',
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                            validator: (value) =>
                                ValidationUtils.validateName(value),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _lastNameController,
                            decoration: InputDecoration(
                              hintText: 'Apellidos',
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                            validator: (value) =>
                                ValidationUtils.validateLastName(value),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => _selectBirthDate(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: ZenTheme.dividerColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: ZenTheme.borderColor,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _selectedBirthDate == null
                                          ? 'Selecciona tu fecha de nacimiento'
                                          : '${_selectedBirthDate?.day}/${_selectedBirthDate?.month}/${_selectedBirthDate?.year}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Email
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Correo electrónico',
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                          validator: (value) =>
                              ValidationUtils.validateEmail(value),
                        ),
                        const SizedBox(height: 16),
                        
                        // Contraseña
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            helperText: authProvider.isLogin
                                ? null
                                : 'Mín. 6 caracteres, 1 mayúscula, 1 número',
                            helperMaxLines: 2,
                          ),
                          validator: (value) =>
                              ValidationUtils.validatePassword(value),
                        ),
                        const SizedBox(height: 24),
                        
                        // Mensaje de error
                        if (authProvider.errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: ZenTheme.errorColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: ZenTheme.errorColor,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              authProvider.errorMessage!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: ZenTheme.errorColor,
                                  ),
                            ),
                          ),
                        if (authProvider.errorMessage != null)
                          const SizedBox(height: 16),
                        
                        // Botón principal
                        FilledButton(
                          onPressed: authProvider.isLoading
                              ? null
                              : () {
                                  if (authProvider.isLogin) {
                                    _handleLogin(context);
                                  } else {
                                    _handleRegister(context);
                                  }
                                },
                          child: authProvider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                  ),
                                )
                              : Text(
                                  authProvider.isLogin
                                      ? 'Iniciar Sesión'
                                      : 'Registrarse',
                                ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Toggle entre login/registro
                        Center(
                          child: GestureDetector(
                            onTap: authProvider.isLoading
                                ? null
                                : () {
                                    _formKey.currentState?.reset();
                                    _emailController.clear();
                                    _passwordController.clear();
                                    _firstNameController.clear();
                                    _lastNameController.clear();
                                    setState(() {
                                      _selectedBirthDate = null;
                                    });
                                    context
                                        .read<AuthProvider>()
                                        .toggleAuthMode();
                                  },
                            child: RichText(
                              text: TextSpan(
                                text: authProvider.isLogin
                                    ? '¿No tienes cuenta? '
                                    : '¿Ya tienes cuenta? ',
                                style: Theme.of(context).textTheme.bodyMedium,
                                children: [
                                  TextSpan(
                                    text: authProvider.isLogin
                                        ? 'Regístrate'
                                        : 'Inicia sesión',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: ZenTheme.primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Center(
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return Column(
            children: [
              Text(
                '🧘',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 16),
              Text(
                'Zen',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: ZenTheme.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                authProvider.isLogin
                    ? 'Bienvenido de vuelta'
                    : 'Únete a Zen',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                authProvider.isLogin
                    ? 'Gestión Personal & Productividad'
                    : 'Organiza tu vida de forma consciente',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }
}
