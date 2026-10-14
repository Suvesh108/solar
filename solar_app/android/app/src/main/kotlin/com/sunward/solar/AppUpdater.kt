package com.sunward.solar

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.BufferedInputStream
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

class AppUpdater(private val activity: Activity, private val channel: MethodChannel) {
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    private val REPO_OWNER = "Suvesh108"
    private val REPO_NAME = "solar"

    fun checkForUpdate(result: MethodChannel.Result) {
        executor.execute {
            try {
                val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    activity.packageManager.getPackageInfo(activity.packageName, PackageManager.PackageInfoFlags.of(0))
                } else {
                    @Suppress("DEPRECATION")
                    activity.packageManager.getPackageInfo(activity.packageName, 0)
                }
                val currentVersion = packageInfo.versionName ?: "0.1.4"

                val url = URL("https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/latest")
                val conn = (url.openConnection() as HttpURLConnection).apply {
                    requestMethod = "GET"
                    setRequestProperty("Accept", "application/vnd.github.v3+json")
                    setRequestProperty("User-Agent", "SunwardSolar-AndroidApp")
                    connectTimeout = 10000
                    readTimeout = 10000
                }

                if (conn.responseCode != 200) {
                    mainHandler.post {
                        result.error("HTTP_ERROR", "GitHub API returned ${conn.responseCode}", null)
                    }
                    return@execute
                }

                val responseText = conn.inputStream.bufferedReader().use { it.readText() }
                val json = JSONObject(responseText)
                val tagName = json.optString("tag_name", "").trim()
                val notes = json.optString("body", "").trim()

                var downloadUrl = ""
                var apkSize = 0L

                val assets = json.optJSONArray("assets")
                if (assets != null) {
                    for (i in 0 until assets.length()) {
                        val asset = assets.getJSONObject(i)
                        val name = asset.optString("name", "").lowercase()
                        if (name.endsWith(".apk")) {
                            downloadUrl = asset.optString("browser_download_url", "")
                            apkSize = asset.optLong("size", 0L)
                            break
                        }
                    }
                }

                if (downloadUrl.isEmpty() && tagName.isNotEmpty()) {
                    downloadUrl = "https://github.com/$REPO_OWNER/$REPO_NAME/releases/download/$tagName/Sunward.apk"
                }

                val hasUpdate = isVersionNewer(tagName, currentVersion)

                val resultMap = hashMapOf<String, Any>(
                    "hasUpdate" to hasUpdate,
                    "currentVersion" to currentVersion,
                    "latestVersion" to tagName,
                    "downloadUrl" to downloadUrl,
                    "size" to apkSize,
                    "notes" to notes
                )

                mainHandler.post {
                    result.success(resultMap)
                }
            } catch (e: Exception) {
                mainHandler.post {
                    result.error("CHECK_ERROR", e.localizedMessage ?: "Unknown check error", null)
                }
            }
        }
    }

    fun downloadAndInstall(downloadUrl: String, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (!activity.packageManager.canRequestPackageInstalls()) {
                mainHandler.post {
                    openInstallPermissionSettings()
                    result.error("PERMISSION_REQUIRED", "Please allow install permission and try again", null)
                }
                return
            }
        }

        executor.execute {
            try {
                val cacheDir = activity.cacheDir
                val apkFile = File(cacheDir, "sunward_update.apk")
                if (apkFile.exists()) {
                    apkFile.delete()
                }

                var currentUrl = URL(downloadUrl)
                var activeConn = (currentUrl.openConnection() as HttpURLConnection).apply {
                    requestMethod = "GET"
                    setRequestProperty("User-Agent", "SunwardSolar-AndroidApp")
                    instanceFollowRedirects = true
                    connectTimeout = 15000
                    readTimeout = 30000
                }

                var responseCode = activeConn.responseCode
                var redirects = 0
                while ((responseCode == HttpURLConnection.HTTP_MOVED_PERM ||
                        responseCode == HttpURLConnection.HTTP_MOVED_TEMP ||
                        responseCode == 307 || responseCode == 308) && redirects < 5) {
                    val newLocation = activeConn.getHeaderField("Location") ?: break
                    currentUrl = URL(currentUrl, newLocation)
                    activeConn = (currentUrl.openConnection() as HttpURLConnection).apply {
                        requestMethod = "GET"
                        setRequestProperty("User-Agent", "SunwardSolar-AndroidApp")
                        connectTimeout = 15000
                        readTimeout = 30000
                    }
                    responseCode = activeConn.responseCode
                    redirects++
                }

                if (responseCode != 200) {
                    mainHandler.post {
                        result.error("DOWNLOAD_ERROR", "HTTP status $responseCode", null)
                    }
                    return@execute
                }

                val totalBytes = activeConn.contentLength.toLong()
                var receivedBytes = 0L

                BufferedInputStream(activeConn.inputStream).use { input ->
                    FileOutputStream(apkFile).use { output ->
                        val buffer = ByteArray(8192)
                        var read: Int
                        var lastProgressTime = 0L

                        while (input.read(buffer).also { read = it } != -1) {
                            output.write(buffer, 0, read)
                            receivedBytes += read

                            val now = System.currentTimeMillis()
                            if (now - lastProgressTime > 100 || receivedBytes == totalBytes) {
                                lastProgressTime = now
                                val progress = if (totalBytes > 0) receivedBytes.toDouble() / totalBytes else 0.0
                                mainHandler.post {
                                    channel.invokeMethod("onDownloadProgress", mapOf(
                                        "progress" to progress,
                                        "received" to receivedBytes,
                                        "total" to totalBytes
                                    ))
                                }
                            }
                        }
                        output.flush()
                    }
                }

                mainHandler.post {
                    installApk(apkFile, result)
                }
            } catch (e: Exception) {
                mainHandler.post {
                    result.error("DOWNLOAD_ERROR", e.localizedMessage ?: "Download failed", null)
                }
            }
        }
    }

    fun installApk(file: File, result: MethodChannel.Result) {
        try {
            if (!file.exists()) {
                result.error("FILE_NOT_FOUND", "File not found: ${file.absolutePath}", null)
                return
            }

            val context = activity.applicationContext
            val uri: Uri = FileProvider.getUriForFile(
                context,
                "${context.packageName}.fileprovider",
                file
            )

            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                putExtra(Intent.EXTRA_NOT_UNKNOWN_SOURCE, true)
            }

            val resInfoList = context.packageManager.queryIntentActivities(
                intent,
                PackageManager.MATCH_DEFAULT_ONLY
            )
            for (resolveInfo in resInfoList) {
                val pkg = resolveInfo.activityInfo.packageName
                context.grantUriPermission(pkg, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }

            activity.startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("INSTALL_ERROR", e.localizedMessage ?: "Installation failed", null)
        }
    }

    fun canRequestPackageInstalls(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            activity.packageManager.canRequestPackageInstalls()
        } else {
            true
        }
    }

    fun openInstallPermissionSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                data = Uri.parse("package:${activity.packageName}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            activity.startActivity(intent)
        }
    }

    private fun isVersionNewer(latest: String, current: String): Boolean {
        if (latest.isEmpty()) return false
        val l = latest.replace(Regex("[^0-9.]"), "").split(".").mapNotNull { it.toIntOrNull() }
        val c = current.replace(Regex("[^0-9.]"), "").split(".").mapNotNull { it.toIntOrNull() }
        val maxLen = maxOf(l.size, c.size)
        for (i in 0 until maxLen) {
            val lVal = if (i < l.size) l[i] else 0
            val cVal = if (i < c.size) c[i] else 0
            if (lVal > cVal) return true
            if (lVal < cVal) return false
        }
        return false
    }
}
