package com.sunward.solar

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    private val UPDATER_CHANNEL = "com.sunward.updater"
    private val WHATSAPP_CHANNEL = "com.sunward.solar/whatsapp"
    private var appUpdater: AppUpdater? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Native Kotlin Updater Channel
        val updaterChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPDATER_CHANNEL)
        val updater = AppUpdater(this, updaterChannel)
        appUpdater = updater

        updaterChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkForUpdate" -> {
                    updater.checkForUpdate(result)
                }
                "downloadAndInstall" -> {
                    val downloadUrl = call.argument<String>("downloadUrl")
                    if (downloadUrl != null) {
                        updater.downloadAndInstall(downloadUrl, result)
                    } else {
                        result.error("INVALID_URL", "downloadUrl cannot be null", null)
                    }
                }
                "installApk" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        updater.installApk(File(filePath), result)
                    } else {
                        result.error("INVALID_PATH", "filePath cannot be null", null)
                    }
                }
                "canRequestPackageInstalls" -> {
                    result.success(updater.canRequestPackageInstalls())
                }
                "openInstallPermissionSettings" -> {
                    updater.openInstallPermissionSettings()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // 2. WhatsApp Image Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WHATSAPP_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "sendWhatsAppImage" -> {
                    val filePath = call.argument<String>("filePath")
                    val phone = call.argument<String>("phone") ?: ""
                    if (filePath == null) {
                        result.error("INVALID_PATH", "File path cannot be null", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val file = File(filePath)
                        if (!file.exists()) {
                            result.error("FILE_NOT_FOUND", "File does not exist: $filePath", null)
                            return@setMethodCallHandler
                        }

                        var cleanPhone = phone.replace(Regex("[^0-9]"), "")
                        if (cleanPhone.startsWith("0")) {
                            cleanPhone = cleanPhone.substring(1)
                        }
                        if (cleanPhone.length == 10) {
                            cleanPhone = "91" + cleanPhone
                        }

                        val contentUri: Uri = FileProvider.getUriForFile(
                            this,
                            "${applicationContext.packageName}.fileprovider",
                            file
                        )

                        val pm = packageManager
                        val isNormalWhatsApp = try {
                            pm.getPackageInfo("com.whatsapp", 0)
                            true
                        } catch (e: Exception) {
                            false
                        }
                        val isBusinessWhatsApp = try {
                            pm.getPackageInfo("com.whatsapp.w4b", 0)
                            true
                        } catch (e: Exception) {
                            false
                        }

                        val targetPackage = when {
                            isNormalWhatsApp -> "com.whatsapp"
                            isBusinessWhatsApp -> "com.whatsapp.w4b"
                            else -> null
                        }

                        val intent = Intent(Intent.ACTION_SEND).apply {
                            type = "image/png"
                            putExtra(Intent.EXTRA_STREAM, contentUri)
                            if (cleanPhone.isNotEmpty()) {
                                putExtra("jid", "$cleanPhone@s.whatsapp.net")
                            }
                            if (targetPackage != null) {
                                setPackage(targetPackage)
                            }
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }

                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SEND_ERROR", e.localizedMessage, null)
                    }
                }
                "installApk" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        appUpdater?.installApk(File(filePath), result)
                    } else {
                        result.error("INVALID_PATH", "Path is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
