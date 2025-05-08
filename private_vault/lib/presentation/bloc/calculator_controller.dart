import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_vault/core/constants/app_constants.dart';
import 'package:private_vault/domain/entities/calculator_operation.dart';
import 'package:private_vault/presentation/bloc/calculator_state.dart';

final calculatorControllerProvider = StateNotifierProvider<CalculatorController, CalculatorState>((ref) {
  return CalculatorController();
});

class CalculatorController extends StateNotifier<CalculatorState> {
  CalculatorController() : super(const CalculatorState());

  // Handle number button press
  void handleNumber(String number) {
    if (state.hasResult) {
      // If we have a result, start fresh
      state = state.copyWith(
        display: number,
        currentOperand: number,
        previousOperand: '',
        currentOperation: OperationType.none,
        hasResult: false,
      );
    } else if (state.currentOperand == '0') {
      // Replace the zero with the number
      state = state.copyWith(
        display: number,
        currentOperand: number,
      );
    } else {
      // Append the number to the current operand
      final updatedOperand = state.currentOperand + number;
      state = state.copyWith(
        display: updatedOperand,
        currentOperand: updatedOperand,
      );
    }
  }

  // Handle decimal point
  void handleDecimal() {
    if (state.hasResult) {
      // If we have a result, start fresh with a decimal
      state = state.copyWith(
        display: '0.',
        currentOperand: '0.',
        previousOperand: '',
        currentOperation: OperationType.none,
        hasResult: false,
      );
    } else if (!state.currentOperand.contains('.')) {
      // Add decimal point if not already there
      final updatedOperand = state.currentOperand.isEmpty 
          ? '0.' 
          : '${state.currentOperand}.';
      
      state = state.copyWith(
        display: updatedOperand,
        currentOperand: updatedOperand,
      );
    }
  }

  // Handle operation button press
  void handleOperation(OperationType operation) {
    // Don't allow operations if there's an error displayed
    if (state.display == 'Error') {
      return;
    }

    // Special cases for operations that work on a single operand
    List<OperationType> singleOperandOperations = [
      OperationType.sqrt, 
      OperationType.sin, 
      OperationType.cos, 
      OperationType.tan, 
      OperationType.log, 
      OperationType.ln, 
      OperationType.factorial,
      OperationType.abs,
      OperationType.inv,
    ];
    
    List<OperationType> constantOperations = [
      OperationType.pi,
      OperationType.e,
    ];
    
    // For single operand functions like sin, cos, etc.
    if (constantOperations.contains(operation)) {
      _handleConstantOperation(operation);
      return;
    }
    
    // Handle opening/closing parentheses separately
    if (operation == OperationType.parenthesesOpen || operation == OperationType.parenthesesClose) {
      _handleParentheses(operation);
      return;
    }

    // If both operands are empty, don't allow operation except for single operand functions
    if (state.currentOperand.isEmpty && state.previousOperand.isEmpty && !singleOperandOperations.contains(operation)) {
      return;
    }
    
    // Handle single operand operations
    if (singleOperandOperations.contains(operation) && state.currentOperand.isNotEmpty) {
      final result = _calculateSingleOperand(operation, state.currentOperand);
      
      final calculatorOperation = CalculatorOperation(
        firstOperand: state.currentOperand,
        secondOperand: '',
        operationType: operation,
        result: result,
        timestamp: DateTime.now(),
      );
      
      state = state.copyWith(
        display: result,
        currentOperand: result,
        previousOperand: '',
        currentOperation: OperationType.none,
        hasResult: true,
        history: [...state.history, calculatorOperation],
      );
      return;
    }
    
    // If we have a result, use it for the next operation
    if (state.hasResult && state.currentOperand.isNotEmpty) {
      state = state.copyWith(
        previousOperand: state.currentOperand,
        currentOperand: '',
        currentOperation: operation,
        hasResult: false,
      );
      return;
    }

    // If both operands have values, calculate the result and prepare for next operation
    if (state.previousOperand.isNotEmpty && state.currentOperand.isNotEmpty) {
      final result = _calculate();
      
      final calculatorOperation = CalculatorOperation(
        firstOperand: state.previousOperand,
        secondOperand: state.currentOperand,
        operationType: state.currentOperation,
        result: result,
        timestamp: DateTime.now(),
      );
      
      state = state.copyWith(
        history: [...state.history, calculatorOperation],
      );
      
      // If next operation is a single operand function, set up for it
      if (singleOperandOperations.contains(operation)) {
        state = state.copyWith(display: result, currentOperand: result, previousOperand: '', currentOperation: OperationType.none, hasResult: true);
        return;
      }
      
      state = state.copyWith(
        display: result,
        previousOperand: result,
        currentOperand: '',
        currentOperation: operation,
        hasResult: false,
      );
    } else {
      // Set up for the operation
      state = state.copyWith(
        previousOperand: state.currentOperand, // currentOperand could be empty if user presses op, then number, then another op
        currentOperand: '',
        currentOperation: operation,
        hasResult: false,
      );
    }
  }

