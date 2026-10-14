import os
import shutil
import re

def setup_android():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    android_app_dir = os.path.join(base_dir, "android", "app")
    android_res = os.path.join(android_app_dir, "src", "main", "res")
    icons_src = os.path.join(base_dir, "assets", "icons")

    # 1. Copy mipmap icons
    if os.path.exists(icons_src) and os.path.exists(android_res):
        for item in os.listdir(icons_src):
            s_dir = os.path.join(icons_src, item)
            d_dir = os.path.join(android_res, item)
            if os.path.isdir(s_dir):
                os.makedirs(d_dir, exist_ok=True)
                for f in os.listdir(s_dir):
                    shutil.copy2(os.path.join(s_dir, f), os.path.join(d_dir, f))
        print("Copied custom app icons to Android res mipmap folders.")

    # 2. Ensure res/xml/file_paths.xml exists for FileProvider
    xml_dir = os.path.join(android_res, "xml")
    os.makedirs(xml_dir, exist_ok=True)
    file_paths_xml = os.path.join(xml_dir, "file_paths.xml")
    with open(file_paths_xml, "w", encoding="utf-8") as f:
        f.write("""<?xml version="1.0" encoding="utf-8"?>
<paths>
    <external-cache-path name="external_cache" path="." />
    <cache-path name="internal_cache" path="." />
    <files-path name="internal_files" path="." />
    <external-files-path name="external_files" path="." />
</paths>
""")
    print("Ensured file_paths.xml exists for FileProvider.")

    # 3. Inject permissions, queries, and FileProvider into AndroidManifest.xml
    manifest_path = os.path.join(android_app_dir, "src", "main", "AndroidManifest.xml")
    if os.path.exists(manifest_path):
        with open(manifest_path, "r", encoding="utf-8") as f:
            content = f.read()

        # Clean any dangerous/obsolete permissions
        content = re.sub(r'<uses-permission\s+android:name="android\.permission\.CALL_PHONE"[^>]*/>\s*', '', content)
        content = re.sub(r'<uses-permission\s+android:name="android\.permission\.READ_EXTERNAL_STORAGE"[^>]*/>\s*', '', content)
        content = re.sub(r'<uses-permission\s+android:name="android\.permission\.READ_MEDIA_[^"]*"[^>]*/>\s*', '', content)

        # Ensure essential permissions are ALWAYS present
        required_permissions = [
            '<uses-permission android:name="android.permission.INTERNET" />',
            '<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />',
            '<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />',
        ]
        for perm in required_permissions:
            perm_match = re.search(r'android:name="([^"]+)"', perm)
            if perm_match and perm_match.group(1) not in content:
                content = content.replace("<application", f"    {perm}\n    <application")

        queries_block = """    <queries>
        <intent>
            <action android:name="android.intent.action.DIAL" />
            <data android:scheme="tel" />
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="whatsapp" />
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:mimeType="application/vnd.android.package-archive" />
        </intent>
        <intent>
            <action android:name="android.intent.action.INSTALL_PACKAGE" />
            <data android:mimeType="application/vnd.android.package-archive" />
        </intent>
        <intent>
            <action android:name="android.intent.action.SEND" />
            <data android:mimeType="*/*" />
        </intent>
        <package android:name="com.whatsapp" />
        <package android:name="com.whatsapp.w4b" />
    </queries>"""

        if "<queries>" in content:
            content = re.sub(r'<queries>.*?</queries>', queries_block.strip(), content, flags=re.DOTALL)
        else:
            content = content.replace("<application", queries_block + "\n    <application")

        provider_block = """        <provider
            android:name="androidx.core.content.FileProvider"
            android:authorities="${applicationId}.fileprovider"
            android:exported="false"
            android:grantUriPermissions="true">
            <meta-data
                android:name="android.support.FILE_PROVIDER_PATHS"
                android:resource="@xml/file_paths" />
        </provider>"""

        if "androidx.core.content.FileProvider" not in content:
            content = content.replace("</application>", provider_block + "\n    </application>")

        with open(manifest_path, "w", encoding="utf-8") as f:
            f.write(content)
        print("Configured Sunward app label, permissions, queries, and FileProvider in AndroidManifest.xml.")

    # 4. Inject native MethodChannel into MainActivity.kt
    kotlin_root = os.path.join(android_app_dir, "src", "main", "kotlin")
    if os.path.exists(kotlin_root):
        for root, _, files in os.walk(kotlin_root):
            if "MainActivity.kt" in files:
                main_activity_file = os.path.join(root, "MainActivity.kt")
                with open(main_activity_file, "r", encoding="utf-8") as f:
                    lines = f.readlines()
                pkg_line = "package com.sunward.solar_app"
                for l in lines:
                    if l.strip().startswith("package "):
                        pkg_line = l.strip()
                        break

                updater_file = os.path.join(root, "AppUpdater.kt")
                updater_code = f"""{pkg_line}

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

class AppUpdater(private val activity: Activity, private val channel: MethodChannel) {{
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    private val REPO_OWNER = "Suvesh108"
    private val REPO_NAME = "solar"

    fun checkForUpdate(result: MethodChannel.Result) {{
        executor.execute {{
            try {{
                val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {{
                    activity.packageManager.getPackageInfo(activity.packageName, PackageManager.PackageInfoFlags.of(0))
                }} else {{
                    @Suppress("DEPRECATION")
                    activity.packageManager.getPackageInfo(activity.packageName, 0)
                }}
                val currentVersion = packageInfo.versionName ?: "0.1.5"

                val url = URL("https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/latest")
                val conn = (url.openConnection() as HttpURLConnection).apply {{
                    requestMethod = "GET"
                    setRequestProperty("Accept", "application/vnd.github.v3+json")
                    setRequestProperty("User-Agent", "SunwardSolar-AndroidApp")
                    connectTimeout = 10000
                    readTimeout = 10000
                }}

                if (conn.responseCode != 200) {{
                    mainHandler.post {{
                        result.error("HTTP_ERROR", "GitHub API returned ${{conn.responseCode}}", null)
                    }}
                    return@execute
                }}

                val responseText = conn.inputStream.bufferedReader().use {{ it.readText() }}
                val json = JSONObject(responseText)
                val tagName = json.optString("tag_name", "").trim()
                val notes = json.optString("body", "").trim()

                var downloadUrl = ""
                var apkSize = 0L

                val assets = json.optJSONArray("assets")
                if (assets != null) {{
                    for (i in 0 until assets.length()) {{
                        val asset = assets.getJSONObject(i)
                        val name = asset.optString("name", "").lowercase()
                        if (name.endsWith(".apk")) {{
                            downloadUrl = asset.optString("browser_download_url", "")
                            apkSize = asset.optLong("size", 0L)
                            break
                        }}
                    }}
                }}

                if (downloadUrl.isEmpty() && tagName.isNotEmpty()) {{
                    downloadUrl = "https://github.com/$REPO_OWNER/$REPO_NAME/releases/download/$tagName/Sunward.apk"
                }}

                val hasUpdate = isVersionNewer(tagName, currentVersion)

                val resultMap = hashMapOf<String, Any>(
                    "hasUpdate" to hasUpdate,
                    "currentVersion" to currentVersion,
                    "latestVersion" to tagName,
                    "downloadUrl" to downloadUrl,
                    "size" to apkSize,
                    "notes" to notes
                )

                mainHandler.post {{
                    result.success(resultMap)
                }}
            }} catch (e: Exception) {{
                mainHandler.post {{
                    result.error("CHECK_ERROR", e.localizedMessage ?: "Unknown check error", null)
                }}
            }}
        }}
    }}

    fun downloadAndInstall(downloadUrl: String, result: MethodChannel.Result) {{
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {{
            if (!activity.packageManager.canRequestPackageInstalls()) {{
                mainHandler.post {{
                    openInstallPermissionSettings()
                    result.error("PERMISSION_REQUIRED", "Please allow install permission and try again", null)
                }}
                return
            }}
        }}

        executor.execute {{
            try {{
                val cacheDir = activity.cacheDir
                val apkFile = File(cacheDir, "sunward_update.apk")
                if (apkFile.exists()) {{
                    apkFile.delete()
                }}

                var currentUrl = URL(downloadUrl)
                var activeConn = (currentUrl.openConnection() as HttpURLConnection).apply {{
                    requestMethod = "GET"
                    setRequestProperty("User-Agent", "SunwardSolar-AndroidApp")
                    instanceFollowRedirects = true
                    connectTimeout = 15000
                    readTimeout = 30000
                }}

                var responseCode = activeConn.responseCode
                var redirects = 0
                while ((responseCode == HttpURLConnection.HTTP_MOVED_PERM ||
                        responseCode == HttpURLConnection.HTTP_MOVED_TEMP ||
                        responseCode == 307 || responseCode == 308) && redirects < 5) {{
                    val newLocation = activeConn.getHeaderField("Location") ?: break
                    currentUrl = URL(currentUrl, newLocation)
                    activeConn = (currentUrl.openConnection() as HttpURLConnection).apply {{
                        requestMethod = "GET"
                        setRequestProperty("User-Agent", "SunwardSolar-AndroidApp")
                        connectTimeout = 15000
                        readTimeout = 30000
                    }}
                    responseCode = activeConn.responseCode
                    redirects++
                }}

                if (responseCode != 200) {{
                    mainHandler.post {{
                        result.error("DOWNLOAD_ERROR", "HTTP status $responseCode", null)
                    }}
                    return@execute
                }}

                val totalBytes = activeConn.contentLength.toLong()
                var receivedBytes = 0L

                BufferedInputStream(activeConn.inputStream).use {{ input ->
                    FileOutputStream(apkFile).use {{ output ->
                        val buffer = ByteArray(8192)
                        var read: Int
                        var lastProgressTime = 0L

                        while (input.read(buffer).also {{ read = it }} != -1) {{
                            output.write(buffer, 0, read)
                            receivedBytes += read

                            val now = System.currentTimeMillis()
                            if (now - lastProgressTime > 100 || receivedBytes == totalBytes) {{
                                lastProgressTime = now
                                val progress = if (totalBytes > 0) receivedBytes.toDouble() / totalBytes else 0.0
                                mainHandler.post {{
                                    channel.invokeMethod("onDownloadProgress", mapOf(
                                        "progress" to progress,
                                        "received" to receivedBytes,
                                        "total" to totalBytes
                                    ))
                                }}
                            }}
                        }}
                        output.flush()
                    }}
                }}

                mainHandler.post {{
                    installApk(apkFile, result)
                }}
            }} catch (e: Exception) {{
                mainHandler.post {{
                    result.error("DOWNLOAD_ERROR", e.localizedMessage ?: "Download failed", null)
                }}
            }}
        }}
    }}

    fun installApk(file: File, result: MethodChannel.Result) {{
        try {{
            if (!file.exists()) {{
                result.error("FILE_NOT_FOUND", "File not found: ${{file.absolutePath}}", null)
                return
            }}

            val context = activity.applicationContext
            val uri: Uri = FileProvider.getUriForFile(
                context,
                "${{context.packageName}}.fileprovider",
                file
            )

            val intent = Intent(Intent.ACTION_VIEW).apply {{
                setDataAndType(uri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                putExtra(Intent.EXTRA_NOT_UNKNOWN_SOURCE, true)
            }}

            val resInfoList = context.packageManager.queryIntentActivities(
                intent,
                PackageManager.MATCH_DEFAULT_ONLY
            )
            for (resolveInfo in resInfoList) {{
                val pkg = resolveInfo.activityInfo.packageName
                context.grantUriPermission(pkg, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }}

            activity.startActivity(intent)
            result.success(true)
        }} catch (e: Exception) {{
            result.error("INSTALL_ERROR", e.localizedMessage ?: "Installation failed", null)
        }}
    }}

    fun canRequestPackageInstalls(): Boolean {{
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {{
            activity.packageManager.canRequestPackageInstalls()
        }} else {{
            true
        }}
    }}

    fun openInstallPermissionSettings() {{
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {{
            val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {{
                data = Uri.parse("package:${{activity.packageName}}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }}
            activity.startActivity(intent)
        }}
    }}

    private fun isVersionNewer(latest: String, current: String): Boolean {{
        if (latest.isEmpty()) return false
        val l = latest.replace(Regex("[^0-9.]"), "").split(".").mapNotNull {{ it.toIntOrNull() }}
        val c = current.replace(Regex("[^0-9.]"), "").split(".").mapNotNull {{ it.toIntOrNull() }}
        val maxLen = maxOf(l.size, c.size)
        for (i in 0 until maxLen) {{
            val lVal = if (i < l.size) l[i] else 0
            val cVal = if (i < c.size) c[i] else 0
            if (lVal > cVal) return true
            if (lVal < cVal) return false
        }}
        return false
    }}
}}
"""
                with open(updater_file, "w", encoding="utf-8") as f:
                    f.write(updater_code)
                print(f"Configured native AppUpdater.kt at {updater_file}")

                kotlin_code = f"""{pkg_line}

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {{
    private val UPDATER_CHANNEL = "com.sunward.updater"
    private val WHATSAPP_CHANNEL = "com.sunward.solar/whatsapp"
    private var appUpdater: AppUpdater? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {{
        super.configureFlutterEngine(flutterEngine)

        // 1. Native Kotlin Updater Channel
        val updaterChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPDATER_CHANNEL)
        val updater = AppUpdater(this, updaterChannel)
        appUpdater = updater

        updaterChannel.setMethodCallHandler {{ call, result ->
            when (call.method) {{
                "checkForUpdate" -> {{
                    updater.checkForUpdate(result)
                }}
                "downloadAndInstall" -> {{
                    val downloadUrl = call.argument<String>("downloadUrl")
                    if (downloadUrl != null) {{
                        updater.downloadAndInstall(downloadUrl, result)
                    }} else {{
                        result.error("INVALID_URL", "downloadUrl cannot be null", null)
                    }}
                }}
                "installApk" -> {{
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {{
                        updater.installApk(File(filePath), result)
                    }} else {{
                        result.error("INVALID_PATH", "filePath cannot be null", null)
                    }}
                }}
                "canRequestPackageInstalls" -> {{
                    result.success(updater.canRequestPackageInstalls())
                }}
                "openInstallPermissionSettings" -> {{
                    updater.openInstallPermissionSettings()
                    result.success(true)
                }}
                else -> result.notImplemented()
            }}
        }}

        // 2. WhatsApp Image Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WHATSAPP_CHANNEL).setMethodCallHandler {{ call, result ->
            when (call.method) {{
                "sendWhatsAppImage" -> {{
                    val filePath = call.argument<String>("filePath")
                    val phone = call.argument<String>("phone") ?: ""
                    if (filePath == null) {{
                        result.error("INVALID_PATH", "File path cannot be null", null)
                        return@setMethodCallHandler
                    }}

                    try {{
                        val file = File(filePath)
                        if (!file.exists()) {{
                            result.error("FILE_NOT_FOUND", "File does not exist: $filePath", null)
                            return@setMethodCallHandler
                        }}

                        var cleanPhone = phone.replace(Regex("[^0-9]"), "")
                        if (cleanPhone.startsWith("0")) {{
                            cleanPhone = cleanPhone.substring(1)
                        }}
                        if (cleanPhone.length == 10) {{
                            cleanPhone = "91" + cleanPhone
                        }}

                        val contentUri: Uri = FileProvider.getUriForFile(
                            this,
                            "${{applicationContext.packageName}}.fileprovider",
                            file
                        )

                        val pm = packageManager
                        val isNormalWhatsApp = try {{
                            pm.getPackageInfo("com.whatsapp", 0)
                            true
                        }} catch (e: Exception) {{
                            false
                        }}
                        val isBusinessWhatsApp = try {{
                            pm.getPackageInfo("com.whatsapp.w4b", 0)
                            true
                        }} catch (e: Exception) {{
                            false
                        }}

                        val targetPackage = when {{
                            isNormalWhatsApp -> "com.whatsapp"
                            isBusinessWhatsApp -> "com.whatsapp.w4b"
                            else -> null
                        }}

                        val intent = Intent(Intent.ACTION_SEND).apply {{
                            type = "image/png"
                            putExtra(Intent.EXTRA_STREAM, contentUri)
                            if (cleanPhone.isNotEmpty()) {{
                                putExtra("jid", "$cleanPhone@s.whatsapp.net")
                            }}
                            if (targetPackage != null) {{
                                setPackage(targetPackage)
                            }}
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }}

                        startActivity(intent)
                        result.success(true)
                    }} catch (e: Exception) {{
                        result.error("SEND_ERROR", e.localizedMessage, null)
                    }}
                }}
                "installApk" -> {{
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {{
                        appUpdater?.installApk(File(filePath), result)
                    }} else {{
                        result.error("INVALID_PATH", "Path is null", null)
                    }}
                }}
                else -> result.notImplemented()
            }}
        }}
    }}
}}
"""
                with open(main_activity_file, "w", encoding="utf-8") as f:
                    f.write(kotlin_code)
                print(f"Configured MainActivity.kt with Kotlin-powered AppUpdater at {main_activity_file}")
                break

    # 5. Configure Signing in build.gradle.kts or build.gradle
    app_gradle_kts = os.path.join(android_app_dir, "build.gradle.kts")
    app_gradle = os.path.join(android_app_dir, "build.gradle")

    keystore_src = os.path.join(base_dir, "sunward-release.jks")
    keystore_dest = os.path.join(android_app_dir, "sunward-release.jks")
    if os.path.exists(keystore_src):
        shutil.copy2(keystore_src, keystore_dest)
        print("Copied sunward-release.jks into android/app/")

    if os.path.exists(app_gradle_kts):
        with open(app_gradle_kts, "r", encoding="utf-8") as f:
            gradle_text = f.read()

        signing_code = """
    signingConfigs {
        create("release") {
            keyAlias = "sunward_key"
            keyPassword = "sunward123456"
            storeFile = file("sunward-release.jks")
            storePassword = "sunward123456"
            enableV1Signing = true
            enableV2Signing = true
            enableV3Signing = true
            enableV4Signing = true
        }
    }
"""
        if 'signingConfigs {' not in gradle_text:
            gradle_text = re.sub(r'(android\s*\{)', r'\1' + signing_code, gradle_text, count=1)
        gradle_text = re.sub(
            r'buildTypes\s*\{\s*release\s*\{[^}]*\}',
            'buildTypes {\n        release {\n            signingConfig = signingConfigs.getByName("release")\n            isMinifyEnabled = false\n            isShrinkResources = false\n        }',
            gradle_text
        )
        with open(app_gradle_kts, "w", encoding="utf-8") as f:
            f.write(gradle_text)
        print("Configured release signing and build types in build.gradle.kts.")

    elif os.path.exists(app_gradle):
        with open(app_gradle, "r", encoding="utf-8") as f:
            gradle_text = f.read()

        signing_code = """
    signingConfigs {
        release {
            keyAlias 'sunward_key'
            keyPassword 'sunward123456'
            storeFile file('sunward-release.jks')
            storePassword 'sunward123456'
            v1SigningEnabled true
            v2SigningEnabled true
            v3SigningEnabled true
            v4SigningEnabled true
        }
    }
"""
        if 'signingConfigs {' not in gradle_text:
            gradle_text = re.sub(r'(android\s*\{)', r'\1' + signing_code, gradle_text, count=1)
        gradle_text = re.sub(
            r'buildTypes\s*\{\s*release\s*\{[^}]*\}',
            'buildTypes {\n        release {\n            signingConfig signingConfigs.release\n            minifyEnabled false\n            shrinkResources false\n        }',
            gradle_text
        )
        with open(app_gradle, "w", encoding="utf-8") as f:
            f.write(gradle_text)
        print("Configured release signing and build types in build.gradle.")

if __name__ == "__main__":
    setup_android()
