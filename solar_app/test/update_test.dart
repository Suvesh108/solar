import 'package:flutter_test/flutter_test.dart';
import 'package:solar_app/services/app_update_service.dart';

void main() {
  test('AppUpdateService.checkForUpdate connects and parses latest release', () async {
    final result = await AppUpdateService.checkForUpdate();
    expect(result.status, isNot(AppUpdateStatus.error));
    expect(result.release, isNotNull);
    expect(result.release!.version, equals('v0.0.9'));
    expect(result.release!.apkDownloadUrl, contains('Sunward.apk'));
    expect(result.release!.formattedSize, isNotEmpty);
  });

  test('isVersionNewer logic tests', () {
    expect(AppUpdateService.isVersionNewer('v0.1.0', 'v0.0.9'), isTrue);
    expect(AppUpdateService.isVersionNewer('v0.0.10', 'v0.0.9'), isTrue);
    expect(AppUpdateService.isVersionNewer('v1.0.0', 'v0.0.9'), isTrue);
    expect(AppUpdateService.isVersionNewer('v0.0.9', 'v0.0.9'), isFalse);
    expect(AppUpdateService.isVersionNewer('v0.0.8', 'v0.0.9'), isFalse);
  });

  test('AppReleaseInfo formattedSize tests', () {
    const info1 = AppReleaseInfo(
      version: 'v0.0.9',
      title: 'v0.0.9',
      notes: 'Notes',
      apkDownloadUrl: 'https://example.com/app.apk',
      apkSizeBytes: 54245959,
      releasePageUrl: 'https://example.com',
    );
    expect(info1.formattedSize, equals('51.7 MB'));

    const info2 = AppReleaseInfo(
      version: 'v0.0.9',
      title: 'v0.0.9',
      notes: 'Notes',
      apkDownloadUrl: 'https://example.com/app.apk',
      apkSizeBytes: 0,
      releasePageUrl: 'https://example.com',
    );
    expect(info2.formattedSize, equals('51.7 MB'));
  });
}
