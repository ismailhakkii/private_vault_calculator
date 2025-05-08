import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:private_vault/core/constants/app_constants.dart';
import 'package:private_vault/presentation/pages/calculator/calculator_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  
  int _currentPage = 0;
  bool _showOnboardingAgain = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuint),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _animationController.reset();
    _animationController.forward();
  }

  void _nextPage() {
    if (_currentPage < AppConstants.onboardingTitles.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.hasCompletedOnboardingKey, true);
    
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const CalculatorScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: AppConstants.onboardingTitles.length,
                itemBuilder: (context, index) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildOnboardingPage(
                        title: AppConstants.onboardingTitles[index],
                        description: AppConstants.onboardingDescriptions[index],
                        index: index,
                      ),
                    ),
                  );
                },
              ),
            ),
            _buildBottomControls(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage({
    required String title,
    required String description,
    required int index,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Custom illustration based on index
          _buildIllustration(index),
          const SizedBox(height: 48),
          
          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          // Description
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.5,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration(int index) {
    final List<Color> gradientColors;
    IconData iconData;
    
    switch (index) {
      case 0:
        iconData = Icons.lock_open_rounded;
        gradientColors = [Colors.blue.shade300, Colors.blue.shade600];
        break;
      case 1:
        iconData = Icons.calculate_rounded;
        gradientColors = [Colors.orange.shade300, Colors.orange.shade600];
        break;
      case 2:
        iconData = Icons.key_rounded;
        gradientColors = [Colors.purple.shade300, Colors.purple.shade600];
        break;
      case 3:
        iconData = Icons.folder_special_rounded;
        gradientColors = [Colors.green.shade300, Colors.green.shade600];
        break;
      default:
        iconData = Icons.info_outline_rounded;
        gradientColors = [Colors.blue.shade300, Colors.blue.shade600];
    }

    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[1].withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(
        iconData,
        size: 80,
        color: Colors.white,
      ),
    );
  }

  Widget _buildBottomControls(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          // Dots indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              AppConstants.onboardingTitles.length,
              (index) => _buildDotIndicator(index == _currentPage),
            ),
          ),
          const SizedBox(height: 40),
          
          // Next button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: Text(
                _currentPage < AppConstants.onboardingTitles.length - 1
                    ? 'Devam Et'
                    : 'Başla',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          if (_currentPage == AppConstants.onboardingTitles.length - 1)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _showOnboardingAgain,
                    onChanged: (value) {
                      setState(() {
                        _showOnboardingAgain = value ?? false;
                      });
                    },
                  ),
                  const Text('Tekrar gösterme'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDotIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
} 