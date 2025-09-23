import 'package:flutter/material.dart';
import 'package:procastimate_app/util/colors.dart';
import 'package:procastimate_app/services/auth_service.dart';
// Firebase removed for now — mock sign-out

class HomeScreen extends StatelessWidget {
  final String? email;
  const HomeScreen({super.key, this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.black87,
      ),
      body: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kAccentA, kAccentB],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                // small top card with logo
                Center(
                  child: Container(
                    height: 110,
                    width: MediaQuery.of(context).size.width * 0.5,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6))],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset('assets/logo.png', width: 80, height: 80, fit: BoxFit.contain),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // buttons below
                if (email == null || email!.isEmpty) ...[
                  SizedBox(
                    width: 220,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pushNamed('/signin'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('Sign In', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 220,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pushNamed('/signup'),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.black12), backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                      child: const Text('Sign Up', style: TextStyle(color: Colors.black87)),
                    ),
                  ),
                ] else ...[
                  // when signed in show the signed in view
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Signed in as',
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          email ?? AuthService.instance.currentUserEmail ?? '',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            await AuthService.instance.signOut();
                            Navigator.of(context).popUntil((route) => route.isFirst);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Signed out (mock)')),
                            );
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.black87),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                ],
              ],
            ),
      ),
    );
  }
}

// Simple placeholder that returns to previous route (or could clear auth state)
// _SignOutPlaceholder removed; sign-out now performs Firebase signOut and returns to first route.
