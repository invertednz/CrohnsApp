# 🚀 Viral Sharing Feature Implementation Prompt

Use this prompt template to implement viral sharing + referral rewards in any mobile app.

---

## 📋 PROMPT TEMPLATE

```
As the world's best marketer and UX designer, implement a comprehensive viral sharing + referral rewards system for Crohn's Companion with the following specifications:

### CONTEXT
- **App Type**: Crohn's Disease & IBD Health Tracking
- **Platform**: Both Android and iOS
- **Tech Stack**: Flutter
- **Current User Flow**: Right after user accepts their $29/year gifted discount (DiscountScreen)

### CORE REQUIREMENTS

#### 1. Referral System Architecture
Create a complete referral tracking system including:
- **Referral Model**: Unique codes, success tracking, earned rewards
- **Referral Provider/Manager**: State management for referral data
- **Code Generation**: 8-character alphanumeric codes (avoid confusing chars like O/0, I/1)
- **Reward Tracking**: Track referrals, calculate rewards, enforce limits
- **Persistence**: Store in database (Supabase/Firebase/etc.)

#### 2. Viral Share Message Design
Craft a share message that includes:
- **Personal Story**: Make it sound authentic, not corporate
- **Specific Value Props**: Concrete benefits (numbers, features, outcomes)
- **Social Proof**: Reference the "gifter" or existing community
- **Clear CTA**: Simple action with referral code
- **Platform Optimization**: Works well on Twitter, Facebook, WhatsApp, SMS, Email
- **Hashtags**: 2-3 relevant, searchable hashtags
- **Emojis**: Strategic use (not excessive) for visual appeal

**Template Structure**:
```
[Emoji] [Personal Hook about receiving value]

[Explain the value/benefit received in 1-2 sentences]

[Explain the unique mechanism - e.g., matched donation, group discount, etc.]

[Brief description of what the app does]

[CTA with referral code]

[Hashtags]
```

#### 3. Rewards Display UI
Design a compelling rewards tracker that shows:
- **Big Number Display**: Earned reward amount (large, bold, colorful)
- **Progress Bar**: Visual progress toward max reward
- **Referral Count**: Number of successful referrals
- **Referral Code**: Prominently displayed, easy to copy
- **Next Milestone**: "X more referrals to earn $Y!"
- **Max Cap Messaging**: Clear limit to create urgency

**Design Principles**:
- Green gradient (success/growth colors)
- Trophy/reward iconography
- White cards with soft shadows
- Clear typography hierarchy
- Celebratory micro-animations (optional but powerful)

#### 4. Share Button & Placement
Implement native sharing with:
- **Platform Integration**: Use `share_plus` (Flutter), `Share` API (React Native), UIActivityViewController (iOS), ShareSheet (Android)
- **Strategic Placement**: Right after value is received (peak gratitude moment)
- **Compelling CTA**: "Share Your Gift", "Help Other [Users]", "Spread the Word"
- **Visual Design**: Outlined button (secondary CTA), warm colors, share icon
- **Context Box**: Yellow/gold gradient explaining why sharing matters

#### 5. Psychological Triggers to Implement
- ✅ **Reciprocity**: Frame sharing as "thank you" for gift/discount received
- ✅ **Social Proof**: Show community stats (e.g., "Join 10,000+ users")
- ✅ **Mission Alignment**: Connect sharing to noble cause
- ✅ **FOMO**: "Your friends might miss out"
- ✅ **Progress Gamification**: Visual progress, achievements, milestones
- ✅ **Status**: Leaderboards or "Top Referrer" badges (optional)

#### 6. Reward Structure
Define the economics:
- **Reward Per Referral**: $5 off next year's subscription for each successful referral
- **Max Reward Cap**: Maximum $25 (5 referrals = nearly free renewal at $24/year)
- **Redemption Timing**: Applied automatically at next annual renewal
- **Stacking**: Rewards stack within the year, reset on renewal
- **Alternative Rewards**: Badge system ("Community Champion" after 3 referrals, "Health Hero" after 5)

#### 7. Success Metrics to Track
Implement analytics for:
- Share button click rate
- Successful share completion rate
- Referral code usage rate
- Conversion rate (share → signup → paid)
- Viral coefficient (avg new users per existing user)
- Time from share to conversion
- Reward redemption rate

### TECHNICAL IMPLEMENTATION CHECKLIST

- [ ] Create Referral model/data class
- [ ] Create Referral provider/state manager
- [ ] Implement unique code generation logic
- [ ] Build rewards calculation & capping logic
- [ ] Design & build rewards display widget
- [ ] Integrate native share functionality
- [ ] Craft compelling share message copy
- [ ] Add referral code to share message
- [ ] Build success/thank you feedback (SnackBar/Toast)
- [ ] Add referral tracking to database schema
- [ ] Implement reward redemption logic
- [ ] Add analytics events for all actions
- [ ] Create admin dashboard for monitoring (optional)
- [ ] Test share on all major platforms (SMS, WhatsApp, Twitter, etc.)

### DELIVERABLES

1. **Complete Referral System Code**
   - Models, providers, database integration
   
2. **Rewards UI Component**
   - Beautiful, gamified display of earnings
   
3. **Share Integration**
   - Native share with optimized message
   
4. **Analytics Events**
   - Track every step of the funnel
   
5. **Documentation**
   - How to customize rewards
   - How to update share message
   - How to view referral data

### BONUS ENHANCEMENTS (Optional)

- [ ] Deep linking with referral code attribution
- [ ] Pre-generated social media graphics
- [ ] Push notification when reward earned
- [ ] Email notification to referrer when friend joins
- [ ] Leaderboard of top referrers
- [ ] Special badges/achievements for referral milestones
- [ ] A/B test framework for share message variations
- [ ] Seasonal referral bonuses (2x rewards month, etc.)

---

## CUSTOMIZATION VARIABLES

When using this prompt, replace these placeholders:

- `[APP_NAME]`: Your app's name
- `[APP_TYPE]`: Category (parenting, fitness, etc.)
- `[PLATFORM]`: iOS/Android/Both
- `[TECH_STACK]`: Development framework
- `[USER_FLOW]`: Where sharing happens
- `[AMOUNT]`: Reward amount per referral
- `[CAP]`: Maximum total reward
- `[PERIOD]`: Reward redemption period (next year, next month, etc.)
- `[VALUE_PROPS]`: Your app's specific benefits

---

## EXAMPLE: Fitness App

```
As the world's best marketer and UX designer, implement a comprehensive viral sharing + referral rewards system for FitTrack with the following specifications:

