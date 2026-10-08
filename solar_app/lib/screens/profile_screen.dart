import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/update_service.dart';
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
  UpdateInfo? _availableUpdate;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

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
        title: const Text('Change Name / Naam Badlein', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Apna Naam (Your Name)',
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
      _updateStatusMessage = 'Checking GitHub releases for latest version...';
      _availableUpdate = null;
    });

    final update = await UpdateService.checkForUpdate();

    if (!mounted) return;

    setState(() {
      _isCheckingUpdate = false;
      if (update != null) {
        _availableUpdate = update;
        _updateStatusMessage = 'New version ${update.version} is available!';
      } else {
        _updateStatusMessage = 'Great! You already have the latest version (${UpdateService.currentVersion}).';
      }
    });
  }

  Future<void> _startInAppDownload(UpdateInfo update) async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    final file = await UpdateService.downloadAndInstallApk(
      apkUrl: update.apkUrl,
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
        const SnackBar(
          backgroundColor: AppColors.coral,
          content: Text('Failed to download update. Please check internet connection.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = _userName.isNotEmpty ? _userName[0].toUpperCase() : 'S';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile / Meri Profile'),
      ),
      body: SingleChildScrollView(
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
                      radius: 32,
                      backgroundColor: AppColors.sun,
                      child: Text(
                        initial,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.ink),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Sunward Solar Partner / User',
                            style: TextStyle(fontSize: 12, color: AppColors.muted),
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
            const SizedBox(height: 16),

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
                            color: AppColors.teal.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.system_update_rounded, color: AppColors.teal, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'App Updates / Naya Version',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink),
                              ),
                              Text(
                                'Current version: v0.0.2',
                                style: TextStyle(fontSize: 12, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (_updateStatusMessage.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _availableUpdate != null
                              ? AppColors.sun.withOpacity(0.2)
                              : AppColors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _availableUpdate != null ? AppColors.sun : AppColors.teal.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _updateStatusMessage,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _availableUpdate != null ? AppColors.ink : AppColors.teal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (_availableUpdate != null && !_isDownloading) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cream.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Whats New in ${_availableUpdate!.version}:',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _availableUpdate!.notes,
                              style: const TextStyle(fontSize: 11, color: AppColors.muted),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
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
                            'Download & Install ${_availableUpdate!.version}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => _startInAppDownload(_availableUpdate!),
                        ),
                      ),
                    ],

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
                            'After download, package installer will open automatically.',
                            style: TextStyle(fontSize: 11, color: AppColors.muted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (!_isDownloading && _availableUpdate == null) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.ink,
                            side: const BorderSide(color: AppColors.ink, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: _isCheckingUpdate
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink),
                                )
                              : const Icon(Icons.refresh_rounded, size: 20),
                          label: Text(
                            _isCheckingUpdate ? 'Checking Updates...' : 'Check For App Update',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: _isCheckingUpdate ? null : _checkForUpdates,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // About & Help Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Help & Support / Madad',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.cream,
                        child: Icon(Icons.phone, color: AppColors.ink, size: 20),
                      ),
                      title: const Text('Call Helpline', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: const Text('+91 99999 99999 (Toll Free)', style: TextStyle(fontSize: 12)),
                      onTap: () => launchUrl(Uri.parse('tel:919999999999')),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFDCF8C6),
                        child: Icon(Icons.chat, color: Color(0xFF075E54), size: 20),
                      ),
                      title: const Text('WhatsApp Chat', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Chat with Solar Advisor', style: TextStyle(fontSize: 12)),
                      onTap: () => launchUrl(
                        Uri.parse('https://wa.me/919999999999?text=${Uri.encodeComponent('Hi Sunward Team, need solar help.')}'),
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
  }
}
