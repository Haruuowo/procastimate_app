import 'dart:async';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:procastimate_app/models/task.dart';
import 'package:procastimate_app/models/task_data.dart';
import 'package:procastimate_app/mainapp/profile_screen.dart';
import 'package:procastimate_app/mainapp/settings_screen.dart';
import 'main_screen.dart';
import 'score_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int _selectedIndex = 0;

  String? _photoUrl;
  bool _loadingUser = true;

  int _streakCount = 0;
  bool _streakActive = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _streakSub;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _subscribeStreak();
  }

  @override
  void dispose() {
    _streakSub?.cancel();
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

  void _subscribeStreak() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _streakSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(
          (snap) {
            final data = snap.data();
            if (data == null) return;
            final dynamic remote = data['streakCount'];
            int remoteCount = 0;
            if (remote is int) {
              remoteCount = remote;
            } else if (remote is double) {
              remoteCount = remote.toInt();
            } else if (remote is String) {
              remoteCount = int.tryParse(remote) ?? 0;
            }
            if (mounted && remoteCount != _streakCount) {
              setState(() {
                _streakCount = remoteCount;
                _streakActive = _streakCount > 0;
              });
            }
          },
          onError: (_) {
          },
        );
  }

  List<Task> _getTasksForDay(DateTime day) {
    final key = DateFormat('yyyy-MM-dd').format(day);
    return (tasksByDate[key] ?? []).where((t) => !t.completed).toList();
  }

  void _onItemTapped(int i) {
    setState(() => _selectedIndex = i);
    if (i == 1) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const MainScreen()));
    } else if (i == 2) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ScoreScreen()));
    }
  }

  Widget _buildAvatarWithStreak() {
    const double avatarRadius = 18.0;
    final double avatarDiameter = avatarRadius * 2;
    final streakAsset = _streakActive
        ? 'assets/Streaks_On.png'
        : 'assets/Streaks_Off.png';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () async {
            await Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ProfileTab()));
            _loadUserData();
          },
          borderRadius: BorderRadius.circular(50),
          child: CircleAvatar(
            radius: avatarRadius,
            backgroundColor: Colors.white24,
            backgroundImage: _photoUrl != null
                ? NetworkImage(_photoUrl!)
                : null,
            child: _photoUrl == null
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: avatarDiameter,
          height: avatarDiameter,
          child: ClipOval(
            child: Image.asset(
              streakAsset,
              width: avatarDiameter,
              height: avatarDiameter,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) {
                return Container(
                  width: avatarDiameter,
                  height: avatarDiameter,
                  color: Colors.white24,
                  child: const Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$_streakCount',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedTasks = _selectedDay != null
        ? _getTasksForDay(_selectedDay!)
        : [];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 72,
              color: Colors.brown.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildAvatarWithStreak(),
                  ),
                  const Center(
                    child: Text(
                      "ProcrastiMate",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 26,
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Column(
                children: [
                  TableCalendar<Task>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    eventLoader: _getTasksForDay,
                    calendarStyle: CalendarStyle(
                      defaultTextStyle: const TextStyle(color: Colors.black87),
                      weekendTextStyle: TextStyle(color: Colors.brown.shade600),
                      todayDecoration: BoxDecoration(
                        color: Colors.orange.shade300,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.brown.shade400,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: Colors.red.shade300,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        color: Colors.brown.shade800,
                        fontSize: 18,
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: Colors.brown.shade700,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: Colors.brown.shade700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: selectedTasks.isEmpty
                        ? const Center(
                            child: Text(
                              "No tasks for this day ✨",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: selectedTasks.length,
                            itemBuilder: (context, index) {
                              final task = selectedTasks[index];
                              return Card(
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 3,
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  title: Text(
                                    task.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (task.description != null &&
                                          task.description!.isNotEmpty)
                                        Text(
                                          task.description!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      if (task.dueDate != null)
                                        Text(
                                          "Due: ${DateFormat('MMM d h:mm a').format(task.dueDate!)}",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

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
