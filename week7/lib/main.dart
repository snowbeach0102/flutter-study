import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const EchoApp());
}

class EchoApp extends StatelessWidget {
  const EchoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Echo - 음악 디깅',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050505),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FFB2),
          surface: Color(0xFF1A1A1A),
        ),
      ),
      home: const DiggingFeedScreen(),
    );
  }
}

class DiggingFeedScreen extends StatefulWidget {
  const DiggingFeedScreen({super.key});

  @override
  State<DiggingFeedScreen> createState() => _DiggingFeedScreenState();
}

class _DiggingFeedScreenState extends State<DiggingFeedScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isStarted = false; // 웹 브라우저 상호작용 체크용

  final List<Map<String, String>> _tracks = [
    {
      'title': 'Midnight Groove',
      'artist': 'SoundHelix',
      'cover': '🌌',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    },
    {
      'title': 'Neon Lights',
      'artist': 'SoundHelix',
      'cover': '🧲',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    },
    {
      'title': 'Urban Flow',
      'artist': 'SoundHelix',
      'cover': '❄️',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    },
  ];

  @override
  void initState() {
    super.initState();
    // 웹에서는 initState에서 바로 재생하면 브라우저가 차단하므로 비워둡니다.
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playCurrentTrack() async {
    if (_tracks.isNotEmpty) {
      setState(() => _isPlaying = true);
      await _audioPlayer.play(UrlSource(_tracks[0]['url']!));
    } else {
      await _audioPlayer.stop();
      setState(() => _isPlaying = false);
    }
  }

  void _onSwipe(int index, DismissDirection direction) {
    final track = _tracks[index];

    setState(() {
      _tracks.removeAt(index);
    });

    if (direction == DismissDirection.startToEnd) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎵 ${track['title']} 보관함에 저장 완료'),
          backgroundColor: const Color(0xFF00FFB2).withOpacity(0.8),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          width: 400,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('다음 곡으로 넘어갑니다.'),
          backgroundColor: Colors.grey.shade800,
          duration: const Duration(milliseconds: 500),
          behavior: SnackBarBehavior.floating,
          width: 400,
        ),
      );
    }

    _playCurrentTrack();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Container(
            color: const Color(0xFF0A0A0A),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: const Text(
                  'Echo',
                  style: TextStyle(
                    color: Color(0xFF00FFB2),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                centerTitle: true,
              ),
              // 상호작용(클릭) 전에는 시작 버튼을 보여주고, 클릭 후에는 카드를 보여줌
              body: !_isStarted
                  ? Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FFB2),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                        ),
                        onPressed: () {
                          setState(() => _isStarted = true);
                          _playCurrentTrack(); // 버튼 클릭 시 오디오 재생 시작
                        },
                        child: const Text(
                          '디깅 시작하기 🎵',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : _tracks.isEmpty
                  ? const Center(
                      child: Text(
                        '오늘의 추천 곡을 모두 확인했습니다.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: _tracks
                          .asMap()
                          .entries
                          .map((entry) {
                            int index = entry.key;
                            var track = entry.value;
                            bool isFrontCard = index == 0;

                            return isFrontCard
                                ? Dismissible(
                                    key: ValueKey(track['title']),
                                    onDismissed: (direction) =>
                                        _onSwipe(index, direction),
                                    background: Container(
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.only(left: 40),
                                      color: const Color(0xFF00FFB2)
                                          .withOpacity(0.2),
                                      child: const Icon(
                                        Icons.favorite_rounded,
                                        color: Color(0xFF00FFB2),
                                        size: 40,
                                      ),
                                    ),
                                    secondaryBackground: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 40),
                                      color: Colors.redAccent.withOpacity(0.2),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.redAccent,
                                        size: 40,
                                      ),
                                    ),
                                    child: _buildTrackCard(track, isFrontCard),
                                  )
                                : _buildTrackCard(track, isFrontCard);
                          })
                          .toList()
                          .reversed
                          .toList(),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackCard(Map<String, String> track, bool isFront) {
    return Container(
      width: 450 * 0.85,
      height: 600,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF00FFB2).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(track['cover']!, style: const TextStyle(fontSize: 100)),
          const SizedBox(height: 30),
          Text(
            track['title']!,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            track['artist']!,
            style: const TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const SizedBox(height: 40),
          if (isFront && _isPlaying)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                7,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 6,
                  height: 15.0 + ((index * 7) % 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FFB2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
