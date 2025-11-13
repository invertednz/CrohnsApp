# 🎁 Viral Referral System Implementation

## Overview

The Crohn's Companion app now includes a complete viral sharing + referral rewards system that activates after users accept their $29/year gifted discount. This creates a "pay it forward" cycle where grateful users can share the app and earn rewards for helping others.

## System Components

### 1. Data Models

**`lib/models/referral.dart`**
- Core referral data structure
- Tracks referral code, successful referrals, and earned rewards
- Constants:
  - `rewardPerReferral`: $5
  - `maxRewardCap`: $25
  - `maxReferrals`: 5
- Badge system: "Community Champion" (3 referrals), "Health Hero" (5 referrals)

### 2. Business Logic

**`lib/services/referral_service.dart`**
- Manages referral state with `ChangeNotifier`
- Generates unique 8-character alphanumeric codes (avoiding O/0, I/1)
- Tracks successful referrals and calculates rewards
- Placeholder methods for database integration (Supabase/Firebase)

Key Methods:
- `generateReferralCode()`: Creates unique codes
- `createReferral(userId)`: Initializes referral for user
- `recordSuccessfulReferral(referredUserId)`: Awards $5 reward
- `applyReferralCode(code, newUserId)`: Validates and applies codes
- `resetRewards()`: Annual reset at renewal

### 3. UI Components

**`lib/widgets/referral_rewards_card.dart`**
- Beautiful green gradient card displaying rewards
- Shows:
  - Total earned amount (large, bold)
  - Number of successful referrals
  - Progress bar to max reward
  - Next milestone messaging
  - Referral code (tap to copy)
  - Share button
- Celebratory design with trophy icon and badges

**`lib/screens/onboarding/screens/referral_share_screen.dart`**
- Post-gift acceptance screen
- Mission-driven messaging ("Pay It Forward")
- Displays referral rewards card
- "How It Works" section (4 steps)
- Native share integration
- Continue to app button

### 4. Integration

**`lib/screens/onboarding/onboarding_flow.dart`**
- Modified to show referral screen after gift acceptance
- Flow: Payment → Discount → **Referral Share** → Home
- New state: `_showReferralScreen`
- New handler: `_handleReferralComplete()`

## User Flow

1. User declines payment → sees DiscountScreen (gift offer)
2. User accepts $29/year gift → DiscountScreen calls `onAccept()`
3. ReferralShareScreen appears with:
   - Donor name acknowledgment
   - Referral code generation
   - Rewards card display
   - Share button
4. User shares message via native share sheet
5. User continues to app

## Share Message

```
🎁 [DonorName] sponsored my health journey and I'm paying it forward!

I received Crohn's Companion for $29/year (40% off!) thanks to a community member who donated through "Pay It Forward". The app matched their gift, and now I have unlimited symptom tracking, AI-powered insights, and a 24/7 health assistant.

Living with IBD is hard enough—everyone deserves access to tools that help. This app has genuinely improved my daily life.

Join our community! Use my code: CROHNS8K to get started 💜

#CrohnsWarrior #IBDCommunity #PayItForward
```

## Reward Structure

- **Per Referral**: $5 off next year's subscription
- **Max Cap**: $25 total (5 successful referrals)
- **Redemption**: Applied automatically at next annual renewal
- **Stacking**: Rewards accumulate throughout the year, reset annually
- **Badges**:
  - 3 referrals = "Community Champion" 🏆
  - 5 referrals = "Health Hero" 🏆

## Technical Implementation

### Package Dependencies

Added to `pubspec.yaml`:
```yaml
share_plus: ^7.2.1
```

### Database Schema (To Implement)

**Referrals Table:**
```sql
CREATE TABLE referrals (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  referral_code TEXT UNIQUE NOT NULL,
  successful_referrals INTEGER DEFAULT 0,
  earned_rewards REAL DEFAULT 0.0,
  created_at TIMESTAMP NOT NULL,
  last_referral_at TIMESTAMP,
  referred_user_ids TEXT[] DEFAULT '{}',
  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### Analytics Events (To Implement)

Track these key events:
- `referral_screen_viewed`
- `referral_code_generated`
- `share_button_clicked`
- `share_completed`
- `referral_code_applied`
- `referral_reward_earned`
- `badge_unlocked`

### Backend Integration (To Do)

1. **Database Setup**:
   - Implement `_saveToDatabase()` in `ReferralService`
   - Implement `_loadFromDatabase()` in `ReferralService`
   - Implement `_findReferralByCode()` in `ReferralService`

2. **New User Flow**:
   - Capture referral code from deep link or input
   - Validate code before signup
   - Record referral after successful payment
   - Notify referrer of successful referral

3. **Reward Redemption**:
   - Apply discount at renewal time
   - Update subscription price based on earned rewards
   - Reset rewards after redemption

4. **Deep Linking** (Optional):
   - Format: `crohnsapp://join?ref=CROHNS8K`
   - Auto-fill referral code on signup

## Design Principles

✅ **Authentic Messaging**: Sounds like a friend, not a corporation  
✅ **Value-First**: Leads with benefit received  
✅ **Mission-Driven**: Connects to "access for all" cause  
✅ **Low Friction**: One tap to share  
✅ **Visual Progress**: Progress bars and milestones  
✅ **Gamification**: Badges and achievements  
✅ **Reciprocity**: Triggered at peak gratitude moment  

## Success Metrics Goals

- **20-40% share rate** among gift recipients
- **5-15% conversion rate** from shares to signups
- **Viral coefficient of 0.4-1.0+**
- **50%+ reward redemption rate**
- **Lower CAC** than paid acquisition
- **Higher LTV** for referred users

## Testing Checklist

Before production launch:

- [ ] Share works on iOS native share sheet
- [ ] Share works on Android ShareSheet
- [ ] Message displays correctly in WhatsApp
- [ ] Message displays correctly in SMS
- [ ] Message displays correctly on Twitter
- [ ] Referral code generation is unique
- [ ] Rewards calculation is accurate
- [ ] Max cap enforcement works
- [ ] Progress bar updates correctly
- [ ] Badge unlocks at correct thresholds
- [ ] Copy-to-clipboard works
- [ ] Analytics events fire correctly
- [ ] Database persistence works
- [ ] Deep link attribution works (if implemented)

## Customization

### Update Share Message

Edit `_generateShareMessage()` in `referral_share_screen.dart`:
```dart
String _generateShareMessage(String referralCode) {
  return '''Your custom message with $referralCode''';
}
```

### Update Rewards

Edit constants in `lib/models/referral.dart`:
```dart
static const double rewardPerReferral = 5.0;  // Change reward amount
static const double maxRewardCap = 25.0;       // Change max cap
static const int maxReferrals = 5;             // Change max referrals
```

### Update Badges

Edit `badgeLevel` getter in `lib/models/referral.dart`:
```dart
String get badgeLevel {
  if (successfulReferrals >= 5) return 'Health Hero';
  if (successfulReferrals >= 3) return 'Community Champion';
  return 'None';
}
```

## Future Enhancements

- [ ] Leaderboard of top referrers
- [ ] Special seasonal bonuses (2x rewards month)
- [ ] Pre-generated social media graphics
- [ ] Push notifications for reward milestones
- [ ] Email notifications when friend joins
- [ ] A/B test framework for message variations
- [ ] Referral contest events

## Support

For questions or issues with the referral system, contact the development team or refer to the main app documentation.

---

**Last Updated**: November 2024  
**Version**: 1.0.0
