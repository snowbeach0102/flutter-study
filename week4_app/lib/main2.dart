import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() {
  runApp(const TowerDefenseApp());
}

class TowerDefenseApp extends StatelessWidget {
  const TowerDefenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '미니 타워 디펜스',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E293B),
      ),
      home: const GameScreen(),
    );
  }
}

// -------------------------------------------------------------
// 게임 모델 (Enemy, Tower, Projectile)
// -------------------------------------------------------------
class Enemy {
  double progress = 0.0; // 0.0 ~ 1.0 (경로 진행도)
  double speed;
  double maxHp;
  double hp;
  final Color color;

  Enemy({required this.speed, required this.maxHp, required this.color})
    : hp = maxHp;
}

enum TowerType { basic, sniper }

class Tower {
  final int gridX;
  final int gridY;
  final TowerType type;
  double lastShotTime = 0.0;

  Tower({required this.gridX, required this.gridY, required this.type});

  double get range => type == TowerType.basic ? 100.0 : 160.0;
  double get fireRate => type == TowerType.basic ? 0.6 : 1.2; // 초당 쿨다운
  int get cost => type == TowerType.basic ? 50 : 90;
  double get damage => type == TowerType.basic ? 25.0 : 65.0;
}

class Projectile {
  Offset position;
  final Enemy target;
  final double damage;
  final double speed = 350.0;

  Projectile({
    required this.position,
    required this.target,
    required this.damage,
  });
}

