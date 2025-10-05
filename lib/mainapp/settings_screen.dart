import 'package:flutter/material.dart';
import 'package:procastimate_app/services/auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:procastimate_app/screens/home_screen.dart'; // added import

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
        title: const Text('Reset Password'),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'Enter your email'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid email address')));
                return;
              }
              Navigator.of(ctx).pop();

              // Guard: ensure Firebase was initialized
              if (Firebase.apps.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Firebase not initialized')));
                return;
              }

              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(const SnackBar(content: Text('Sending reset email...')));
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                messenger.showSnackBar(const SnackBar(content: Text('Password reset email sent')));
              } on FirebaseAuthException catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('Error: ${e.message ?? e.code}')));
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    // Guard: ensure Firebase was initialized
    if (Firebase.apps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Firebase not initialized')));
      return;
    }

    try {
      await FirebaseAuth.instance.signOut();
      try { await AuthService.instance.signOut(); } catch (_) {}
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed out')));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign out failed: ${e.message ?? e.code}')));
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
            subtitle: const Text('Sends a password reset email'),
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