### CONTEXT
- **App Type**: Fitness & Nutrition Tracking
- **Platform**: Both iOS & Android
- **Tech Stack**: Flutter
- **Current User Flow**: After user completes their first 7-day streak

### Share Message Example:
```
💪 I just completed my first week on FitTrack and I'm already down 3 lbs!

A friend shared their "Workout Buddy" code with me and we both got $15 off our premium plans. Now we keep each other accountable!

FitTrack's AI creates custom workout plans, tracks nutrition, and sends motivation when you need it. Way better than hiring a $100/hr personal trainer!

Join me! Use my code: FIT8XK2P to get started 🚀

#FitnessGoals #HealthyLiving #FitTrack
```

### Rewards Structure:
- $15 off next year for each referral
- Max cap: $99 (full year free if you refer 7 friends)
- Redemption: Applied automatically at next renewal
```

---

## EXAMPLE: Crohn's Companion App

```
As the world's best marketer and UX designer, implement a comprehensive viral sharing + referral rewards system for Crohn's Companion with the following specifications:

### CONTEXT
- **App Type**: Crohn's Disease & IBD Health Tracking
- **Platform**: Both iOS & Android
- **Tech Stack**: Flutter
- **Current User Flow**: Right after user accepts their $29/year gifted discount on the DiscountScreen

### Share Message Example:
```
🎁 Someone just sponsored my health journey and I'm paying it forward!

I received Crohn's Companion for $29/year (40% off!) thanks to a community member who donated through "Pay It Forward". The app matched their gift, and now I have unlimited symptom tracking, AI-powered insights, and a 24/7 health assistant.

Living with IBD is hard enough—everyone deserves access to tools that help. This app has genuinely improved my daily life.

Join our community! Use my code: CROHNS8K to get started 💜

#CrohnsWarrior #IBDCommunity #PayItForward
```

