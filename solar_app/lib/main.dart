import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/lead.dart';
import 'screens/calculator_screen.dart';
import 'screens/leads_screen.dart';
import 'screens/profile_screen.dart';
import 'services/language_service.dart';
import 'services/lead_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LanguageService.instance.init();
  await LeadService.instance.init();
  runApp(const SunwardSolarApp());
}

class SunwardSolarApp extends StatelessWidget {
  const SunwardSolarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sunward',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainTabScreen(),
    );
  }
}

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    CalculatorScreen(),
    LeadsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstTimeOnboarding();
    });
  }

  Future<void> _checkFirstTimeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name');
    if (name == null || name.trim().isEmpty) {
      if (!mounted) return;
      _showOnboardingDialog();
    }
  }

  void _showOnboardingDialog() {
    final lang = LanguageService.instance;
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/logo.png', height: 34, width: 34),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Welcome to Sunward',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please enter your name to personalize your app experience:',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Your Name *',
                hintText: 'e.g. Suvesh',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final input = nameCtrl.text.trim();
                final finalName = input.isNotEmpty ? input : 'Solar Partner';
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('user_name', finalName);
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text(
                'Get Started',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.02, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: ValueListenableBuilder<List<Lead>>(
        valueListenable: LeadService.instance.leadsNotifier,
        builder: (context, leads, _) {
          final newLeadsCount = leads.where((l) => l.status == LeadStatus.newLead).length;

          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.calculate_outlined),
                activeIcon: Icon(Icons.calculate),
                label: 'Calculator',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: newLeadsCount > 0,
                  label: Text('$newLeadsCount'),
                  backgroundColor: AppColors.coral,
                  child: const Icon(Icons.people_alt_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: newLeadsCount > 0,
                  label: Text('$newLeadsCount'),
                  backgroundColor: AppColors.coral,
                  child: const Icon(Icons.people_alt),
                ),
                label: 'Leads',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          );
        },
      ),
    );
  }
}
