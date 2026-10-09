import 'package:flutter/material.dart';

enum AppLanguage { en }

class LanguageService {
  static final LanguageService instance = LanguageService._internal();
  LanguageService._internal();

  final ValueNotifier<AppLanguage> languageNotifier = ValueNotifier<AppLanguage>(AppLanguage.en);

  Future<void> init() async {}

  Future<void> toggleLanguage() async {}

  bool get isHindi => false;

  String t(String en, [String? hi]) => en;
}

class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
