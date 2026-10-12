import 'package:flutter/material.dart';

void main() {
  runApp(const UnitConverterApp());
}

class UnitConverterApp extends StatelessWidget {
  const UnitConverterApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 메인 컬러: 딥 로열 블루, 서브 컬러: 앰버 오렌지
    const primaryBlue = Color(0xFF1E40AF);
    const secondaryAmber = Color(0xFFF59E0B);

    return MaterialApp(
      title: '단위 & 환율 변환기',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          primary: primaryBlue,
          secondary: secondaryAmber,
          surface: const Color(0xFFF8FAFC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const ConverterHomePage(),
    );
  }
}

class ConverterHomePage extends StatefulWidget {
  const ConverterHomePage({super.key});

  @override
  State<ConverterHomePage> createState() => _ConverterHomePageState();
}

class _ConverterHomePageState extends State<ConverterHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _inputController = TextEditingController();
  String _resultText = '0.00';

  // 변환 방향 상태 (true: 왼쪽 단위 -> 오른쪽 단위)
  bool _isForward = true;

  // 고정 환율 기준 (1 USD = 1,350 KRW)
  final double _usdToKrwRate = 1350.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _inputController.clear();
        setState(() {
          _resultText = '0.00';
          _isForward = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  // 실시간 변환 로직
  void _convert(String value) {
    if (value.trim().isEmpty) {
      setState(() => _resultText = '0.00');
      return;
    }

    final double? input = double.tryParse(value);
    if (input == null) {
      setState(() => _resultText = '입력 오류');
      return;
    }

    double result = 0.0;
    switch (_tabController.index) {
      // 1. 온도: 섭씨(°C) ↔ 화씨(°F)
      case 0:
        result = _isForward ? (input * 9 / 5) + 32 : (input - 32) * 5 / 9;
        break;

      // 2. 길이: 센티미터(cm) ↔ 인치(inch)
      case 1:
        result = _isForward ? input / 2.54 : input * 2.54;
        break;

      // 3. 환율: 원화(KRW) ↔ 달러(USD)
      case 2:
        result = _isForward ? input / _usdToKrwRate : input * _usdToKrwRate;
        break;
    }

    setState(() {
      // 통화 원화 변환 시 정수로 출력, 그 외 소수점 2자리
      if (_tabController.index == 2 && !_isForward) {
        _resultText = result.toStringAsFixed(0);
      } else {
        _resultText = result.toStringAsFixed(2);
      }
    });
  }

  // 단위 맞교환(Swap)
  void _swapUnits() {
    setState(() {
      _isForward = !_isForward;
      _convert(_inputController.text);
    });
  }

  // 탭별 라벨 정보 가져오기
  (String from, String to, String hint, IconData icon) _getUnitLabels() {
    switch (_tabController.index) {
      case 0:
        return _isForward
            ? ('섭씨 (°C)', '화씨 (°F)', '섭씨 온도 입력', Icons.thermostat_outlined)
            : ('화씨 (°F)', '섭씨 (°C)', '화씨 온도 입력', Icons.thermostat_outlined);
      case 1:
        return _isForward
            ? ('센티미터 (cm)', '인치 (inch)', '길이(cm) 입력', Icons.straighten_outlined)
            : (
                '인치 (inch)',
                '센티미터 (cm)',
                '길이(inch) 입력',
                Icons.straighten_outlined,
              );
      case 2:
        return _isForward
            ? (
                '원화 (₩)',
                '달러 (\$)',
                '금액(원) 입력',
                Icons.currency_exchange_outlined,
              )
            : (
                '달러 (\$)',
                '원화 (₩)',
                '금액(달러) 입력',
                Icons.currency_exchange_outlined,
              );
      default:
        return ('', '', '', Icons.swap_horiz);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (fromLabel, toLabel, hintText, tabIcon) = _getUnitLabels();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sync_alt_rounded, size: 24),
            SizedBox(width: 8),
            Text(
              '단위 & 환율 변환기',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.secondary,
          indicatorWeight: 4,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.thermostat), text: '온도'),
            Tab(icon: Icon(Icons.straighten), text: '길이'),
            Tab(icon: Icon(Icons.attach_money), text: '환율'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. 상단 단위 전환 카드
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '변환 전',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                fromLabel,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 스왑 버튼 (서브 앰버 컬러)
                        IconButton.filled(
                          onPressed: _swapUnits,
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.secondary,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.swap_horiz_rounded),
                          tooltip: '단위 맞바꾸기',
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                '변환 후',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                toLabel,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 2. 입력 필드
                TextField(
                  controller: _inputController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  onChanged: _convert,
                  decoration: InputDecoration(
                    labelText: fromLabel,
                    hintText: hintText,
                    prefixIcon: Icon(tabIcon, color: theme.colorScheme.primary),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 3. 변환 결과 카드
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 18,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '변환 결과 ($toLabel)',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _resultText,
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      if (_tabController.index == 2) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withOpacity(
                              0.12,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '기준 환율: 1 USD = ${_usdToKrwRate.toInt()} KRW',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ),
                      ],
                    ],
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
