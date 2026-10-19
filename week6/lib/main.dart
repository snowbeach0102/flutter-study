// ============================================================================
// [프로덕션급 공지사항 시스템: 실시간 피드 및 백그라운드 인덱싱]
//
// 핵심 비동기/동시성 아키텍처:
// 1. Future<T> & async/await : 공지사항 REST API 통신 모의 및 단발성 로드
// 2. Stream<T>               : 긴급 공지 실시간 브로드캐스팅 수신 (Server-Sent Event 모의)
// 3. compute() (Isolate 계열) : 수백 건의 공지 데이터 전문(Full-text) 검색/필터링을
//                              UI 스레드와 분리하여 Chrome 웹 및 모바일에서 안전하게 처리
// ============================================================================

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const NoticeProductionApp());
}

class NoticeProductionApp extends StatelessWidget {
  const NoticeProductionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '공지사항 시스템 대시보드',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          primary: const Color(0xFF0284C7),
        ),
      ),
      home: const NoticeDashboardPage(),
    );
  }
}

/// [데이터 모델] 공지사항 규격
class NoticeItem {
  final String id;
  final String title;
  final String content;
  final String category;
  final DateTime createdAt;
  final bool isUrgent;

  NoticeItem({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.createdAt,
    this.isUrgent = false,
  });

  // Isolate 간 메시지 패싱에 안전하도록 단순 Map 변환 지원
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'content': content,
    'category': category,
    'createdAt': createdAt.toIso8601String(),
    'isUrgent': isUrgent,
  };

  factory NoticeItem.fromMap(Map<String, dynamic> map) {
    return NoticeItem(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      category: map['category'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      isUrgent: map['isUrgent'] as bool,
    );
  }
}

/// [Isolate 탑레벨 함수]
/// 대량의 공지 데이터에서 검색어를 필터링하는 CPU 집약적 작업.
/// compute()로 전달하기 위해 반드시 최상위(Top-level) 또는 static 함수여야 합니다.
List<Map<String, dynamic>> _filterNoticesInBackground(
  Map<String, dynamic> params,
) {
  final List<dynamic> rawList = params['notices'] as List<dynamic>;
  final String query = (params['query'] as String).toLowerCase();

  final filtered = rawList
      .where((raw) {
        final title = (raw['title'] as String).toLowerCase();
        final content = (raw['content'] as String).toLowerCase();
        return title.contains(query) || content.contains(query);
      })
      .cast<Map<String, dynamic>>()
      .toList();

  return filtered;
}

class NoticeDashboardPage extends StatefulWidget {
  const NoticeDashboardPage({super.key});

  @override
  State<NoticeDashboardPage> createState() => _NoticeDashboardPageState();
}

class _NoticeDashboardPageState extends State<NoticeDashboardPage> {
  // 1. 전체 공지 원본 캐시
  List<NoticeItem> _allNotices = [];
  // 2. 검색/필터링되어 화면에 표시될 공지 목록
  List<NoticeItem> _displayedNotices = [];

  bool _isLoading = false;
  bool _isSearching = false;

