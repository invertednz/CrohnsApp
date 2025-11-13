import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../onboarding_theme.dart';
import '../onboarding_controller.dart';
import '../../../models/referral.dart';
import '../../../services/referral_service.dart';
import '../../../widgets/referral_rewards_card.dart';

class ReferralShareScreen extends StatefulWidget {
  final OnboardingController controller;
  final ReferralService referralService;
  final VoidCallback onComplete;
  final String donorName;

  const ReferralShareScreen({
    Key? key,
    required this.controller,
    required this.referralService,
    required this.onComplete,
    required this.donorName,
  }) : super(key: key);

  @override
  State<ReferralShareScreen> createState() => _ReferralShareScreenState();
}

class _ReferralShareScreenState extends State<ReferralShareScreen> {
  bool _isCreatingReferral = false;

  @override
  void initState() {
    super.initState();
    _initializeReferral();
  }

  Future<void> _initializeReferral() async {
    setState(() {
      _isCreatingReferral = true;
    });

    try {
      // Create referral code for this user
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}'; // TODO: Use actual user ID
      await widget.referralService.createReferral(userId);
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isCreatingReferral = false;
      });
    }
  }

  String _generateShareMessage(String referralCode) {
    return '''💜 Join me in supporting the IBD community!

I'm using Crohn's Companion and it's been life-changing. ${widget.donorName} helped me get started through our "Pay It Forward" program, and now I want to help others too.

This app gives you:
✅ Unlimited symptom & food tracking
✅ AI-powered insights that actually understand IBD
✅ 24/7 health assistant when you need it most
✅ A community that gets what you're going through

Living with Crohn's or Colitis is tough enough. Everyone deserves access to tools that help us thrive, not just survive.

Use my code $referralCode and we'll both save \$10 on our next year! 

#CrohnsWarrior #IBDCommunity #PayItForward #CrohnsLife''';
  }

  Future<void> _shareReferralCode() async {
    if (widget.referralService.referral == null) return;

    final message = _generateShareMessage(
      widget.referralService.referral!.referralCode,
    );

    try {
      // Track analytics
      // TODO: Add analytics event for share button clicked

      await Share.share(
        message,
        subject: 'Join me on Crohn\'s Companion!',
      );

      // Track share completion
      // TODO: Add analytics event for share completed

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Thank you for sharing! 💜'),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: OnboardingTheme.primaryGradient,
      ),
      child: SafeArea(
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

                      // Header with emoji
                      const Text(
                        '💜',
                        style: TextStyle(fontSize: 48),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Text(
                        'Share Our Mission',
                        style: OnboardingTheme.headingTextStyle(fontSize: 36),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'Help others living with IBD find the support they deserve',
                        style: OnboardingTheme.subheadingStyle,
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),

                      // Mission box
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFF59E0B).withOpacity(0.3),
                              const Color(0xFFEF4444).withOpacity(0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withOpacity(0.5),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.favorite,
                              color: Color(0xFFF59E0B),
                              size: 40,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Everyone Deserves Great Care',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Just like ${widget.donorName} helped you find Crohn\'s Companion, you can help others living with IBD discover the tools they need to thrive. Share our mission with your community and feel amazing knowing you\'re making a difference!',
                              style: OnboardingTheme.bodyStyle.copyWith(
                                fontSize: 15,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.card_giftcard,
                                    color: Color(0xFFF59E0B),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Earn \$10 off for each friend who joins!',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Referral rewards card
                      if (_isCreatingReferral)
                        const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              OnboardingTheme.accentIndigo,
                            ),
                          ),
                        )
                      else if (widget.referralService.hasReferral)
                        ReferralRewardsCard(
                          referral: widget.referralService.referral!,
                          onSharePressed: _shareReferralCode,
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: OnboardingTheme.cardDecoration(),
                          child: const Text(
                            'Unable to create referral code. Please try again later.',
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
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
                            _HowItWorksRow(
                              number: '1',
                              text: 'Share your unique link with your IBD community',
                            ),
                            const SizedBox(height: 12),
                            _HowItWorksRow(
                              number: '2',
                              text: 'They discover Crohn\'s Companion and subscribe',
                            ),
                            const SizedBox(height: 12),
                            _HowItWorksRow(
                              number: '3',
                              text: 'You get \$10 off your next year - automatically!',
                            ),
                            const SizedBox(height: 12),
                            _HowItWorksRow(
                              number: '4',
                              text: 'Share up to 5 times and save \$50 total',
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
