import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_update_service.dart';
import '../services/language_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Sunward User';
  bool _isCheckingUpdate = false;
  String _updateStatusMessage = '';
  AppReleaseInfo? _latestRelease;
  AppUpdateStatus _updateStatus = AppUpdateStatus.idle;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  DateTime? _lastCheckedAt;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name');
    if (name != null && name.trim().isNotEmpty) {
      setState(() => _userName = name.trim());
    }
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _userName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: const Text(
          'Change Name',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Your Name',
            hintText: 'Enter name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.ink, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', result);
      setState(() => _userName = result);
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingUpdate = true;
      _updateStatus = AppUpdateStatus.checking;
      _updateStatusMessage = 'Checking GitHub releases for latest version...';
    });

    final result = await AppUpdateService.checkForUpdate();

    if (!mounted) return;

    setState(() {
      _isCheckingUpdate = false;
      _updateStatus = result.status;
      _latestRelease = result.release;
      _lastCheckedAt = DateTime.now();

      switch (result.status) {
        case AppUpdateStatus.updateAvailable:
          _updateStatusMessage = 'New version ${result.release?.version ?? result.latestVersion} is available!';
          break;
        case AppUpdateStatus.upToDate:
          _updateStatusMessage = 'You are already running the latest version (${result.currentVersion}).';
          break;
        case AppUpdateStatus.error:
          _updateStatusMessage = result.message ?? 'Could not connect to GitHub. You can still download the APK below.';
          break;
        case AppUpdateStatus.idle:
        case AppUpdateStatus.checking:
          break;
      }
    });
  }

  Future<void> _startInAppDownload(AppReleaseInfo update) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.teal,
          content: Text('Starting download for ${update.version} (${update.formattedSize})...'),
          duration: const Duration(seconds: 3),
        ),
      );
      await AppUpdateService.openUrl(update.apkDownloadUrl);
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    final file = await AppUpdateService.downloadAndInstallApk(
      apkUrl: update.apkDownloadUrl,
      onProgress: (p) {
        if (mounted) {
          setState(() => _downloadProgress = p);
        }
      },
    );

    if (!mounted) return;

    setState(() => _isDownloading = false);

    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.coral,
          content: const Text('Failed to download update. Please check internet connection or open in browser.'),
          action: SnackBarAction(
            label: 'Browser',
            textColor: Colors.white,
            onPressed: () => AppUpdateService.openUrl(update.apkDownloadUrl),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService.instance;
    final initial = _userName.isNotEmpty ? _userName[0].toUpperCase() : 'S';

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: lang.languageNotifier,
      builder: (context, _, __) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Profile'),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User Header Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.sun,
                          child: Text(
                            initial,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.ink),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userName,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                lang.t('Sunward Solar Partner / User', 'सनवर्ड सोलर पार्टनर / यूजर'),
                                style: const TextStyle(fontSize: 12, color: AppColors.muted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.ink),
                          tooltip: lang.t('Edit Name', 'नाम बदलें'),
                          onPressed: _editName,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // In-App Updates Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.teal.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.system_update_rounded, color: AppColors.teal, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'App Updates',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'Version: ${AppUpdateService.currentVersion}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.muted),
                                      ),
                                      if (_lastCheckedAt != null) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          '• Checked ${DateFormat('hh:mm a').format(_lastCheckedAt!)}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.muted),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Status Banner
                        if (_updateStatusMessage.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _updateStatus == AppUpdateStatus.updateAvailable
                                  ? AppColors.sun.withValues(alpha: 0.2)
                                  : (_updateStatus == AppUpdateStatus.error
                                      ? AppColors.coral.withValues(alpha: 0.15)
                                      : AppColors.teal.withValues(alpha: 0.1)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _updateStatus == AppUpdateStatus.updateAvailable
                                    ? AppColors.sun
                                    : (_updateStatus == AppUpdateStatus.error
                                        ? AppColors.coral.withValues(alpha: 0.4)
                                        : AppColors.teal.withValues(alpha: 0.3)),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _updateStatus == AppUpdateStatus.updateAvailable
                                      ? Icons.new_releases_rounded
                                      : (_updateStatus == AppUpdateStatus.error
                                          ? Icons.error_outline_rounded
                                          : Icons.check_circle_outline_rounded),
                                  size: 20,
                                  color: _updateStatus == AppUpdateStatus.updateAvailable
                                      ? AppColors.ink
                                      : (_updateStatus == AppUpdateStatus.error ? AppColors.coral : AppColors.teal),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _updateStatusMessage,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _updateStatus == AppUpdateStatus.updateAvailable
                                          ? AppColors.ink
                                          : (_updateStatus == AppUpdateStatus.error ? AppColors.coral : AppColors.teal),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Release Notes Box (shown if release info exists)
                        if (_latestRelease != null && !_isDownloading) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.cream.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.cream),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "What's New in ${_latestRelease!.version}:",
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.ink),
                                    ),
                                    Text(
                                      _latestRelease!.formattedSize,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _latestRelease!.notes,
                                  style: const TextStyle(fontSize: 12, color: AppColors.ink, height: 1.4),
                                  maxLines: 6,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Downloading Progress Bar
                        if (_isDownloading) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Downloading update...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  Text('${(_downloadProgress * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: _downloadProgress,
                                backgroundColor: AppColors.cream,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Package installer will trigger automatically upon download completion.',
                                style: TextStyle(fontSize: 11, color: AppColors.muted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Action Buttons
                        if (!_isDownloading) ...[
                          // Primary Install Button if update is available
                          if (_updateStatus == AppUpdateStatus.updateAvailable && _latestRelease != null) ...[
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.teal,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.download_for_offline_outlined, size: 20),
                                label: Text(
                                  'Download & Install ${_latestRelease!.version} (${_latestRelease!.formattedSize})',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                onPressed: () => _startInAppDownload(_latestRelease!),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],

                          // Secondary Re-download / Install APK button if up-to-date or fallback
                          if ((_updateStatus == AppUpdateStatus.upToDate || _updateStatus == AppUpdateStatus.error) && _latestRelease != null) ...[
                            SizedBox(
                              width: double.infinity,
                              height: 42,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.teal,
                                  side: const BorderSide(color: AppColors.teal, width: 1.2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.file_download_outlined, size: 18),
                                label: Text(
                                  'Download Sunward.apk (${_latestRelease!.formattedSize})',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                onPressed: () => _startInAppDownload(_latestRelease!),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],

                          // Check For Updates Button
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.ink,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: _isCheckingUpdate
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.refresh_rounded, size: 20),
                              label: Text(
                                _isCheckingUpdate ? 'Checking GitHub...' : 'Check For App Updates',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onPressed: _isCheckingUpdate ? null : _checkForUpdates,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Direct Web Links
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                style: TextButton.styleFrom(foregroundColor: AppColors.muted, padding: const EdgeInsets.symmetric(horizontal: 8)),
                                icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                                label: const Text(
                                  'Releases Page',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                                ),
                                onPressed: () => AppUpdateService.openUrl(
                                  _latestRelease?.releasePageUrl ?? AppUpdateService.defaultReleasePageUrl,
                                ),
                              ),
                              const Text('•', style: TextStyle(color: AppColors.muted)),
                              TextButton.icon(
                                style: TextButton.styleFrom(foregroundColor: AppColors.muted, padding: const EdgeInsets.symmetric(horizontal: 8)),
                                icon: const Icon(Icons.download_rounded, size: 16),
                                label: const Text(
                                  'Direct APK Link',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                                ),
                                onPressed: () => AppUpdateService.openUrl(
                                  _latestRelease?.apkDownloadUrl ?? AppUpdateService.defaultDirectApkUrl,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Helpline Support Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.t('Help & Support', 'मदद और सहायता'),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink),
                        ),
                        const SizedBox(height: 10),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.cream,
                            child: Icon(Icons.phone, color: AppColors.ink, size: 20),
                          ),
                          title: Text(lang.t('Call Helpline', 'हेल्पलाइन कॉल करें'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          subtitle: const Text('+91 9731001477', style: TextStyle(fontSize: 12)),
                          onTap: () => launchUrl(Uri.parse('tel:9731001477')),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFDCF8C6),
                            child: Icon(Icons.chat, color: Color(0xFF075E54), size: 20),
                          ),
                          title: Text(lang.t('WhatsApp Advisor', 'व्हाट्सऐप पर संपर्क करें'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          subtitle: Text(lang.t('Chat with Solar Advisor', 'सोलर सलाहकार से चैट करें'), style: const TextStyle(fontSize: 12)),
                          onTap: () => launchUrl(
                            Uri.parse('https://wa.me/919731001477?text=${Uri.encodeComponent("Namaste Sunward Team, need solar help.")}'),
                            mode: LaunchMode.externalApplication,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