  // 3. Stream 관련: 긴급 속보 공지 구독 컨트롤러
  late final StreamController<NoticeItem> _urgentNoticeStreamController;
  StreamSubscription<NoticeItem>? _urgentNoticeSubscription;
  Timer? _urgentNoticeMockTimer;
  NoticeItem? _latestUrgentNotice;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initUrgentNoticeStream();
    _fetchNotices(); // Future<T> 비동기 데이터 초기 로드
  }

  @override
  void dispose() {
    // [현업 핵심] 메모리 누수 방지: StreamSubscription 및 Controller 반드시 해제
    _urgentNoticeSubscription?.cancel();
    _urgentNoticeMockTimer?.cancel();
    _urgentNoticeStreamController.close();
    _searchController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // [요소 1 & 2]: Future<T> + async/await 를 활용한 서버 통신 및 단발성 패치
  // --------------------------------------------------------------------------
  Future<void> _fetchNotices() async {
    setState(() => _isLoading = true);

    try {
      // 서버 REST API 호출 모의 (네트워크 I/O 딜레이 시뮬레이션)
      final List<NoticeItem> fetchedData = await _mockFetchNoticesFromApi();

      setState(() {
        _allNotices = fetchedData;
        _displayedNotices = fetchedData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('공지사항 로드 실패: $e')));
      }
    }
  }

  Future<List<NoticeItem>> _mockFetchNoticesFromApi() async {
    await Future.delayed(const Duration(milliseconds: 900));

    // 실무 운영 시 누적되는 대량 공지사항 모의 데이터 (50건 생성)
    return List.generate(50, (index) {
      final id = index + 1;
      return NoticeItem(
        id: 'NOTC-$id',
        title: id % 7 == 0
            ? '[$id] 정기 서버 점검 및 보안 패치 안내'
            : (id % 5 == 0
                  ? '[$id] 신규 기능 릴리즈 및 서비스 이용약관 개정'
                  : '[$id] 일반 안내 사항입니다.'),
        content:
            '본 공지는 시스템 안정화 및 사용자 경험 개선을 위한 세부 공지사항 본문 내용입니다. 공지 고유번호는 NOTC-$id 이며 지속적으로 관리 감독됩니다.',
        category: id % 7 == 0 ? '시스템' : (id % 5 == 0 ? '약관' : '일반'),
        createdAt: DateTime.now().subtract(Duration(hours: id * 2)),
        isUrgent: id % 13 == 0,
      );
    });
  }

  // --------------------------------------------------------------------------
  // [요소 3]: Stream<T> 를 활용한 실시간 긴급 공지 푸시 (SSE/WebSocket 모의)
  // --------------------------------------------------------------------------
  void _initUrgentNoticeStream() {
    _urgentNoticeStreamController = StreamController<NoticeItem>.broadcast();

    // 15초마다 서버에서 비정기적으로 긴급 장애/점검 속보가 내려오는 상황 시뮬레이션
    _urgentNoticeMockTimer = Timer.periodic(const Duration(seconds: 15), (
      timer,
    ) {
      if (!_urgentNoticeStreamController.isClosed) {
        final alert = NoticeItem(
          id: 'ALERT-${timer.tick}',
          title: '🚨 긴급 공지 (${timer.tick}차): AWS 리전 네트워크 순단 감지',
          content: '클라우드 인프라 긴급 대응팀이 투입되어 정상화 작업 중입니다.',
          category: '긴급',
          createdAt: DateTime.now(),
          isUrgent: true,
        );
        _urgentNoticeStreamController.add(alert);
      }
    });

    // 스트림 구독 및 UI 바인딩
    _urgentNoticeSubscription = _urgentNoticeStreamController.stream.listen((
      urgentNotice,
    ) {
      setState(() {
        _latestUrgentNotice = urgentNotice;
      });
    });
  }

  // --------------------------------------------------------------------------
  // [요소 4]: Isolate / compute() 를 활용한 백그라운드 고속 검색
  // Chrome 브라우저에서는 Web Worker 호환 방식으로 작동하여 UI 멈춤을 방지함
  // --------------------------------------------------------------------------
  Future<void> _handleSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _displayedNotices = _allNotices);
      return;
    }

    setState(() => _isSearching = true);

    try {
      // Isolate 경계를 안전하게 넘나들기 위해 Map 기반 페이로드 구성
      final payload = {
        'notices': _allNotices.map((n) => n.toMap()).toList(),
        'query': query,
      };

      // compute() 실행: Chrome에서는 이벤트 루프 비차단 방식으로, 모바일에서는 별도 Isolate로 실행
      final List<Map<String, dynamic>> rawResults = await compute(
        _filterNoticesInBackground,
        payload,
      );

      if (mounted) {
        setState(() {
          _displayedNotices = rawResults
              .map((map) => NoticeItem.fromMap(map))
              .toList();
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.campaign_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text(
              '엔터프라이즈 공지 관제 센터',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            tooltip: '새로고침 (async/await)',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _fetchNotices,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          // Chrome 웹 환경 데스크톱 뷰를 고려한 최대 너비 제약
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            children: [
              // 1. [Stream 연동] 상단 실시간 긴급 공지 배너
              if (_latestUrgentNotice != null) _buildUrgentBanner(),

              // 2. [Isolate / compute 연동] 검색 입력 바
              _buildSearchBar(),

              // 3. [Future 연동] 메인 공지사항 목록
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildNoticeListView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUrgentBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border.all(color: const Color(0xFFFCA5A5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _latestUrgentNotice!.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF991B1B),
                  ),
                ),
                Text(
                  _latestUrgentNotice!.content,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7F1D1D),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Color(0xFF991B1B)),
            onPressed: () => setState(() => _latestUrgentNotice = null),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => _handleSearch(val),
        decoration: InputDecoration(
          hintText: '공지 제목 또는 본문 검색 (Isolate / compute 기반 고속 필터링)...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _isSearching
              ? Transform.scale(
                  scale: 0.5,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : (_searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _handleSearch('');
                        },
                      )
                    : null),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
        ),
      ),
    );
  }

  Widget _buildNoticeListView() {
    if (_displayedNotices.isEmpty) {
      return const Center(
        child: Text(
          '조건에 일치하는 공지사항이 없습니다.',
          style: TextStyle(color: Colors.black45),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchNotices,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _displayedNotices.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final notice = _displayedNotices[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundColor: notice.category == '시스템'
                    ? const Color(0xFFE0F2FE)
                    : (notice.category == '약관'
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFF1F5F9)),
                child: Icon(
                  notice.category == '시스템'
                      ? Icons.dns_rounded
                      : (notice.category == '약관'
                            ? Icons.description_rounded
                            : Icons.info_outline),
                  color: notice.category == '시스템'
                      ? const Color(0xFF0284C7)
                      : (notice.category == '약관'
                            ? const Color(0xFFD97706)
                            : const Color(0xFF475569)),
                ),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      notice.category,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      notice.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  notice.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              trailing: Text(
                '${notice.createdAt.hour.toString().padLeft(2, '0')}:${notice.createdAt.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ),
          );
        },
      ),
    );
  }
}
