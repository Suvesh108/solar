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

    # 2. Create xml/file_paths.xml for FileProvider
    xml_dir = os.path.join(android_res, "xml")
    os.makedirs(xml_dir, exist_ok=True)
    file_paths_path = os.path.join(xml_dir, "file_paths.xml")
    file_paths_content = """<?xml version="1.0" encoding="utf-8"?>
<paths xmlns:android="http://schemas.android.com/apk/res/android">
    <cache-path name="cache" path="." />
    <external-cache-path name="external_cache" path="." />
    <files-path name="files" path="." />
</paths>
"""
    with open(file_paths_path, "w", encoding="utf-8") as f:
        f.write(file_paths_content)
    print("Created file_paths.xml for FileProvider.")

    # 3. Write enhanced MainActivity.kt with direct WhatsApp intent handler
    kotlin_dir = os.path.join(android_app_dir, "src", "main", "kotlin", "com", "sunward", "solar")
    os.makedirs(kotlin_dir, exist_ok=True)
    main_activity_path = os.path.join(kotlin_dir, "MainActivity.kt")
    main_activity_content = """package com.sunward.solar

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
"""
    with open(main_activity_path, "w", encoding="utf-8") as f:
        f.write(main_activity_content)
    print("Configured enhanced MainActivity.kt with WhatsApp image channel.")

    # 4. Inject permissions, queries, and FileProvider into AndroidManifest.xml
    manifest_path = os.path.join(android_app_dir, "src", "main", "AndroidManifest.xml")
    if os.path.exists(manifest_path):
        with open(manifest_path, "r", encoding="utf-8") as f:
            content = f.read()

        # Update app label to "Sunward"
        content = re.sub(r'android:label="[^"]*"', 'android:label="Sunward"', content)

        # Inject permissions if missing
        required_permissions = [
            '<uses-permission android:name="android.permission.INTERNET" />',
            '<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />',
            '<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />',
        ]
        for perm in required_permissions:
            perm_name = re.search(r'android:name="([^"]+)"', perm).group(1)
            if perm_name not in content:
                content = content.replace("<application", f"    {perm}\n    <application")

        # Queries block
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
            <action android:name="android.intent.action.SEND" />
            <data android:mimeType="image/png" />
        </intent>
        <package android:name="com.whatsapp" />
        <package android:name="com.whatsapp.w4b" />
    </queries>"""

        if "<queries>" in content:
            content = re.sub(r'<queries>.*?</queries>', queries_block, content, flags=re.DOTALL)
        else:
            content = content.replace("<application", queries_block + "\n    <application")

        # FileProvider injection inside <application>
        file_provider_tag = """        <provider
            android:name="androidx.core.content.FileProvider"
            android:authorities="${applicationId}.fileprovider"
            android:exported="false"
            android:grantUriPermissions="true">
            <meta-data
                android:name="android.support.FILE_PROVIDER_PATHS"
                android:resource="@xml/file_paths" />
        </provider>"""

        if "androidx.core.content.FileProvider" not in content:
            content = content.replace("</application>", f"{file_provider_tag}\n    </application>")

        with open(manifest_path, "w", encoding="utf-8") as f:
            f.write(content)
        print("Configured AndroidManifest.xml with permissions, queries, and FileProvider.")

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
        }
    }
"""
        if 'signingConfigs {' not in gradle_text:
            gradle_text = gradle_text.replace("android {", "android {" + signing_code)
            gradle_text = gradle_text.replace(
                'signingConfig = signingConfigs.getByName("debug")',
                'signingConfig = signingConfigs.getByName("release")'
            )
            with open(app_gradle_kts, "w", encoding="utf-8") as f:
                f.write(gradle_text)
            print("Configured release signing in build.gradle.kts.")

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
        }
    }
"""
        if 'signingConfigs {' not in gradle_text:
            gradle_text = gradle_text.replace("android {", "android {" + signing_code)
            gradle_text = gradle_text.replace(
                "signingConfig signingConfigs.debug",
                "signingConfig signingConfigs.release"
            )
            with open(app_gradle, "w", encoding="utf-8") as f:
                f.write(gradle_text)
            print("Configured release signing in build.gradle.")

if __name__ == "__main__":
    setup_android()
