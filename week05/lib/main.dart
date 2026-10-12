import 'package:flutter/material.dart';

void main() {
  runApp(const StateManagementLabApp());
}

class StateManagementLabApp extends StatelessWidget {
  const StateManagementLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '5주차 - Flutter 상태 관리 실습',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF0FDF4), // 은은한 민트/아이보리 배경
        useMaterial3: true,
      ),
      home: const TodoStatePage(),
    );
  }
}

/// [1. 데이터 모델 정의]
/// 할 일 항목의 상태를 나타내는 데이터 클래스입니다.
/// title(제목)과 isCompleted(완료 여부)라는 '상태(State)'를 가집니다.
class TodoItem {
  final String title;
  bool isCompleted;

  TodoItem({required this.title, this.isCompleted = false});
}

/// [2. StatefulWidget 선언]
/// 시간에 따라, 혹은 사용자의 인터랙션(버튼 탭)에 따라 변하는 상태 데이터를
/// 보유하고 화면을 갱신해야 하므로 StatefulWidget을 사용합니다.
class TodoStatePage extends StatefulWidget {
  const TodoStatePage({super.key});

  @override
  State<TodoStatePage> createState() => _TodoStatePageState();
}

class _TodoStatePageState extends State<TodoStatePage> {
  /// [3. 앱의 핵심 '상태(State)' 데이터]
  /// 스크린샷에 등장하는 두 개의 할 일 데이터를 초기 상태로 정의합니다.
  final List<TodoItem> _todoList = [
    TodoItem(title: '5주차 강의 복습', isCompleted: false),
    TodoItem(title: '상태 흐름도 작성', isCompleted: false),
  ];

  /// [4. 파생된 상태 (Derived State / 계산된 프로퍼티)]
  /// '남은 할 일 수'는 별도의 변수로 따로 저장할 필요 없이,
  /// 원본 _todoList의 완료되지 않은 항목 개수를 실시간으로 계산(filtering)합니다.
  /// 이렇게 하면 데이터 불일치(Single Source of Truth 위반) 버그를 방지할 수 있습니다.
  int get _remainingCount =>
      _todoList.where((item) => !item.isCompleted).length;

  /// [5. 핵심 상태 관리 메서드: 단일 진실 공급원(SSOT) 갱신]
  /// 스크린샷의 "버튼 한 번에 달라지는 두 곳"의 원리가 작동하는 곳입니다.
  ///
  /// 동작 원리:
  /// 1) 사용자가 특정 행의 [완료] / [취소] 버튼을 누르면 이 함수가 호출됩니다.
  /// 2) setState() 내부에서 해당 아이템의 isCompleted 불리언 값을 반전(!isCompleted)시킵니다.
  /// 3) setState()가 Flutter 엔진에게 "위젯 트리가 더러워졌으니(dirty) 다시 빌드하라!"고 알립니다.
  /// 4) build() 메서드가 재실행되면서 동일한 하나의 데이터 변경으로 인해:
  ///    - [달라지는 곳 1]: 상단 '남은 할 일'의 숫자 Text 위젯이 다시 계산되어 바뀜 (2 -> 1)
  ///    - [달라지는 곳 2]: 하단 해당 할 일 카드의 아이콘, 배경색, 버튼 글자가 바뀜 ([완료] -> [취소])
  void _toggleTodoStatus(int index) {
    setState(() {
      _todoList[index].isCompleted = !_todoList[index].isCompleted;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 테마 색상 설정 (스크린샷 색상과 동일하게 구성)
    const borderColor = Color(0xFF1E293B); // 카드 외곽 네이비 테두리
    const primaryGreen = Color(0xFF14B8A6); // 포인트 청록/에메랄드 그린

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 상단 설명 헤더 (스크린샷 내용)
              const Text(
                '버튼 한 번에 달라지는 두 곳',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '첫 할 일을 완료하면 카드 표시와 남은 할 일 수가 함께 바뀝니다.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 28),

              // ========================================================
              // [메인 카드]: 스크린샷 속 "나의 할 일" 컨테이너
              // ========================================================
              Container(
                width: 320,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  // 두꺼운 다크 네이비 테두리
                  border: Border.all(color: borderColor, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 카드 타이틀
                    const Text(
                      '나의 할 일',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF1F5F9),
                    ),
                    const SizedBox(height: 16),

                    // ----------------------------------------------------
                    // [달라지는 곳 1]: 남은 할 일 개수 UI
                    // _todoList의 상태가 바뀌면 build()가 다시 돌면서
                    // _remainingCount 게터가 새 개수를 즉시 반환하여 텍스트가 바뀝니다.
                    // ----------------------------------------------------
                    Row(
                      children: [
                        const Text(
                          '남은 할 일 ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '$_remainingCount',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: primaryGreen, // 강조 청록색
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ----------------------------------------------------
                    // [달라지는 곳 2]: 할 일 항목 목록 UI
                    // 각 아이템의 isCompleted 상태에 따라 체크 아이콘,
                    // 배경색, 오른쪽 버튼 텍스트가 달라집니다.
                    // ----------------------------------------------------
                    Column(
                      children: List.generate(_todoList.length, (index) {
                        final item = _todoList[index];
                        return _buildTodoRow(
                          item: item,
                          primaryGreen: primaryGreen,
                          onToggle: () => _toggleTodoStatus(index),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// [단일 할 일 카드 렌더링 함수]
  /// isCompleted 상태 값에 따라 외형이 조건부 렌더링됩니다.
  Widget _buildTodoRow({
    required TodoItem item,
    required Color primaryGreen,
    required VoidCallback onToggle,
  }) {
    final bool isDone = item.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        // 완료 상태면 은은한 민트색 배경, 미완료면 흰색
        color: isDone ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // 상태 표시 아이콘 (완료: 체크 표시 / 미완료: 빈 원)
          Icon(
            isDone ? Icons.check_rounded : Icons.circle_outlined,
            size: 20,
            color: isDone ? primaryGreen : const Color(0xFF64748B),
          ),
          const SizedBox(width: 10),

          // 할 일 제목 텍스트
          Expanded(
            child: Text(
              item.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isDone ? FontWeight.w600 : FontWeight.w500,
                color: isDone ? Colors.black87 : const Color(0xFF334155),
              ),
            ),
          ),

          // 완료/취소 토글 버튼
          InkWell(
            onTap: onToggle, // 버튼을 누르면 상태 변경 함수 호출
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDone
                    ? const Color(0xFFE2E8F0)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isDone ? '취소' : '완료',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDone
                      ? const Color(0xFF64748B)
                      : const Color(0xFF0D9488),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
