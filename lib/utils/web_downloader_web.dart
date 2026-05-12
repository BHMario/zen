// web_downloader_web.dart
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js_interop';

@JS('eval')
external void _jsEval(String code);

void downloadWeb(String url, String fileName) {
  final safeUrl = url.replaceAll("'", "\\'");
  final safeName = fileName.replaceAll("'", "\\'");
  try {
    _jsEval("""
      (function() {
        var link = document.createElement('a');
        link.href = '$safeUrl';
        link.download = '$safeName';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
      })();
    """);
  } catch (e) {
    _jsEval("window.open('$safeUrl', '_blank')");
  }
}
