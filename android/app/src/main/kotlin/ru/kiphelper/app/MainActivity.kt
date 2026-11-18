package ru.kiphelper.app

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val requestSaveMap = 4937
    private var pendingResult: MethodChannel.Result? = null
    private var pendingBytes: ByteArray? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ru.kiphelper.app/position_backup")
            .setMethodCallHandler { call, result ->
                if (call.method != "save") {
                    result.notImplemented()
                } else if (pendingResult != null) {
                    result.error("busy", "A save is already in progress", null)
                } else {
                    val bytes = call.argument<ByteArray>("bytes")
                    val name = call.argument<String>("name")
                    if (bytes == null || bytes.size > 2 * 1024 * 1024 || name.isNullOrBlank()) {
                        result.error("invalid", "Invalid backup", null)
                    } else {
                        pendingResult = result
                        pendingBytes = bytes
                        try {
                            val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                                addCategory(Intent.CATEGORY_OPENABLE)
                                type = "application/json"
                                putExtra(Intent.EXTRA_TITLE, name)
                            }
                            @Suppress("DEPRECATION")
                            startActivityForResult(intent, requestSaveMap)
                        } catch (e: Exception) {
                            pendingResult = null
                            pendingBytes = null
                            result.error("open_failed", "Cannot open save dialog", null)
                        }
                    }
                }
            }
    }

    @Deprecated("Deprecated by Android")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != requestSaveMap) return
        val callback = pendingResult ?: return
        val bytes = pendingBytes
        pendingResult = null
        pendingBytes = null
        if (resultCode != Activity.RESULT_OK) {
            callback.success(false)
            return
        }
        val uri = data?.data
        if (uri == null || bytes == null) {
            callback.error("save_failed", "No destination returned", null)
            return
        }
        try {
            val stream = contentResolver.openOutputStream(uri, "wt")
                ?: throw IllegalStateException("Cannot open destination")
            stream.use { it.write(bytes) }
            callback.success(true)
        } catch (e: Exception) {
            callback.error("save_failed", "Cannot write backup", null)
        }
    }

    override fun onDestroy() {
        pendingResult?.error("interrupted", "Save interrupted", null)
        pendingResult = null
        pendingBytes = null
        super.onDestroy()
    }
}
