// ============================================================================
// [5주차 과제: 상태 기능과 작업 컨텍스트]
// 파일명: lib/main.dart
// 목표: 단일 상태 변경에 반응하는 선언형 UI 동기화 및 단일 진실 공급원(SSOT) 구현
// ============================================================================
//
// [동작 원리 및 아키텍처 개요]
// 1. 상태 소유권 (State Ownership):
//    - 최상위 위젯인 _TodoStatePageState가 원본 상태인 `_todoList`의 유일한 소유자입니다.
//    - 하위 리스트 항목 위젯은 상태를 직접 수정하지 않으며, 콜백(onToggle)을 통해서만
//      소유자에게 상태 변경을 요청(State Lifting / 단방향 데이터 흐름)합니다.
//
// 2. 단일 진실 공급원 (SSOT) 및 계산값 분리 (AC4 만족):
//    - '남은 할 일 수'는 별도의 int 변수로 저장하지 않습니다.
//    - Getter인 `_remainingCount`를 통해 `_todoList`에서 실시간으로 계산(Derived State)하여,
//      상태 불일치 및 데이터 중복 저장 버그를 원천 차단합니다.
//
// 3. 이벤트 -> 상태 -> UI 흐름도 (Event-driven Rebuild):
//    - [Event]: 사용자가 카드 행 전체 또는 버튼을 탭 (InkWell onTap)
//    - [Handler]: _toggleTodoStatus(index) 실행
//    - [Mutation]: setState() 내부에서 _todoList[index].isCompleted 토글 (!isCompleted)
//    - [Rebuild]: Flutter 엔진이 build() 재호출
//    - [Sync - 달라지는 두 곳]:
//      1) 상단 남은 할 일 수 카운터 Text가 2 -> 1로 갱신 (AC2)
//      2) 해당 카드의 배경색(민트), 아이콘(체크), 배지 텍스트('취소')가 동시 변경 (AC2)
//    - [Revert]: 동일 항목을 다시 터치하면 이전 상태로 완벽히 원복 (AC3)
// ============================================================================

import 'package:flutter/material.dart';

void main() {
  runApp(const StateManagementLabApp());
}

class StateManagementLabApp extends StatelessWidget {
  const StateManagementLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '5주차 과제 - Flutter 상태 관리',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF14B8A6)),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        useMaterial3: true,
      ),
      home: const TodoStatePage(),
    );
  }
}

/// [데이터 모델]
/// 개별 할 일의 제목과 완료 상태를 보관하는 독립 데이터 클래스
class TodoItem {
  final String title;
  bool isCompleted;

  TodoItem({required this.title, this.isCompleted = false});
}

/// [StatefulWidget]
/// 동적으로 상태가 변경되는 메인 화면 위젯
class TodoStatePage extends StatefulWidget {
  const TodoStatePage({super.key});

  @override
  State<TodoStatePage> createState() => _TodoStatePageState();
}

class _TodoStatePageState extends State<TodoStatePage> {
  // [원본 상태 (Source of Truth)] - AC1: 초기값 2개 미완료 상태 정의
  final List<TodoItem> _todoList = [
    TodoItem(title: '5주차 강의 복습', isCompleted: false),
    TodoItem(title: '상태 흐름도 작성', isCompleted: false),
  ];

  // [파생 상태 (Derived State)] - AC4: 별도 원본 변수로 저장하지 않고 실시간 계산
  int get _remainingCount =>
      _todoList.where((item) => !item.isCompleted).length;

  // [상태 갱신 메서드] - AC2, AC3: 토글 동작 및 역동작 처리
  void _toggleTodoStatus(int index) {
    setState(() {
      _todoList[index].isCompleted = !_todoList[index].isCompleted;
    });
  }

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFF1E293B); // 카드 외곽 다크 네이비 테두리
    const primaryGreen = Color(0xFF14B8A6); // 포인트 청록색

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '5주차 상태 기능 실습',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFE2E8F0), height: 1.0),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 헤더 안내 텍스트
              const Text(
                '버튼 한 번에 달라지는 두 곳',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '첫 할 일을 완료하면 카드 표시와 남은 할 일 수가 함께 바뀝니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 28),

              // ========================================================
              // [메인 카드 컨테이너]: 스크린샷 인터페이스 완벽 재현
              // ========================================================
              Container(
                width: 340,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: borderColor, width: 3.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 카드 제목
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

                    // [달라지는 곳 1]: 남은 할 일 수 표시
                    Row(
                      children: [
                        const Text(
                          '남은 할 일 ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                        Text(
                          '$_remainingCount',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // [달라지는 곳 2]: 할 일 항목 목록 (행 전체 인터랙션 지원)
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

  /// [단일 할 일 아이템 빌더]
  /// 행 전체에 InkWell을 적용하여 모바일 터치 사용성을 극대화합니다.
  Widget _buildTodoRow({
    required TodoItem item,
    required Color primaryGreen,
    required VoidCallback onToggle,
  }) {
    final bool isDone = item.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle, // 행 전체 클릭 시 완료/취소 토글 실행
          borderRadius: BorderRadius.circular(14),
          splashColor: primaryGreen.withValues(alpha: 0.12),
          highlightColor: primaryGreen.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // 상태 아이콘 (완료: 체크 / 미완료: 원)
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
                      color: isDone
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF334155),
                    ),
                  ),
                ),

                // 우측 완료/취소 배지 버튼
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
