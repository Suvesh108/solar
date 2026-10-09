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
<paths xmlns:android="http://schemas.android.com/apk/res/android">
    <cache-path name="cache" path="." />
    <external-cache-path name="external_cache" path="." />
    <files-path name="files" path="." />
</paths>
""")
    print("Ensured file_paths.xml exists for FileProvider.")

    # 3. Inject permissions, queries, and FileProvider into AndroidManifest.xml
    manifest_path = os.path.join(android_app_dir, "src", "main", "AndroidManifest.xml")
    if os.path.exists(manifest_path):
        with open(manifest_path, "r", encoding="utf-8") as f:
            content = f.read()

        permissions = """
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.CALL_PHONE"/>
    <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>
    <queries>
        <intent>
            <action android:name="android.intent.action.DIAL"/>
            <data android:scheme="tel"/>
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW"/>
            <data android:scheme="https"/>
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW"/>
            <data android:scheme="whatsapp"/>
        </intent>
        <intent>
            <action android:name="android.intent.action.SEND"/>
            <data android:mimeType="*/*"/>
        </intent>
        <package android:name="com.whatsapp" />
        <package android:name="com.whatsapp.w4b" />
    </queries>
"""
        content = re.sub(r'android:label="[^"]*"', 'android:label="Sunward"', content)
        if "<queries>" not in content:
            content = content.replace("<application", permissions + "\n    <application")

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

    # 4. Inject native MethodChannel into MainActivity.kt (WhatsApp direct JID dispatch)
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

                kotlin_code = f"""{pkg_line}

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {{
    private val CHANNEL = "com.sunward.solar/whatsapp"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {{
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {{ call, result ->
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

                        val contentUri = FileProvider.getUriForFile(
                            this,
                            "${{applicationContext.packageName}}.fileprovider",
                            file
                        )

                        val intent = Intent(Intent.ACTION_VIEW).apply {{
                            setDataAndType(contentUri, "application/vnd.android.package-archive")
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }}

                        startActivity(intent)
                        result.success(true)
                    }} catch (e: Exception) {{
                        result.error("INSTALL_ERROR", e.localizedMessage, null)
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
                print(f"Configured MainActivity.kt with WhatsApp MethodChannel at {main_activity_file}")
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
