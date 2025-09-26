import 'package:flutter/material.dart';
import 'package:procastimate_app/util/colors.dart';
import 'package:procastimate_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.userChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final email = user?.email;

        return Scaffold(
          body: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kAccentA, kAccentB],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: 200,
                      height: 350,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 32),
                    if (email == null || email.isEmpty) ...[
                      const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 250,
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/signin'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: const StadiumBorder(),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 220,
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/signup'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.black12),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Account',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Signed in as',
                        style:
                            TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          await AuthService.instance.signOut();
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Signed out')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 14),
                        ),
                        child: const Text(
                          'Sign Out',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
