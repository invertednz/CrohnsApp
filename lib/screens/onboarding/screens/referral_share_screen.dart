import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../onboarding_theme.dart';
import '../../../core/backend_service_provider.dart';
import '../../../models/referral.dart';
import '../../../services/referral_service.dart';
import '../../../widgets/referral_rewards_card.dart';

class ReferralShareScreen extends StatefulWidget {
  final ReferralService referralService;
  final VoidCallback onComplete;

  const ReferralShareScreen({
    Key? key,
    required this.referralService,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<ReferralShareScreen> createState() => _ReferralShareScreenState();
}

class _ReferralShareScreenState extends State<ReferralShareScreen> {
  bool _isCreatingReferral = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _initializeReferral();
  }

  Future<void> _initializeReferral() async {
    if (widget.referralService.hasReferral) return;
    setState(() {
      _isCreatingReferral = true;
      _loadFailed = false;
    });

    try {
      // Signed-out users get a code now; it is saved once they sign up.
      final userId = BackendServiceProvider.isInitialized
          ? BackendServiceProvider.instance.auth.currentUser?.id
          : null;
      await widget.referralService.loadOrCreate(userId);
    } catch (e) {
      if (mounted) setState(() => _loadFailed = true);
    } finally {
      if (mounted) setState(() => _isCreatingReferral = false);
    }
  }

  static String shareMessage(String referralCode) {
    return '''I've been using GutMD to track my gut health - symptoms, food, supplements and medications in one place, with AI summaries of my patterns.

If you live with Crohn's, colitis, IBS or another gut condition, it might help you too. Use my code $referralCode when you sign up.''';
  }

  Future<void> _shareReferralCode() async {
    final referral = widget.referralService.referral;
    if (referral == null) return;
    final message = shareMessage(referral.referralCode);

    ShareResult? result;
    try {
      result = await SharePlus.instance.share(
        ShareParams(
          text: message,
          subject: 'Join me on GutMD',
          // Without a share sheet (most desktop browsers) copy instead of
          // opening an email client.
          mailToFallbackEnabled: false,
        ),
      );
    } catch (_) {
      result = null;
    }
    if (!mounted) return;

    if (result == null) {
      await _copyInvite(message);
      return;
    }
    if (result.status == ShareResultStatus.dismissed) return;
    _showSnack('Thanks for sharing GutMD!');
  }

  Future<void> _copyInvite(String message) async {
    var copied = true;
    try {
      await Clipboard.setData(ClipboardData(text: message));
    } catch (_) {
      copied = false;
    }
    if (!mounted) return;
    if (copied) {
      _showSnack('Invite message copied - paste it anywhere to share');
    } else {
      _showSnack(
        'Sharing isn\'t available here. Your code is '
        '${widget.referralService.referral?.referralCode}',
        success: false,
      );
    }
  }

  void _showSnack(String text, {bool success = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(success ? Icons.check_circle : Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
        backgroundColor: success ? OnboardingTheme.ctaGreen : OnboardingTheme.deepPurple,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final referral = widget.referralService.referral;
    return Container(
      decoration: const BoxDecoration(
        gradient: OnboardingTheme.primaryGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Skip button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: widget.onComplete,
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),

                        const Icon(
                          Icons.favorite,
                          color: OnboardingTheme.lightIndigo,
                          size: 48,
                        ),

                        const SizedBox(height: 16),

                        Semantics(
                          header: true,
                          child: Text(
                            'Share GutMD',
                            style: OnboardingTheme.headingTextStyle(fontSize: 36),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          'Know someone living with a gut condition? Invite them with your personal code.',
                          style: OnboardingTheme.subheadingStyle,
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 24),

                        // Referral terms
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: OnboardingTheme.lightIndigo.withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.card_giftcard,
                                color: OnboardingTheme.lightIndigo,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Each friend who subscribes with your code earns you a '
                                  '\$${Referral.rewardPerReferral.toStringAsFixed(0)} credit, '
                                  'up to \$${Referral.maxRewardCap.toStringAsFixed(0)} a year.',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Referral code card
                        if (_isCreatingReferral)
                          const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                OnboardingTheme.accentIndigo,
                              ),
                            ),
                          )
                        else if (referral != null) ...[
                          ReferralRewardsCard(
                            referral: referral,
                            onSharePressed: _shareReferralCode,
                          ),
                          if (!widget.referralService.isSaved) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Your code is saved to your account when you sign up.',
                              style: OnboardingTheme.bodyStyle.copyWith(fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ] else
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: OnboardingTheme.cardDecoration(),
                            child: Column(
                              children: [
                                Text(
                                  _loadFailed
                                      ? 'We couldn\'t create your referral code. Check your connection and try again.'
                                      : 'Your referral code isn\'t ready yet.',
                                  style: const TextStyle(color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: _initializeReferral,
                                  child: const Text('Try again'),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),

                        // How it works
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: OnboardingTheme.cardDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'How It Works',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const _HowItWorksRow(
                                number: '1',
                                text: 'Share your code with friends or your support community',
                              ),
                              const SizedBox(height: 12),
                              const _HowItWorksRow(
                                number: '2',
                                text: 'They enter it when they sign up for GutMD',
                              ),
                              const SizedBox(height: 12),
                              _HowItWorksRow(
                                number: '3',
                                text: 'When they subscribe, you earn a '
                                    '\$${Referral.rewardPerReferral.toStringAsFixed(0)} credit toward your plan',
                              ),
                              const SizedBox(height: 12),
                              _HowItWorksRow(
                                number: '4',
                                text: 'Credits are capped at \$${Referral.maxRewardCap.toStringAsFixed(0)} '
                                    '(${Referral.maxReferrals} friends) per year',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Continue button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onComplete,
                    style: OnboardingTheme.primaryButtonStyle().copyWith(
                      padding: const MaterialStatePropertyAll(
                        EdgeInsets.symmetric(vertical: 18),
                      ),
                    ),
                    child: const Text(
                      'Continue to App',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HowItWorksRow extends StatelessWidget {
  final String number;
  final String text;

  const _HowItWorksRow({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF10B981),
                Color(0xFF059669),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
