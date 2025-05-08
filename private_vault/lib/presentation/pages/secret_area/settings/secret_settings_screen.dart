import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_vault/core/constants/app_constants.dart';
import 'package:private_vault/domain/entities/app_settings.dart';
import 'package:private_vault/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecretSettingsScreen extends ConsumerStatefulWidget {
  const SecretSettingsScreen({super.key});

  @override
  ConsumerState<SecretSettingsScreen> createState() => _SecretSettingsScreenState();
}

final RegExp _allowedSecretKeyCharacters = RegExp(r'[0-9\+\-\*\/]');
final RegExp _endsWithOperatorRegExp = RegExp(r'[\+\-\*\/]$');
final RegExp _startsWithOperatorRegExp = RegExp(r'^[\+\-\*\/]');

class _SecretSettingsScreenState extends ConsumerState<SecretSettingsScreen> {
  AppSettings _settings = AppSettings.defaults();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final String? currentStoredKey = prefs.getString(AppConstants.secretKeyPrefKey);

    setState(() {
      _isLoading = false;
      if (currentStoredKey != null) {
        _settings = _settings.copyWith(secretKey: currentStoredKey);
      }
    });
  }

  Future<void> _changeSecretKey() async {
    final currentSecretKeyController = TextEditingController();
    final newSecretKeyController = TextEditingController();
    final confirmSecretKeyController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: const Text('Gizli Alan Şifresini Değiştir'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: currentSecretKeyController,
                        decoration: const InputDecoration(
                          labelText: 'Mevcut şifre',
                          hintText: 'Örn: 1234+5678=',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Mevcut şifre boş olamaz';
                          }
                          if (value != _settings.secretKey) {
                            return 'Mevcut şifre yanlış';
                          }
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: newSecretKeyController,
                        decoration: const InputDecoration(
                          labelText: 'Yeni şifre ( = olmadan girin)',
                          hintText: 'Örn: 1234+5678',
                          border: OutlineInputBorder(),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(_allowedSecretKeyCharacters),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Yeni şifre boş olamaz';
                          }
                          if (value.endsWith('=')) {
                            return '= karakterini girmeyin';
                          }
                          if (value.length < 4) {
                            return 'Şifre en az 4 karakter olmalı';
                          }
                          if (_endsWithOperatorRegExp.hasMatch(value)) {
                            return 'Şifre operatör ile bitemez';
                          }
                          if (_startsWithOperatorRegExp.hasMatch(value)) {
                            return 'Şifre operatör ile başlayamaz';
                          }
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: confirmSecretKeyController,
                        decoration: const InputDecoration(
                          labelText: 'Yeni şifreyi doğrula ( = olmadan girin)',
                          hintText: 'Örn: 1234+5678',
                          border: OutlineInputBorder(),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(_allowedSecretKeyCharacters),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Doğrulama şifresi boş olamaz';
                          }
                          if (newSecretKeyController.text != value) {
                            return 'Yeni şifreler eşleşmiyor';
                          }
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sadece rakamlar ve +, -, ×, ÷ kullanın. Şifreniz otomatik olarak \'=\' ile sonlanacaktır.',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final String newKeyWithoutEquals = newSecretKeyController.text;
                      final String newKeyWithEquals = '$newKeyWithoutEquals=';
                      
                      final oldKey = _settings.secretKey;
                      setState(() {
                        _settings = _settings.copyWith(secretKey: newKeyWithEquals);
                      });
                      bool success = await _saveSecretKeyToPrefs(newKeyWithEquals);

                      if (success) {
                        Navigator.pop(context);
                        _showSuccessSnackBar('Şifre başarıyla değiştirildi.');
                      } else {
                        setState(() {
                          _settings = _settings.copyWith(secretKey: oldKey);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Şifre kaydedilirken bir hata oluştu.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Değiştir'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _saveSecretKeyToPrefs(String newSecretKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.secretKeyPrefKey, newSecretKey);
      debugPrint("Gizli şifre güncellendi ve kaydedildi: $newSecretKey");
      return true;
    } catch (e) {
      debugPrint("Gizli şifre kaydedilirken hata: $e");
      return false;
    }
  }

  void _updateAutoLockTime(int minutes) {
    setState(() {
      _settings = _settings.copyWith(autoLockTimeInMinutes: minutes);
    });
    // TODO: Save setting to repository
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hakkında'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Private Vault v${AppConstants.appVersion}'),
              const SizedBox(height: 8),
              const Text('Bu uygulama, özel verilerinizi güvenli bir şekilde saklamanıza yardımcı olmak için tasarlanmıştır.'),
              const SizedBox(height: 16),
              const Text('Gizlilik her şeyden önce gelir. Tüm verileriniz cihazınızda şifrelenmiş olarak saklanır ve hiçbir şekilde harici sunuculara gönderilmez.'),
              const SizedBox(height: 16),
              const Text('ismail hakkı kemikli tarafından flutter ile geliştirilmiştir.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  void _resetApp() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Uygulamayı Sıfırla'),
          content: const Text(
            'Bu işlem tüm verilerinizi silecek ve uygulamayı ilk kurulum durumuna getirecektir. Bu işlem geri alınamaz!',
            style: TextStyle(color: Colors.red),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                // TODO: Reset app data
                Navigator.pop(context);
                // Navigate to onboarding or login screen
              },
              child: const Text('Sıfırla', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _lockAndExit() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Kilitle ve Çık'),
          content: const Text('Gizli alandan çıkılacak ve uygulama kapatılacaktır. Devam etmek istiyor musunuz?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                // First exit the secret area (pop all routes until the calculator)
                Navigator.of(context).popUntil((route) => route.isFirst);
                
                // Then exit the app
                SystemNavigator.pop();
              },
              child: const Text('Kilitle ve Çık'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final bool isDarkMode = ref.watch(isDarkModeProvider);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Security section
          const Text(
            'Güvenlik',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.key),
                  title: const Text('Gizli Alan Şifresi'),
                  subtitle: const Text('Hesap makinesinde gireceğiniz gizli kodunuzu değiştirin'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _changeSecretKey,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.lock_clock),
                  title: const Text('Otomatik Kilitleme Süresi'),
                  subtitle: Text('${_settings.autoLockTimeInMinutes} dakika sonra'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Show dialog to change auto lock time
                    showDialog(
                      context: context,
                      builder: (context) {
                        int selectedTime = _settings.autoLockTimeInMinutes;
                        return AlertDialog(
                          title: const Text('Otomatik Kilitleme Süresi'),
                          content: StatefulBuilder(
                            builder: (BuildContext context, StateSetter setState) {
                              return DropdownButton<int>(
                                value: selectedTime,
                                items: [5, 10, 15, 30, 60]
                                    .map((time) => DropdownMenuItem(
                                          value: time,
                                          child: Text('$time dakika'),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedTime = value;
                                    });
                                  }
                                },
                              );
                            },
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('İptal'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _updateAutoLockTime(selectedTime);
                                Navigator.pop(context);
                              },
                              child: const Text('Kaydet'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.red),
                  title: const Text('Kilitle ve Çık'),
                  subtitle: const Text('Gizli alandan çık ve uygulamayı kapat'),
                  onTap: _lockAndExit,
                ),
              ],
            ),
          ),

          // Appearance section
          const SizedBox(height: 24),
          const Text(
            'Görünüm',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_6),
                  title: const Text('Karanlık Mod'),
                  trailing: Switch(
                    value: isDarkMode,
                    onChanged: (value) {
                      ref.read(isDarkModeProvider.notifier).state = value;
                    },
                  ),
                  onTap: () {
                    ref.read(isDarkModeProvider.notifier).state = !isDarkMode;
                  },
                ),
              ],
            ),
          ),

          // About section
          const SizedBox(height: 24),
          const Text(
            'Hakkında',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('Uygulama Bilgisi'),
                  subtitle: Text('Sürüm ${AppConstants.appVersion}'),
                  onTap: _showAboutDialog,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text(
                    'Uygulamayı Sıfırla',
                    style: TextStyle(color: Colors.red),
                  ),
                  subtitle: const Text('Tüm verileri sil ve baştan başla'),
                  onTap: _resetApp,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 