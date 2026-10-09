import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final String? manualDownloadUrl;

  UpdateCheckResult({
    required this.status,
    this.update,
    required this.currentVersion,
    this.latestVersion,
    this.errorMessage,
    this.manualDownloadUrl,
  });
}

class UpdateService {
  static const String currentVersion = 'v0.0.6';
  static const String latestDirectApkUrl = 'https://github.com/Suvesh108/solar/releases/latest/download/Sunward.apk';

  // Multi-tier endpoints to guarantee connectivity even on networks with DNS blocks on api.github.com
  static const List<String> _versionEndpoints = [
    // Tier 1: Fast CDN with Indian edge servers (Mumbai, Delhi) - never blocked on Jio/Airtel
    'https://cdn.jsdelivr.net/gh/Suvesh108/solar@main/version.json',
    // Tier 2: GitHub Raw JSON
    'https://raw.githubusercontent.com/Suvesh108/solar/main/version.json',
    // Tier 3: Official GitHub Releases API
    'https://api.github.com/repos/Suvesh108/solar/releases',
  ];

  static Future<UpdateCheckResult> checkForUpdate() async {
    String lastError = '';

    for (final endpoint in _versionEndpoints) {
      try {
        final response = await http.get(
          Uri.parse(endpoint),
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'SunwardSolarApp/$currentVersion',
          },
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final dynamic data = jsonDecode(response.body);

          // Handle version.json schema
          if (data is Map<String, dynamic> && data.containsKey('version')) {
            final latestTag = (data['version'] as String? ?? '').trim();
            final notes = data['notes'] as String? ?? 'New version available with improvements.';
            final apkUrl = data['apkUrl'] as String? ?? latestDirectApkUrl;
            final apkSize = data['apkSize'] as int? ?? 0;

            if (latestTag.isNotEmpty) {
              final isNewer = _isNewerVersion(latestTag, currentVersion);
              if (isNewer) {
                return UpdateCheckResult(
                  status: UpdateCheckStatus.updateAvailable,
                  update: UpdateInfo(
                    version: latestTag,
                    notes: notes,
                    apkUrl: apkUrl,
                    apkSize: apkSize,
                  ),
                  currentVersion: currentVersion,
                  latestVersion: latestTag,
                  manualDownloadUrl: apkUrl,
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

          // Handle GitHub Releases list schema
          if (data is List && data.isNotEmpty) {
            for (final item in data) {
              final release = item as Map<String, dynamic>;
              final isDraft = release['draft'] as bool? ?? false;
              final isPrerelease = release['prerelease'] as bool? ?? false;
              if (isDraft || isPrerelease) continue;

              final latestTag = (release['tag_name'] as String? ?? '').trim();
              final body = release['body'] as String? ?? 'New version available with improvements.';
              final assets = release['assets'] as List<dynamic>? ?? [];

              String apkUrl = latestDirectApkUrl;
              int apkSize = 0;

              for (final asset in assets) {
                final name = (asset['name'] as String? ?? '').toLowerCase();
                if (name.endsWith('.apk')) {
                  apkUrl = asset['browser_download_url'] as String? ?? latestDirectApkUrl;
                  apkSize = asset['size'] as int? ?? 0;
                  break;
                }
              }

              if (latestTag.isNotEmpty) {
                final isNewer = _isNewerVersion(latestTag, currentVersion);
                if (isNewer) {
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
                    manualDownloadUrl: apkUrl,
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
        }
      } catch (e) {
        debugPrint('Endpoint $endpoint failed: $e');
        lastError = e.toString();
        // Continue loop to try next fallback endpoint
      }
    }

    return UpdateCheckResult(
      status: UpdateCheckStatus.error,
      currentVersion: currentVersion,
      errorMessage: lastError.isNotEmpty ? lastError : 'Could not reach update servers.',
      manualDownloadUrl: latestDirectApkUrl,
    );
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
      final apkFile = File('${tempDir.path}/Sunward.apk');

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

  static Future<void> openManualDownloadUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
