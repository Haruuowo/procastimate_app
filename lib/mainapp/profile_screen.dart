// profile_screen.dart
import 'package:flutter/material.dart';
import 'package:procastimate_app/models/task_data.dart';
import 'package:procastimate_app/mainapp/calendar_screen.dart';
import 'package:procastimate_app/mainapp/score_screen.dart';
import 'package:procastimate_app/mainapp/main_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  int _selectedIndex = 1;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  String _userName = "Your Name"; // default until loaded from prefs

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadProfileImage();
  }

  // 🔄 Load saved name
  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('username');
    if (saved != null && saved.isNotEmpty) {
      setState(() {
        _userName = saved;
      });
    }
  }

  // 💾 Save name
  Future<void> _saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', name);
  }

  // 🔄 Load saved profile image
  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profileImagePath');
    if (imagePath != null && imagePath.isNotEmpty) {
      setState(() {
        _profileImage = File(imagePath);
      });
    }
  }

  // 💾 Save image path
  Future<void> _saveProfileImage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileImagePath', path);
  }

  // 📸 Pick image (Camera or Gallery)
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
                final XFile? image =
                    await _picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  setState(() => _profileImage = File(image.path));
                  _saveProfileImage(image.path);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt, size: 35),
              onPressed: () async {
                Navigator.pop(context);
                final XFile? image =
                    await _picker.pickImage(source: ImageSource.camera);
                if (image != null) {
                  setState(() => _profileImage = File(image.path));
                  _saveProfileImage(image.path);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ✏️ Edit Name Dialog
  void _showEditProfileDialog() {
    TextEditingController nameController =
        TextEditingController(text: _userName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Enter your name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  setState(() {
                    _userName = newName;
                  });
                  await _saveUserName(newName);
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allTasks = tasksByDate.values.expand((t) => t).toList();
    final completedCount = allTasks.where((t) => t.completed).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EF),
      appBar: AppBar(
        backgroundColor: Colors.brown.shade800,
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
            // PROFILE SECTION
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
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : const AssetImage('assets/profile_placeholder.png')
                              as ImageProvider,
                      child: _profileImage == null
                          ? const Icon(Icons.person,
                              size: 60, color: Colors.black54)
                          : null,
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                // Points + Task summary + Name
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: const [
                        Icon(Icons.stars_sharp, color: Colors.orange, size: 40),
                        SizedBox(width: 6),
                        Text(
                          '0',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Points obtained!\n',
                      style: TextStyle(color: Colors.black, fontSize: 22),
                    ),
                    Text(
                      '$completedCount Tasks completed',
                      style:
                          const TextStyle(color: Colors.black, fontSize: 15),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ✏️ Edit Profile Button
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

            // TASK VIEW SECTION
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
                    'Task View',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (allTasks.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No tasks available.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    )
                  else
                    for (final task in allTasks.take(3))
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
                            Row(
                              children: [
                                Checkbox(
                                  value: task.completed,
                                  onChanged: (_) {},
                                  activeColor: Colors.brown.shade800,
                                ),
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      decoration: task.completed
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Due: ${task.dueDate != null ? "${task.dueDate!.month}/${task.dueDate!.day} ${task.dueDate!.hour}:${task.dueDate!.minute.toString().padLeft(2, '0')}" : "No due date"}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                            if (task.description != null &&
                                task.description!.isNotEmpty)
                              Text(
                                task.description!,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54),
                              ),
                            const Text(
                              'Type: Project',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black54),
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
                MaterialPageRoute(builder: (_) => const CalendarScreen()));
          } else if (i == 1) {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => MainScreen()));
          } else if (i == 2) {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ScoreScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'Calendar'),
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
