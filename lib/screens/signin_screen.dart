import 'package:flutter/material.dart';
import 'package:procastimate_app/util/colors.dart';
import 'package:procastimate_app/screens/signup_screen.dart';
import 'package:procastimate_app/mainapp/main_screen.dart';
import 'package:procastimate_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _trySignIn() async {
    if (!mounted) return;
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _error = null);
      try {
        final dynamic result = await AuthService.instance.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );

        debugPrint('signIn result: $result (${result.runtimeType})');

        String? email;
        if (result == null) {
          setState(() => _error = 'Sign in failed. Please try again.');
          return;
        } else if (result is String) {
          email = result;
        } else if (result is User) {
          email = (result as User).email;
        } else {
          // fallback: try to extract email if result provides it, otherwise use toString()
          try {
            final possibleEmail = (result as dynamic).email;
            if (possibleEmail is String) {
              email = possibleEmail;
            } else {
              email = result.toString();
            }
          } catch (_) {
            email = result.toString();
          }
        }

        if (email != null && email.isNotEmpty) {
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => MainScreen(email: email)),
            (route) => false,
          );
        } else {
          setState(() => _error = 'Sign in succeeded but no email returned.');
        }
      } catch (e, st) {
        debugPrint('signIn error: $e\n$st');
        if (!mounted) return;
        setState(() => _error = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              hexStringToColorValue("BCA88D"),
              hexStringToColorValue("BCA88D"),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 🔙 Back Arrow Button
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/');
                  },
                ),
              ),

              // Main content
              Center(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Image.asset(
                            'assets/logo.png',
                            width: 200,
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Welcome back',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            filled: true,
                            fillColor: Colors.white70,
                            hintText: 'Email',
                            prefixIcon: Icon(Icons.email),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(value.trim())) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white70,
                            hintText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                  _obscure ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _trySignIn,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.black87,
                          ),
                          child: const Text('Sign In'),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SignUp()),
                            );
                          },
                          child: const Text(
                            'Don\'t have an account? Sign up',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
