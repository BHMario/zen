import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:zen/providers/providers.dart';
import 'package:zen/models/models.dart';
import 'package:zen/theme/zen_theme.dart';
import 'package:zen/services/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  static const platform = MethodChannel('com.example.zen/download');

  Future<void> _downloadData(User user) async {
    try {
      final token = await TokenService.getToken();
      final url = '${ApiService.baseUrl}/users/${user.id}/export';
      final fileName = 'zen_datos_${user.id.substring(0, 5)}.json';

      if (kIsWeb) {
        // En Web, simplemente lanzamos la URL y el navegador gestiona la descarga
        // gracias a los headers Content-Disposition del backend.
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Iniciando descarga en el navegador...')),
            );
          }
        } else {
          throw Exception('No se pudo abrir el enlace de descarga');
        }
        return;
      }

      if (Platform.isAndroid) {
        // Usar nuestro canal nativo para Android
        final bool result = await platform.invokeMethod('downloadFile', {
          'url': url,
          'fileName': fileName,
          'token': token,
        });

        if (result && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Descarga iniciada. Revisa tus notificaciones.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        // Descarga directa para Desktop usando dart:io
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Descargando archivo...')),
          );
        }

        final response = await http.get(
          Uri.parse(url),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          String? downloadPath;
          if (Platform.isWindows) {
            final userProfile = Platform.environment['USERPROFILE'];
            downloadPath = '$userProfile\\Downloads\\$fileName';
          } else {
            final home = Platform.environment['HOME'];
            downloadPath = '$home/Downloads/$fileName';
          }

          final file = File(downloadPath);
          await file.writeAsBytes(response.bodyBytes);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Archivo guardado en Descargas: $fileName'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('Error del servidor: ${response.statusCode}');
        }
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en la descarga: ${e.message}'),
            backgroundColor: ZenTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: ZenTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar cuenta?'),
        content: const Text(
          'Esta acción es irreversible. Se eliminarán permanentemente todos tus datos, tareas, proyectos y configuraciones.',
          style: TextStyle(color: ZenTheme.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ZenTheme.errorColor,
            ),
            onPressed: () {
              Navigator.pop(context);
              _handleDeleteAccount();
            },
            child: const Text('Eliminar Permanentemente'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteAccount() async {
    final success = await context.read<AuthProvider>().deleteAccount();
    if (success && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta eliminada correctamente')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<AuthProvider>().errorMessage ??
                'Error al eliminar la cuenta',
          ),
          backgroundColor: ZenTheme.errorColor,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacidad'),
        elevation: 0,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = authProvider.currentUser!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Datos y Analíticas'),
                _buildSwitchTile(
                  title: 'Compartir analíticas',
                  subtitle: 'Ayúdanos a mejorar Zen compartiendo datos anónimos de uso.',
                  value: user.shareAnalytics,
                  onChanged: (val) => authProvider.updatePrivacySettings(shareAnalytics: val),
                  icon: Icons.analytics_outlined,
                ),
                const Divider(),
                _buildSwitchTile(
                  title: 'Estado de actividad',
                  subtitle: 'Permitir que otros vean si estás activo en la aplicación.',
                  value: user.showActiveStatus,
                  onChanged: (val) => authProvider.updatePrivacySettings(showActiveStatus: val),
                  icon: Icons.visibility_outlined,
                ),
                _buildSwitchTile(
                  title: 'Perfil privado',
                  subtitle: 'Solo tú podrás ver tus estadísticas y progresos.',
                  value: user.profilePrivate,
                  onChanged: (val) => authProvider.updatePrivacySettings(profilePrivate: val),
                  icon: Icons.lock_outline,
                ),
                const Divider(),
                _buildSectionTitle('Comunicaciones'),
                _buildSwitchTile(
                  title: 'Notificaciones de marketing',
                  subtitle: 'Recibe novedades sobre funciones y ofertas especiales.',
                  value: user.marketingEmails,
                  onChanged: (val) => authProvider.updatePrivacySettings(marketingEmails: val),
                  icon: Icons.email_outlined,
                ),
                const Divider(),
                _buildSectionTitle('Tus Datos'),
                ListTile(
                  leading: const Icon(Icons.download_outlined, color: ZenTheme.primaryColor),
                  title: const Text('Descargar mi información'),
                  subtitle: const Text('Obtén un archivo JSON con todos tus datos de Zen.'),
                  onTap: () => _downloadData(user),
                  trailing: const Icon(Icons.download, size: 20),
                ),
                const Divider(),
                _buildSectionTitle('Seguridad y Sesiones'),
                ListTile(
                  leading: const Icon(Icons.devices_outlined, color: ZenTheme.primaryColor),
                  title: const Text('Sesiones activas'),
                  subtitle: const Text('Gestiona los dispositivos donde tienes sesión iniciada.'),
                  onTap: () {},
                ),
                const Divider(),
                _buildSectionTitle('Cuenta'),
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined, color: ZenTheme.errorColor),
                  title: const Text('Eliminar cuenta', style: TextStyle(color: ZenTheme.errorColor)),
                  subtitle: const Text('Elimina tu cuenta y todos tus datos personales.'),
                  onTap: _showDeleteAccountDialog,
                ),
                const SizedBox(height: 32),
                _buildSectionTitle('Legal'),
                ListTile(
                  title: const Text('Política de Privacidad'),
                  trailing: const Icon(Icons.open_in_new, size: 16),
                  onTap: () {},
                ),
                ListTile(
                  title: const Text('Términos de Servicio'),
                  trailing: const Icon(Icons.open_in_new, size: 16),
                  onTap: () {},
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: ZenTheme.textLight,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: ZenTheme.primaryColor),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
      activeColor: ZenTheme.primaryColor,
    );
  }
}
