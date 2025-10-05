import 'package:flutter/material.dart';
import 'package:procastimate_app/services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false; // local placeholder

  void _showResetPasswordDialog() {
    final TextEditingController emailController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password (placeholder)'),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'Enter your email'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reset password placeholder — implement backend call')),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await AuthService.instance.signOut();
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed out')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign out failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('Reset Password'),
            subtitle: const Text('Sends a password reset email (placeholder)'),
            trailing: ElevatedButton(
              onPressed: _showResetPasswordDialog,
              child: const Text('Reset'),
            ),
          ),
          const Divider(),
          // Local placeholder switch (does not change app theme yet)
          SwitchListTile(
            title: const Text('Dark mode (placeholder)'),
            subtitle: const Text('Local toggle only — not persisted'),
            value: _darkMode,
            onChanged: (v) {
              setState(() => _darkMode = v);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Dark mode placeholder: ${v ? 'on' : 'off'}')),
              );
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black87),
                onPressed: _signOut,
                child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}