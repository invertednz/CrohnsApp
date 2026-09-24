import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import 'package:gut_md/core/backend_service_provider.dart';
import 'package:gut_md/screens/auth/sign_in_screen.dart';
import 'package:gut_md/screens/home/home_screen.dart';
import 'package:gut_md/screens/onboarding/onboarding_flow.dart';

/// Password rules for new accounts, shown under the password field.
const passwordRulesText = 'At least 8 characters, with a letter and a number';

/// Validates a new account password against [passwordRulesText].
String? validateNewPassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return 'Please enter a password';
  if (password.length < 8) return 'Password must be at least 8 characters';
  if (!password.contains(RegExp(r'[A-Za-z]')) || !password.contains(RegExp(r'[0-9]'))) {
    return 'Password must include a letter and a number';
  }
  return null;
}

class SignUpScreen extends StatefulWidget {
  final bool shouldReturnToOnboarding;

  /// True when this screen was opened from the sign-in screen, so "Sign In"
  /// goes back instead of stacking another sign-in screen.
  final bool openedFromSignIn;

  const SignUpScreen({
    Key? key,
    this.shouldReturnToOnboarding = false,
    this.openedFromSignIn = false,
  }) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  /// A signed-in guest is upgrading to a full account; their data carries over.
  bool get _isUpgradingGuest {
    if (!BackendServiceProvider.isInitialized) return false;
    return BackendServiceProvider.instance.auth.currentUser?.isAnonymous ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _goToApp() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) =>
            widget.shouldReturnToOnboarding ? const OnboardingFlow() : const HomeScreen(),
      ),
      (route) => false,
    );
  }

  /// Runs an account attempt, then opens the app or shows why it failed.
  Future<void> _runAuth(String method, Future<AppUser?> Function(UnifiedAuthService auth) attempt) async {
    developer.log('Attempting $method', name: 'SignUpScreen');
    setState(() => _isLoading = true);
    try {
      await BackendServiceProvider.initialize();
      final user = await attempt(BackendServiceProvider.instance.auth);
      if (!mounted) return;
      if (user != null) {
        _goToApp();
      } else {
        showAuthError(context, 'We couldn\'t create your account. Please try again.');
      }
    } catch (e, stackTrace) {
      developer.log('$method failed', name: 'SignUpScreen', error: e, stackTrace: stackTrace);
      if (mounted) showAuthError(context, authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUpWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    await _runAuth(
      'email sign up',
      (auth) => auth.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        userData: {'name': name},
      ),
    );
  }

  void _openSignIn() {
    if (widget.openedFromSignIn) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SignInScreen(
          shouldReturnToOnboarding: widget.shouldReturnToOnboarding,
          openedFromSignUp: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final upgradingGuest = _isUpgradingGuest;
    return AuthScaffold(
      title: 'Create Account',
      subtitle: upgradingGuest
          ? 'Save everything you\'ve logged as a guest to a GutMD account'
          : 'Start your gut health journey',
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: Colors.white),
                decoration: authInputDecoration(label: 'Name', icon: Icons.person_outline),
                validator: (value) {
                  final name = value?.trim() ?? '';
                  if (name.isEmpty) return 'Please enter your name';
                  if (name.length > 50) return 'Name must be 50 characters or fewer';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: Colors.white),
                decoration: authInputDecoration(label: 'Email', icon: Icons.email_outlined),
                validator: validateAuthEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: Colors.white),
                decoration: authInputDecoration(
                  label: 'Password',
                  icon: Icons.lock_outline,
                  helperText: passwordRulesText,
                  suffixIcon: PasswordVisibilityToggle(
                    obscured: _obscurePassword,
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: validateNewPassword,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _isLoading ? null : _signUpWithEmail(),
                style: const TextStyle(color: Colors.white),
                decoration: authInputDecoration(
                  label: 'Confirm password',
                  icon: Icons.lock_outline,
                  suffixIcon: PasswordVisibilityToggle(
                    obscured: _obscureConfirm,
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please confirm your password';
                  if (value != _passwordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: 'Create Account',
                loading: _isLoading,
                onPressed: _signUpWithEmail,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SocialSignInButtons(
          onGoogle: _isLoading ? null : () => _runAuth('Google sign up', (auth) => auth.signInWithGoogle()),
          onApple: _isLoading ? null : () => _runAuth('Apple sign up', (auth) => auth.signInWithApple()),
        ),
        if (!upgradingGuest) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: TextButton(
              onPressed: _isLoading ? null : () => _runAuth('guest sign in', (auth) => auth.signInAsGuest()),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text(
                'Continue as guest',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Text(
            'Try GutMD without an account. You can create one later to keep your data.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.75)),
          ),
        ],
        const SizedBox(height: 16),
        AuthSwitchLink(
          prompt: 'Already have an account?',
          action: 'Sign In',
          onPressed: _isLoading ? null : _openSignIn,
        ),
        const SizedBox(height: 8),
        Text(
          'By creating an account, you agree to our Terms of Service and Privacy Policy',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
        ),
      ],
    );
  }
}
