import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:zen/services/services.dart';

// No podemos importar dart:html directamente porque rompería la compilación en móvil.
// Usaremos una técnica de "conditional export" o simplemente lógica de plataforma si es seguro.

class DownloadHelper {
  static const _platform = MethodChannel('com.example.zen/download');

  static Future<bool> download({
    required String url,
    required String fileName,
    String? token,
    required List<int> bytes,
  }) async {
    if (kIsWeb) {
      // La implementación de Web se maneja mediante JS interop o una función específica
      // que inyectaremos o llamaremos de forma segura.
      return false; 
    }

    if (Platform.isAndroid) {
      try {
        final bool result = await _platform.invokeMethod('downloadFile', {
          'url': url,
          'fileName': fileName,
          'token': token,
        });
        return result;
      } catch (e) {
        return false;
      }
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      try {
        String? downloadPath;
        if (Platform.isWindows) {
          final userProfile = Platform.environment['USERPROFILE'];
          downloadPath = '$userProfile\\Downloads\\$fileName';
        } else {
          final home = Platform.environment['HOME'];
          downloadPath = '$home/Downloads/$fileName';
        }

        final file = File(downloadPath);
        await file.writeAsBytes(bytes);
        return true;
      } catch (e) {
        return false;
      }
    }
    
    return false;
  }
}