  // Handle constants like π and e
  void _handleConstantOperation(OperationType operation) {
    String value = '';
    
    switch (operation) {
      case OperationType.pi:
        value = math.pi.toString();
        break;
      case OperationType.e:
        value = math.e.toString();
        break;
      default:
        return;
    }
    
    final calculatorOperation = CalculatorOperation(
      firstOperand: '',
      secondOperand: '',
      operationType: operation,
      result: value,
      timestamp: DateTime.now(),
    );
    
    // If we're in the middle of an operation, use as second operand
    if (state.previousOperand.isNotEmpty && state.currentOperation != OperationType.none) {
      state = state.copyWith(
        currentOperand: value,
        display: value,
      );
    } else {
      // Otherwise just display and set as current operand
      state = state.copyWith(
        currentOperand: value,
        display: value,
        history: [...state.history, calculatorOperation],
      );
    }
  }
  
  // Handle opening and closing parentheses (placeholder for future expression parsing)
  void _handleParentheses(OperationType operation) {
    // This would require a more complex expression parsing system
    // For now, we'll just show a message
    state = state.copyWith(
      display: 'Coming soon',
    );
    
    // Reset after a delay
    Future.delayed(const Duration(seconds: 1), () {
      if (state.display == 'Coming soon') {
        state = state.copyWith(
          display: state.currentOperand.isEmpty ? '0' : state.currentOperand,
        );
      }
    });
  }

  // Handle equals button
  void handleEquals() {
    if (state.currentOperand.isEmpty || state.previousOperand.isEmpty) {
      return; // Not enough operands
    }

    final result = _calculate();
    final operation = CalculatorOperation(
      firstOperand: state.previousOperand,
      secondOperand: state.currentOperand,
      operationType: state.currentOperation,
      result: result,
      timestamp: DateTime.now(),
    );

    // Check if this is the secret key
    final enteredKey = '${state.previousOperand}${_getOperationSymbol()}${state.currentOperand}=';
    final isSecretKey = enteredKey == AppConstants.defaultSecretKey;

    state = state.copyWith(
      display: result,
      previousOperand: '',
      currentOperand: result,
      currentOperation: OperationType.none,
      hasResult: true,
      isSecretKeyEntered: isSecretKey,
      history: [...state.history, operation],
    );
  }

  // Handle clear button
  void handleClear() {
    state = state.copyWith(
      display: '0',
      currentOperand: '',
      previousOperand: '',
      currentOperation: OperationType.none,
      hasResult: false,
      isSecretKeyEntered: false,
    );
  }

  // Handle clear entry button (CE / backspace)
  void handleClearEntry() {
    if (state.currentOperand.isNotEmpty) {
      // Remove last digit
      String newOperand = state.currentOperand.substring(0, state.currentOperand.length - 1);
      state = state.copyWith(
        currentOperand: newOperand,
        display: newOperand.isEmpty ? '0' : newOperand,
      );
    } else if (state.previousOperand.isNotEmpty && state.currentOperation != OperationType.none) {
      // If current operand is empty but there's a previous operand and operation,
      // allow editing previous operand
      state = state.copyWith(
        currentOperand: state.previousOperand,
        previousOperand: '',
        currentOperation: OperationType.none,
        display: state.previousOperand,
      );
    }
  }

  // Toggle history view
  void toggleHistory() {
    state = state.copyWith(
      shouldShowHistory: !state.shouldShowHistory,
    );
  }

  // Clear history
  void clearHistory() {
    state = state.copyWith(
      history: [],
    );
  }

  // Reset secret key entered flag
  void resetSecretKeyEntered() {
    state = state.copyWith(
      isSecretKeyEntered: false,
    );
  }

