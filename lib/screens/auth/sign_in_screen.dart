import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:gut_md/core/theme/app_theme.dart';
import 'package:gut_md/core/backend_service_provider.dart';
import 'package:gut_md/screens/auth/sign_up_screen.dart';
import 'package:gut_md/screens/home/home_screen.dart';
import 'package:gut_md/screens/onboarding/onboarding_flow.dart';

class SignInScreen extends StatefulWidget {
  final bool shouldReturnToOnboarding;

  const SignInScreen({Key? key, this.shouldReturnToOnboarding = false}) : super(key: key);

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
  void initState() {
    developer.log('Initializing SignInScreen', name: 'SignInScreen');
    super.initState();
  }

  @override
  void dispose() {
    developer.log('Disposing SignInScreen', name: 'SignInScreen');
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _ensureBackendInitialized() async {
    try {
      // Try to access instance - if not initialized, initialize it
      BackendServiceProvider.instance;
    } catch (e) {
      developer.log('Backend not initialized, initializing now...', name: 'SignInScreen');
      await BackendServiceProvider.initialize();
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    developer.log('Attempting Google sign in', name: 'SignInScreen');
    setState(() {
      _isLoading = true;
    });

    try {
      await _ensureBackendInitialized();
      final authService = BackendServiceProvider.instance.auth;
      final user = await authService.signInWithGoogle();

      if (!mounted) {
        developer.log('Widget not mounted after Google sign in', name: 'SignInScreen');
        return;
      }

      if (user != null) {
        developer.log('Google sign in successful', name: 'SignInScreen');
        if (widget.shouldReturnToOnboarding) {
          developer.log('Navigating to OnboardingFlow after Google sign in', name: 'SignInScreen');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const OnboardingFlow()),
            (route) => false,
          );
        } else {
          developer.log('Navigating to HomeScreen after Google sign in', name: 'SignInScreen');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      } else {
        developer.log('Google sign in failed: user is null', name: 'SignInScreen');
        _showError('Sign in failed. Please try again.');
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error during Google sign in',
        name: 'SignInScreen',
        error: e,
        stackTrace: stackTrace,
      );
      _showError('Sign in error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithApple() async {
    developer.log('Attempting Apple sign in', name: 'SignInScreen');
    setState(() {
      _isLoading = true;
    });

    try {
      await _ensureBackendInitialized();
      final authService = BackendServiceProvider.instance.auth;
      final user = await authService.signInWithApple();

      if (!mounted) {
        developer.log('Widget not mounted after Apple sign in', name: 'SignInScreen');
        return;
      }

      if (user != null) {
        developer.log('Apple sign in successful', name: 'SignInScreen');
        if (widget.shouldReturnToOnboarding) {
          developer.log('Navigating to OnboardingFlow after Apple sign in', name: 'SignInScreen');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const OnboardingFlow()),
            (route) => false,
          );
        } else {
          developer.log('Navigating to HomeScreen after Apple sign in', name: 'SignInScreen');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      } else {
        developer.log('Apple sign in failed: user is null', name: 'SignInScreen');
        _showError('Sign in failed. Please try again.');
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error during Apple sign in',
        name: 'SignInScreen',
        error: e,
        stackTrace: stackTrace,
      );
      _showError('Sign in error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signIn() async {
    developer.log('Attempting email sign in', name: 'SignInScreen');
    // Validate form
    if (!_formKey.currentState!.validate()) {
      developer.log('Form validation failed', name: 'SignInScreen');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _ensureBackendInitialized();
      developer.log('Initializing auth service', name: 'SignInScreen');
      final authService = BackendServiceProvider.instance.auth;
      developer.log('Calling signInWithEmail', name: 'SignInScreen');
      final user = await authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        developer.log('Widget not mounted after sign in', name: 'SignInScreen');
        return;
      }

      if (user != null) {
        developer.log('Sign in successful', name: 'SignInScreen');
        if (widget.shouldReturnToOnboarding) {
          developer.log('Navigating to OnboardingFlow after email sign in', name: 'SignInScreen');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const OnboardingFlow()),
            (route) => false,
          );
        } else {
          developer.log('Navigating to HomeScreen after email sign in', name: 'SignInScreen');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      } else {
        developer.log('Sign in failed: user is null', name: 'SignInScreen');
        _showError('Sign in failed. Please check your credentials.');
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error during sign in',
        name: 'SignInScreen',
        error: e,
        stackTrace: stackTrace,
      );
      _showError('Sign in error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    developer.log('Building SignInScreen widget', name: 'SignInScreen');
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App logo and name
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.medical_services_outlined,
                                size: 40,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Crohn\'s Companion',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Your personal health tracker',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Card containing the form
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Email field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                      .hasMatch(value)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              // Password field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              // Forgot password button
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    // TODO: Implement forgot password
                                  },
                                  child: const Text('Forgot Password?'),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Sign in button
                              ElevatedButton(
                                onPressed: _isLoading ? null : _signIn,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                              Colors.white),
                                        ),
                                      )
                                    : const Text('Sign In'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Or sign in with
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Or sign in with',
                            style: TextStyle(color: AppTheme.lightTextColor),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Social sign in buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Google sign in
                        OutlinedButton(
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          style: OutlinedButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(12),
                          ),
                          child: const Icon(
                            Icons.g_mobiledata,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Apple sign in
                        OutlinedButton(
                          onPressed: _isLoading ? null : _signInWithApple,
                          style: OutlinedButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(12),
                          ),
                          child: const Icon(Icons.apple),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Sign up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Don\'t have an account?',
                          style: TextStyle(color: AppTheme.lightTextColor),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => SignUpScreen(
                                  shouldReturnToOnboarding: widget.shouldReturnToOnboarding,
                                ),
                              ),
                            );
                          },
                          child: const Text('Sign Up'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}