import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_vault/domain/entities/app_settings.dart';

final settingsControllerProvider = StateNotifierProvider<SettingsController, AppSettings>((ref) {
  return SettingsController();
});

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController() : super(AppSettings.defaults());

  // Update secret key
  Future<void> updateSecretKey(String newSecretKey) async {
    state = state.copyWith(secretKey: newSecretKey);
    await _saveSettings();
  }

  // Toggle dark mode
  Future<void> toggleDarkMode() async {
    state = state.copyWith(isDarkMode: !state.isDarkMode);
    await _saveSettings();
  }

  // Mark onboarding as completed
  Future<void> completeOnboarding() async {
    state = state.copyWith(hasCompletedOnboarding: true);
    await _saveSettings();
  }

  // Update auto lock time
  Future<void> updateAutoLockTime(int minutes) async {
    state = state.copyWith(autoLockTimeInMinutes: minutes);
    await _saveSettings();
  }

  // Toggle biometric authentication
  Future<void> toggleBiometricAuth() async {
    state = state.copyWith(useBiometricAuth: !state.useBiometricAuth);
    await _saveSettings();
  }

  // Load settings from storage
  Future<void> loadSettings() async {
    // TODO: Implement loading from secure storage
    // For now, use defaults
    state = AppSettings.defaults();
  }

  // Save settings to storage
  Future<void> _saveSettings() async {
    // TODO: Implement saving to secure storage
  }
} 