@Timeout(Duration(seconds: 60))
library;

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gut_md/core/backend_service_provider.dart';
import 'package:gut_md/screens/auth/sign_in_screen.dart';
import 'package:gut_md/screens/auth/sign_up_screen.dart';
import 'package:gut_md/screens/home/home_screen.dart';
import 'package:gut_md/screens/onboarding/onboarding_flow.dart';
import 'package:gut_md/screens/splash_screen.dart';

/// Phone-sized surface so the auth forms lay out like they do on device.
void _usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _pumpScreen(WidgetTester tester, Widget screen) async {
  _usePhoneSize(tester);
  await tester.pumpWidget(MaterialApp(theme: ThemeData.dark(), home: screen));
  await tester.pump();
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

Future<void> _enter(WidgetTester tester, String label, String value) async {
  await tester.ensureVisible(_field(label));
  await tester.enterText(_field(label), value);
}

/// Lets auth calls finish. The backend was initialised in setUpAll (real
/// zone), so awaiting it from a widget resumes on the real event loop, while
/// the mock's latency timers and route animations run on the fake clock.
/// Alternate between the two; spinners never settle, so no pumpAndSettle.
Future<void> _settle(WidgetTester tester, {int rounds = 4}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump(const Duration(milliseconds: 400));
  }
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final target = find.text(text).last;
  await tester.ensureVisible(target);
  // Focusing a field animates it into view, and a scrolling list ignores
  // taps until the animation ends.
  await tester.pump(const Duration(milliseconds: 500));
  await tester.tap(target);
  await _settle(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await BackendServiceProvider.initialize();
  });

  setUp(() async {
    await BackendServiceProvider.instance.auth.signOut();
  });

  group('validateAuthEmail', () {
    test('accepts plus addressing and long top-level domains', () {
      expect(validateAuthEmail('sam+ibd@gmail.com'), isNull);
      expect(validateAuthEmail('pat@clinic.health'), isNull);
      expect(validateAuthEmail('  padded@example.com  '), isNull);
    });

    test('rejects empty and malformed addresses', () {
      expect(validateAuthEmail(''), 'Please enter your email');
      expect(validateAuthEmail('   '), 'Please enter your email');
      expect(validateAuthEmail('not-an-email'), 'Please enter a valid email');
      expect(validateAuthEmail('a@b'), 'Please enter a valid email');
      expect(validateAuthEmail('a b@example.com'), 'Please enter a valid email');
    });
  });

  group('validateNewPassword', () {
    test('enforces length and a letter plus a number', () {
      expect(validateNewPassword(''), 'Please enter a password');
      expect(validateNewPassword('abc12'), 'Password must be at least 8 characters');
      expect(validateNewPassword('abcdefgh'), 'Password must include a letter and a number');
      expect(validateNewPassword('12345678'), 'Password must include a letter and a number');
      expect(validateNewPassword('gutcheck1'), isNull);
    });
  });

  group('authErrorMessage', () {
    test('maps Firebase codes to friendly messages', () {
      expect(authErrorMessage(FirebaseAuthException(code: 'invalid-credential')), 'Incorrect email or password.');
      expect(authErrorMessage(FirebaseAuthException(code: 'wrong-password')), 'Incorrect email or password.');
      expect(
        authErrorMessage(FirebaseAuthException(code: 'email-already-in-use')),
        'An account already exists for that email. Try signing in instead.',
      );
      expect(authErrorMessage(FirebaseAuthException(code: 'network-request-failed')), contains('internet'));
      expect(authErrorMessage(FirebaseAuthException(code: 'popup-closed-by-user')), 'Sign-in was cancelled.');
    });

    test('strips the Exception prefix and hides unexpected errors', () {
      expect(authErrorMessage(Exception('Invalid email or password')), 'Invalid email or password');
      expect(authErrorMessage(StateError('boom')), 'Something went wrong. Please try again.');
    });
  });

  group('SignInScreen', () {
    testWidgets('shows GutMD branding, not the old name', (tester) async {
      await _pumpScreen(tester, const SignInScreen());
      expect(find.text('GutMD'), findsOneWidget);
      expect(find.textContaining('Crohn'), findsNothing);
    });

    testWidgets('validates empty and invalid input', (tester) async {
      await _pumpScreen(tester, const SignInScreen());
      await _tapText(tester, 'Sign In');
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);

      await _enter(tester, 'Email', 'bad-email');
      await _tapText(tester, 'Sign In');
      expect(find.text('Please enter a valid email'), findsOneWidget);
      expect(BackendServiceProvider.instance.auth.currentUser, isNull);
    });

    testWidgets('signs in with email and opens Home', (tester) async {
      await _pumpScreen(tester, const SignInScreen());
      await _enter(tester, 'Email', 'sam@example.com');
      await _enter(tester, 'Password', 'password123');
      await _tapText(tester, 'Sign In');
      expect(BackendServiceProvider.instance.auth.currentUser?.email, 'sam@example.com');
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Google and Apple buttons sign in', (tester) async {
      await _pumpScreen(tester, const SignInScreen());
      await _tapText(tester, 'Continue with Google');
      expect(BackendServiceProvider.instance.auth.currentUser, isNotNull);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('password toggle has an accessible name and reveals the password', (tester) async {
      await _pumpScreen(tester, const SignInScreen());
      expect(find.byTooltip('Show password'), findsOneWidget);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(find.byTooltip('Hide password'), findsOneWidget);
    });

    testWidgets('forgot password sends a reset link for the typed email', (tester) async {
      await _pumpScreen(tester, const SignInScreen());
      await _enter(tester, 'Email', 'sam@example.com');
      await _tapText(tester, 'Forgot Password?');
      expect(find.text('Reset your password'), findsOneWidget);

      final dialogEmail = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextFormField));
      expect(tester.widget<TextFormField>(dialogEmail).controller?.text, 'sam@example.com');

      await _tapText(tester, 'Send reset link');
      expect(find.text('Check your email'), findsOneWidget);
      expect(find.textContaining('If an account exists for sam@example.com'), findsOneWidget);

      await _tapText(tester, 'Done');
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('forgot password validates the email before sending', (tester) async {
      await _pumpScreen(tester, const SignInScreen());
      await _tapText(tester, 'Forgot Password?');
      await _tapText(tester, 'Send reset link');
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Check your email'), findsNothing);
    });

    testWidgets('Sign Up link opens sign up and Sign In returns', (tester) async {
      await _pumpScreen(tester, const SignInScreen());
      await _tapText(tester, 'Sign Up');
      expect(find.byType(SignUpScreen), findsOneWidget);
      await _tapText(tester, 'Sign In');
      expect(find.byType(SignUpScreen), findsNothing);
      expect(find.byType(SignInScreen), findsOneWidget);
    });
  });

  group('SignUpScreen', () {
    testWidgets('validates name, email, password rules and confirmation', (tester) async {
      await _pumpScreen(tester, const SignUpScreen());
      await _tapText(tester, 'Create Account');
      expect(find.text('Please enter your name'), findsOneWidget);
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter a password'), findsOneWidget);
      expect(find.text('Please confirm your password'), findsOneWidget);

      await _enter(tester, 'Password', 'short');
      await _enter(tester, 'Confirm password', 'different');
      await _tapText(tester, 'Create Account');
      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(BackendServiceProvider.instance.auth.currentUser, isNull);
    });

    testWidgets('creates an account with the entered name and opens Home', (tester) async {
      await _pumpScreen(tester, const SignUpScreen());
      await _enter(tester, 'Name', 'Sam Lee');
      await _enter(tester, 'Email', 'sam.lee@example.com');
      await _enter(tester, 'Password', 'gutcheck1');
      await _enter(tester, 'Confirm password', 'gutcheck1');
      await _tapText(tester, 'Create Account');

      final user = BackendServiceProvider.instance.auth.currentUser;
      expect(user?.email, 'sam.lee@example.com');
      expect(user?.displayName, 'Sam Lee');
      expect(user?.isAnonymous, isFalse);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('continue as guest signs in anonymously and opens Home', (tester) async {
      await _pumpScreen(tester, const SignUpScreen());
      await _tapText(tester, 'Continue as guest');
      expect(BackendServiceProvider.instance.auth.currentUser?.isAnonymous, isTrue);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('a signed-in guest is offered to save their data, not to stay a guest', (tester) async {
      final guest = await tester.runAsync(() => BackendServiceProvider.instance.auth.signInAsGuest());
      await _pumpScreen(tester, const SignUpScreen());
      expect(find.text('Continue as guest'), findsNothing);
      expect(find.textContaining('logged as a guest'), findsOneWidget);

      await _enter(tester, 'Name', 'Guest Upgrade');
      await _enter(tester, 'Email', 'upgrade@example.com');
      await _enter(tester, 'Password', 'gutcheck1');
      await _enter(tester, 'Confirm password', 'gutcheck1');
      await _tapText(tester, 'Create Account');
      expect(BackendServiceProvider.instance.auth.currentUser?.id, guest!.id);
      expect(BackendServiceProvider.instance.auth.currentUser?.isAnonymous, isFalse);
    });

    testWidgets('has no back button when it is the first screen', (tester) async {
      await _pumpScreen(tester, const SignUpScreen());
      expect(find.byType(BackButton), findsNothing);
      await _tapText(tester, 'Sign In');
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
    });
  });

  group('SplashScreen', () {
    testWidgets('sends a signed-out visitor to onboarding', (tester) async {
      await _pumpScreen(tester, const SplashScreen());
      expect(find.text('GutMD'), findsOneWidget);
      expect(find.textContaining('Crohn'), findsNothing);
      await _settle(tester, rounds: 6);
      expect(find.byType(OnboardingFlow), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('sends a returning signed-in user straight to Home', (tester) async {
      await tester.runAsync(() => BackendServiceProvider.instance.auth
          .signInWithEmail(email: 'back@example.com', password: 'pw123456'));
      await _pumpScreen(tester, const SplashScreen());
      await _settle(tester, rounds: 6);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(OnboardingFlow), findsNothing);
    });
  });
}
