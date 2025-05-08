class AppConstants {
  // App information
  static const String appName = 'Private Vault';
  static const String appVersion = '1.0.0';
  
  // Secret key constants
  static const String defaultSecretKey = '1234+5678=';
  
  // Shared preferences keys
  static const String hasCompletedOnboardingKey = 'has_completed_onboarding';
  static const String isDarkModeKey = 'is_dark_mode';
  static const String secretKeyPrefKey = 'secret_key';
  
  // Authentication constants
  static const int autoLockTimeInMinutes = 5;
  static const int maxFailedAttempts = 5;
  
  // Calculator constants
  static const int maxDisplayDigits = 12;
  static const int maxHistoryEntries = 50;
  
  // Storage paths
  static const String notesFolder = 'notes';
  static const String imagesFolder = 'images';
  static const String videosFolder = 'videos';
  static const String documentsFolder = 'documents';
  
  // Encryption
  static const String encryptionIv = '16-bytes-iv-secure'; // 16 bytes
  
  // Demo texts for onboarding
  static const List<String> onboardingTitles = [
    'Hoş Geldiniz',
    'Hesaplama Yapın',
    'Gizli Özellik',
    'Dosyalarınızı Güvende Tutun',
  ];
  
  static const List<String> onboardingDescriptions = [
    'Bu basit görünen hesap makinesi aslında çok daha fazlasını yapabilir.',
    'Normal bir hesap makinesi olarak kullanabilirsiniz.',
    '1234+5678= işlemini yaparak gizli alana erişebilirsiniz.',
    'Gizli alanda dosyalarınızı saklayabilir ve yönetebilirsiniz.',
  ];
} 