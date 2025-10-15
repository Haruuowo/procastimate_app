import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:procastimate_app/mainapp/score_screen.dart';

class RewardShopScreen extends StatefulWidget {
  const RewardShopScreen({super.key});

  @override
  State<RewardShopScreen> createState() => _RewardShopScreenState();
}

class _RewardShopScreenState extends State<RewardShopScreen> {
  List<Map<String, dynamic>> rewards = [];
  int currentPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentPoints = prefs.getInt('score') ?? 0;
      final rewardData = prefs.getString('rewards');
      if (rewardData != null) {
        rewards = List<Map<String, dynamic>>.from(jsonDecode(rewardData));
      }
    });
  }

  Future<void> _saveRewards() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('rewards', jsonEncode(rewards));
  }

  Future<void> _updatePoints(int value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('score', value);
    setState(() {
      currentPoints = value;
    });
  }

  void _showCustomizeDialog() {
    final rewardController = TextEditingController();
    final pointsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF7F3EF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Add Reward',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.brown,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: rewardController,
              decoration: InputDecoration(
                labelText: 'Reward Name',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pointsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Cost (Points)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.brown)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              final rewardName = rewardController.text.trim();
              final cost = int.tryParse(pointsController.text.trim()) ?? 0;
              if (rewardName.isNotEmpty && cost > 0) {
                setState(() {
                  rewards.add({
                    'reward': rewardName,
                    'points': cost,
                    'claimed': false,
                  });
                });
                _saveRewards();
              }
              Navigator.pop(context);
            },
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteReward(int index) {
    setState(() {
      rewards.removeAt(index);
    });
    _saveRewards();
  }

  void _claimReward(int index) async {
    final cost = rewards[index]['points'];
    if (currentPoints >= cost) {
      await _updatePoints((currentPoints - cost).toInt());
      setState(() {
        rewards[index]['claimed'] = true;
      });
      _saveRewards();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade400,
          content: Text(
            'You claimed "${rewards[index]['reward']}"!',
            style: const TextStyle(color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.brown.shade300,
          content: const Text(
            'Not enough points!',
            style: TextStyle(color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EF),
      appBar: AppBar(
        backgroundColor: Colors.brown.shade800,
        elevation: 0,
        title: const Text(
          'Reward Shop',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ScoreScreen()),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCustomizeDialog,
        backgroundColor: Colors.green.shade400,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Reward',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Points Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stars, color: Colors.green, size: 26),
                  const SizedBox(width: 8),
                  Text(
                    '$currentPoints points',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Reward List
            Expanded(
              child: rewards.isEmpty
                  ? const Center(
                      child: Text(
                        'No rewards yet.\nTap "Add Reward" to create one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: rewards.length,
                      itemBuilder: (context, index) {
                        final reward = rewards[index];
                        final isClaimed = reward['claimed'] ?? false;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            title: Text(
                              reward['reward'],
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                decoration: isClaimed
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isClaimed
                                    ? Colors.grey
                                    : Colors.brown.shade900,
                              ),
                            ),
                            subtitle: Text(
                              '${reward['points']} points',
                              style: TextStyle(
                                color: Colors.green.shade400,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isClaimed)
                                  TextButton(
                                    onPressed: () => _claimReward(index),
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.green.shade400,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Claim'),
                                  )
                                else
                                  const Icon(Icons.check_circle,
                                      color: Colors.green),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.brown),
                                  onPressed: () => _deleteReward(index),
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
    );
  }
}
