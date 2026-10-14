import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solar_app/services/app_update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppUpdateInfo formattedSize tests', () {
    const info1 = AppUpdateInfo(
      hasUpdate: true,
      currentVersion: '0.1.3',
      latestVersion: '0.1.4',
      downloadUrl: 'https://example.com/app.apk',
      size: 54245959,
      notes: 'New release',
    );
    expect(info1.formattedSize, equals('51.7 MB'));

    const info2 = AppUpdateInfo(
      hasUpdate: false,
      currentVersion: '0.1.4',
      latestVersion: '0.1.4',
      downloadUrl: '',
      size: 0,
      notes: '',
    );
    expect(info2.formattedSize, equals('55 MB'));
  });

  test('AppUpdateService.checkForUpdate handles native channel response', () async {
    const channel = MethodChannel('com.sunward.updater');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'checkForUpdate') {
        return {
          'hasUpdate': true,
          'currentVersion': '0.1.3',
          'latestVersion': '0.1.4',
          'downloadUrl': 'https://github.com/SuveshTheCoder/sunward-releases/releases/download/v0.1.4/Sunward.apk',
          'size': 54245959,
          'notes': 'Bug fixes and performance improvements',
        };
      }
      return null;
    });

    final updateInfo = await AppUpdateService.checkForUpdate();
    expect(updateInfo.hasUpdate, isTrue);
    expect(updateInfo.currentVersion, equals('0.1.3'));
    expect(updateInfo.latestVersion, equals('0.1.4'));
    expect(updateInfo.downloadUrl, contains('Sunward.apk'));
    expect(updateInfo.formattedSize, equals('51.7 MB'));
    expect(updateInfo.notes, contains('Bug fixes'));
  });
}
