import 'package:flutter/material.dart';

void main() {
  runApp(const WindowsCalculatorApp());
}

class WindowsCalculatorApp extends StatelessWidget {
  const WindowsCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Windows 스타일 계산기',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF202020),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0078D7),
          surface: Color(0xFF202020),
        ),
        useMaterial3: true,
      ),
      home: const WindowsCalculatorPage(),
    );
  }
}

class WindowsCalculatorPage extends StatefulWidget {
  const WindowsCalculatorPage({super.key});

  @override
  State<WindowsCalculatorPage> createState() => _WindowsCalculatorPageState();
}

class _WindowsCalculatorPageState extends State<WindowsCalculatorPage> {
  // 상태 변수
  String _display = '0'; // 메인 표시 숫자
  String _expression = ''; // 상단 수식 (예: 12 +)
  double? _firstOperand;
  String? _operator;
  bool _shouldResetDisplay = false;

  // 버튼 클릭 핸들러
  void _onButtonPressed(String label) {
    setState(() {
      if (RegExp(r'^[0-9]$').hasMatch(label)) {
        _inputDigit(label);
      } else if (label == '.') {
        _inputDecimal();
      } else if (label == 'C') {
        _clearAll();
      } else if (label == 'CE') {
        _clearEntry();
      } else if (label == '⌫') {
        _backspace();
      } else if (label == '±') {
        _toggleSign();
      } else if (['+', '-', '×', '÷'].contains(label)) {
        _setOperator(label);
      } else if (label == '=') {
        _calculateResult();
      }
    });
  }

  void _inputDigit(String digit) {
    if (_display == '0' || _shouldResetDisplay) {
      _display = digit;
      _shouldResetDisplay = false;
    } else {
      _display += digit;
    }
  }

  void _inputDecimal() {
    if (_shouldResetDisplay) {
      _display = '0.';
      _shouldResetDisplay = false;
      return;
    }
    if (!_display.contains('.')) {
      _display += '.';
    }
  }

  void _clearAll() {
    _display = '0';
    _expression = '';
    _firstOperand = null;
    _operator = null;
    _shouldResetDisplay = false;
  }

  void _clearEntry() {
    _display = '0';
  }

  void _backspace() {
    if (_shouldResetDisplay) return;
    if (_display.length > 1) {
      _display = _display.substring(0, _display.length - 1);
    } else {
      _display = '0';
    }
  }

  void _toggleSign() {
    if (_display == '0') return;
    if (_display.startsWith('-')) {
      _display = _display.substring(1);
    } else {
      _display = '-$_display';
    }
  }

  void _setOperator(String op) {
    final double currentValue = double.tryParse(_display) ?? 0;

    if (_firstOperand != null && _operator != null && !_shouldResetDisplay) {
      _performCalculation(currentValue);
    } else {
      _firstOperand = currentValue;
    }

    _operator = op;
    _expression = '${_formatNumber(_firstOperand!)} $op';
    _shouldResetDisplay = true;
  }

  void _calculateResult() {
    if (_firstOperand == null || _operator == null) return;

    final double secondOperand = double.tryParse(_display) ?? 0;
    _expression =
        '${_formatNumber(_firstOperand!)} $_operator ${_formatNumber(secondOperand)} =';

    _performCalculation(secondOperand);

    _firstOperand = null;
    _operator = null;
    _shouldResetDisplay = true;
  }

  void _performCalculation(double secondOperand) {
    double result = 0;
    switch (_operator) {
      case '+':
        result = _firstOperand! + secondOperand;
        break;
      case '-':
        result = _firstOperand! - secondOperand;
        break;
      case '×':
        result = _firstOperand! * secondOperand;
        break;
      case '÷':
        if (secondOperand == 0) {
          _display = '0으로 나눌 수 없습니다';
          _firstOperand = null;
          _operator = null;
          _shouldResetDisplay = true;
          return;
        }
        result = _firstOperand! / secondOperand;
        break;
    }
    _display = _formatNumber(result);
    _firstOperand = result;
  }

  String _formatNumber(double num) {
    if (num == num.toInt()) {
      return num.toInt().toString();
    }
    // 소수점 6자리까지 깔끔하게 반올림
    String str = num.toStringAsFixed(6);
    while (str.contains('.') && (str.endsWith('0') || str.endsWith('.'))) {
      str = str.substring(0, str.length - 1);
    }
    return str;
  }

  @override
  Widget build(BuildContext context) {
    // 키패드 배치 (Windows 계산기 표준 6행 구조)
    final List<List<String>> buttons = [
      ['CE', 'C', '⌫', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['±', '0', '.', '='],
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.calculate_outlined, size: 20, color: Colors.white70),
            SizedBox(width: 8),
            Text(
              '표준',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF202020),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380, maxHeight: 620),
            child: Column(
              children: [
                // 1. 디스플레이 영역 (수식 및 메인 숫자)
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    alignment: Alignment.bottomRight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // 상단 이전 수식 라인
                        Text(
                          _expression,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white54,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // 현재 입력/결과 숫자
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            _display,
                            style: const TextStyle(
                              fontSize: 54,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1, color: Color(0xFF2D2D2D)),

                // 2. 키패드 그리드 영역 (버튼들)
                Expanded(
                  flex: 7,
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Column(
                      children: buttons.map((row) {
                        return Expanded(
                          child: Row(
                            children: row.map((label) {
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: _buildCalculatorButton(label),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Windows 계산기 룩앤필 버튼 위젯
  Widget _buildCalculatorButton(String label) {
    Color bgColor = const Color(0xFF3B3B3B); // 일반 숫자 버튼 색
    Color fgColor = Colors.white;
    FontWeight fontWeight = FontWeight.w500;

    final bool isOperator = ['÷', '×', '-', '+'].contains(label);
    final bool isFunction = ['CE', 'C', '⌫', '±'].contains(label);
    final bool isEqual = label == '=';

    if (isEqual) {
      bgColor = const Color(0xFF0078D7); // Windows 포인트 블루
      fgColor = Colors.white;
      fontWeight = FontWeight.bold;
    } else if (isOperator || isFunction) {
      bgColor = const Color(0xFF323232); // 기능/연산자 버튼 (더 짙은 회색)
      if (isOperator) {
        fontWeight = FontWeight.bold;
      }
    }

    return ElevatedButton(
      onPressed: () => _onButtonPressed(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: EdgeInsets.zero,
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 20, fontWeight: fontWeight),
      ),
    );
  }
}
