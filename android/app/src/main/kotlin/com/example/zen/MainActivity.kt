package com.example.zen

import android.app.DownloadManager
import android.content.Context
import android.net.Uri
import android.os.Environment
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.example.zen/download"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "downloadFile") {
                val url = call.argument<String>("url")
                val fileName = call.argument<String>("fileName")
                val token = call.argument<String>("token")
                
                if (url != null && fileName != null) {
                    try {
                        downloadFile(url, fileName, token)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("DOWNLOAD_ERROR", e.message, null)
                    }
                } else {
                    result.error("INVALID_ARGUMENTS", "URL or FileName is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun downloadFile(url: String, fileName: String, token: String?) {
        val request = DownloadManager.Request(Uri.parse(url))
        request.setTitle("Datos de Zen")
        request.setDescription("Descargando tu archivo de información personal...")
        request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
        request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, fileName)
        request.setMimeType("application/json")
        
        if (token != null) {
            request.addRequestHeader("Authorization", "Bearer $token")
        }

        val manager = getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        manager.enqueue(request)
    }
}