  // Calculate result
  String _calculate() {
    if (state.previousOperand.isEmpty || state.currentOperand.isEmpty) {
      // Square root and other single operand operations handled separately
      if (state.currentOperation == OperationType.sqrt && state.currentOperand.isNotEmpty) {
        final curr = double.parse(state.currentOperand);
        if (curr < 0) return 'Error'; // Square root of negative number error
        final result = math.sqrt(curr);
        if (result == result.toInt()) {
          return result.toInt().toString();
        }
        return result.toString();
      }
      
      return state.currentOperand.isEmpty ? state.previousOperand : state.currentOperand;
    }

    final prev = double.parse(state.previousOperand);
    final curr = double.parse(state.currentOperand);
    double result = 0;

    switch (state.currentOperation) {
      case OperationType.addition:
        result = prev + curr;
        break;
      case OperationType.subtraction:
        result = prev - curr;
        break;
      case OperationType.multiplication:
        result = prev * curr;
        break;
      case OperationType.division:
        if (curr == 0) {
          return 'Error'; // Division error
        }
        result = prev / curr;
        break;
      case OperationType.percentage:
        // Calculate percentage of prev: prev * (curr/100)
        result = prev * (curr / 100);
        break;
      case OperationType.power: 
        result = math.pow(prev, curr).toDouble();
        break;
      case OperationType.sqrt: 
        if (curr < 0) return 'Error';
        result = math.sqrt(curr); // Usually single operand, prev is ignored
        break;
      case OperationType.none:
        return state.currentOperand;
      default:
        return 'Error'; // Unknown operation
    }

    // Format result (remove .0 if integer)
    if (result.isNaN || result.isInfinite) {
        return 'Error';
    }
    if (result == result.toInt()) {
      return result.toInt().toString();
    }
    // Round to 8 decimal places for better precision
    return double.parse(result.toStringAsFixed(8)).toString().replaceAll(RegExp(r'0*$'),'').replaceAll(RegExp(r'\.$'),'');
  }

  // Get operation symbol for display or secret key check
  String _getOperationSymbol() {
    switch (state.currentOperation) {
      case OperationType.addition:
        return '+';
      case OperationType.subtraction:
        return '-';
      case OperationType.multiplication:
        return '×'; // or *
      case OperationType.division:
        return '÷'; // or /
      case OperationType.percentage:
        return '%';
      case OperationType.power:
        return '^';
      case OperationType.sqrt:
        return '√';
      case OperationType.sin:
        return 'sin';
      case OperationType.cos:
        return 'cos';
      case OperationType.tan:
        return 'tan';
      case OperationType.log:
        return 'log';
      case OperationType.ln:
        return 'ln';
      case OperationType.factorial:
        return '!';
      case OperationType.pi:
        return 'π';
      case OperationType.e:
        return 'e';
      case OperationType.abs:
        return '|';
      case OperationType.inv:
        return '1/';
      case OperationType.parenthesesOpen:
        return '(';
      case OperationType.parenthesesClose:
        return ')';
      case OperationType.none:
        return '';
    }
  }

  String _calculateSingleOperand(OperationType operation, String operand) {
    if (operand.isEmpty) return 'Error';
    final val = double.parse(operand);
    double result = 0;

    switch (operation) {
      case OperationType.sqrt:
        if (val < 0) return 'Error';
        result = math.sqrt(val);
        break;
      case OperationType.sin:
        // Convert to radians if needed
        result = math.sin(val * (math.pi / 180)); // Assuming degrees input
        break;
      case OperationType.cos:
        result = math.cos(val * (math.pi / 180)); // Assuming degrees input
        break;
      case OperationType.tan:
        result = math.tan(val * (math.pi / 180)); // Assuming degrees input
        break;
      case OperationType.log:
        if (val <= 0) return 'Error';
        result = math.log(val) / math.ln10; // log base 10
        break;
      case OperationType.ln:
        if (val <= 0) return 'Error';
        result = math.log(val); // natural log
        break;
      case OperationType.factorial:
        if (val < 0 || val != val.floor()) return 'Error'; // Must be non-negative integer
        if (val > 170) return 'Error'; // Prevent overflow
        result = _factorial(val.toInt()).toDouble();
        break;
      case OperationType.abs:
        result = val.abs();
        break;
      case OperationType.inv:
        if (val == 0) return 'Error';
        result = 1 / val;
        break;
      default:
        return 'Error'; // Should not happen for other ops
    }
    
    if (result.isNaN || result.isInfinite) {
        return 'Error';
    }
    if (result == result.toInt()) {
      return result.toInt().toString();
    }
    return double.parse(result.toStringAsFixed(8)).toString().replaceAll(RegExp(r'0*$'),'').replaceAll(RegExp(r'\.$'),'');
  }
  
  // Helper method for factorial calculation
  int _factorial(int n) {
    if (n == 0 || n == 1) return 1;
    return n * _factorial(n - 1);
  }
} 