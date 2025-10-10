# Crohn's Companion - Onboarding Redesign

## Overview
Complete redesign of the onboarding flow matching the beautiful DigitalBasics design style with dark gradient backgrounds, neon glow effects, and modern UI components.

## Design Style
- **Color Scheme**: Dark navy to deep purple gradient backgrounds
- **Accent Colors**: Indigo with neon glow effects
- **Typography**: Bold headings with text shadows for neon effect
- **Cards**: Glassmorphism with backdrop blur and glowing borders
- **Animations**: Smooth transitions, floating elements, and scale effects

## Onboarding Flow (14 Screens)

### 1. Welcome Screen
- **Purpose**: Social proof and app introduction
- **Features**:
  - Clinically validated badge
  - Statistics (87% reduced symptoms, 92% feel in control, 10k+ users, 4.8★ rating)
  - Evidence-based research callout
  - Animated entrance

### 2. Goal Selection
- **Purpose**: Personalize user experience
- **Options**:
  - Reduce Symptoms
  - Identify Triggers
  - Improve Diet
  - Better Understanding
  - Overall Wellness
- **Features**: Single-select with visual feedback

### 3. Expected Results
- **Purpose**: Set expectations and build motivation
- **Results Shown**:
  - More regular bowel movements
  - Reduced pain & discomfort
  - Less bloating & gas
  - Increased energy levels
  - Better mental clarity
- **Features**: Animated cards with staggered entrance

### 4. Progress Graph
- **Purpose**: Show typical improvement timeline
- **Features**:
  - Custom-painted progress curve (exponential growth)
  - Timeline milestones (Week 1-2, 3-4, 5-8, 9+)
  - Visual graph with gradient fill
  - Encouragement messaging

### 5. App Usage Carousel
- **Purpose**: Demonstrate key features
- **Slides**:
  - Daily Tracking
  - Smart Insights
  - Diet Management
  - AI Assistant
- **Features**: Swipeable carousel with page indicators

### 6. Diet Flags
- **Purpose**: Collect dietary restrictions/triggers
- **Common Options**: Dairy, Gluten, Lactose, Spicy Foods, High Fiber, Caffeine, etc.
- **Features**:
  - Multi-select chips
  - Custom entry field
  - Selected items display with remove option

### 7. Supplements
- **Purpose**: Track vitamins and supplements
- **Common Options**: Vitamin D, Probiotics, Omega-3, Iron, B12, etc.
- **Features**:
  - AM/PM time chips for each supplement
  - Custom supplement entry
  - Dialog for time selection
  - List view with edit/delete

### 8. Lifestyle Factors
- **Purpose**: Identify lifestyle impacts
- **Factors**: Poor Sleep, High Stress, Irregular Meals, Low Exercise, Smoking, etc.
- **Features**:
  - Multi-select cards with icons
  - Custom factor entry
  - Selected items summary

### 9. Medications
- **Purpose**: Track current medications
- **Common Options**: Mesalamine, Prednisone, Azathioprine, Infliximab, etc.
- **Features**:
  - Multi-select with categories
  - Custom medication entry
  - Medical disclaimer
  - Selected medications display

### 10. Current Symptoms
- **Purpose**: Baseline symptom assessment
- **Symptoms**: Abdominal Pain, Diarrhea, Bloating, Gas, Fatigue, Nausea, etc.
- **Features**:
  - Color-coded by severity (High/Medium/Low)
  - Multi-select with visual feedback
  - Celebration message if no symptoms

### 11. Thank You Screen
- **Purpose**: Congratulate and motivate user
- **Features**:
  - Animated checkmark
  - Benefits list
  - Encouraging messages
  - Smooth transitions

### 12. Trial Offer
- **Purpose**: Present 7-day free trial
- **Features**:
  - Special offer badge
  - Large price display ($0 for 7 days, then $9.99/month)
  - Feature list (6 premium features)
  - Notification reminder callout
  - Risk-free guarantee

### 13. Timeline Screen
- **Purpose**: Show trial timeline and expectations
- **Features**:
  - Visual timeline with 3 milestones:
    - Trial starts (today)
    - Reminder notification (day 5)
    - Trial ends (day 7)
  - Important information cards
  - Risk-free guarantee

### 14. Payment Screen
- **Purpose**: Collect payment information
- **Features**:
  - Pricing display with "First 7 days FREE" badge
  - Payment method options (Credit Card, Apple Pay, Google Pay)
  - Benefits reminder
  - Close button triggers discount offer
  - Terms and conditions

