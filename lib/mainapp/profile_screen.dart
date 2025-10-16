import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:procastimate_app/mainapp/score_screen.dart';
import 'package:procastimate_app/mainapp/calendar_screen.dart';

import 'package:procastimate_app/mainapp/main_screen.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  int _selectedIndex = 1;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  String _userName = "Your Name";
  String _photoUrl = "";
  int score = 0;
  List<Map<String, dynamic>> completedTasks = [];

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadScore();
    _loadCompletedTasks();
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint("⚠️ No authenticated user found");
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _userName = data['username'] ?? user.displayName ?? "Your Name";
          _photoUrl = data['photoUrl'] ?? "";
        });
        return;
      }
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'username': user.displayName ?? "Your Name",
        'photoUrl': "",
        'createdAt': FieldValue.serverTimestamp(),
      });
      setState(() {
        _userName = user.displayName ?? "Your Name";
      });
    } catch (e) {
      debugPrint("⚠️ Firestore load failed: $e");
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('username');
      final savedImagePath = prefs.getString('profileImagePath');
      setState(() {
        if (savedName != null) _userName = savedName;
        if (savedImagePath != null) _profileImage = File(savedImagePath);
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
      // completedTasksRaw is maintained with newest-first by your completion handler,
      // so preserve that order here (newest at index 0).
      completedTasks = completedTasksRaw
          .map((e) => jsonDecode(e) as Map<String, dynamic>)
          .toList();
    });
  }

  Future<void> _updateUserProfile({
    String? newName,
    File? newImage,
    String? imageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      if (newName != null && newName.isNotEmpty) {
        await user.updateDisplayName(newName);
      }
      if (newImage != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profileImagePath', newImage.path);
      }
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'username': newName ?? _userName,
        'photoUrl': imageUrl ?? "",
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      setState(() {
        if (newName != null) _userName = newName;
        if (imageUrl != null) _photoUrl = imageUrl;
        if (newImage != null) _profileImage = newImage;
      });
    } catch (e) {
      debugPrint('⚠️ Profile update failed: $e');
    }
  }

  void _showImageUrlDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Image URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter image URL'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _updateUserProfile(imageUrl: controller.text);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.photo_library, size: 35),
              onPressed: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (image != null) {
                  await _updateUserProfile(newImage: File(image.path));
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt, size: 35),
              onPressed: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.camera,
                );
                if (image != null) {
                  await _updateUserProfile(newImage: File(image.path));
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.link, size: 35),
              onPressed: () {
                Navigator.pop(context);
                _showImageUrlDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final controller = TextEditingController(text: _userName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Enter your name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _updateUserProfile(newName: controller.text);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown.shade800,
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _profileImage != null
        ? FileImage(_profileImage!)
        : (_photoUrl.isNotEmpty
              ? NetworkImage(_photoUrl)
              : const AssetImage('assets/profile_placeholder.png')
                    as ImageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EF),
      appBar: AppBar(
        backgroundColor: Colors.brown.shade800,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 26),
        child: Column(
          children: [
            // Profile Section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(100),
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.black12,
                      backgroundImage: imageProvider,
                      child: (_photoUrl.isEmpty && _profileImage == null)
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.black54,
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Flexible(child: 
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.stars_sharp,
                          color: Colors.orange,
                          size: 40,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$score',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Points obtained!',
                      style: TextStyle(color: Colors.black, fontSize: 22),
                    ),
                    Text(
                      '${completedTasks.length} Tasks completed',
                      style: const TextStyle(color: Colors.black, fontSize: 15),
                    ),
                  ],
                )
                )
                ,
              ],
            ),

            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _showEditProfileDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown.shade800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text(
                'Edit Profile',
                style: TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 30),
            // Completed Tasks Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Completed Tasks',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (completedTasks.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No completed tasks yet.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    )
                  else
                    // show newest completed tasks first (completedTasks is maintained newest-first)
                    for (final task in completedTasks.take(5))
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 3,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task['title'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (task['description'] != null &&
                                (task['description'] as String).isNotEmpty)
                              Text(
                                task['description'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                task['completedAt'] != null
                                    ? DateFormat('MMM d h:mm a').format(
                                        DateTime.parse(task['completedAt']),
                                      )
                                    : '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
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
        onTap: (i) {
          setState(() => _selectedIndex = i);
          if (i == 0) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const CalendarScreen()),
            );
          } else if (i == 1) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainScreen()),
            );
          } else if (i == 2) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const ScoreScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Score'),
        ],
        selectedItemColor: Colors.brown,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        backgroundColor: Colors.white,
        elevation: 8,
      ),
    );
  }
}
