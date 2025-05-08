import 'package:private_vault/domain/entities/calculator_operation.dart';

class CalculatorState {
  final String display;
  final String currentOperand;
  final String previousOperand;
  final OperationType currentOperation;
  final bool hasResult;
  final bool isSecretKeyEntered;
  final bool shouldShowHistory;
  final List<CalculatorOperation> history;

  const CalculatorState({
    this.display = '0',
    this.currentOperand = '',
    this.previousOperand = '',
    this.currentOperation = OperationType.none,
    this.hasResult = false,
    this.isSecretKeyEntered = false,
    this.shouldShowHistory = false,
    this.history = const [],
  });

  CalculatorState copyWith({
    String? display,
    String? currentOperand,
    String? previousOperand,
    OperationType? currentOperation,
    bool? hasResult,
    bool? isSecretKeyEntered,
    bool? shouldShowHistory,
    List<CalculatorOperation>? history,
  }) {
    return CalculatorState(
      display: display ?? this.display,
      currentOperand: currentOperand ?? this.currentOperand,
      previousOperand: previousOperand ?? this.previousOperand,
      currentOperation: currentOperation ?? this.currentOperation,
      hasResult: hasResult ?? this.hasResult,
      isSecretKeyEntered: isSecretKeyEntered ?? this.isSecretKeyEntered,
      shouldShowHistory: shouldShowHistory ?? this.shouldShowHistory,
      history: history ?? this.history,
    );
  }
} 