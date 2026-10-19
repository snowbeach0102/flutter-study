import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const EnterpriseNoticeApp());
}

class EnterpriseNoticeApp extends StatelessWidget {
  const EnterpriseNoticeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '스마트 공지사항 시스템',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0284C7),
          primary: const Color(0xFF0369A1),
          surface: const Color(0xFFF8FAFC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      home: const NoticeDashboardScreen(),
    );
  }
}

// ============================================================================
// 1. 도메인 모델 (Domain Model)
// ============================================================================
class NoticeItem {
  final int id;
  final String title;
  final String content;
  final String category;
  final String date;
  final bool isUrgent;

  NoticeItem({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.date,
    this.isUrgent = false,
  });

  factory NoticeItem.fromMap(Map<String, dynamic> map) {
    return NoticeItem(
      id: map['id'] as int,
      title: map['title'] as String,
      content: map['content'] as String,
      category: map['category'] as String,
      date: map['date'] as String,
      isUrgent: map['isUrgent'] as bool? ?? false,
    );
  }
}

// ============================================================================
// 2. 비즈니스 서비스 & 비동기 레이어 (Service Layer)
//    - Future<T>, async/await, Stream<T>, Isolate (compute)
// ============================================================================
class NoticeService {
  // [A] Future<T> & async/await: 네트워크 API 통신 모사
  static Future<List<NoticeItem>> fetchNotices() async {
    // 네트워크 I/O 지연 시간 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 900));

    // 원시 데이터(Raw Mock Data)
    final rawData = [
      {
        'id': 101,
        'title': '[안내] 2026학년도 2학기 수강신청 최종 정정 기간 공지',
        'content': '수강신청 정정 기간은 금주 금요일 18:00까지이며 기한 후 추가 신청은 불가합니다.',
        'category': '학사',
        'date': '2026-10-19',
        'isUrgent': true,
      },
      {
        'id': 102,
        'title': '[점검] 학사 포털 시스템 보안 패치 및 데이터베이스 정기 점검',
        'content': '10월 22일(목) 새벽 02:00부터 05:00까지 서비스 접근이 일시 중단됩니다.',
        'category': '전산',
        'date': '2026-10-18',
        'isUrgent': false,
      },
      {
        'id': 103,
        'title': '[장학] 2026년 하반기 성적우수 및 동문 산학장학금 신청 서류 접수',
        'content': '학생처 장학복지팀을 통해 신청서 및 소득증빙서류 원본을 구비하여 제출하시기 바랍니다.',
        'category': '장학',
        'date': '2026-10-15',
        'isUrgent': false,
      },
      {
        'id': 104,
        'title': '[채용] 하반기 IT 엔지니어링 동계 인턴십 모집 공고',
        'content': '소프트웨어, 클라우드 인프라, 모바일 앱 분야 인턴십 서류 접수가 진행 중입니다.',
        'category': '취업',
        'date': '2026-10-12',
        'isUrgent': false,
      },
      {
        'id': 105,
        'title': '[시설] 도서관 열람실 냉난방 공조기 교체 작업에 따른 소음 안내',
        'content': '제2열람실 소음 발생 예상 시간은 오전 09시부터 12시까지입니다.',
        'category': '시설',
        'date': '2026-10-10',
        'isUrgent': false,
      },
    ];

    return rawData.map((e) => NoticeItem.fromMap(e)).toList();
  }

  // [B] Stream<T>: 실시간 속보 / 긴급 방송 푸시 스트림
  //     WebSocket 또는 SSE(Server-Sent Events)를 모방하여 4초마다 새 긴급 공지를 스트리밍 방출
  static Stream<String> urgentNoticeStream() async* {
    final urgentAlerts = [
      '⚡ [속보] 학사지원처 서버 긴급 증설 완료 (정상 접속 가능)',
      '🚨 [안내] 금일 학생식당 점심시간 결제 단말기 점검 진행',
      '📢 [필독] 5주차 비동기 상태 관리 과제 제출 기한 D-1',
      '⚠️ [기상] 캠퍼스 내 강풍 주의보 발효에 따른 낙하물 유의',
    ];

    int index = 0;
    while (true) {
      await Future.delayed(const Duration(seconds: 4));
      yield urgentAlerts[index % urgentAlerts.length];
      index++;
    }
  }

  // [C] Isolate (compute): 무거운 검색 및 문자열 필터링 연산
  //     Chrome Web과 Windows Desktop 양쪽 모두에서 메인 UI 스레드 버벅임(Jank) 없이 작동
  static Future<List<NoticeItem>> searchFilterWithIsolate({
    required List<NoticeItem> list,
    required String query,
  }) async {
    if (query.trim().isEmpty) return list;

    // Isolate로 격리 실행할 패킷 객체 포장
    final payload = _FilterPayload(list: list, query: query);

    // compute: 웹(Web) 환경과 네이티브(Desktop) 환경을 자동 식별하여 Isolate 태스크 분기 처리
    return await compute(_filterWorker, payload);
  }
}