// -------------------------------------------------------------
// 메인 게임 화면 & 루프
// -------------------------------------------------------------
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  // 게임 상태 변수
  int _gold = 100;
  int _baseHp = 10;
  int _wave = 1;
  int _score = 0;
  bool _isGameOver = false;
  TowerType _selectedTowerType = TowerType.basic;

  // 맵 그리드 (8 x 10)
  final int cols = 8;
  final int rows = 10;

  // 몬스터 이동 경로 (Waypoints)
  final List<Point<int>> waypoints = const [
    Point(1, 0),
    Point(1, 3),
    Point(6, 3),
    Point(6, 6),
    Point(2, 6),
    Point(2, 9),
  ];

  final List<Tower> _towers = [];
  final List<Enemy> _enemies = [];
  final List<Projectile> _projectiles = [];

  double _waveTimer = 0.0;
  int _enemiesSpawnedInWave = 0;
  final int _enemiesPerWave = 8;
  double _elapsedGameTime = 0.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // 60FPS 실시간 게임 업데이트 루프
  void _onTick(Duration elapsed) {
    if (_isGameOver) return;

    final double dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;
    if (dt > 0.1) return; // 프레임 드랍 튐 방지

    _elapsedGameTime += dt;
    _waveTimer += dt;

    // 1. 적 소환 (웨이브 스폰)
    if (_enemiesSpawnedInWave < _enemiesPerWave) {
      if (_waveTimer >= 1.2) {
        _waveTimer = 0.0;
        _enemiesSpawnedInWave++;
        _enemies.add(
          Enemy(
            speed: 0.12 + (_wave * 0.015),
            maxHp: 50.0 + (_wave * 25.0),
            color: _wave % 2 == 0 ? Colors.purpleAccent : Colors.redAccent,
          ),
        );
      }
    } else if (_enemies.isEmpty) {
      // 웨이브 클리어 ➔ 다음 웨이브
      _wave++;
      _gold += 40 + (_wave * 10);
      _enemiesSpawnedInWave = 0;
      _waveTimer = -2.0; // 웨이브 간 2초 휴식
    }

    // 2. 적 이동 및 기지 도달 판정
    for (int i = _enemies.length - 1; i >= 0; i--) {
      final enemy = _enemies[i];
      enemy.progress += enemy.speed * dt;

      if (enemy.progress >= 1.0) {
        _enemies.removeAt(i);
        _baseHp--;
        if (_baseHp <= 0) {
          _isGameOver = true;
        }
      }
    }

    // 3. 타워 자동 사격 (타겟 탐색 & 발사)
    for (var tower in _towers) {
      if (_elapsedGameTime - tower.lastShotTime >= tower.fireRate) {
        final towerPos = _getTileCenter(tower.gridX, tower.gridY);

        Enemy? bestTarget;
        double maxProgress = -1.0;

        for (var enemy in _enemies) {
          final enemyPos = _getEnemyPosition(enemy.progress);
          final dist = (towerPos - enemyPos).distance;

          if (dist <= tower.range && enemy.progress > maxProgress) {
            maxProgress = enemy.progress;
            bestTarget = enemy;
          }
        }

        if (bestTarget != null) {
          tower.lastShotTime = _elapsedGameTime;
          _projectiles.add(
            Projectile(
              position: towerPos,
              target: bestTarget,
              damage: tower.damage,
            ),
          );
        }
      }
    }

    // 4. 투사체 이동 및 충돌 판정
    for (int i = _projectiles.length - 1; i >= 0; i--) {
      final p = _projectiles[i];
      if (!_enemies.contains(p.target)) {
        _projectiles.removeAt(i);
        continue;
      }

      final targetPos = _getEnemyPosition(p.target.progress);
      final dir = targetPos - p.position;
      final dist = dir.distance;

      if (dist <= 12.0) {
        // 명중
        p.target.hp -= p.damage;
        _projectiles.removeAt(i);

        if (p.target.hp <= 0) {
          _enemies.remove(p.target);
          _gold += 15 + (_wave * 2);
          _score += 100;
        }
      } else {
        p.position += (dir / dist) * (p.speed * dt);
      }
    }

    setState(() {});
  }

  // 그리드 좌표 ➔ 실제 화면 픽셀 좌표 변환
  Offset _getTileCenter(int gx, int gy) {
    const tileSize = 42.0;
    return Offset(gx * tileSize + tileSize / 2, gy * tileSize + tileSize / 2);
  }

  // 경로 진행도(0.0 ~ 1.0)에 따른 적의 픽셀 좌표 계산
  Offset _getEnemyPosition(double progress) {
    if (waypoints.isEmpty) return Offset.zero;
    final totalSegments = waypoints.length - 1;
    final segmentProgress = progress * totalSegments;
    final index = segmentProgress.floor().clamp(0, totalSegments - 1);
    final subT = segmentProgress - index;

    final p1 = _getTileCenter(waypoints[index].x, waypoints[index].y);
    final p2 = _getTileCenter(waypoints[index + 1].x, waypoints[index + 1].y);

    return Offset(
      p1.dx + (p2.dx - p1.dx) * subT,
      p1.dy + (p2.dy - p1.dy) * subT,
    );
  }

  // 타일 터치 시 타워 건설
  void _onTileTap(int gx, int gy) {
    if (_isGameOver) return;

    // 경로 위에는 타워 건설 불가
    if (_isPathTile(gx, gy)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('몬스터 경로 위에는 설치할 수 없습니다!'),
          duration: Duration(milliseconds: 600),
        ),
      );
      return;
    }

    // 이미 설치된 타워인지 확인
    if (_towers.any((t) => t.gridX == gx && t.gridY == gy)) {
      return;
    }

    final cost = _selectedTowerType == TowerType.basic ? 50 : 90;
    if (_gold >= cost) {
      setState(() {
        _gold -= cost;
        _towers.add(Tower(gridX: gx, gridY: gy, type: _selectedTowerType));
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('골드가 부족합니다!'),
          duration: Duration(milliseconds: 600),
        ),
      );
    }
  }

  bool _isPathTile(int x, int y) {
    for (int i = 0; i < waypoints.length - 1; i++) {
      final p1 = waypoints[i];
      final p2 = waypoints[i + 1];
      final minX = min(p1.x, p2.x);
      final maxX = max(p1.x, p2.x);
      final minY = min(p1.y, p2.y);
      final maxY = max(p1.y, p2.y);

      if (x >= minX && x <= maxX && y >= minY && y <= maxY) {
        return true;
      }
    }
    return false;
  }

  void _restartGame() {
    setState(() {
      _gold = 100;
      _baseHp = 10;
      _wave = 1;
      _score = 0;
      _isGameOver = false;
      _towers.clear();
      _enemies.clear();
      _projectiles.clear();
      _enemiesSpawnedInWave = 0;
      _waveTimer = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    const tileSize = 42.0;
    final boardWidth = cols * tileSize;
    final boardHeight = rows * tileSize;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🛡️ 타워 디펜스',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F172A),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. 상단 상태창 (골드, 하트, 웨이브)
              Container(
                width: boardWidth,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.blueGrey.shade700),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '💰 $_gold G',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '❤️ $_baseHp',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '🌊 Wave $_wave',
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              // 2. 디펜스 메인 전장 캔버스
              GestureDetector(
                onTapUp: (details) {
                  final gx = (details.localPosition.dx / tileSize).floor();
                  final gy = (details.localPosition.dy / tileSize).floor();
                  if (gx >= 0 && gx < cols && gy >= 0 && gy < rows) {
                    _onTileTap(gx, gy);
                  }
                },
                child: Container(
                  width: boardWidth,
                  height: boardHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blueGrey.shade700,
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // 배경 타일 그리드 및 경로 렌더링
                      CustomPaint(
                        size: Size(boardWidth, boardHeight),
                        painter: GridAndPathPainter(
                          cols: cols,
                          rows: rows,
                          tileSize: tileSize,
                          waypoints: waypoints,
                        ),
                      ),
                      // 타워, 적, 탄환 실시간 렌더링
                      CustomPaint(
                        size: Size(boardWidth, boardHeight),
                        painter: EntityPainter(
                          towers: _towers,
                          enemies: _enemies,
                          projectiles: _projectiles,
                          getTileCenter: _getTileCenter,
                          getEnemyPosition: _getEnemyPosition,
                        ),
                      ),
                      // 게임 오버 오버레이
                      if (_isGameOver)
                        Container(
                          color: Colors.black87,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'GAME OVER',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '최종 점수: $_score 점',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _restartGame,
                                icon: const Icon(Icons.refresh),
                                label: const Text('다시 도전'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. 하단 타워 선택 패널
              Container(
                width: boardWidth,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ChoiceChip(
                      label: const Text('🔫 캐논 (50G)'),
                      selected: _selectedTowerType == TowerType.basic,
                      selectedColor: Colors.blueAccent,
                      onSelected: (val) {
                        setState(() => _selectedTowerType = TowerType.basic);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('⚡ 스나이퍼 (90G)'),
                      selected: _selectedTowerType == TowerType.sniper,
                      selectedColor: Colors.amber.shade700,
                      onSelected: (val) {
                        setState(() => _selectedTowerType = TowerType.sniper);
                      },
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
}

// -------------------------------------------------------------
// 배경 타일 및 이동 경로 그리기
// -------------------------------------------------------------
class GridAndPathPainter extends CustomPainter {
  final int cols;
  final int rows;
  final double tileSize;
  final List<Point<int>> waypoints;

  GridAndPathPainter({
    required this.cols,
    required this.rows,
    required this.tileSize,
    required this.waypoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1.0;

    // 타일 그리드 선
    for (int i = 0; i <= cols; i++) {
      canvas.drawLine(
        Offset(i * tileSize, 0),
        Offset(i * tileSize, size.height),
        linePaint,
      );
    }
    for (int j = 0; j <= rows; j++) {
      canvas.drawLine(
        Offset(0, j * tileSize),
        Offset(size.width, j * tileSize),
        linePaint,
      );
    }

    // 몬스터 경로 로드 (갈색 길)
    final pathPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = tileSize * 0.75
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < waypoints.length; i++) {
      final pt = Offset(
        waypoints[i].x * tileSize + tileSize / 2,
        waypoints[i].y * tileSize + tileSize / 2,
      );
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(path, pathPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -------------------------------------------------------------
// 타워, 몬스터, 투사체 실시간 그리기
// -------------------------------------------------------------
class EntityPainter extends CustomPainter {
  final List<Tower> towers;
  final List<Enemy> enemies;
  final List<Projectile> projectiles;
  final Offset Function(int, int) getTileCenter;
  final Offset Function(double) getEnemyPosition;

  EntityPainter({
    required this.towers,
    required this.enemies,
    required this.projectiles,
    required this.getTileCenter,
    required this.getEnemyPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 타워 그리기
    for (var tower in towers) {
      final pos = getTileCenter(tower.gridX, tower.gridY);
      final isSniper = tower.type == TowerType.sniper;

      // 타워 사거리 범위 링 (은은한 원)
      canvas.drawCircle(
        pos,
        tower.range,
        Paint()
          ..color = (isSniper ? Colors.amber : Colors.blue).withOpacity(0.08)
          ..style = PaintingStyle.fill,
      );

      // 타워 받침대
      canvas.drawCircle(
        pos,
        16,
        Paint()
          ..color = isSniper ? Colors.amber.shade800 : Colors.blue.shade800,
      );
      // 타워 코어
      canvas.drawCircle(
        pos,
        9,
        Paint()..color = isSniper ? Colors.amberAccent : Colors.cyanAccent,
      );
    }

    // 2. 적(몬스터) & 체력바 그리기
    for (var enemy in enemies) {
      final pos = getEnemyPosition(enemy.progress);

      // 몬스터 본체
      canvas.drawCircle(pos, 11, Paint()..color = enemy.color);
      canvas.drawCircle(pos, 5, Paint()..color = Colors.white70);

      // 체력바 배경 (검정)
      final hpBarRect = Rect.fromCenter(
        center: Offset(pos.dx, pos.dy - 17),
        width: 24,
        height: 4,
      );
      canvas.drawRect(hpBarRect, Paint()..color = Colors.black);

      // 현재 체력 (초록)
      final hpPercent = (enemy.hp / enemy.maxHp).clamp(0.0, 1.0);
      final currentHpRect = Rect.fromLTWH(
        hpBarRect.left,
        hpBarRect.top,
        24 * hpPercent,
        4,
      );
      canvas.drawRect(
        currentHpRect,
        Paint()
          ..color = hpPercent > 0.4 ? Colors.greenAccent : Colors.redAccent,
      );
    }

    // 3. 투사체(탄환) 그리기
    for (var p in projectiles) {
      canvas.drawCircle(
        p.position,
        4.0,
        Paint()
          ..color = Colors.yellowAccent
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
