import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_vault/app/routes.dart';
import 'package:private_vault/app/theme.dart';
import 'package:private_vault/presentation/pages/calculator/calculator_screen.dart';
import 'package:private_vault/presentation/pages/onboarding/onboarding_screen.dart';
import 'package:private_vault/presentation/pages/secret_area/secret_area_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:private_vault/core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load initial settings
  final prefs = await SharedPreferences.getInstance();
  final hasCompletedOnboarding = prefs.getBool(AppConstants.hasCompletedOnboardingKey) ?? false;
  final isDarkMode = prefs.getBool(AppConstants.isDarkModeKey) ?? false;

  runApp(
    ProviderScope(
      overrides: [
        isDarkModeProvider.overrideWith((ref) => isDarkMode),
      ],
      child: const PrivateVaultApp(),
    ),
  );
}

// Dark mode provider
final isDarkModeProvider = StateProvider<bool>((ref) => false);

// For persisting dark mode settings
final darkModeSettingsProvider = Provider<DarkModeSettings>((ref) {
  return DarkModeSettings();
});

class DarkModeSettings {
  Future<void> toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.isDarkModeKey, value);
  }
}

class PrivateVaultApp extends ConsumerWidget {
  const PrivateVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final darkModeSettings = ref.watch(darkModeSettingsProvider);
    
    // Set up listener for dark mode changes
    ref.listen<bool>(isDarkModeProvider, (previous, current) {
      if (previous != current) {
        darkModeSettings.toggleDarkMode(current);
      }
    });

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      onGenerateRoute: AppRoutes.generateRoute,
      home: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          final prefs = snapshot.data!;
          final hasCompletedOnboarding = prefs.getBool(AppConstants.hasCompletedOnboardingKey) ?? false;
          
          return hasCompletedOnboarding
              ? const CalculatorScreen()
              : const OnboardingScreen();
        },
      ),
    );
  }
}
