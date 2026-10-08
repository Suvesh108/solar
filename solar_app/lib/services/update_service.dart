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

class UpdateService {
  static const String currentVersion = 'v0.0.3';
  static const String _repoReleasesUrl = 'https://api.github.com/repos/Suvesh108/solar/releases/latest';

  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http.get(
        Uri.parse(_repoReleasesUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final latestTag = (data['tag_name'] as String? ?? '').trim();
        final body = data['body'] as String? ?? 'New version available with improvements.';
        final assets = data['assets'] as List<dynamic>? ?? [];

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

        // Compare versions (e.g. v0.0.3 vs v0.0.2)
        if (_isNewerVersion(latestTag, currentVersion) && apkUrl.isNotEmpty) {
          return UpdateInfo(
            version: latestTag,
            notes: body,
            apkUrl: apkUrl,
            apkSize: apkSize,
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking for update: $e');
    }
    return null;
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
      final request = http.Request('GET', Uri.parse(apkUrl));
      final response = await http.Client().send(request);

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

      // Launch in-place native package installer without browser redirection
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
