import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
  static const String currentVersion = 'v0.0.9';
  static const String latestDirectApkUrl = 'https://github.com/Suvesh108/solar/releases/download/v0.0.9/Sunward.apk';

  // Multi-tier endpoints verified to be accessible without ISP blocking or rate limiting
  static List<String> get versionEndpoints {
    final t = DateTime.now().millisecondsSinceEpoch;
    return [
      // Tier 1: Direct github.com raw file (never blocked by Indian ISPs, zero API rate limit)
      'https://github.com/Suvesh108/solar/raw/main/version.json?t=$t',
      // Tier 2: Raw GitHack mirror (zero proxy cache, instant real-time sync)
      'https://raw.githack.com/Suvesh108/solar/main/version.json?t=$t',
      // Tier 3: Statically CDN (Cloudflare edge proxy)
      'https://cdn.statically.io/gh/Suvesh108/solar/main/version.json?t=$t',
      // Tier 4: GitHub rawusercontent
      'https://raw.githubusercontent.com/Suvesh108/solar/main/version.json?t=$t',
      // Tier 5: Official GitHub Releases API (latest)
      'https://api.github.com/repos/Suvesh108/solar/releases/latest',
      // Tier 6: Official GitHub Releases API list
      'https://api.github.com/repos/Suvesh108/solar/releases',
    ];
  }

  static Future<UpdateCheckResult> checkForUpdate() async {
    String lastError = '';

    for (final endpoint in versionEndpoints) {
      try {
        final response = await http.get(
          Uri.parse(endpoint),
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'Mozilla/5.0 (Linux; Android 14; Mobile; SunwardSolar/$currentVersion)',
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
    HttpClient? client;
    IOSink? sink;
    File? apkFile;

    try {
      // 1. Determine storage directory accessible to Android package installer
      Directory? targetDir;
      try {
        final extDirs = await getExternalCacheDirectories();
        if (extDirs != null && extDirs.isNotEmpty) {
          targetDir = extDirs.first;
        }
      } catch (_) {}
      targetDir ??= await getTemporaryDirectory();

      apkFile = File('${targetDir.path}/Sunward.apk');
      if (await apkFile.exists()) {
        try {
          await apkFile.delete();
        } catch (_) {}
      }

      // 2. Open HTTP client with connection and idle timeouts
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 25);
      client.idleTimeout = const Duration(seconds: 25);

      Uri currentUri = Uri.parse(apkUrl);
      HttpClientResponse? finalResponse;

      // 3. Follow HTTP 301/302 redirects cleanly, draining the previous stream to prevent socket deadlock
      for (int i = 0; i < 10; i++) {
        final request = await client.getUrl(currentUri);
        request.followRedirects = false;
        request.headers.set(HttpHeaders.userAgentHeader, 'Mozilla/5.0 (Linux; Android 14; Mobile; SunwardSolar/$currentVersion)');
        request.headers.set(HttpHeaders.acceptHeader, '*/*');

        final resp = await request.close();

        if (resp.isRedirect && resp.headers.value(HttpHeaders.locationHeader) != null) {
          final location = resp.headers.value(HttpHeaders.locationHeader)!;
          currentUri = currentUri.resolve(location);
          // CRITICAL: Draining stream frees the underlying socket connection!
          await resp.drain();
          continue;
        }

        finalResponse = resp;
        break;
      }

      if (finalResponse == null || finalResponse.statusCode != 200) {
        debugPrint('Download failed with status: ${finalResponse?.statusCode} at $currentUri');
        return null;
      }

      final totalBytes = finalResponse.contentLength;
      sink = apkFile.openWrite();
      int receivedBytes = 0;

      await for (final chunk in finalResponse) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          onProgress((receivedBytes / totalBytes).clamp(0.0, 1.0));
        }
      }

      await sink.flush();
      await sink.close();
      sink = null;

      // 4. Trigger installation: First try native FileProvider MethodChannel, fallback to OpenFilex
      bool installed = false;
      try {
        const platform = MethodChannel('com.sunward.solar/whatsapp');
        final res = await platform.invokeMethod<bool>('installApk', {'filePath': apkFile.path});
        if (res == true) {
          installed = true;
        }
      } catch (e) {
        debugPrint('Native install method error: $e');
      }

      if (!installed) {
        await OpenFilex.open(
          apkFile.path,
          type: 'application/vnd.android.package-archive',
        );
      }

      return apkFile;
    } catch (e, stack) {
      debugPrint('Error downloading update: $e\n$stack');
      try {
        await sink?.close();
      } catch (_) {}
      return null;
    } finally {
      client?.close();
    }
  }

  static Future<void> openManualDownloadUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
