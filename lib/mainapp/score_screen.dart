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

  @override
  void initState() {
    super.initState();
    _loadScore();
    _loadCompletedTasks();
    _loadUserData(); // ✅ Load the user's profile photo
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (mounted) {
      setState(() {
        _photoUrl = doc.data()?['photoUrl'];
        _loadingUser = false;
      });
    }
  }

  Future<void> _loadScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      score = prefs.getInt('score') ?? 0;
    });
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
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EF),
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 TOP APP BAR (matches CalendarScreen)
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
          _loadUserData(); // refresh on return
        },
        borderRadius: BorderRadius.circular(50),
        child: CircleAvatar(
          radius: 22,
          backgroundColor: Colors.white24,
          backgroundImage:
              _photoUrl != null ? NetworkImage(_photoUrl!) : null,
          child: _photoUrl == null
              ? const Icon(Icons.person, color: Colors.white, size: 26)
              : null,
        ),
      ),
      const Spacer(),
      const Text(
        "Procastimate",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 20,
          letterSpacing: 0.5,
        ),
      ),
      const Spacer(),
      IconButton(
        icon: const Icon(Icons.settings, color: Colors.white, size: 26),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
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
                            builder: (_) => const RewardShopScreen()),
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

            // 🧮 Points Display
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 14),
              child: Column(
                children: [
                  SizedBox(
                    height: 100,
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your Points',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$score',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Complete tasks to earn points!',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // 📋 Completed Tasks Table
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
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
                                              ? DateFormat('MM/dd/yyyy HH:mm')
                                                  .format(
                                                  DateTime.parse(
                                                      task['completedAt']),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Score',
          ),
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
