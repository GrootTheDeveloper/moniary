package com.moniary.moniary

import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "moniary/file_actions")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openFile" -> {
                        val path = call.argument<String>("path")
                        if (path.isNullOrBlank()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        result.success(openFile(path))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun openFile(path: String): Boolean {
        val file = File(path)
        if (!file.exists()) return false

        val uri = FileProvider.getUriForFile(this, "${applicationContext.packageName}.fileprovider", file)
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, mimeType(path))
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        if (intent.resolveActivity(packageManager) == null) return false
        startActivity(Intent.createChooser(intent, "Open exported file"))
        return true
    }

    private fun mimeType(path: String): String {
        return when {
            path.endsWith(".csv", ignoreCase = true) -> "text/csv"
            path.endsWith(".xlsx", ignoreCase = true) -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            path.endsWith(".pdf", ignoreCase = true) -> "application/pdf"
            else -> "application/octet-stream"
        }
    }
}
