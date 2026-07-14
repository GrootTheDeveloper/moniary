package com.moniary.moniary

import android.content.ContentValues
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private var deepLinkChannel: MethodChannel? = null
    private var initialDeepLink: String? = null
    private var latestDeepLink: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        captureDeepLink(intent, setInitial = true)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        deepLinkChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "moniary/deep_links")
        captureDeepLink(intent, setInitial = initialDeepLink == null)
        deepLinkChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialLink" -> result.success(initialDeepLink)
                "getLatestLink" -> result.success(latestDeepLink)
                else -> result.notImplemented()
            }
        }

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
                    "shareFile" -> {
                        val path = call.argument<String>("path")
                        if (path.isNullOrBlank()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        result.success(shareFile(path))
                    }
                    "saveToDownloads" -> {
                        val fileName = call.argument<String>("fileName")
                        val mimeType = call.argument<String>("mimeType")
                        val bytes = call.argument<ByteArray>("bytes")
                        if (fileName.isNullOrBlank() || mimeType.isNullOrBlank() || bytes == null) {
                            result.success(null)
                            return@setMethodCallHandler
                        }
                        result.success(saveToDownloads(fileName, mimeType, bytes))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val link = captureDeepLink(intent, setInitial = false)
        if (link != null) {
            deepLinkChannel?.invokeMethod("onDeepLink", link)
        }
    }

    private fun captureDeepLink(intent: Intent?, setInitial: Boolean): String? {
        if (intent?.action != Intent.ACTION_VIEW) return null
        val link = intent.dataString?.takeIf { it.isNotBlank() } ?: return null
        if (setInitial && initialDeepLink == null) {
            initialDeepLink = link
        }
        latestDeepLink = link
        return link
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
        startActivity(Intent.createChooser(intent, "Mở file đã xuất"))
        return true
    }

    private fun shareFile(path: String): Boolean {
        val file = File(path)
        if (!file.exists()) return false

        val uri = FileProvider.getUriForFile(this, "${applicationContext.packageName}.fileprovider", file)
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = mimeType(path)
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        if (intent.resolveActivity(packageManager) == null) return false
        startActivity(Intent.createChooser(intent, "Chia sẻ file"))
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

    private fun saveToDownloads(fileName: String, mimeType: String, bytes: ByteArray): String? {
        return try {
            val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            val publicFile = File(downloadsDir, fileName)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val values = ContentValues().apply {
                    put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                    put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                    put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                    put(MediaStore.MediaColumns.IS_PENDING, 1)
                }

                val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                    ?: return null

                contentResolver.openOutputStream(uri)?.use { output ->
                    output.write(bytes)
                } ?: return null

                values.clear()
                values.put(MediaStore.MediaColumns.IS_PENDING, 0)
                contentResolver.update(uri, values, null, null)
                publicFile.absolutePath
            } else {
                downloadsDir.mkdirs()
                publicFile.writeBytes(bytes)
                publicFile.absolutePath
            }
        } catch (_: Exception) {
            null
        }
    }
}
