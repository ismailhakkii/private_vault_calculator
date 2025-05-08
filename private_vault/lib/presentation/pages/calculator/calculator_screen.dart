import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_vault/app/theme.dart';
import 'package:private_vault/core/constants/app_constants.dart';
import 'package:private_vault/domain/entities/calculator_operation.dart';
import 'package:private_vault/presentation/bloc/calculator_controller.dart';
import 'package:private_vault/presentation/pages/secret_area/secret_area_screen.dart';
import 'package:private_vault/app/app.dart';
import 'package:private_vault/presentation/bloc/calculator_state.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _buttonPressAnimation;
  int? _activeButtonIndex;
  bool _isAcademicMode = false;
  bool _isLandscape = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    
    _buttonPressAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    // Set preferred orientations for academic mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Reset to portrait mode only when exiting
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _animationController.dispose();
    super.dispose();
  }

  void _animateButton(int index, VoidCallback onPressed) {
    setState(() {
      _activeButtonIndex = index;
    });
    
    _animationController.forward().then((_) {
      _animationController.reverse().then((_) {
        setState(() {
          _activeButtonIndex = null;
        });
        onPressed();
      });
    });
  }

  void _toggleDarkMode() {
    final isDarkMode = ref.read(isDarkModeProvider);
    ref.read(isDarkModeProvider.notifier).state = !isDarkMode;
  }

  void _toggleAcademicMode() {
    setState(() {
      _isAcademicMode = !_isAcademicMode;
      
      // If switching to academic mode, suggest landscape
      if (_isAcademicMode) {
        _showOrientationHint();
      }
    });
  }
  
  void _showOrientationHint() {
    final orientation = MediaQuery.of(context).orientation;
    if (orientation == Orientation.portrait && _isAcademicMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daha fazla işlem için yatay moda geçebilirsiniz'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(calculatorControllerProvider.notifier);
    final state = ref.watch(calculatorControllerProvider);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final orientation = MediaQuery.of(context).orientation;
    _isLandscape = orientation == Orientation.landscape;
    
    // Check if secret key was entered
    if (state.isSecretKeyEntered) {
      Future.delayed(const Duration(milliseconds: 300), () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SecretAreaScreen()),
        );
      });
    }
    
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        backgroundColor: isDarkMode
            ? theme.colorScheme.surface
            : theme.colorScheme.primary.withOpacity(0.95),
        title: Text(
          AppConstants.appName,
          style: TextStyle(
            color: isDarkMode
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isAcademicMode ? Icons.calculate : Icons.functions),
            onPressed: _toggleAcademicMode,
            tooltip: _isAcademicMode ? 'Standart Mod' : 'Akademik Mod',
          ),
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: _toggleDarkMode,
            tooltip: isDarkMode ? 'Açık Tema' : 'Koyu Tema',
          ),
          IconButton(
            icon: Icon(state.shouldShowHistory ? Icons.keyboard : Icons.history),
            onPressed: controller.toggleHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          // Display section
          _buildDisplaySection(state, theme, isDarkMode),
          
          // History or keypad
          Expanded(
            child: state.shouldShowHistory 
                ? _buildHistoryView(state, controller) 
                : _isAcademicMode 
                    ? _buildAcademicKeypad(isDarkMode, controller) 
                    : _buildKeypad(isDarkMode, controller),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplaySection(CalculatorState state, ThemeData theme, bool isDarkMode) {
    final operationTextStyle = TextStyle(
      fontSize: 24,
      color: theme.colorScheme.onSurface.withOpacity(0.7),
      fontWeight: FontWeight.w400,
    );

    final resultTextStyle = TextStyle(
      fontSize: 56,
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.bold,
    );

    // Build operation display text
    String operationText = '';
    if (state.previousOperand.isNotEmpty) {
      String operationSymbol = '';
      switch (state.currentOperation) {
        case OperationType.addition:
          operationSymbol = '+';
          break;
        case OperationType.subtraction:
          operationSymbol = '-';
          break;
        case OperationType.multiplication:
          operationSymbol = '×';
          break;
        case OperationType.division:
          operationSymbol = '÷';
          break;
        case OperationType.percentage:
          operationSymbol = '%';
          break;
        case OperationType.power:
          operationSymbol = '^';
          break;
        default:
          operationSymbol = '';
      }
      operationText = '${_formatOperand(state.previousOperand)} $operationSymbol ${state.currentOperand.isEmpty ? '' : _formatOperand(state.currentOperand)}';
    } else if (state.currentOperation == OperationType.sqrt && state.currentOperand.isNotEmpty) {
      operationText = '√${_formatOperand(state.currentOperand)}';
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800.withOpacity(0.5) : Colors.grey.shade100.withOpacity(0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
      alignment: Alignment.bottomRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Operation
          if (operationText.isNotEmpty)
            Text(
              operationText,
              style: operationTextStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 10),
          
          // Result
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Text(
              _formatOperand(state.display),
              style: resultTextStyle,
              maxLines: 1,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryView(CalculatorState state, CalculatorController controller) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // History header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'İşlem Geçmişi',
                style: theme.textTheme.titleMedium,
              ),
              if (state.history.isNotEmpty)
                TextButton.icon(
                  onPressed: controller.clearHistory,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: const Text('Temizle'),
                ),
            ],
          ),
        ),
        
        // History list
        Expanded(
          child: state.history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: theme.colorScheme.onBackground.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz işlem geçmişi yok',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onBackground.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: state.history.length,
                  separatorBuilder: (_, __) => Divider(
                    color: theme.colorScheme.onBackground.withOpacity(0.1),
                  ),
                  itemBuilder: (context, index) {
                    final operation = state.history[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(operation.displayText),
                      subtitle: Text(
                        '${operation.timestamp.hour}:${operation.timestamp.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onBackground.withOpacity(0.5),
                        ),
                      ),
                      trailing: Text(
                        operation.result,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      onTap: () {
                        controller.handleClear();
                        controller.handleOperation(operation.operationType);
                        for (var digit in operation.result.split('')) {
                          if (digit == '.') {
                            controller.handleDecimal();
                          } else if (digit == '-') {
                            // Do nothing for negative sign
                          } else {
                            controller.handleNumber(digit);
                          }
                        }
                        controller.toggleHistory();
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildKeypad(bool isDarkMode, CalculatorController controller) {
    final buttonStyle = _getButtonStyle(isDarkMode);
    final operatorButtonStyle = _getOperatorButtonStyle(isDarkMode);
    final specialOperatorButtonStyle = _getSpecialOperatorButtonStyle(isDarkMode);
    final equalsButtonStyle = _getEqualsButtonStyle(isDarkMode);

    final List<List<Map<String, dynamic>>> buttonRows = [
      [
        {'text': 'AC', 'action': controller.handleClear, 'style': specialOperatorButtonStyle},
        {'text': '⌫', 'action': controller.handleClearEntry, 'style': specialOperatorButtonStyle},
        {'text': '%', 'action': () => controller.handleOperation(OperationType.percentage), 'style': operatorButtonStyle},
        {'text': '÷', 'action': () => controller.handleOperation(OperationType.division), 'style': operatorButtonStyle},
      ],
      [
        {'text': '7', 'action': () => controller.handleNumber('7'), 'style': buttonStyle},
        {'text': '8', 'action': () => controller.handleNumber('8'), 'style': buttonStyle},
        {'text': '9', 'action': () => controller.handleNumber('9'), 'style': buttonStyle},
        {'text': '×', 'action': () => controller.handleOperation(OperationType.multiplication), 'style': operatorButtonStyle},
      ],
      [
        {'text': '4', 'action': () => controller.handleNumber('4'), 'style': buttonStyle},
        {'text': '5', 'action': () => controller.handleNumber('5'), 'style': buttonStyle},
        {'text': '6', 'action': () => controller.handleNumber('6'), 'style': buttonStyle},
        {'text': '-', 'action': () => controller.handleOperation(OperationType.subtraction), 'style': operatorButtonStyle},
      ],
      [
        {'text': '1', 'action': () => controller.handleNumber('1'), 'style': buttonStyle},
        {'text': '2', 'action': () => controller.handleNumber('2'), 'style': buttonStyle},
        {'text': '3', 'action': () => controller.handleNumber('3'), 'style': buttonStyle},
        {'text': '+', 'action': () => controller.handleOperation(OperationType.addition), 'style': operatorButtonStyle},
      ],
      [
        {'text': '0', 'action': () => controller.handleNumber('0'), 'style': buttonStyle, 'flex': 2},
        {'text': '.', 'action': controller.handleDecimal, 'style': buttonStyle},
        {'text': '=', 'action': controller.handleEquals, 'style': equalsButtonStyle},
      ],
    ];

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: buttonRows.map((row) {
          return Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: row.map((buttonData) {
                final int flex = buttonData['flex'] ?? 1;
                return Expanded(
                  flex: flex,
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: _buildCalcButton(
                      buttonData['text'] as String,
                      buttonData['action'] as VoidCallback,
                      buttonData['style'] as ButtonStyle,
                      ValueKey(buttonData['text'] as String),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAcademicKeypad(bool isDarkMode, CalculatorController controller) {
    final buttonStyle = _getButtonStyle(isDarkMode, academic: true);
    final operatorButtonStyle = _getOperatorButtonStyle(isDarkMode, academic: true);
    final specialOperatorButtonStyle = _getSpecialOperatorButtonStyle(isDarkMode, academic: true);
    final equalsButtonStyle = _getEqualsButtonStyle(isDarkMode, academic: true);
    final funcButtonStyle = _getFunctionButtonStyle(isDarkMode);

    // Define button layout with scientific features
    List<List<Map<String, dynamic>>> academicButtonRows = [];
    
    if (_isLandscape) {
      // Enhanced scientific calculator in landscape mode
      academicButtonRows = [
        [
          {'text': 'sin', 'action': () => controller.handleOperation(OperationType.sin), 'style': funcButtonStyle},
          {'text': 'cos', 'action': () => controller.handleOperation(OperationType.cos), 'style': funcButtonStyle},
          {'text': 'tan', 'action': () => controller.handleOperation(OperationType.tan), 'style': funcButtonStyle},
          {'text': 'log', 'action': () => controller.handleOperation(OperationType.log), 'style': funcButtonStyle},
          {'text': 'ln', 'action': () => controller.handleOperation(OperationType.ln), 'style': funcButtonStyle},
          {'text': 'AC', 'action': controller.handleClear, 'style': specialOperatorButtonStyle},
          {'text': '⌫', 'action': controller.handleClearEntry, 'style': specialOperatorButtonStyle},
          {'text': '%', 'action': () => controller.handleOperation(OperationType.percentage), 'style': operatorButtonStyle},
        ],
        [
          {'text': 'π', 'action': () => controller.handleOperation(OperationType.pi), 'style': funcButtonStyle},
          {'text': 'e', 'action': () => controller.handleOperation(OperationType.e), 'style': funcButtonStyle},
          {'text': '|x|', 'action': () => controller.handleOperation(OperationType.abs), 'style': funcButtonStyle},
          {'text': 'x!', 'action': () => controller.handleOperation(OperationType.factorial), 'style': funcButtonStyle},
          {'text': '1/x', 'action': () => controller.handleOperation(OperationType.inv), 'style': funcButtonStyle},
          {'text': '7', 'action': () => controller.handleNumber('7'), 'style': buttonStyle},
          {'text': '8', 'action': () => controller.handleNumber('8'), 'style': buttonStyle},
          {'text': '9', 'action': () => controller.handleNumber('9'), 'style': buttonStyle},
        ],
        [
          {'text': '(', 'action': () => controller.handleOperation(OperationType.parenthesesOpen), 'style': funcButtonStyle},
          {'text': ')', 'action': () => controller.handleOperation(OperationType.parenthesesClose), 'style': funcButtonStyle},
          {'text': '√', 'action': () => controller.handleOperation(OperationType.sqrt), 'style': funcButtonStyle},
          {'text': 'x²', 'action': () => {
            controller.handleOperation(OperationType.power), 
            controller.handleNumber('2')
          }, 'style': funcButtonStyle},
          {'text': 'x^y', 'action': () => controller.handleOperation(OperationType.power), 'style': funcButtonStyle},
          {'text': '4', 'action': () => controller.handleNumber('4'), 'style': buttonStyle},
          {'text': '5', 'action': () => controller.handleNumber('5'), 'style': buttonStyle},
          {'text': '6', 'action': () => controller.handleNumber('6'), 'style': buttonStyle},
        ],
        [
          {'text': 'ANS', 'action': () { /* Placeholder for future answer recall */ }, 'style': funcButtonStyle},
          {'text': '×', 'action': () => controller.handleOperation(OperationType.multiplication), 'style': operatorButtonStyle},
          {'text': '÷', 'action': () => controller.handleOperation(OperationType.division), 'style': operatorButtonStyle},
          {'text': '+', 'action': () => controller.handleOperation(OperationType.addition), 'style': operatorButtonStyle},
          {'text': '-', 'action': () => controller.handleOperation(OperationType.subtraction), 'style': operatorButtonStyle},
          {'text': '1', 'action': () => controller.handleNumber('1'), 'style': buttonStyle},
          {'text': '2', 'action': () => controller.handleNumber('2'), 'style': buttonStyle},
          {'text': '3', 'action': () => controller.handleNumber('3'), 'style': buttonStyle},
        ],
        [
          {'text': '=', 'action': controller.handleEquals, 'style': equalsButtonStyle, 'flex': 5},
          {'text': '0', 'action': () => controller.handleNumber('0'), 'style': buttonStyle, 'flex': 2},
          {'text': '.', 'action': controller.handleDecimal, 'style': buttonStyle},
        ],
      ];
    } else {
      // Smaller set of scientific functions in portrait mode
      academicButtonRows = [
        [
          {'text': 'AC', 'action': controller.handleClear, 'style': specialOperatorButtonStyle},
          {'text': '⌫', 'action': controller.handleClearEntry, 'style': specialOperatorButtonStyle},
          {'text': '√', 'action': () => controller.handleOperation(OperationType.sqrt), 'style': operatorButtonStyle},
          {'text': '^', 'action': () => controller.handleOperation(OperationType.power), 'style': operatorButtonStyle},
        ],
        [
          {'text': 'sin', 'action': () => controller.handleOperation(OperationType.sin), 'style': funcButtonStyle},
          {'text': 'cos', 'action': () => controller.handleOperation(OperationType.cos), 'style': funcButtonStyle},
          {'text': 'tan', 'action': () => controller.handleOperation(OperationType.tan), 'style': funcButtonStyle},
          {'text': '÷', 'action': () => controller.handleOperation(OperationType.division), 'style': operatorButtonStyle},
        ],
        [
          {'text': '7', 'action': () => controller.handleNumber('7'), 'style': buttonStyle},
          {'text': '8', 'action': () => controller.handleNumber('8'), 'style': buttonStyle},
          {'text': '9', 'action': () => controller.handleNumber('9'), 'style': buttonStyle},
          {'text': '×', 'action': () => controller.handleOperation(OperationType.multiplication), 'style': operatorButtonStyle},
        ],
        [
          {'text': '4', 'action': () => controller.handleNumber('4'), 'style': buttonStyle},
          {'text': '5', 'action': () => controller.handleNumber('5'), 'style': buttonStyle},
          {'text': '6', 'action': () => controller.handleNumber('6'), 'style': buttonStyle},
          {'text': '-', 'action': () => controller.handleOperation(OperationType.subtraction), 'style': operatorButtonStyle},
        ],
        [
          {'text': '1', 'action': () => controller.handleNumber('1'), 'style': buttonStyle},
          {'text': '2', 'action': () => controller.handleNumber('2'), 'style': buttonStyle},
          {'text': '3', 'action': () => controller.handleNumber('3'), 'style': buttonStyle},
          {'text': '+', 'action': () => controller.handleOperation(OperationType.addition), 'style': operatorButtonStyle},
        ],
        [
          {'text': '0', 'action': () => controller.handleNumber('0'), 'style': buttonStyle, 'flex': 2},
          {'text': '.', 'action': controller.handleDecimal, 'style': buttonStyle},
          {'text': '=', 'action': controller.handleEquals, 'style': equalsButtonStyle},
        ],
      ];
    }
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: academicButtonRows.map((row) {
          return Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: row.map((buttonData) {
                final int flex = buttonData['flex'] ?? 1;
                return Expanded(
                  flex: flex,
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: _buildCalcButton(
                      buttonData['text'] as String,
                      buttonData['action'] as VoidCallback,
                      buttonData['style'] as ButtonStyle,
                      ValueKey(buttonData['text'] as String),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalcButton(String text, VoidCallback onPressed, ButtonStyle style, Key key) {
    final int buttonIndex = text.hashCode;

    return ScaleTransition(
      key: key,
      scale: _activeButtonIndex == buttonIndex ? _buttonPressAnimation : const AlwaysStoppedAnimation(1.0),
      child: ElevatedButton(
        onPressed: () => _animateButton(buttonIndex, onPressed),
        style: style,
        child: FittedBox(
          child: Text(
            text,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  ButtonStyle _getButtonStyle(bool isDarkMode, {bool academic = false}) {
    final ColorScheme colorScheme = isDarkMode ? AppTheme.darkTheme().colorScheme : AppTheme.lightTheme().colorScheme;
    return ElevatedButton.styleFrom(
      backgroundColor: isDarkMode ? AppTheme.calculatorPrimaryColor.withOpacity(0.3) : colorScheme.surfaceVariant,
      foregroundColor: colorScheme.onSurfaceVariant,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(academic ? 16 : 12)),
      padding: EdgeInsets.symmetric(vertical: academic ? 18 : 16, horizontal: 10),
    );
  }

  ButtonStyle _getOperatorButtonStyle(bool isDarkMode, {bool academic = false}) {
    final ColorScheme colorScheme = isDarkMode ? AppTheme.darkTheme().colorScheme : AppTheme.lightTheme().colorScheme;
    return ElevatedButton.styleFrom(
      backgroundColor: isDarkMode ? AppTheme.calculatorSecondaryColor.withOpacity(0.5) : AppTheme.primaryColor.withOpacity(0.1),
      foregroundColor: isDarkMode ? Colors.white : AppTheme.primaryColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(academic ? 16 : 12)),
      padding: EdgeInsets.symmetric(vertical: academic ? 18 : 16, horizontal: 10),
    );
  }
  
  ButtonStyle _getSpecialOperatorButtonStyle(bool isDarkMode, {bool academic = false}) {
    final ColorScheme colorScheme = isDarkMode ? AppTheme.darkTheme().colorScheme : AppTheme.lightTheme().colorScheme;
    return ElevatedButton.styleFrom(
      backgroundColor: isDarkMode ? AppTheme.calculatorAccentColor.withOpacity(0.4) : AppTheme.secondaryColor.withOpacity(0.1),
      foregroundColor: isDarkMode ? Colors.white : AppTheme.secondaryColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(academic ? 16 : 12)),
      padding: EdgeInsets.symmetric(vertical: academic ? 18 : 16, horizontal: 10),
    );
  }

  ButtonStyle _getEqualsButtonStyle(bool isDarkMode, {bool academic = false}) {
    return ElevatedButton.styleFrom(
      backgroundColor: isDarkMode ? AppTheme.secondaryColor : AppTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(academic ? 16 : 12)),
      padding: EdgeInsets.symmetric(vertical: academic ? 18 : 16, horizontal: 10),
    );
  }

  ButtonStyle _getFunctionButtonStyle(bool isDarkMode) {
    final ColorScheme colorScheme = isDarkMode ? AppTheme.darkTheme().colorScheme : AppTheme.lightTheme().colorScheme;
    return ElevatedButton.styleFrom(
      backgroundColor: isDarkMode 
          ? colorScheme.tertiaryContainer.withOpacity(0.6) 
          : colorScheme.tertiaryContainer.withOpacity(0.7),
      foregroundColor: colorScheme.onTertiaryContainer,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
    );
  }

  String _formatOperand(String operand) {
    if (operand.isEmpty || operand == "Error" || operand == "Infinity" || operand == "NaN") {
      return operand;
    }
    try {
      List<String> parts = operand.split('.');
      String integerPart = parts[0];
      String? decimalPart = parts.length > 1 ? parts[1] : null;

      integerPart = integerPart.replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      
      if (decimalPart != null) {
        return '$integerPart.$decimalPart';
      }
      return integerPart;
    } catch (e) {
      return operand;
    }
  }
} 