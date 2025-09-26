import 'package:flutter/material.dart';
import 'package:procastimate_app/util/colors.dart';
import 'package:procastimate_app/screens/home_screen.dart';
import 'package:procastimate_app/services/auth_service.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _trySignUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final user = await AuthService.instance.createUserWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (user != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          setState(() => _error = 'Sign up failed. Please try again.');
        }
      } catch (e) {
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
              // 🔙 Back Arrow
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  },
                ),
              ),

              // 👉 Main content
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
                            width: 250,
                            height: 250,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Create Account',
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
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmController,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white70,
                            hintText: 'Confirm Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                  _obscureConfirm ? Icons.visibility : Icons.visibility_off),
                              onPressed: () =>
                                  setState(() => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
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
                          onPressed: _trySignUp,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.black87,
                          ),
                          child: const Text('Sign Up'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            MaterialPageRoute(builder: (_) => const SignIn());
                          },
                          child: const Text(
                            'Already have an account? Sign in',
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