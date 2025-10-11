import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:procastimate_app/models/task_data.dart';
import 'package:procastimate_app/mainapp/calendar_screen.dart';
import 'package:procastimate_app/mainapp/score_screen.dart';
import 'package:procastimate_app/mainapp/main_screen.dart';

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

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint("⚠️ No authenticated user found");
      return;
    }

    try {
      // Try loading from Firestore
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _userName = data['username'] ?? user.displayName ?? "Your Name";
          _photoUrl = data['photoUrl'] ?? "";
        });
        return;
      }

      // If no Firestore data, create initial profile
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
      
      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('username');
      final savedImagePath = prefs.getString('profileImagePath');
      
      setState(() {
        if (savedName != null) _userName = savedName;
        if (savedImagePath != null) _profileImage = File(savedImagePath);
      });
    }
  }

  Future<void> _updateUserProfile({String? newName, File? newImage, String? imageUrl}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      if (newName != null && newName.isNotEmpty) {
        await user.updateDisplayName(newName);
      }

      // Handle local image
      if (newImage != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profileImagePath', newImage.path);
      }

      // Update Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'username': newName ?? _userName,
        'photoUrl': imageUrl ?? "", // Store URL if provided
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update local state
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
          decoration: const InputDecoration(
            hintText: 'Enter image URL',
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
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  await _updateUserProfile(newImage: File(image.path));
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt, size: 35),
              onPressed: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(source: ImageSource.camera);
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

// Add this method inside the _ProfileTabState class
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
    final allTasks = tasksByDate.values.expand((t) => t).toList();
    final completedCount = allTasks.where((t) => t.completed).length;

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
        title: const Text('Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                          ? const Icon(Icons.person,
                              size: 60, color: Colors.black54)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_userName,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: const [
                        Icon(Icons.stars_sharp,
                            color: Colors.orange, size: 40),
                        SizedBox(width: 6),
                        Text('0',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Points obtained!',
                        style: TextStyle(color: Colors.black, fontSize: 22)),
                    Text('$completedCount Tasks completed',
                        style:
                            const TextStyle(color: Colors.black, fontSize: 15)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _showEditProfileDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown.shade800,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text('Edit Profile',
                  style: TextStyle(color: Colors.white)),
            ),

            const SizedBox(height: 30),
            // Task View Section
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
                  const Text('Task View',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (allTasks.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No tasks available.',
                            style: TextStyle(color: Colors.black54)),
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
                                offset: Offset(0, 2))
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
                            if (task.description != null &&
                                task.description!.isNotEmpty)
                              Text(task.description!,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black54)),
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
                MaterialPageRoute(builder: (_) => const MainScreen()));
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