### Rewards Structure:
- $5 off next year for each successful referral
- Max cap: $25 (5 referrals = renewal at just $24/year)
- Redemption: Applied automatically at next annual renewal
- Badge rewards: "Community Champion" (3 referrals), "Health Hero" (5 referrals)
```

---

## SUCCESS INDICATORS

A well-implemented viral sharing system should achieve:

- **20-40% share rate** among users who received value
- **5-15% conversion rate** from shares to signups
- **Viral coefficient of 0.4-1.0+** (sustainable growth)
- **50%+ reward redemption rate** (users actually come back)
- **Lower CAC** than paid acquisition channels
- **Higher LTV** for referred users (better quality, stickier)

---

## DESIGN PRINCIPLES TO FOLLOW

1. **Authentic over Corporate**: Message should sound like a friend texting, not a brand advertising
2. **Value-First**: Lead with benefit received, not app features
3. **Specific Numbers**: Concrete results (saved $X, achieved Y, helped Z parents)
4. **Low Friction**: One tap to share, code auto-included
5. **Immediate Gratification**: Show reward earned instantly
6. **Visual Progress**: Humans love seeing bars fill up
7. **Mission-Driven**: Connect to larger purpose (helping community, access for all, etc.)

---

## ANTI-PATTERNS TO AVOID

❌ Generic "Share this app" button  
❌ No reward or unclear reward  
❌ Complicated multi-step sharing process  
❌ Corporate-sounding share message  
❌ No tracking or attribution  
❌ Hidden referral code or too small  
❌ Reward that's too small to motivate  
❌ Placing share button in wrong location (not at gratitude peak)  
❌ No visual feedback after sharing  
❌ Ignoring the "why" (just asks to share without explaining mission)  

---

## TESTING CHECKLIST

Before launch, verify:

- [ ] Share works on iOS native share sheet
- [ ] Share works on Android ShareSheet
- [ ] Message displays correctly in WhatsApp
- [ ] Message displays correctly in SMS
- [ ] Message displays correctly on Twitter (280 char limit)
- [ ] Message displays correctly in email
- [ ] Referral code is correct in message
- [ ] Referral code can be extracted/copied easily
- [ ] Rewards update when referral succeeds
- [ ] Progress bar animates smoothly
- [ ] Analytics events fire correctly
- [ ] Reward cap is enforced
- [ ] Success feedback shows after share
- [ ] Deep link works with referral code (if implemented)

---

## SAMPLE SHARE MESSAGES BY VERTICAL

### Parenting App
```
🎁 [Name] gave me access to BabySteps for just $29/year!

They donated $10 through "Pay It Forward", BabySteps matched it, and now I'm saving $20. This app has reduced my parenting stress by 50% - no more 2 AM googling!

Use my code: BABY4P7K to join the movement! 

#ParentingCommunity #PayItForward
```

### Finance App
```
💰 I just saved $1,247 in the last 3 months using MoneyMind!

[Name] shared their referral code and we both got 3 months free premium. The AI finds subscriptions I forgot about, negotiates bills, and actually makes saving automatic.

Your turn! Code: SAVE9MX2 

#FinancialFreedom #SmartMoney
```

### Education App
```
🎓 My daughter's math scores went from C to A in 6 weeks with LearnFast!

[Name] gifted me 50% off and now I'm paying it forward. The adaptive AI makes learning actually fun - she asks to do her homework now!

Join us! Code: LEARN3K9P

#EdTech #ProudParent
```

### Mental Health App
```
🧘 I've meditated 30 days straight thanks to MindfulMe and [Name]!

They shared their "Meditation Buddy" code and we both got $20 off. My anxiety has dropped significantly and I'm sleeping better than ever.

Your journey starts here: MIND7Q4R

#MentalHealthMatters #Mindfulness
```

### Crohn's Disease / IBD Health App
```
💜 [Name] sponsored my Crohn's Companion subscription and changed my life!

Through "Pay It Forward", they donated $10, the app matched it, and I got access for just $29/year. I've tracked 47 meals, identified 3 trigger foods, and my flare-ups are down 60%.

The AI actually understands IBD—it's like having a gastroenterologist in my pocket. No more guessing what's safe to eat or forgetting to log symptoms.

Help someone else thrive! Use my code: CROHN6K3M

#CrohnsLife #IBDWarrior #GutHealth
```

---

## FINAL NOTES

This viral sharing system works because it:
1. **Creates reciprocity** (they got value, now they share)
2. **Rewards both parties** (win-win)
3. **Feels authentic** (friend recommendation, not ad)
4. **Builds community** (movement of people helping each other)
5. **Gamifies growth** (progress bars, achievements, rewards)
6. **Aligns with mission** (e.g., "access for all parents")

The key is making users feel like **advocates for a mission**, not just unpaid marketers.

---

**Save this prompt and customize the [VARIABLES] for each new app!**
