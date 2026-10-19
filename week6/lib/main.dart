import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const IndexEtfPortfolioApp());
}

class IndexEtfPortfolioApp extends StatelessWidget {
  const IndexEtfPortfolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '미국 지수 ETF 장기 자산 배분 대시보드',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A), // 네이비 블루 테마
          surface: const Color(0xFFF8FAFC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      home: const PortfolioDashboardScreen(),
    );
  }
}

class PortfolioDashboardScreen extends StatefulWidget {
  const PortfolioDashboardScreen({super.key});

  @override
  State<PortfolioDashboardScreen> createState() =>
      _PortfolioDashboardScreenState();
}

class _PortfolioDashboardScreenState extends State<PortfolioDashboardScreen> {
  // 1. 핵심 상태: ETF별 편입 비중 가중치 (기본값: VOO 50%, QQQM 30%, SCHD 20%)
  double _vooWeight = 50.0;
  double _qqqmWeight = 30.0;
  double _schdWeight = 20.0;

  // 2. 시뮬레이션 변수
  double _monthlyInvestment = 100.0; // 월 적립액 (만원 단위)
  double _investYears = 10.0; // 투자 기간 (년 단위)

  // ETF 기본 역사적 기대 CAGR (보수적 추정치)
  final double _vooCagr = 0.105; // 10.5%
  final double _qqqmCagr = 0.145; // 14.5%
  final double _schdCagr = 0.100; // 10.0%

  // 비중 정규화 게터 (합계 100% 기준)
  double get _totalWeight => _vooWeight + _qqqmWeight + _schdWeight;
  double get _vooRatio => _totalWeight == 0 ? 0 : (_vooWeight / _totalWeight);
  double get _qqqmRatio => _totalWeight == 0 ? 0 : (_qqqmWeight / _totalWeight);
  double get _schdRatio => _totalWeight == 0 ? 0 : (_schdWeight / _totalWeight);

  // 포트폴리오 가중 평균 기대 수익률 (Expected CAGR)
  double get _portfolioExpectedCagr =>
      (_vooRatio * _vooCagr) +
      (_qqqmRatio * _qqqmCagr) +
      (_schdRatio * _schdCagr);

  // 총 납입 원금 (만원)
  double get _totalPrincipal => _monthlyInvestment * 12 * _investYears;

  // 복리 미래가치 계산 공식 (Future Value of Monthly Annuity)
  // FV = P * [ ((1 + r/12)^(12*t) - 1) / (r/12) ]
  double get _futurePortfolioValue {
    final double r = _portfolioExpectedCagr;
    final double n = 12 * _investYears;
    final double monthlyRate = r / 12;

    if (monthlyRate == 0) return _totalPrincipal;
    return _monthlyInvestment * ((pow(1 + monthlyRate, n) - 1) / monthlyRate);
  }

