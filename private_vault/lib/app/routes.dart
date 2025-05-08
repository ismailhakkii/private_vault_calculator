import 'package:flutter/material.dart';
import 'package:private_vault/presentation/pages/calculator/calculator_screen.dart';
import 'package:private_vault/presentation/pages/onboarding/onboarding_screen.dart';
import 'package:private_vault/presentation/pages/secret_area/secret_area_screen.dart';

class AppRoutes {
  // Route names
  static const String calculator = '/calculator';
  static const String onboarding = '/onboarding';
  static const String secretArea = '/secret_area';

  // Route generation
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case calculator:
        return MaterialPageRoute(builder: (_) => const CalculatorScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case secretArea:
        return MaterialPageRoute(builder: (_) => const SecretAreaScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
} 