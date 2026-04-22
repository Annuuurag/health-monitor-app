import 'package:flutter/material.dart';

import '../../app/state/app_controller.dart';
import '../../core/app_colors.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  _AuthMode _mode = _AuthMode.welcome;

  @override
  Widget build(BuildContext context) {
    if (_mode == _AuthMode.welcome) {
      return _AuthWelcome(
        onSignUp: () => setState(() => _mode = _AuthMode.signUp),
        onLogIn: () => setState(() => _mode = _AuthMode.signIn),
      );
    }

    final isSignUp = _mode == _AuthMode.signUp;
    final title = isSignUp ? 'Create your account' : 'Welcome Back!';
    final actionLabel = isSignUp ? 'Get Started' : 'Log In';

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => setState(() => _mode = _AuthMode.welcome),
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
              const SizedBox(height: 6),
              const _AuthHero(),
              const SizedBox(height: 28),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.darkBackground,
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              _socialButton(
                icon: Icons.facebook_outlined,
                label: 'Continue with Facebook',
              ),
              const SizedBox(height: 12),
              _socialButton(
                icon: Icons.g_mobiledata,
                label: 'Continue with Google',
              ),
              const SizedBox(height: 24),
              Text(
                isSignUp ? 'OR SIGN UP WITH EMAIL' : 'OR LOG IN WITH EMAIL',
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              if (isSignUp) ...[
                const _AuthField(label: 'Full name'),
                const SizedBox(height: 12),
              ],
              const _AuthField(label: 'Email address'),
              const SizedBox(height: 12),
              const _AuthField(label: 'Password', obscureText: true),
              if (isSignUp) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Checkbox(value: true, onChanged: (_) {}),
                    const Expanded(
                      child: Text(
                        'I have read the Privacy Policy',
                        style: TextStyle(color: AppColors.mutedText),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 10),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(color: AppColors.mutedText),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.controller.signIn,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: Text(actionLabel),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(
                  () => _mode = isSignUp ? _AuthMode.signIn : _AuthMode.signUp,
                ),
                child: Text(
                  isSignUp
                      ? 'Already have an account? Log In'
                      : 'Don\'t have an account? Sign Up',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialButton({required IconData icon, required String label}) {
    return OutlinedButton.icon(
      onPressed: widget.controller.signIn,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        backgroundColor: Colors.white,
      ),
      icon: Icon(icon, color: AppColors.teal),
      label: Text(label),
    );
  }
}

enum _AuthMode { welcome, signIn, signUp }

class _AuthWelcome extends StatelessWidget {
  const _AuthWelcome({required this.onSignUp, required this.onLogIn});

  final VoidCallback onSignUp;
  final VoidCallback onLogIn;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            children: [
              const Spacer(),
              const _AuthHero(),
              const SizedBox(height: 34),
              const Text(
                'We are what we do',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.darkBackground,
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Let\'s keep your pulse in Rhythm!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 18,
                  height: 1.35,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onSignUp,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: const Text('Sign Up'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: onLogIn,
                child: const Text('Already have an account? Log In'),
              ),
              const SizedBox(height: 14),
              Container(
                width: 82,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFB7B0A7),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthHero extends StatelessWidget {
  const _AuthHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF7F2E9), Color(0xFFEEE5D7)],
                ),
              ),
            ),
          ),
          Positioned(
            left: -24,
            right: -24,
            top: -34,
            child: Container(
              height: 145,
              decoration: const BoxDecoration(
                color: AppColors.softLilac,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(42),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: -16,
            child: Container(
              height: 76,
              decoration: const BoxDecoration(
                color: AppColors.softLilacDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(38)),
              ),
            ),
          ),
          Positioned(
            right: 18,
            top: 16,
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.cream,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Center(
            child: Icon(Icons.favorite_outline, size: 82, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({required this.label, this.obscureText = false});

  final String label;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscureText,
      decoration: InputDecoration(labelText: label),
    );
  }
}
