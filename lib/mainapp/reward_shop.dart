import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:procastimate_app/mainapp/score_screen.dart';
import 'dart:convert';

class RewardShopScreen extends StatefulWidget {
  const RewardShopScreen({super.key});

  @override
  State<RewardShopScreen> createState() => _RewardShopScreenState();
}

class _RewardShopScreenState extends State<RewardShopScreen> {
  List<Map<String, dynamic>> rewards = [];
  int? selectedIndex;
  int currentPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadPoints();
    _loadRewards();
  }

  // 🔹 Load saved points
  Future<void> _loadPoints() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentPoints = prefs.getInt('score') ?? 0;
    });
  }

  // 🔹 Save and load rewards to SharedPreferences
  Future<void> _saveRewards() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = rewards.map((r) => jsonEncode(r)).toList();
    await prefs.setStringList('customRewards', encoded);
  }

  Future<void> _loadRewards() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('customRewards') ?? [];
    setState(() {
      rewards = stored.map((r) => jsonDecode(r) as Map<String, dynamic>).toList();
    });
  }

  // 🔹 Deduct points
  Future<void> _deductPoints(int points) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentPoints -= points;
      if (currentPoints < 0) currentPoints = 0;
    });
    await prefs.setInt('score', currentPoints);
  }

  // 🔹 Add new custom reward
  void _showCustomizeDialog(BuildContext context) {
    final rewardController = TextEditingController();
    final pointsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF7F3EF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Customize Reward',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: rewardController,
              decoration: const InputDecoration(
                labelText: 'Reward Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pointsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Required Points',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown.shade800,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              if (rewardController.text.isNotEmpty &&
                  pointsController.text.isNotEmpty) {
                setState(() {
                  rewards.add({
                    'reward': rewardController.text,
                    'points': pointsController.text,
                  });
                });
                _saveRewards();
              }
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 🔹 Delete reward
  void _deleteReward(int index) {
    setState(() {
      rewards.removeAt(index);
      selectedIndex = null;
    });
    _saveRewards();
  }

  // 🔹 Claim reward
  void _confirmReward(int index) async {
    final pointsRequired = int.tryParse(rewards[index]['points'] ?? '0') ?? 0;
    if (currentPoints >= pointsRequired) {
      await _deductPoints(pointsRequired);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '🎉 Reward "${rewards[index]['reward']}" claimed! $pointsRequired points deducted.'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough points to claim this reward.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double boxWidth = MediaQuery.of(context).size.width * 0.9;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EF),
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFF7F3EF),
                  Color(0xFFEAD9C3),
                  Color(0xFFF7F3EF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 🔹 Top App Bar
                Container(
                  height: 72,
                  color: Colors.brown.shade800,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const ScoreScreen()),
                          );
                        },
                      ),
                      const Spacer(),
                      const Text(
                        "Reward Shop",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                // 🔹 Customize / Confirm / Delete Buttons
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Spacer(),
                      if (selectedIndex == null)
                        ElevatedButton.icon(
                          onPressed: () => _showCustomizeDialog(context),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text(
                            "Add Reward",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                        )
                      else
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => _deleteReward(selectedIndex!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _confirmReward(selectedIndex!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                "Confirm",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // 🔹 Title + Points Display
                const Text(
                  "You've Earned This!",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.stars, color: Colors.orange, size: 32),
                    const SizedBox(width: 6),
                    Text(
                      '$currentPoints',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('Points',
                        style: TextStyle(fontSize: 18, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 16),

                // 🔹 Reward List
                Expanded(
                  child: Container(
                    width: boxWidth,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: rewards.isEmpty
                        ? Container(
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'No rewards yet. Add one!',
                                style: TextStyle(
                                    color: Colors.black54, fontSize: 16),
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: rewards.length,
                            itemBuilder: (context, index) {
                              final reward = rewards[index];
                              final isSelected = selectedIndex == index;

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedIndex =
                                        isSelected ? null : index;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.orange.shade50
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.orange
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        reward['reward'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.stars,
                                              color: Colors.orange, size: 26),
                                          const SizedBox(width: 4),
                                          Text(
                                            reward['points'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
