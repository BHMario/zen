// web_downloader_web.dart
import 'dart:js' as js;

void downloadWeb(String url, String fileName) {
  try {
    js.context.callMethod('eval', ["""
      var link = document.createElement('a');
      link.href = '$url';
      link.download = '$fileName';
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
    """]);
  } catch (e) {
    js.context.callMethod('open', [url, '_blank']);
  }
}