  // 복리 수익금
  double get _totalCompoundReturn => _futurePortfolioValue - _totalPrincipal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.candlestick_chart_rounded, size: 28),
            SizedBox(width: 10),
            Text(
              '미국 지수 ETF 장기 자산 배분',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              // 1. 포트폴리오 미래 자산 요약 카드
              _buildSummaryCard(theme),
              const SizedBox(height: 20),

              // 2. 비중 조절 패널 (VOO, QQQM, SCHD)
              _buildAllocationSliders(theme),
              const SizedBox(height: 20),

              // 3. 적립식 시뮬레이션 매개변수 설정
              _buildSimulationControls(theme),
              const SizedBox(height: 20),

              // 4. 자산군 세부 스펙 및 리밸런싱 가이드
              _buildEtfDetailComparison(),
            ],
          ),
        ),
      ),
    );
  }

  // 상단 성과 요약 위젯
  Widget _buildSummaryCard(ThemeData theme) {
    final expectedCagrPercent = (_portfolioExpectedCagr * 100).toStringAsFixed(
      1,
    );
    final principalStr = _totalPrincipal.toStringAsFixed(0);
    final futureValStr = _futurePortfolioValue.toStringAsFixed(0);
    final profitStr = _totalCompoundReturn.toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '예상 최종 포트폴리오 가치',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: Text(
                  '기대 CAGR: +$expectedCagrPercent%',
                  style: const TextStyle(
                    color: Color(0xFF34D399),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '약 $futureValStr 만원',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricColumn('투자 원금', '$principalStr 만원', Colors.white70),
              Container(height: 30, width: 1, color: Colors.white24),
              _buildMetricColumn(
                '복리 창출 수익',
                '+$profitStr 만원',
                const Color(0xFF38BDF8),
              ),
              Container(height: 30, width: 1, color: Colors.white24),
              _buildMetricColumn(
                '투자 기간',
                '${_investYears.toInt()}년 적립',
                Colors.white70,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white60),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // 비중 조절 슬라이더 패널
  Widget _buildAllocationSliders(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '포트폴리오 자산 배분 비중',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // 시각적 비중 바
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 14,
                child: Row(
                  children: [
                    Expanded(
                      flex: (_vooRatio * 1000).toInt(),
                      child: Container(color: const Color(0xFF2563EB)),
                    ),
                    Expanded(
                      flex: (_qqqmRatio * 1000).toInt(),
                      child: Container(color: const Color(0xFF7C3AED)),
                    ),
                    Expanded(
                      flex: (_schdRatio * 1000).toInt(),
                      child: Container(color: const Color(0xFF059669)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            _buildSliderRow(
              name: 'VOO (S&P 500 시장 지수)',
              ratio: _vooRatio,
              color: const Color(0xFF2563EB),
              value: _vooWeight,
              onChanged: (val) => setState(() => _vooWeight = val),
            ),
            _buildSliderRow(
              name: 'QQQM (나스닥 100 기술 성장)',
              ratio: _qqqmRatio,
              color: const Color(0xFF7C3AED),
              value: _qqqmWeight,
              onChanged: (val) => setState(() => _qqqmWeight = val),
            ),
            _buildSliderRow(
              name: 'SCHD (배당성장 100 앵커)',
              ratio: _schdRatio,
              color: const Color(0xFF059669),
              value: _schdWeight,
              onChanged: (val) => setState(() => _schdWeight = val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow({
    required String name,
    required double ratio,
    required Color color,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    final percent = (ratio * 100).toStringAsFixed(0);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            Text(
              '$percent%',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: color,
                fontSize: 15,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            thumbColor: color,
            overlayColor: color.withOpacity(0.15),
            trackHeight: 4,
          ),
          child: Slider(value: value, min: 0, max: 100, onChanged: onChanged),
        ),
      ],
    );
  }

  // 월 적립금 및 투자 기간 슬라이더
  Widget _buildSimulationControls(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '장기 적립 시뮬레이션 조건',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('월 적립 투자금', style: TextStyle(fontSize: 14)),
                Text(
                  '${_monthlyInvestment.toInt()} 만원',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            Slider(
              value: _monthlyInvestment,
              min: 10,
              max: 500,
              divisions: 49,
              onChanged: (val) => setState(() => _monthlyInvestment = val),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('투자 기간 (년)', style: TextStyle(fontSize: 14)),
                Text(
                  '${_investYears.toInt()} 년',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            Slider(
              value: _investYears,
              min: 3,
              max: 30,
              divisions: 27,
              onChanged: (val) => setState(() => _investYears = val),
            ),
          ],
        ),
      ),
    );
  }

  // 하단 ETF 특성 카드
  Widget _buildEtfDetailComparison() {
    return Column(
      children: [
        _buildInfoTile('VOO (S&P 500)', '0.03%', '1.5%', '시장 전체의 안정적 성장 동력'),
        const SizedBox(height: 8),
        _buildInfoTile('QQQM (나스닥 100)', '0.15%', '0.6%', '빅테크 중심 자본차익 극대화'),
        const SizedBox(height: 8),
        _buildInfoTile('SCHD (미국배당다우존스)', '0.06%', '3.5%', '하락장 방어 및 배당 복리 엔진'),
      ],
    );
  }

  Widget _buildInfoTile(
    String ticker,
    String expense,
    String dividend,
    String desc,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ticker,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '보수: $expense',
                style: const TextStyle(fontSize: 11, color: Colors.black87),
              ),
              Text(
                '배당률: $dividend',
                style: const TextStyle(fontSize: 11, color: Color(0xFF059669)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
