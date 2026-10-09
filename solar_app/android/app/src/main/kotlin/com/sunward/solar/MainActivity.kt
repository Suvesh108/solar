package com.sunward.solar

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.sunward.solar/whatsapp"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "sendImageToWhatsApp") {
                val filePath = call.argument<String>("filePath")
                val rawPhone = call.argument<String>("phone") ?: ""

                if (filePath == null) {
                    result.error("INVALID_PATH", "File path is null", null)
                    return@setMethodCallHandler
                }

                try {
                    val file = File(filePath)
                    if (!file.exists()) {
                        result.error("FILE_NOT_FOUND", "File does not exist: $filePath", null)
                        return@setMethodCallHandler
                    }

                    // Clean phone number to WhatsApp international format (e.g. 919731001477)
                    var cleanPhone = rawPhone.replace(Regex("[^0-9]"), "")
                    if (cleanPhone.startsWith("0")) {
                        cleanPhone = cleanPhone.substring(1)
                    }
                    if (cleanPhone.length == 10) {
                        cleanPhone = "91" + cleanPhone
                    }

                    val uri: Uri = FileProvider.getUriForFile(
                        this,
                        "${applicationContext.packageName}.fileprovider",
                        file
                    )

                    val intent = Intent(Intent.ACTION_SEND).apply {
                        type = "image/png"
                        putExtra(Intent.EXTRA_STREAM, uri)
                        if (cleanPhone.isNotEmpty()) {
                            putExtra("jid", "$cleanPhone@s.whatsapp.net")
                        }
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }

                    val pm = packageManager
                    val hasWhatsApp = try { pm.getPackageInfo("com.whatsapp", 0); true } catch (e: Exception) { false }
                    val hasWhatsAppBusiness = try { pm.getPackageInfo("com.whatsapp.w4b", 0); true } catch (e: Exception) { false }

                    if (hasWhatsApp) {
                        intent.setPackage("com.whatsapp")
                    } else if (hasWhatsAppBusiness) {
                        intent.setPackage("com.whatsapp.w4b")
                    }

                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("INTENT_ERROR", e.localizedMessage, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
