package com.ardentnetworks.hris

import android.content.ContentValues
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException

// local_auth requires a FragmentActivity host to show the biometric prompt.
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DOWNLOADS_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "savePdf") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val bytes = call.argument<ByteArray>("bytes")
                val name = call.argument<String>("name")
                if (bytes == null || name == null) {
                    result.error("BAD_ARGS", "Missing bytes or name.", null)
                    return@setMethodCallHandler
                }
                val main = Handler(Looper.getMainLooper())
                Thread {
                    try {
                        val saved = savePdfToDownloads(bytes, name)
                        main.post { result.success(saved) }
                    } catch (e: Exception) {
                        main.post { result.error("SAVE_FAILED", e.message, null) }
                    }
                }.start()
            }
    }

    /** Writes the PDF to the public Downloads folder and returns its final name. */
    private fun savePdfToDownloads(bytes: ByteArray, name: String): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            val dir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            dir.mkdirs()
            val base = name.removeSuffix(".pdf")
            var file = File(dir, name)
            var suffix = 1
            while (file.exists()) file = File(dir, "$base (${suffix++}).pdf")
            file.writeBytes(bytes)
            MediaScannerConnection.scanFile(
                this, arrayOf(file.path), arrayOf("application/pdf"), null,
            )
            return file.name
        }

        val resolver = contentResolver
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, name)
            put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf")
            put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            ?: throw IOException("Could not create the file in Downloads.")
        try {
            val out = resolver.openOutputStream(uri)
                ?: throw IOException("Could not open the file in Downloads.")
            out.use { it.write(bytes) }
            values.clear()
            values.put(MediaStore.MediaColumns.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
        } catch (e: Exception) {
            resolver.delete(uri, null, null)
            throw e
        }
        // MediaStore may have renamed it to avoid a clash with an earlier save.
        resolver.query(uri, arrayOf(MediaStore.MediaColumns.DISPLAY_NAME), null, null, null)
            ?.use { if (it.moveToFirst()) return it.getString(0) }
        return name
    }

    private companion object {
        const val DOWNLOADS_CHANNEL = "com.ardentnetworks.hris/downloads"
    }
}
