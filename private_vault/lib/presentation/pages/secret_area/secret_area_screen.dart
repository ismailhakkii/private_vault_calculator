import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_vault/presentation/pages/calculator/calculator_screen.dart';
import 'package:private_vault/presentation/pages/secret_area/files/secret_files_screen.dart';
import 'package:private_vault/presentation/pages/secret_area/notes/secret_notes_screen.dart';
import 'package:private_vault/presentation/pages/secret_area/settings/secret_settings_screen.dart';

class SecretAreaScreen extends ConsumerStatefulWidget {
  const SecretAreaScreen({super.key});

  @override
  ConsumerState<SecretAreaScreen> createState() => _SecretAreaScreenState();
}

class _SecretAreaScreenState extends ConsumerState<SecretAreaScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const SecretFilesScreen(),
    const SecretNotesScreen(),
    const SecretSettingsScreen(),
  ];

  void _returnToCalculator() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesap Makinesine Dön'),
        content: const Text('Hesap makinesi moduna dönmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const CalculatorScreen()),
              );
            },
            child: const Text('Evet, Dön'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gizli Alan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate),
            tooltip: 'Hesap Makinesine Dön',
            onPressed: _returnToCalculator,
          ),
          IconButton(
            icon: const Icon(Icons.lock),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const CalculatorScreen()),
                (Route<dynamic> route) => false,
              );
              
              Future.delayed(const Duration(milliseconds: 100), () {
                SystemNavigator.pop();
              });
            },
            tooltip: 'Kilitle ve Çık',
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: 'Dosyalarım',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note),
            label: 'Notlarım',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
} 