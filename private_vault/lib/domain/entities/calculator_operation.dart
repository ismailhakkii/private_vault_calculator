enum OperationType {
  addition,
  subtraction,
  multiplication,
  division,
  percentage,
  power,
  sqrt,
  // Advanced scientific operations
  sin,
  cos,
  tan,
  log,
  ln,
  factorial,
  pi,
  e,
  abs,
  inv, // 1/x
  parenthesesOpen,
  parenthesesClose,
  none,
}

class CalculatorOperation {
  final String firstOperand;
  final String secondOperand;
  final OperationType operationType;
  final String result;
  final DateTime timestamp;

  const CalculatorOperation({
    required this.firstOperand,
    required this.secondOperand,
    required this.operationType,
    required this.result,
    required this.timestamp,
  });

  String get displayText {
    final String operatorSymbol = _getOperatorSymbol();
    
    // Special handling for functions
    if (operationType == OperationType.sqrt) {
      return '$operatorSymbol$firstOperand = $result';
    } else if (operationType == OperationType.sin || 
              operationType == OperationType.cos || 
              operationType == OperationType.tan ||
              operationType == OperationType.log ||
              operationType == OperationType.ln ||
              operationType == OperationType.factorial ||
              operationType == OperationType.abs ||
              operationType == OperationType.inv) {
      return '$operatorSymbol($firstOperand) = $result';
    } else if (operationType == OperationType.pi || operationType == OperationType.e) {
      return '$operatorSymbol = $result';
    }
    
    return '$firstOperand $operatorSymbol $secondOperand = $result';
  }

  String _getOperatorSymbol() {
    switch (operationType) {
      case OperationType.addition:
        return '+';
      case OperationType.subtraction:
        return '-';
      case OperationType.multiplication:
        return '×';
      case OperationType.division:
        return '÷';
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

  // For storing in database
  Map<String, dynamic> toMap() {
    return {
      'firstOperand': firstOperand,
      'secondOperand': secondOperand,
      'operationType': operationType.index,
      'result': result,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  // Create from database
  factory CalculatorOperation.fromMap(Map<String, dynamic> map) {
    return CalculatorOperation(
      firstOperand: map['firstOperand'] as String,
      secondOperand: map['secondOperand'] as String,
      operationType: OperationType.values[map['operationType'] as int],
      result: map['result'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }
} 