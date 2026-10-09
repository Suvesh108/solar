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

    # 2. Inject permissions & queries into AndroidManifest.xml
    manifest_path = os.path.join(android_app_dir, "src", "main", "AndroidManifest.xml")
    if os.path.exists(manifest_path):
        with open(manifest_path, "r", encoding="utf-8") as f:
            content = f.read()

        # Update app label to "Sunward"
        content = re.sub(r'android:label="[^"]*"', 'android:label="Sunward"', content)

        # In-app update and internet permissions
        required_permissions = [
            '<uses-permission android:name="android.permission.INTERNET" />',
            '<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />',
        ]
        for perm in required_permissions:
            perm_name = re.search(r'android:name="([^"]+)"', perm).group(1)
            if perm_name not in content:
                content = content.replace("<application", f"    {perm}\n    <application")

        # Queries block for WhatsApp, tel, and web
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
            <data android:mimeType="*/*" />
        </intent>
        <package android:name="com.whatsapp" />
        <package android:name="com.whatsapp.w4b" />
    </queries>"""

        if "<queries>" in content:
            content = re.sub(r'<queries>.*?</queries>', queries_block, content, flags=re.DOTALL)
        else:
            content = content.replace("<application", queries_block + "\n    <application")

        with open(manifest_path, "w", encoding="utf-8") as f:
            f.write(content)
        print("Configured AndroidManifest.xml with permissions and queries.")

    # 3. Configure Signing in build.gradle.kts or build.gradle
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
