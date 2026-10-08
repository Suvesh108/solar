import 'package:flutter/material.dart';
import 'models/lead.dart';
import 'screens/admin_inbox_screen.dart';
import 'screens/calculator_screen.dart';
import 'services/lead_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LeadService.instance.init();
  runApp(const SunwardSolarApp());
}

class SunwardSolarApp extends StatelessWidget {
  const SunwardSolarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sunward Solar',
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
    AdminInboxScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
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
                icon: Icon(Icons.solar_power_outlined),
                activeIcon: Icon(Icons.solar_power),
                label: 'Calculator',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: newLeadsCount > 0,
                  label: Text('$newLeadsCount'),
                  backgroundColor: AppColors.coral,
                  child: const Icon(Icons.all_inbox_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: newLeadsCount > 0,
                  label: Text('$newLeadsCount'),
                  backgroundColor: AppColors.coral,
                  child: const Icon(Icons.all_inbox),
                ),
                label: 'Admin Box',
              ),
            ],
          );
        },
      ),
    );
  }
}
