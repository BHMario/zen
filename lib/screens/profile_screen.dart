import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zen/providers/providers.dart';
import 'package:zen/theme/zen_theme.dart';
import 'package:zen/utils/utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>?> _userDetailsFuture;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _userDetailsFuture = authProvider.getUserDetails(authProvider.currentUser?.email ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        elevation: 0,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.currentUser == null) {
            return const Center(
              child: Text('No autenticado'),
            );
          }

          final user = authProvider.currentUser!;

          return FutureBuilder<Map<String, dynamic>?>(
            future: _userDetailsFuture,
            builder: (context, snapshot) {
              final userDetails = snapshot.data;

              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Header con avatar
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            ZenTheme.primaryColor,
                            ZenTheme.primaryColor.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: ZenTheme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user.name,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user.email,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Información del usuario
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Información Personal',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),
                          
                          // Tarjetas de información
                          if (snapshot.connectionState == ConnectionState.done && userDetails != null) ...[
                            _buildInfoCard(
                              context,
                              icon: Icons.person_outline,
                              label: 'Nombre',
                              value: userDetails['name'] as String? ?? user.name,
                              color: ZenTheme.primaryColor,
                            ),
                            const SizedBox(height: 12),
                            _buildInfoCard(
                              context,
                              icon: Icons.email_outlined,
                              label: 'Email',
                              value: userDetails['email'] as String? ?? user.email,
                              color: ZenTheme.secondaryColor,
                            ),
                            const SizedBox(height: 12),
                            _buildInfoCard(
                              context,
                              icon: Icons.calendar_today_outlined,
                              label: 'Miembro desde',
                              value: DateTimeUtils.formatDate(
                                userDetails['createdAt'] != null 
                                  ? DateTime.parse(userDetails['createdAt'] as String)
                                  : user.createdAt,
                                format: 'dd/MM/yyyy',
                              ),
                              color: ZenTheme.warningColor,
                            ),
                          ] else if (snapshot.connectionState == ConnectionState.waiting) ...[
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          ] else ...[
                            Center(
                              child: Text(
                                'No se pudo cargar la información del usuario',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: ZenTheme.textLight,
                                ),
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 32),
                          
                          // Sección de configuración
                          Text(
                            'Cuenta',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),
                          
                          ListTile(
                            title: const Text('Cambiar contraseña'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Funcionalidad en desarrollo'),
                                ),
                              );
                            },
                          ),
                          
                          Divider(
                            color: ZenTheme.borderColor,
                            height: 1,
                          ),
                          
                          ListTile(
                            title: const Text('Privacidad'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Funcionalidad en desarrollo'),
                                ),
                              );
                            },
                          ),
                          
                          Divider(
                            color: ZenTheme.borderColor,
                            height: 1,
                          ),
                          
                          ListTile(
                            title: const Text('Notificaciones'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Funcionalidad en desarrollo'),
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Botón cerrar sesión
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: ZenTheme.errorColor,
                                side: const BorderSide(
                                  color: ZenTheme.errorColor,
                                ),
                              ),
                              onPressed: () {
                                _showLogoutDialog(context, authProvider);
                              },
                              child: const Text('Cerrar Sesión'),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ZenTheme.textLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cerrar Sesión?'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              authProvider.logout();
              Navigator.pop(context);
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}