### Bonus: Discount Screen (Conditional)
- **Purpose**: Retention offer when user tries to skip payment
- **Features**:
  - Pulsing "WAIT! EXCLUSIVE OFFER" badge
  - 50% discount (from $9.99 to $4.99/month)
  - Urgency messaging
  - Savings calculation ($60/year)
  - Cannot be dismissed (must choose)
  - Two options: Accept discount or decline

## Technical Implementation

### File Structure
```
lib/screens/onboarding/
├── onboarding_data.dart          # Data models
├── onboarding_controller.dart    # State management
├── onboarding_theme.dart         # Design system
├── onboarding_flow.dart          # Main flow controller
└── screens/
    ├── welcome_screen.dart
    ├── goal_screen.dart
    ├── expected_results_screen.dart
    ├── progress_graph_screen.dart
    ├── app_usage_screen.dart
    ├── diet_flags_screen.dart
    ├── supplements_screen.dart
    ├── lifestyle_screen.dart
    ├── medications_screen.dart
    ├── symptoms_screen.dart
    ├── thank_you_screen.dart
    ├── trial_offer_screen.dart
    ├── timeline_screen.dart
    ├── payment_screen.dart
    └── discount_screen.dart
```

### Key Components

**OnboardingData**
- Stores all user selections
- Serializable to JSON
- Includes trial status and payment info

**OnboardingController**
- Manages flow state (currentStep)
- Handles data mutations
- Provides progress tracking
- Extends ChangeNotifier for reactivity

**OnboardingTheme**
- Centralized design tokens
- Gradient definitions
- Neon glow effects
- Input/button styles
- Text styles

### Navigation Flow
1. Splash Screen → Onboarding Flow
2. Linear progression through 14 screens
3. Back navigation supported
4. Payment screen close → Discount screen
5. Completion → Home Screen

### Data Collected
- User goal
- Diet flags (list)
- Supplements with AM/PM timing
- Lifestyle factors
- Current medications
- Current symptoms
- Trial/payment status

## Design Features

### Visual Effects
- **Neon Glow**: Box shadows with white and indigo colors
- **Glassmorphism**: Backdrop blur with semi-transparent backgrounds
- **Gradients**: Dark navy to deep purple, indigo accent gradients
- **Animations**: Fade, scale, slide transitions
- **Floating**: Subtle up/down animation on cards

### Color Palette
- Dark Navy: `#0F172A`
- Deep Purple: `#1E1B4B`
- Accent Indigo: `#4F46E5`
- Light Indigo: `#818CF8`
- Health Green: `#10B981`
- Warning Amber: `#F59E0B`
- Error Red: `#EF4444`

### Typography
- **Headings**: 32-40px, bold, with neon text shadow
- **Subheadings**: 18px, indigo glow color
- **Body**: 16px, indigo glow color
- **Captions**: 12-14px, lighter opacity

## User Experience

### Progress Indicators
- Step counter (e.g., "Step 5 of 14")
- Back button on all screens except welcome
- Visual feedback on selections
- Loading states for async operations

### Validation
- Goal selection required before continuing
- Medications must be non-empty strings
- Supplements require AM or PM selection
- Payment methods trigger processing state

### Accessibility
- High contrast text
- Clear visual hierarchy
- Touch-friendly tap targets
- Screen reader compatible structure

## Marketing Flow

### Conversion Optimization
1. **Social Proof**: Statistics and validation on welcome
2. **Value Proposition**: Expected results and progress timeline
3. **Feature Education**: Carousel demonstration
4. **Data Collection**: Personalization through user input
5. **Emotional Connection**: Thank you and congratulations
6. **Trial Offer**: Low-friction 7-day free trial
7. **Transparency**: Clear timeline and notification promise
8. **Payment**: Multiple convenient options
9. **Retention**: 50% discount offer on exit attempt

### Psychological Triggers
- **Authority**: Clinically validated, evidence-based
- **Social Proof**: 10k+ users, 4.8★ rating
- **Scarcity**: "Limited time" discount offer
- **Loss Aversion**: "Don't miss this offer"
- **Commitment**: Progressive data collection
- **Reciprocity**: Free trial before payment

## Next Steps

### To Run
1. Ensure all dependencies are installed
2. Run `flutter pub get`
3. Launch app - it will show new onboarding flow

### Future Enhancements
- Analytics tracking for each screen
- A/B testing different messaging
- Skip options for certain screens
- Save progress and resume later
- Email verification integration
- Social login integration
- Onboarding completion persistence
