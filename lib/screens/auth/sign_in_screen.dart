import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/material.dart';

import 'package:gut_md/core/backend_service_provider.dart';
import 'package:gut_md/screens/auth/sign_up_screen.dart';
import 'package:gut_md/screens/home/home_screen.dart';
import 'package:gut_md/screens/onboarding/onboarding_flow.dart';
import 'package:gut_md/screens/onboarding/onboarding_theme.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

/// Email validator shared by sign in, sign up and password reset.
String? validateAuthEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Please enter your email';
  if (!_emailPattern.hasMatch(email)) return 'Please enter a valid email';
  return null;
}

/// Turns an authentication failure into a short message that is safe to show.
String authErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'That email address doesn\'t look right.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'email-already-in-use':
      case 'credential-already-in-use':
        return 'An account already exists for that email. Try signing in instead.';
      case 'account-exists-with-different-credential':
        return 'An account already exists for that email with a different sign-in method.';
      case 'weak-password':
        return 'That password is too weak. Choose a stronger one.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Check your connection and try again.';
      case 'popup-blocked':
        return 'Your browser blocked the sign-in window. Allow pop-ups and try again.';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
      case 'web-context-canceled':
      case 'canceled':
        return 'Sign-in was cancelled.';
      case 'operation-not-allowed':
        return 'This sign-in method isn\'t available right now.';
    }
    return error.message ?? 'Something went wrong. Please try again.';
  }
  final text = error.toString();
  const prefix = 'Exception: ';
  if (error is Exception && text.startsWith(prefix)) {
    return text.substring(prefix.length);
  }
  return 'Something went wrong. Please try again.';
}

/// Text field decoration for the auth screens (light text on the dark gradient).
InputDecoration authInputDecoration({
  required String label,
  required IconData icon,
  String? helperText,
  Widget? suffixIcon,
}) {
  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
    floatingLabelStyle: const TextStyle(color: Colors.white),
    helperText: helperText,
    helperMaxLines: 2,
    helperStyle: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
    errorStyle: const TextStyle(color: Color(0xFFFCA5A5)),
    errorMaxLines: 2,
    prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.75)),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.1),
    enabledBorder: border(Colors.white.withValues(alpha: 0.3)),
    focusedBorder: border(Colors.white, 1.5),
    errorBorder: border(const Color(0xFFFCA5A5)),
    focusedErrorBorder: border(const Color(0xFFFCA5A5), 1.5),
  );
}

/// Show/hide toggle for password fields, with an accessible name.
class PasswordVisibilityToggle extends StatelessWidget {
  final bool obscured;
  final VoidCallback onPressed;

  const PasswordVisibilityToggle({Key? key, required this.obscured, required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: obscured ? 'Show password' : 'Hide password',
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: Colors.white.withValues(alpha: 0.75),
      ),
      onPressed: onPressed,
    );
  }
}

/// Full-screen gradient layout shared by the sign-in and sign-up screens.
/// Shows a back button only when there is a screen to go back to.
class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const AuthScaffold({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: OnboardingTheme.primaryGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.spa_outlined,
                          size: 32,
                          color: OnboardingTheme.accentIndigo,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'GutMD',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: OnboardingTheme.indigoGlow,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Primary call-to-action button for the auth screens.
class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const AuthPrimaryButton({
    Key? key,
    required this.label,
    required this.loading,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: OnboardingTheme.accentIndigo,
          foregroundColor: Colors.white,
          disabledBackgroundColor: OnboardingTheme.accentIndigo.withValues(alpha: 0.6),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}

/// "or continue with" divider followed by the Google and Apple buttons.
class SocialSignInButtons extends StatelessWidget {
  final VoidCallback? onGoogle;
  final VoidCallback? onApple;

  const SocialSignInButtons({Key? key, required this.onGoogle, required this.onApple})
      : super(key: key);

  Widget _button({required String label, required Widget icon, required VoidCallback? onPressed}) {
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.3))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'or continue with',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 14),
              ),
            ),
            Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.3))),
          ],
        ),
        const SizedBox(height: 24),
        _button(
          label: 'Continue with Google',
          icon: const Icon(Icons.g_mobiledata, size: 28),
          onPressed: onGoogle,
        ),
        const SizedBox(height: 12),
        _button(
          label: 'Continue with Apple',
          icon: const Icon(Icons.apple, size: 24),
          onPressed: onApple,
        ),
      ],
    );
  }
}

/// "Don't have an account? Sign Up" style footer link.
class AuthSwitchLink extends StatelessWidget {
  final String prompt;
  final String action;
  final VoidCallback? onPressed;

  const AuthSwitchLink({
    Key? key,
    required this.prompt,
    required this.action,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prompt, style: TextStyle(color: Colors.white.withValues(alpha: 0.75))),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(foregroundColor: OnboardingTheme.lightIndigo),
          child: Text(action, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

/// Shows an auth error in a snackbar with readable contrast.
void showAuthError(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFB91C1C),
      ),
    );
}

