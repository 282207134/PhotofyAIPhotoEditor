package com.photofy.photofy

import android.app.Activity
import android.content.ContentValues
import android.content.Intent
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private var photoResult: MethodChannel.Result? = null
    private val photoRequest = 101

    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        val preferences = getSharedPreferences("photofy", MODE_PRIVATE)
        MethodChannel(engine.dartExecutor.binaryMessenger, "photofy/device").setMethodCallHandler { call, result ->
            when (call.method) {
                "readTheme" -> result.success(preferences.getBoolean("dark", false))
                "theme" -> {
                    preferences.edit().putBoolean("dark", call.arguments == true).apply()
                    result.success(null)
                }
                "pick" -> {
                    if (photoResult != null) {
                        result.error("busy", "A photo picker is already open.", null)
                        return@setMethodCallHandler
                    }
                    val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                        type = "image/*"
                        addCategory(Intent.CATEGORY_OPENABLE)
                        putExtra(Intent.EXTRA_ALLOW_MULTIPLE, call.arguments == true)
                    }
                    try {
                        photoResult = result
                        startActivityForResult(intent, photoRequest)
                    } catch (error: Exception) {
                        photoResult = null
                        result.error("picker", error.message, null)
                    }
                }
                "save" -> {
                    val bytes = call.arguments as ByteArray
                    Thread {
                        try {
                            val destination = saveImage(bytes)
                            runOnUiThread { result.success(destination) }
                        } catch (error: Exception) {
                            runOnUiThread { result.error("write", error.message, null) }
                        }
                    }.start()
                }
                "share" -> {
                    val uri = android.net.Uri.parse(call.arguments as String)
                    if (uri.scheme == "content") {
                        startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).apply {
                            type = "image/png"
                            putExtra(Intent.EXTRA_STREAM, uri)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }, null))
                        result.success(null)
                    } else {
                        result.error("share", "Sharing through the system requires Android 10 or newer.", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    @Deprecated("Activity result bridge for FlutterActivity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != photoRequest) return
        val result = photoResult ?: return
        photoResult = null
        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(emptyList<String>())
            return
        }
        val clips = data.clipData
        val uris = if (clips != null) {
            (0 until minOf(clips.itemCount, 10)).map { clips.getItemAt(it).uri }
        } else listOfNotNull(data.data)
        Thread {
            val created = mutableListOf<File>()
            try {
                for (uri in uris) {
                    val image = File.createTempFile("pick_", ".image", cacheDir)
                    created.add(image)
                    contentResolver.openInputStream(uri)?.use { source ->
                        image.outputStream().use { source.copyTo(it) }
                    } ?: error("Unable to open the selected photo.")
                }
                runOnUiThread { result.success(created.map { it.absolutePath }) }
            } catch (error: Exception) {
                created.forEach { it.delete() }
                runOnUiThread { result.error("read", error.message, null) }
            }
        }.start()
    }

    private fun saveImage(bytes: ByteArray): String {
        val name = "Photofy_${System.currentTimeMillis()}.png"
        if (Build.VERSION.SDK_INT < 29) {
            val folder = getExternalFilesDir(Environment.DIRECTORY_PICTURES) ?: filesDir
            return File(folder, name).also { it.writeBytes(bytes) }.absolutePath
        }
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, name)
            put(MediaStore.Images.Media.MIME_TYPE, "image/png")
            put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/Photofy")
            put(MediaStore.Images.Media.IS_PENDING, 1)
        }
        val uri = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
            ?: error("Unable to create the image.")
        try {
            contentResolver.openOutputStream(uri)?.use { it.write(bytes) }
                ?: error("Unable to write the image.")
            values.clear()
            values.put(MediaStore.Images.Media.IS_PENDING, 0)
            contentResolver.update(uri, values, null, null)
            return uri.toString()
        } catch (error: Exception) {
            contentResolver.delete(uri, null, null)
            throw error
        }
    }
}
