import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AppReleaseInfo {
  final String version;
  final String title;
  final String notes;
  final String apkDownloadUrl;
  final int apkSizeBytes;
  final String releasePageUrl;
  final DateTime? publishedAt;

  const AppReleaseInfo({
    required this.version,
    required this.title,
    required this.notes,
    required this.apkDownloadUrl,
    required this.apkSizeBytes,
    required this.releasePageUrl,
    this.publishedAt,
  });

  String get formattedSize {
    if (apkSizeBytes <= 0) return '51.7 MB';
    final mb = apkSizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}

enum AppUpdateStatus {
  idle,
  checking,
  updateAvailable,
  upToDate,
  error,
}

class AppUpdateResult {
  final AppUpdateStatus status;
  final AppReleaseInfo? release;
  final String currentVersion;
  final String? latestVersion;
  final String? message;

  const AppUpdateResult({
    required this.status,
    this.release,
    required this.currentVersion,
    this.latestVersion,
    this.message,
  });
}

class AppUpdateService {
  static const String currentVersion = 'v0.1.1';
  static const String githubOwner = 'Suvesh108';
  static const String githubRepo = 'solar';

  static const String defaultReleasePageUrl =
      'https://github.com/$githubOwner/$githubRepo/releases';
  static const String defaultDirectApkUrl =
      'https://github.com/$githubOwner/$githubRepo/releases/download/$currentVersion/Sunward.apk';

  static Map<String, String> _getHeaders() {
    final map = <String, String>{
      'Accept': 'application/vnd.github.v3+json',
    };
    if (!kIsWeb) {
      map['User-Agent'] = 'SunwardSolar-App/$currentVersion';
    }
    return map;
  }

  /// Check GitHub releases API for newer versions with multi-layer fallback
  static Future<AppUpdateResult> checkForUpdate() async {
    final client = http.Client();

    try {
      // 1. Try GitHub /releases/latest endpoint
      final latestResult = await _checkLatestEndpoint(client);
      if (latestResult != null) return latestResult;

      // 2. Try GitHub /releases (list) endpoint fallback
      final listResult = await _checkListEndpoint(client);
      if (listResult != null) return listResult;

      // 3. Try Raw GitHub manifest fallback (bypasses GitHub API rate limits completely)
      final rawResult = await _checkRawFallback(client);
      if (rawResult != null) return rawResult;

      return AppUpdateResult(
        status: AppUpdateStatus.error,
        release: AppReleaseInfo(
          version: currentVersion,
          title: '$currentVersion - Sunward Solar App',
          notes: 'Standard release package.',
          apkDownloadUrl: defaultDirectApkUrl,
          apkSizeBytes: 54245959,
          releasePageUrl: defaultReleasePageUrl,
        ),
        currentVersion: currentVersion,
        message: 'Could not connect to GitHub API. You can still download the APK directly below.',
      );
    } catch (e) {
      debugPrint('[AppUpdateService] Check update error: $e');
      return AppUpdateResult(
        status: AppUpdateStatus.error,
        release: AppReleaseInfo(
          version: currentVersion,
          title: '$currentVersion - Sunward Solar App',
          notes: 'Standard release package.',
          apkDownloadUrl: defaultDirectApkUrl,
          apkSizeBytes: 54245959,
          releasePageUrl: defaultReleasePageUrl,
        ),
        currentVersion: currentVersion,
        message: 'Network error checking for updates: $e',
      );
    } finally {
      client.close();
    }
  }

  static Future<AppUpdateResult?> _checkLatestEndpoint(http.Client client) async {
    try {
      final uri = Uri.parse('https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest');
      final response = await client.get(
        uri,
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return _parseReleaseMap(data);
      } else {
        debugPrint('[AppUpdateService] Latest endpoint returned status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Latest endpoint failed: $e');
    }
    return null;
  }

  static Future<AppUpdateResult?> _checkListEndpoint(http.Client client) async {
    try {
      final uri = Uri.parse('https://api.github.com/repos/$githubOwner/$githubRepo/releases');
      final response = await client.get(
        uri,
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final isDraft = item['draft'] as bool? ?? false;
            final isPrerelease = item['prerelease'] as bool? ?? false;
            if (!isDraft && !isPrerelease) {
              return _parseReleaseMap(item);
            }
          }
        }
      } else {
        debugPrint('[AppUpdateService] List endpoint returned status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[AppUpdateService] List endpoint failed: $e');
    }
    return null;
  }

  static Future<AppUpdateResult?> _checkRawFallback(http.Client client) async {
    try {
      final uri = Uri.parse('https://raw.githubusercontent.com/$githubOwner/$githubRepo/main/solar_app/pubspec.yaml');
      final response = await client.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final lines = response.body.split('\n');
        String versionStr = '';
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.startsWith('version:')) {
            versionStr = trimmed.replaceFirst('version:', '').trim();
            final plusIdx = versionStr.indexOf('+');
            if (plusIdx != -1) versionStr = versionStr.substring(0, plusIdx).trim();
            break;
          }
        }

        if (versionStr.isNotEmpty) {
          final tag = versionStr.startsWith('v') ? versionStr : 'v$versionStr';

          String notes = 'What\'s new in $tag:\n- Turnkey pricing\n- Simplified English layout\n- Rebuilt in-app update installer';
          try {
            final notesUri = Uri.parse('https://raw.githubusercontent.com/$githubOwner/$githubRepo/main/release_notes.md');
            final notesRes = await client.get(notesUri).timeout(const Duration(seconds: 5));
            if (notesRes.statusCode == 200 && notesRes.body.trim().isNotEmpty) {
              notes = notesRes.body.trim();
            }
          } catch (_) {}

          final release = AppReleaseInfo(
            version: tag,
            title: '$tag - Sunward Solar App Update',
            notes: notes,
            apkDownloadUrl: 'https://github.com/$githubOwner/$githubRepo/releases/download/$tag/Sunward.apk',
            apkSizeBytes: 54245959,
            releasePageUrl: 'https://github.com/$githubOwner/$githubRepo/releases/tag/$tag',
            publishedAt: DateTime.now(),
          );

          final isNewer = isVersionNewer(tag, currentVersion);
          return AppUpdateResult(
            status: isNewer ? AppUpdateStatus.updateAvailable : AppUpdateStatus.upToDate,
            release: release,
            currentVersion: currentVersion,
            latestVersion: tag,
            message: isNewer ? 'New update $tag is available!' : 'You are on the latest version ($currentVersion).',
          );
        }
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Raw fallback failed: $e');
    }
    return null;
  }

  static AppUpdateResult _parseReleaseMap(Map<String, dynamic> data) {
    final tagName = (data['tag_name'] as String? ?? '').trim();
    final title = (data['name'] as String? ?? tagName).trim();
    final body = (data['body'] as String? ?? '').trim();
    final htmlUrl = (data['html_url'] as String? ?? defaultReleasePageUrl).trim();
    final publishedStr = data['published_at'] as String?;
    final publishedAt = publishedStr != null ? DateTime.tryParse(publishedStr) : null;

    final assets = (data['assets'] as List<dynamic>? ?? []);
    String apkUrl = '';
    int apkSize = 0;

    for (final asset in assets) {
      if (asset is Map<String, dynamic>) {
        final name = (asset['name'] as String? ?? '').toLowerCase();
        if (name.endsWith('.apk')) {
          apkUrl = asset['browser_download_url'] as String? ?? '';
          apkSize = asset['size'] as int? ?? 0;
          break;
        }
      }
    }

    if (apkUrl.isEmpty) {
      apkUrl = 'https://github.com/$githubOwner/$githubRepo/releases/download/$tagName/Sunward.apk';
    }

    final releaseInfo = AppReleaseInfo(
      version: tagName,
      title: title,
      notes: body.isNotEmpty ? body : 'New version available with improvements and bug fixes.',
      apkDownloadUrl: apkUrl,
      apkSizeBytes: apkSize,
      releasePageUrl: htmlUrl,
      publishedAt: publishedAt,
    );

    final isNewer = isVersionNewer(tagName, currentVersion);

    if (isNewer) {
      return AppUpdateResult(
        status: AppUpdateStatus.updateAvailable,
        release: releaseInfo,
        currentVersion: currentVersion,
        latestVersion: tagName,
        message: 'New update $tagName is available!',
      );
    } else {
      return AppUpdateResult(
        status: AppUpdateStatus.upToDate,
        release: releaseInfo,
        currentVersion: currentVersion,
        latestVersion: tagName,
        message: 'You are on the latest version ($currentVersion).',
      );
    }
  }

  /// Numeric semantic version comparator (e.g., v0.0.10 > v0.0.9)
  static bool isVersionNewer(String latest, String current) {
    try {
      final cleanLatest = latest.replaceAll(RegExp(r'[^0-9.]'), '');
      final cleanCurrent = current.replaceAll(RegExp(r'[^0-9.]'), '');

      final latParts = cleanLatest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final curParts = cleanCurrent.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      final maxLen = latParts.length > curParts.length ? latParts.length : curParts.length;

      for (int i = 0; i < maxLen; i++) {
        final l = i < latParts.length ? latParts[i] : 0;
        final c = i < curParts.length ? curParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
      return false;
    } catch (_) {
      return latest.compareTo(current) > 0;
    }
  }

  /// In-app APK download and trigger installation
  static Future<File?> downloadAndInstallApk({
    required String apkUrl,
    required void Function(double progress) onProgress,
  }) async {
    if (kIsWeb) {
      // On web, direct user to download link
      await openUrl(apkUrl);
      return null;
    }

    HttpClient? client;
    IOSink? sink;
    File? apkFile;

    try {
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

      client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 30)
        ..idleTimeout = const Duration(seconds: 30);

      Uri currentUri = Uri.parse(apkUrl);
      HttpClientResponse? finalResponse;

      // Follow HTTP 301/302 redirects with stream draining
      for (int redirectCount = 0; redirectCount < 10; redirectCount++) {
        final request = await client.getUrl(currentUri);
        request.followRedirects = false;
        request.headers.set(
          HttpHeaders.userAgentHeader,
          'Mozilla/5.0 (Linux; Android 14; Mobile; SunwardSolar/$currentVersion)',
        );
        request.headers.set(HttpHeaders.acceptHeader, '*/*');

        final response = await request.close();

        if (response.isRedirect) {
          final location = response.headers.value(HttpHeaders.locationHeader);
          if (location != null) {
            currentUri = currentUri.resolve(location);
            await response.drain();
            continue;
          }
        }

        finalResponse = response;
        break;
      }

      if (finalResponse == null || finalResponse.statusCode != 200) {
        debugPrint('[AppUpdateService] Download failed: ${finalResponse?.statusCode}');
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

      // Trigger Android installer
      bool nativeInstalled = false;
      try {
        const platform = MethodChannel('com.sunward.solar/whatsapp');
        final res = await platform.invokeMethod<bool>(
          'installApk',
          {'filePath': apkFile.path},
        );
        if (res == true) nativeInstalled = true;
      } catch (_) {}

      if (!nativeInstalled) {
        await OpenFilex.open(
          apkFile.path,
          type: 'application/vnd.android.package-archive',
        );
      }

      return apkFile;
    } catch (e) {
      debugPrint('[AppUpdateService] Download error: $e');
      try {
        await sink?.close();
      } catch (_) {}
      return null;
    } finally {
      client?.close();
    }
  }

  /// Open external URL safely
  static Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