// Isolate에 전달할 순수 데이터 페이로드
class _FilterPayload {
  final List<NoticeItem> list;
  final String query;

  _FilterPayload({required this.list, required this.query});
}

// 최상위 전역 함수(Top-level function): Isolate가 메인 스레드와 별개 공간에서 실행하는 작업
List<NoticeItem> _filterWorker(_FilterPayload payload) {
  final q = payload.query.toLowerCase().trim();
  return payload.list.where((item) {
    final titleMatch = item.title.toLowerCase().contains(q);
    final contentMatch = item.content.toLowerCase().contains(q);
    final categoryMatch = item.category.toLowerCase().contains(q);
    return titleMatch || contentMatch || categoryMatch;
  }).toList();
}

// ============================================================================
// 3. UI Presentation Layer
// ============================================================================
class NoticeDashboardScreen extends StatefulWidget {
  const NoticeDashboardScreen({super.key});

  @override
  State<NoticeDashboardScreen> createState() => _NoticeDashboardScreenState();
}

class _NoticeDashboardScreenState extends State<NoticeDashboardScreen> {
  // 1) Future 캐싱 및 상태
  late Future<List<NoticeItem>> _noticeFuture;
  List<NoticeItem> _allNotices = [];
  List<NoticeItem> _filteredNotices = [];

  // 2) Stream 컨트롤러 & 캐시
  late final Stream<String> _urgentStream;

  // 3) 검색 컨트롤러 및 연산 상태
  final TextEditingController _searchController = TextEditingController();
  bool _isFiltering = false;

  @override
  void initState() {
    super.initState();
    // Future 로드 초기화
    _loadNotices();
    // 실시간 긴급 공지 Stream 구독 준비
    _urgentStream = NoticeService.urgentNoticeStream();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // async/await를 이용한 수동 새로고침 처리
  Future<void> _loadNotices() async {
    setState(() {
      _noticeFuture = NoticeService.fetchNotices();
    });

    final data = await _noticeFuture;
    setState(() {
      _allNotices = data;
      _filteredNotices = data;
    });
  }

  // 검색어 입력 시 Isolate 기반 필터링 트리거
  Future<void> _onSearchChanged(String text) async {
    setState(() => _isFiltering = true);

    // Isolate Worker에게 백그라운드 필터링 위임 (메인 UI 프레임 유지)
    final results = await NoticeService.searchFilterWithIsolate(
      list: _allNotices,
      query: text,
    );

    setState(() {
      _filteredNotices = results;
      _isFiltering = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.campaign_rounded, size: 28),
            SizedBox(width: 10),
            Text(
              '캠퍼스 스마트 공지센터',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '새로고침 (async/await)',
            onPressed: _loadNotices,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820), // 웹 및 윈도우 와이드 대응
          child: Column(
            children: [
              // ---------------------------------------------------------------
              // [요소 1: Stream<T> & StreamBuilder] 실시간 속보 배너
              // ---------------------------------------------------------------
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: StreamBuilder<String>(
                  stream: _urgentStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.redAccent,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            '실시간 긴급 공지 피드 연결 중...',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        const Icon(
                          Icons.emergency_rounded,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            snapshot.data ?? '수신된 긴급 공지가 없습니다.',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB91C1C),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // ---------------------------------------------------------------
              // [요소 2: Isolate 검색 바]
              // ---------------------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: '공지 제목, 본문, 카테고리 검색 (Isolate 연산)',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _isFiltering
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : (_searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                )
                              : null),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ),

              // ---------------------------------------------------------------
              // [요소 3: Future<T> & FutureBuilder] 공지 리스트 비동기 렌더링
              // ---------------------------------------------------------------
              Expanded(
                child: FutureBuilder<List<NoticeItem>>(
                  future: _noticeFuture,
                  builder: (context, snapshot) {
                    // [1] 로딩 상태
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        _allNotices.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text(
                              '서버에서 공지사항을 불러오는 중입니다... (Future)',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      );
                    }

                    // [2] 오류 상태
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          '공지사항 로드 중 오류가 발생했습니다: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    // [3] 검색 결과 없음 상태
                    if (_filteredNotices.isEmpty) {
                      return const Center(
                        child: Text(
                          '검색 조건과 일치하는 공지사항이 없습니다.',
                          style: TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                      );
                    }

                    // [4] 데이터 정상 수신 완료
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredNotices.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = _filteredNotices[index];
                        return _buildNoticeCard(item, theme);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 공지사항 카드 UI 컴포넌트
  Widget _buildNoticeCard(NoticeItem item, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isUrgent ? Colors.red.shade200 : Colors.grey.shade200,
          width: item.isUrgent ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: item.isUrgent
                ? const Color(0xFFFEE2E2)
                : theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            item.category,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: item.isUrgent
                  ? Colors.red.shade800
                  : theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Row(
          children: [
            if (item.isUrgent) ...[
              const Icon(
                Icons.priority_high_rounded,
                size: 16,
                color: Colors.red,
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.content,
                style: const TextStyle(color: Colors.black87, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                '게시일: ${item.date}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