class SignInScreen extends StatefulWidget {
  final bool shouldReturnToOnboarding;

  /// True when this screen was opened from the sign-up screen, so "Sign Up"
  /// goes back instead of stacking another sign-up screen.
  final bool openedFromSignUp;

  const SignInScreen({
    Key? key,
    this.shouldReturnToOnboarding = false,
    this.openedFromSignUp = false,
  }) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _goToApp() {
    developer.log(
      widget.shouldReturnToOnboarding ? 'Signed in, returning to onboarding' : 'Signed in, opening home',
      name: 'SignInScreen',
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) =>
            widget.shouldReturnToOnboarding ? const OnboardingFlow() : const HomeScreen(),
      ),
      (route) => false,
    );
  }

  /// Runs a sign-in attempt, then opens the app or shows why it failed.
  Future<void> _runSignIn(String method, Future<AppUser?> Function(UnifiedAuthService auth) attempt) async {
    developer.log('Attempting $method sign in', name: 'SignInScreen');
    setState(() => _isLoading = true);
    try {
      await BackendServiceProvider.initialize();
      final user = await attempt(BackendServiceProvider.instance.auth);
      if (!mounted) return;
      if (user != null) {
        _goToApp();
      } else {
        showAuthError(context, 'Sign in failed. Please try again.');
      }
    } catch (e, stackTrace) {
      developer.log('$method sign in failed', name: 'SignInScreen', error: e, stackTrace: stackTrace);
      if (mounted) showAuthError(context, authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    await _runSignIn(
      'email',
      (auth) => auth.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  Future<void> _showForgotPassword() async {
    await showDialog<void>(
      context: context,
      builder: (context) => _ForgotPasswordDialog(initialEmail: _emailController.text.trim()),
    );
  }

  void _openSignUp() {
    if (widget.openedFromSignUp) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SignUpScreen(
          shouldReturnToOnboarding: widget.shouldReturnToOnboarding,
          openedFromSignIn: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to keep tracking your gut health',
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _isLoading ? null : _signIn(),
                style: const TextStyle(color: Colors.white),
                decoration: authInputDecoration(
                  label: 'Password',
                  icon: Icons.lock_outline,
                  suffixIcon: PasswordVisibilityToggle(
                    obscured: _obscurePassword,
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : _showForgotPassword,
                  style: TextButton.styleFrom(foregroundColor: OnboardingTheme.lightIndigo),
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 8),
              AuthPrimaryButton(label: 'Sign In', loading: _isLoading, onPressed: _signIn),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SocialSignInButtons(
          onGoogle: _isLoading ? null : () => _runSignIn('Google', (auth) => auth.signInWithGoogle()),
          onApple: _isLoading ? null : () => _runSignIn('Apple', (auth) => auth.signInWithApple()),
        ),
        const SizedBox(height: 16),
        AuthSwitchLink(
          prompt: 'Don\'t have an account?',
          action: 'Sign Up',
          onPressed: _isLoading ? null : _openSignUp,
        ),
      ],
    );
  }
}

/// Asks for an email address and sends a password reset link to it.
class _ForgotPasswordDialog extends StatefulWidget {
  final String initialEmail;

  const _ForgotPasswordDialog({required this.initialEmail});

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController =
      TextEditingController(text: widget.initialEmail);
  bool _sending = false;
  String? _error;
  String? _sentTo;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await BackendServiceProvider.initialize();
      await BackendServiceProvider.instance.auth.sendPasswordReset(email);
      if (mounted) setState(() => _sentTo = email);
    } catch (e, stackTrace) {
      developer.log('Password reset failed', name: 'SignInScreen', error: e, stackTrace: stackTrace);
      if (!mounted) return;
      // Never reveal whether an account exists for an address.
      if (e is FirebaseAuthException && e.code == 'user-not-found') {
        setState(() => _sentTo = email);
      } else {
        setState(() => _error = authErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sentTo = _sentTo;
    if (sentTo != null) {
      return AlertDialog(
        title: const Text('Check your email'),
        content: Text(
          'If an account exists for $sentTo, we\'ve sent it a link to reset your password. '
          'It can take a few minutes to arrive, so check your spam folder too.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      );
    }
    return AlertDialog(
      title: const Text('Reset your password'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Enter the email you use for GutMD and we\'ll send you a link to reset your password.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.send,
              onFieldSubmitted: (_) => _sending ? null : _send(),
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: validateAuthEmail,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Color(0xFFFCA5A5))),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _sending ? null : _send,
          style: ElevatedButton.styleFrom(
            backgroundColor: OnboardingTheme.accentIndigo,
            foregroundColor: Colors.white,
          ),
          child: _sending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Send reset link'),
        ),
      ],
    );
  }
}
