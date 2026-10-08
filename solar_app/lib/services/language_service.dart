import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

enum AppLanguage { en, hi }

class LanguageService {
  static final LanguageService instance = LanguageService._internal();
  LanguageService._internal();

  final ValueNotifier<AppLanguage> languageNotifier = ValueNotifier<AppLanguage>(AppLanguage.en);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('app_language') ?? 'en';
    languageNotifier.value = code == 'hi' ? AppLanguage.hi : AppLanguage.en;
  }

  Future<void> toggleLanguage() async {
    final next = languageNotifier.value == AppLanguage.en ? AppLanguage.hi : AppLanguage.en;
    languageNotifier.value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', next == AppLanguage.hi ? 'hi' : 'en');
  }

  bool get isHindi => languageNotifier.value == AppLanguage.hi;

  String t(String en, String hi) => isHindi ? hi : en;
}

class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: LanguageService.instance.languageNotifier,
      builder: (context, lang, _) {
        final isHi = lang == AppLanguage.hi;
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Center(
            child: InkWell(
              onTap: () => LanguageService.instance.toggleLanguage(),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isHi ? AppColors.sun : AppColors.cream,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.ink, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.translate_rounded, size: 14, color: AppColors.ink),
                    const SizedBox(width: 5),
                    Text(
                      isHi ? 'हिन्दी' : 'English',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
