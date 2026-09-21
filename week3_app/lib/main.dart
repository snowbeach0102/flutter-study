import 'package:flutter/material.dart';

void main() {
  runApp(const AddCalculatorApp());
}

class AddCalculatorApp extends StatelessWidget {
  const AddCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '덧셈 계산기',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const CalculatorHomePage(),
    );
  }
}

class CalculatorHomePage extends StatefulWidget {
  const CalculatorHomePage({super.key});

  @override
  State<CalculatorHomePage> createState() => _CalculatorHomePageState();
}

class _CalculatorHomePageState extends State<CalculatorHomePage> {
  // 두 개의 입력을 제어할 컨트롤러
  final TextEditingController _num1Controller = TextEditingController();
  final TextEditingController _num2Controller = TextEditingController();

  // 계산 결과 문자열 저장 변수
  String _resultText = '결과가 여기에 표시됩니다.';

  // 덧셈 실행 함수
  void _calculateSum() {
    final String text1 = _num1Controller.text.trim();
    final String text2 = _num2Controller.text.trim();

    // 입력값 검증 (숫자 파싱)
    final double? num1 = double.tryParse(text1);
    final double? num2 = double.tryParse(text2);

    setState(() {
      if (num1 == null || num2 == null) {
        _resultText = '⚠️ 두 칸 모두 올바른 숫자를 입력해주세요.';
      } else {
        final double sum = num1 + num2;
        // 소수점 0으로 끝나면 정수로 깔끔하게 출력
        if (sum == sum.toInt()) {
          _resultText = '결과: ${sum.toInt()}';
        } else {
          _resultText = '결과: $sum';
        }
      }
    });
  }

  @override
  void dispose() {
    _num1Controller.dispose();
    _num2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('간단 덧셈 계산기'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            // 세로 배치를 위한 Column 위젯
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1번째 숫자 입력 필드
                TextField(
                  controller: _num1Controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: '첫 번째 숫자',
                    hintText: '숫자를 입력하세요',
                    prefixIcon: Icon(Icons.looks_one_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // 2번째 숫자 입력 필드
                TextField(
                  controller: _num2Controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: '두 번째 숫자',
                    hintText: '숫자를 입력하세요',
                    prefixIcon: Icon(Icons.looks_two_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // 더하기 버튼
                ElevatedButton.icon(
                  onPressed: _calculateSum,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text(
                    '두 수 더하기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 32),

                // 계산 결과 출력 카드
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Text(
                    _resultText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
}
