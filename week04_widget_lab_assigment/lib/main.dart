import 'package:flutter/material.dart';

void main() {
  runApp(const WidgetLabApp());
}

class WidgetLabApp extends StatelessWidget {
  const WidgetLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '4주차 과제 - 위젯 조합 모바일 화면',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const GoalTrackerHomePage(),
    );
  }
}

class GoalItem {
  final String title;
  bool isCompleted;

  GoalItem({required this.title, this.isCompleted = false});
}

class GoalTrackerHomePage extends StatefulWidget {
  const GoalTrackerHomePage({super.key});

  @override
  State<GoalTrackerHomePage> createState() => _GoalTrackerHomePageState();
}

class _GoalTrackerHomePageState extends State<GoalTrackerHomePage> {
  final TextEditingController _textController = TextEditingController();

  final List<GoalItem> _goals = [
    GoalItem(title: 'Flutter 기본 위젯 공식 문서 읽기', isCompleted: true),
    GoalItem(title: 'Column과 ListView 조합 레이아웃 완성', isCompleted: true),
    GoalItem(title: 'flutter analyze 경고 0건 달성하기', isCompleted: false),
  ];

  int get _completedCount => _goals.where((g) => g.isCompleted).length;

  // [신규] 달성률 비율 계산 (0.0 ~ 1.0)
  double get _progressRate =>
      _goals.isEmpty ? 0.0 : _completedCount / _goals.length;

  void _addGoal() {
    final String text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _goals.add(GoalItem(title: text, isCompleted: false));
      _textController.clear();
    });
  }

  void _toggleGoal(int index) {
    setState(() {
      _goals[index].isCompleted = !_goals[index].isCompleted;
    });
  }

  void _deleteGoal(int index) {
    setState(() {
      _goals.removeAt(index);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // [신규] 달성률 정수 퍼센트 (예: 67%)
    final int progressPercent = (_progressRate * 100).toInt();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '학습 목표 관리 대시보드',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // 1. 상단 통계 요약 카드 + 달성률 프로그레스 바
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // 통계 개수 행
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      icon: Icons.checklist_rounded,
                      label: '전체 목표',
                      value: '${_goals.length}개',
                      iconColor: theme.colorScheme.primary,
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: theme.colorScheme.outlineVariant,
                    ),
                    _buildStatItem(
                      icon: Icons.task_alt_rounded,
                      label: '달성 완료',
                      value: '$_completedCount개',
                      iconColor: Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // [신규] 달성률 레이블 & 퍼센트 텍스트
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '목표 달성률',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      '$progressPercent%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // [신규] 둥근 모서리의 게이지 바
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progressRate,
                    minHeight: 10,
                    backgroundColor: theme.colorScheme.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progressPercent == 100 ? Colors.green : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. 신규 목표 입력 바
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: '새로운 학습 목표 입력',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _addGoal(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _addGoal,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('추가'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. 목표 목록 스크롤 뷰
          Expanded(
            child: _goals.isEmpty
                ? const Center(
                    child: Text(
                      '등록된 목표가 없습니다.\n새 목표를 추가해보세요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _goals.length,
                    itemBuilder: (context, index) {
                      final item = _goals[index];
                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: IconButton(
                            icon: Icon(
                              item.isCompleted
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color:
                                  item.isCompleted ? Colors.green : Colors.grey,
                            ),
                            onPressed: () => _toggleGoal(index),
                          ),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              decoration: item.isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color: item.isCompleted
                                  ? Colors.grey
                                  : theme.textTheme.bodyLarge?.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent),
                            onPressed: () => _deleteGoal(index),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 28, color: iconColor),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}