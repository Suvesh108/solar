import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateInfo {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final int size;
  final String notes;

  const AppUpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    required this.size,
    required this.notes,
  });

  String get formattedSize {
    if (size <= 0) return '55 MB';
    final mb = size / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}

class AppUpdateService {
  static const MethodChannel _channel = MethodChannel('com.sunward.updater');
  static void Function(double progress, int received, int total)? _progressCallback;
  static bool _listenerRegistered = false;

  static void _ensureListener() {
    if (_listenerRegistered) return;
    _listenerRegistered = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onDownloadProgress') {
        final args = call.arguments as Map?;
        if (args != null) {
          final double prog = (args['progress'] as num?)?.toDouble() ?? 0.0;
          final int rec = (args['received'] as num?)?.toInt() ?? 0;
          final int tot = (args['total'] as num?)?.toInt() ?? 0;
          _progressCallback?.call(prog, rec, tot);
        }
      }
    });
  }

  /// Queries the native Kotlin engine to check for updates from GitHub Releases
  static Future<AppUpdateInfo> checkForUpdate() async {
    _ensureListener();

    if (kIsWeb) {
      return const AppUpdateInfo(
        hasUpdate: false,
        currentVersion: '0.1.6',
        latestVersion: '0.1.6',
        downloadUrl: '',
        size: 0,
        notes: '',
      );
    }

    try {
      final res = await _channel.invokeMethod<Map>('checkForUpdate');
      if (res == null) throw Exception('No response from native update engine');

      return AppUpdateInfo(
        hasUpdate: res['hasUpdate'] as bool? ?? false,
        currentVersion: res['currentVersion'] as String? ?? '0.1.6',
        latestVersion: res['latestVersion'] as String? ?? '',
        downloadUrl: res['downloadUrl'] as String? ?? '',
        size: (res['size'] as num?)?.toInt() ?? 0,
        notes: res['notes'] as String? ?? '',
      );
    } on MissingPluginException {
      return const AppUpdateInfo(
        hasUpdate: false,
        currentVersion: '0.1.6',
        latestVersion: '0.1.6',
        downloadUrl: '',
        size: 0,
        notes: '',
      );
    } catch (e) {
      debugPrint('[AppUpdateService] Native check update error: $e');
      rethrow;
    }
  }

  /// Downloads the APK via native background thread and triggers package installer
  static Future<bool> startDownloadAndInstall({
    required String downloadUrl,
    required void Function(double progress, int received, int total) onProgress,
  }) async {
    _ensureListener();
    _progressCallback = onProgress;

    try {
      final bool? success = await _channel.invokeMethod<bool>(
        'downloadAndInstall',
        {'downloadUrl': downloadUrl},
      );
      return success ?? false;
    } catch (e) {
      debugPrint('[AppUpdateService] Native download error: $e');
      rethrow;
    } finally {
      _progressCallback = null;
    }
  }

  /// Direct install of a local file via native Intent
  static Future<bool> installApk(String filePath) async {
    try {
      final bool? success = await _channel.invokeMethod<bool>(
        'installApk',
        {'filePath': filePath},
      );
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Checks if device allows package installs
  static Future<bool> canRequestPackageInstalls() async {
    if (kIsWeb) return true;
    try {
      final can = await _channel.invokeMethod<bool>('canRequestPackageInstalls');
      return can ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Opens Android system settings for unknown sources
  static Future<void> openInstallPermissionSettings() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('openInstallPermissionSettings');
    } catch (_) {}
  }

  /// Open external URL safely in browser
  static Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
