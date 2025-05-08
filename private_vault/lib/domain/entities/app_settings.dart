class AppSettings {
  final String secretKey;
  final bool isDarkMode;
  final bool hasCompletedOnboarding;
  final int autoLockTimeInMinutes;
  final bool useBiometricAuth;

  const AppSettings({
    required this.secretKey,
    this.isDarkMode = false,
    this.hasCompletedOnboarding = false,
    this.autoLockTimeInMinutes = 5,
    this.useBiometricAuth = false,
  });

  // Create a copy with modified fields
  AppSettings copyWith({
    String? secretKey,
    bool? isDarkMode,
    bool? hasCompletedOnboarding,
    int? autoLockTimeInMinutes,
    bool? useBiometricAuth,
  }) {
    return AppSettings(
      secretKey: secretKey ?? this.secretKey,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      autoLockTimeInMinutes: autoLockTimeInMinutes ?? this.autoLockTimeInMinutes,
      useBiometricAuth: useBiometricAuth ?? this.useBiometricAuth,
    );
  }

  // For storing in preferences
  Map<String, dynamic> toMap() {
    return {
      'secretKey': secretKey,
      'isDarkMode': isDarkMode,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'autoLockTimeInMinutes': autoLockTimeInMinutes,
      'useBiometricAuth': useBiometricAuth,
    };
  }

  // Create from preferences
  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      secretKey: map['secretKey'] as String,
      isDarkMode: map['isDarkMode'] as bool,
      hasCompletedOnboarding: map['hasCompletedOnboarding'] as bool,
      autoLockTimeInMinutes: map['autoLockTimeInMinutes'] as int,
      useBiometricAuth: map['useBiometricAuth'] as bool,
    );
  }

  // Default settings
  factory AppSettings.defaults() {
    return const AppSettings(
      secretKey: '1234+5678=',
      isDarkMode: false,
      hasCompletedOnboarding: false,
      autoLockTimeInMinutes: 5,
      useBiometricAuth: false,
    );
  }
} 