import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:procastimate_app/mainapp/settings_screen.dart';
import 'package:procastimate_app/mainapp/calendar_screen.dart';
import 'package:procastimate_app/mainapp/profile_screen.dart';
import 'package:procastimate_app/mainapp/reward_shop.dart';
import 'package:procastimate_app/mainapp/main_screen.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class ScoreScreen extends StatefulWidget {
  const ScoreScreen({super.key});

  @override
  State<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends State<ScoreScreen> {
  int score = 0;
  int _selectedIndex = 2;
  List<Map<String, dynamic>> completedTasks = [];

  String? _photoUrl;
  bool _loadingUser = true;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  @override
  void initState() {
    super.initState();
    _loadScore();
    _loadCompletedTasks();
    _loadUserData();
    _subscribeScoreUpdates();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (mounted) {
      setState(() {
        _photoUrl = doc.data()?['photoUrl'];
        _loadingUser = false;
      });
    }
  }

  Future<void> _loadScore() async {
    final prefs = await SharedPreferences.getInstance();
    final savedScore = prefs.getInt('score') ?? 0;

    // Keep cumulative score (do not reset at 100)
    if (mounted) {
      setState(() {
        score = savedScore;
      });
    }
  }

  // Listen to Firestore user document so ScoreScreen updates in real-time
  // when other parts of the app (MainScreen / RewardShop) update the score.
  void _subscribeScoreUpdates() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(
          (snap) async {
            if (!mounted) return;
            final data = snap.data();
            if (data == null) return;
            final dynamic remote = data['score'];
            if (remote == null) return;

            final int remoteScore;
            if (remote is int) {
              remoteScore = remote;
            } else if (remote is double) {
              remoteScore = remote.toInt();
            } else if (remote is String) {
              remoteScore = int.tryParse(remote) ?? score;
            } else {
              remoteScore = score;
            }

            if (remoteScore != score) {
              setState(() {
                score = remoteScore;
              });
              // keep local prefs in sync
              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt('score', remoteScore);
            }
          },
          onError: (e) {
            // ignore errors - Firestore listener may throw on permission issues etc.
          },
        );
  }

  Future<void> _loadCompletedTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final completedTasksRaw = prefs.getStringList('completedTasks') ?? [];
    setState(() {
      completedTasks = completedTasksRaw
          .map((e) => jsonDecode(e) as Map<String, dynamic>)
          .toList();
    });
  }

  void _onItemTapped(int i) {
    setState(() => _selectedIndex = i);
    if (i == 0) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CalendarScreen()),
      );
    } else if (i == 1) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    // fill ratio between 0 and 1 based on the current score (keeps cumulative score)
    final double fillRatio = ((score % 100) / 100).clamp(
      0.0,
      1.0,
    ); // safe clamp

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EF),
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 TOP APP BAR
            Container(
              width: double.infinity,
              height: 72,
              color: Colors.brown.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  InkWell(
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfileTab()),
                      );
                      _loadUserData();
                    },
                    borderRadius: BorderRadius.circular(50),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white24,
                      backgroundImage: _photoUrl != null
                          ? NetworkImage(_photoUrl!)
                          : null,
                      child: _photoUrl == null
                          ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 26,
                            )
                          : null,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    "ProcrastiMate",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // 🎁 Reward Shop button
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
              child: Row(
                children: [
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RewardShopScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Reward Shop",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 🧮 Points Display + Animated Wave
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 14),
              child: Column(
                children: [
                  SizedBox(
                    height: 150,
                    width: 150,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: fillRatio),
                      duration: const Duration(seconds: 1),
                      builder: (context, value, _) {
                        return AnimatedWaterFill(progress: value);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Points: $score',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Fills up every 100 points!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            // 📋 Completed Tasks Table
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8,
                ),
                child: completedTasks.isEmpty
                    ? const Center(child: Text('No completed tasks yet.'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: DataTable(
                          columnSpacing: 24,
                          columns: const [
                            DataColumn(label: Text('Task')),
                            DataColumn(label: Text('Points')),
                            DataColumn(label: Text('Completed At')),
                          ],
                          rows: completedTasks
                              .map(
                                (task) => DataRow(
                                  cells: [
                                    DataCell(
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          task['title'] ?? '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(task['points'].toString())),
                                    DataCell(
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          task['completedAt'] != null
                                              ? DateFormat(
                                                  'MM/dd/yyyy HH:mm',
                                                ).format(
                                                  DateTime.parse(
                                                    task['completedAt'],
                                                  ),
                                                )
                                              : '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),

      // 🔹 Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Score'),
        ],
        selectedItemColor: Colors.brown.shade800,
        unselectedItemColor: Colors.grey.shade600,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        backgroundColor: Colors.white,
        elevation: 8,
      ),
    );
  }
}

// 🌊 Animated Water Fill Widget
class AnimatedWaterFill extends StatefulWidget {
  final double progress; // 0–1
  const AnimatedWaterFill({super.key, required this.progress});

  @override
  State<AnimatedWaterFill> createState() => _AnimatedWaterFillState();
}

class _AnimatedWaterFillState extends State<AnimatedWaterFill>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: WavePainter(
            progress: widget.progress,
            wavePhase: _controller.value * 2 * math.pi,
          ),
        );
      },
    );
  }
}

// 🎨 Gradient + Animated Wave Painter
class WavePainter extends CustomPainter {
  final double progress;
  final double wavePhase;

  WavePainter({required this.progress, required this.wavePhase});

  @override
  void paint(Canvas canvas, Size size) {
    // Gradient fill (blue → teal)
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.lightBlueAccent.withOpacity(0.9),
        Colors.tealAccent.shade700.withOpacity(0.8),
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.brown.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final clipPath = Path()..addOval(rect);
    canvas.clipPath(clipPath);

    // Base water level
    final baseHeight = size.height * (1 - progress);

    // Create a smooth wave path
    final path = Path();
    const waveAmplitude = 6.0;
    const waveFrequency = 2.0;

    path.moveTo(0, baseHeight);
    for (double x = 0; x <= size.width; x++) {
      final y =
          baseHeight +
          math.sin((x / size.width * waveFrequency * 2 * math.pi) + wavePhase) *
              waveAmplitude;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Fill with gradient
    canvas.drawPath(path, paint);
    // Draw outer circle border
    canvas.drawOval(rect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.wavePhase != wavePhase;
  }
}
