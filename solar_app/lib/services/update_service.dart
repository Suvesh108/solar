import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class UpdateInfo {
  final String version;
  final String notes;
  final String apkUrl;
  final int apkSize;

  UpdateInfo({
    required this.version,
    required this.notes,
    required this.apkUrl,
    required this.apkSize,
  });
}

enum UpdateCheckStatus {
  updateAvailable,
  upToDate,
  error,
}

class UpdateCheckResult {
  final UpdateCheckStatus status;
  final UpdateInfo? update;
  final String currentVersion;
  final String? latestVersion;
  final String? errorMessage;

  UpdateCheckResult({
    required this.status,
    this.update,
    required this.currentVersion,
    this.latestVersion,
    this.errorMessage,
  });
}

class UpdateService {
  static const String currentVersion = 'v0.0.4';
  static const String _releasesListUrl = 'https://api.github.com/repos/Suvesh108/solar/releases';

  static Future<UpdateCheckResult> checkForUpdate() async {
    try {
      final response = await http.get(
        Uri.parse(_releasesListUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'SunwardSolarApp/$currentVersion',
        },
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          // GitHub returns releases array ordered descending by date; data[0] is latest
          for (final item in data) {
            final release = item as Map<String, dynamic>;
            final isDraft = release['draft'] as bool? ?? false;
            final isPrerelease = release['prerelease'] as bool? ?? false;
            if (isDraft || isPrerelease) continue;

            final latestTag = (release['tag_name'] as String? ?? '').trim();
            final body = release['body'] as String? ?? 'New version available with improvements.';
            final assets = release['assets'] as List<dynamic>? ?? [];

            String apkUrl = '';
            int apkSize = 0;

            for (final asset in assets) {
              final name = (asset['name'] as String? ?? '').toLowerCase();
              if (name.endsWith('.apk')) {
                apkUrl = asset['browser_download_url'] as String? ?? '';
                apkSize = asset['size'] as int? ?? 0;
                break;
              }
            }

            if (latestTag.isNotEmpty) {
              final isNewer = _isNewerVersion(latestTag, currentVersion);
              if (isNewer && apkUrl.isNotEmpty) {
                return UpdateCheckResult(
                  status: UpdateCheckStatus.updateAvailable,
                  update: UpdateInfo(
                    version: latestTag,
                    notes: body,
                    apkUrl: apkUrl,
                    apkSize: apkSize,
                  ),
                  currentVersion: currentVersion,
                  latestVersion: latestTag,
                );
              } else {
                return UpdateCheckResult(
                  status: UpdateCheckStatus.upToDate,
                  currentVersion: currentVersion,
                  latestVersion: latestTag,
                );
              }
            }
          }
        }

        return UpdateCheckResult(
          status: UpdateCheckStatus.upToDate,
          currentVersion: currentVersion,
        );
      } else {
        return UpdateCheckResult(
          status: UpdateCheckStatus.error,
          currentVersion: currentVersion,
          errorMessage: 'Server returned HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error checking for update: $e');
      return UpdateCheckResult(
        status: UpdateCheckStatus.error,
        currentVersion: currentVersion,
        errorMessage: e.toString(),
      );
    }
  }

  static bool _isNewerVersion(String latest, String current) {
    try {
      final cleanLatest = latest.replaceAll(RegExp(r'[^0-9.]'), '');
      final cleanCurrent = current.replaceAll(RegExp(r'[^0-9.]'), '');

      final latParts = cleanLatest.split('.').map(int.parse).toList();
      final curParts = cleanCurrent.split('.').map(int.parse).toList();

      for (int i = 0; i < latParts.length && i < curParts.length; i++) {
        if (latParts[i] > curParts[i]) return true;
        if (latParts[i] < curParts[i]) return false;
      }
      return latParts.length > curParts.length;
    } catch (_) {
      return latest.compareTo(current) > 0;
    }
  }

  static Future<File?> downloadAndInstallApk({
    required String apkUrl,
    required void Function(double progress) onProgress,
  }) async {
    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(apkUrl));
      request.headers['User-Agent'] = 'SunwardSolarApp/$currentVersion';
      request.followRedirects = true;

      final response = await client.send(request);

      if (response.statusCode != 200) return null;

      final totalBytes = response.contentLength ?? 0;
      final tempDir = await getTemporaryDirectory();
      final apkFile = File('${tempDir.path}/sunward-solar-update.apk');

      if (await apkFile.exists()) {
        await apkFile.delete();
      }

      final sink = apkFile.openWrite();
      int receivedBytes = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          onProgress(receivedBytes / totalBytes);
        }
      }

      await sink.flush();
      await sink.close();

      // Launch native package installer directly
      await OpenFilex.open(
        apkFile.path,
        type: 'application/vnd.android.package-archive',
      );

      return apkFile;
    } catch (e) {
      debugPrint('Error downloading update: $e');
      return null;
    }
  }
}
