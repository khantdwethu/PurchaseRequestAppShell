package com.sunfix.purchase_request_app_shell

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.webkit.MimeTypeMap
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private companion object {
        const val FILE_PICKER_REQUEST_CODE = 41021
    }

    private var pendingFilePickerResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "purchase_request_app_shell/file_selector"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickFiles" -> launchFilePicker(call, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun launchFilePicker(call: MethodCall, result: MethodChannel.Result) {
        if (pendingFilePickerResult != null) {
            result.error("file_selection_active", "A file selection request is already active.", null)
            return
        }

        val allowMultiple = call.argument<Boolean>("allowMultiple") ?: false
        val allowedExtensions = call.argument<List<String>>("allowedExtensions").orEmpty()
        val mimeTypes = buildMimeTypes(allowedExtensions)

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = if (mimeTypes.size == 1) mimeTypes.first() else "*/*"
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, allowMultiple)
            if (mimeTypes.isNotEmpty() && !(mimeTypes.size == 1 && mimeTypes.first() == "*/*")) {
                putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes.toTypedArray())
            }
        }

        pendingFilePickerResult = result
        startActivityForResult(intent, FILE_PICKER_REQUEST_CODE)
    }

    @Deprecated("Uses the Android activity result callback required by FlutterActivity.")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode != FILE_PICKER_REQUEST_CODE) {
            return
        }

        val result = pendingFilePickerResult ?: return
        pendingFilePickerResult = null

        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(emptyList<String>())
            return
        }

        try {
            result.success(readSelectedUris(data))
        } catch (error: Exception) {
            result.error("file_selection_failed", error.message, null)
        }
    }

    private fun readSelectedUris(data: Intent): List<String> {
        val uris = mutableListOf<String>()

        data.clipData?.let { clipData ->
            for (index in 0 until clipData.itemCount) {
                clipData.getItemAt(index)?.uri?.let { uri ->
                    persistReadPermission(uri, data.flags)
                    uris += uri.toString()
                }
            }
        }

        if (uris.isEmpty()) {
            data.data?.let { uri ->
                persistReadPermission(uri, data.flags)
                uris += uri.toString()
            }
        }

        return uris
    }

    private fun persistReadPermission(uri: Uri, flags: Int) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.KITKAT) {
            return
        }

        val readFlags = flags and Intent.FLAG_GRANT_READ_URI_PERMISSION
        if (readFlags == 0) {
            return
        }

        try {
            contentResolver.takePersistableUriPermission(uri, readFlags)
        } catch (_: SecurityException) {
        }
    }

    private fun buildMimeTypes(extensions: List<String>): List<String> {
        if (extensions.isEmpty()) {
            return listOf("*/*")
        }

        val mimeTypes = linkedSetOf<String>()
        for (rawExtension in extensions) {
            val extension = rawExtension.trim().lowercase()
            if (extension.isEmpty()) {
                continue
            }

            val mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension)
            if (mimeType != null) {
                mimeTypes += mimeType
            }

            if (extension == "csv") {
                mimeTypes += "text/csv"
            }
        }

        return if (mimeTypes.isEmpty()) listOf("*/*") else mimeTypes.toList()
    }
}
