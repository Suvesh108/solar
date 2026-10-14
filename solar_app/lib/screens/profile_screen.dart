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
  String? _updateStatusMessage;
  AppUpdateInfo? _updateInfo;
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
      _updateStatusMessage = 'Checking for updates...';
    });

    try {
      final info = await AppUpdateService.checkForUpdate();
      if (!mounted) return;

      setState(() {
        _updateInfo = info;
        _lastCheckedAt = DateTime.now();
        _isCheckingUpdate = false;
      });

      if (info.hasUpdate) {
        setState(() {
          _updateStatusMessage = 'New version ${info.latestVersion} is available!';
        });
        _showUpdateDialog(info);
      } else {
        setState(() {
          _updateStatusMessage = 'Sunward Solar is up to date (${info.currentVersion})';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.teal,
            content: Text('Sunward Solar is up to date (${info.currentVersion})'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCheckingUpdate = false;
        _updateStatusMessage = 'Could not check updates: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.coral,
          content: Text('Could not check updates: $e'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showUpdateDialog(AppUpdateInfo info) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        double downloadProgress = 0.0;
        bool isDownloading = false;
        String downloadStatus = '';

        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.system_update, color: AppColors.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Update to ${info.latestVersion}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'A new version (${info.latestVersion}) is available. Current version is ${info.currentVersion}.',
                    style: const TextStyle(fontSize: 13, color: AppColors.ink),
                  ),
                  const SizedBox(height: 12),
                  if (info.notes.isNotEmpty) ...[
                    const Text("What's New:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 4),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 130),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.cream.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          info.notes,
                          style: const TextStyle(fontSize: 11.5, color: AppColors.ink, height: 1.35),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (isDownloading) ...[
                    LinearProgressIndicator(
                      value: downloadProgress > 0 ? downloadProgress : null,
                      backgroundColor: AppColors.cream,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      downloadStatus,
                      style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
              actions: [
                if (!isDownloading) ...[
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Later'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      setModalState(() {
                        isDownloading = true;
                        downloadStatus = 'Downloading update package...';
                      });

                      try {
                        final success = await AppUpdateService.startDownloadAndInstall(
                          downloadUrl: info.downloadUrl,
                          onProgress: (prog, rec, tot) {
                            setModalState(() {
                              downloadProgress = prog;
                              final mbRec = (rec / (1024 * 1024)).toStringAsFixed(1);
                              final mbTot = (tot / (1024 * 1024)).toStringAsFixed(1);
                              downloadStatus = '$mbRec MB / $mbTot MB (${(prog * 100).toInt()}%)';
                            });
                          },
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (success && mounted) {
                          messenger.showSnackBar(
                            const SnackBar(
                              backgroundColor: AppColors.teal,
                              content: Text('Update downloaded! Launching installer...'),
                              duration: Duration(seconds: 4),
                            ),
                          );
                        }
                      } catch (e) {
                        setModalState(() {
                          isDownloading = false;
                          downloadStatus = 'Install failed: $e';
                        });
                      }
                    },
                    child: const Text('Update Now', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
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
                              const Text(
                                'Sunward Solar Partner / User',
                                style: TextStyle(fontSize: 12, color: AppColors.muted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.ink),
                          tooltip: 'Edit Name',
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
                                        'Version: ${_updateInfo?.currentVersion ?? "0.1.4"}',
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
                        if (_updateStatusMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _updateStatusMessage!,
                            style: const TextStyle(fontSize: 12, color: AppColors.muted),
                          ),
                        ],
                        const SizedBox(height: 14),
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
                              _isCheckingUpdate ? 'Checking for Updates...' : 'Check For App Updates',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: _isCheckingUpdate ? null : _checkForUpdates,
                          ),
                        ),
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
                        const Text(
                          'Help & Support',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink),
                        ),
                        const SizedBox(height: 10),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.cream,
                            child: Icon(Icons.phone, color: AppColors.ink, size: 20),
                          ),
                          title: const Text('Call Helpline', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
                          title: const Text('WhatsApp Advisor', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          subtitle: const Text('Chat with Solar Advisor', style: TextStyle(fontSize: 12)),
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
