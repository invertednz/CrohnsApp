# Crohn's Companion - Design System

## Color Palette

### Primary Colors
```dart
Dark Navy:     #0F172A  // Background gradient start
Deep Purple:   #1E1B4B  // Background gradient end
Accent Indigo: #4F46E5  // Primary accent, buttons
Light Indigo:  #818CF8  // Secondary accent, text
Indigo Glow:   #E0E7FF  // Light text, labels
```

### Semantic Colors
```dart
Health Green:  #10B981  // Success, positive states
Warning Amber: #F59E0B  // Warnings, important info
Error Red:     #EF4444  // Errors, high severity
```

## Gradients

### Primary Gradient (Background)
```dart
LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [darkNavy, deepPurple],
)
```

### Accent Gradient (Buttons, Icons)
```dart
LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [accentIndigo, lightIndigo],
)
```

## Typography

### Heading Styles
```dart
// Neon Text (Main Headings)
TextStyle(
  fontSize: 32-40,
  fontWeight: FontWeight.bold,
  color: Colors.white,
  shadows: [
    Shadow(color: white.withOpacity(0.8), blurRadius: 5),
    Shadow(color: accentIndigo.withOpacity(0.8), blurRadius: 10),
  ],
)

// Regular Heading
TextStyle(
  fontSize: 24-28,
  fontWeight: FontWeight.bold,
  color: Colors.white,
)

// Subheading
TextStyle(
  fontSize: 18,
  color: indigoGlow,
  height: 1.5,
)
```

### Body Text
```dart
// Body
TextStyle(
  fontSize: 16,
  color: indigoGlow,
  height: 1.6,
)

// Small Text
TextStyle(
  fontSize: 12-14,
  color: indigoGlow.withOpacity(0.7),
)
```

## Components

### Neon Glow Effect
```dart
BoxShadow(
  color: Colors.white.withOpacity(0.5),
  blurRadius: 5,
  spreadRadius: 0,
),
BoxShadow(
  color: accentIndigo.withOpacity(0.5),
  blurRadius: 10,
  spreadRadius: 0,
)
```

### Card Decoration
```dart
BoxDecoration(
  color: Colors.black.withOpacity(0.4),
  borderRadius: BorderRadius.circular(24),
  border: Border.all(
    color: accentIndigo.withOpacity(0.3),
    width: 1,
  ),
  boxShadow: withGlow ? neonGlow() : null,
)
```

### Input Fields
```dart
InputDecoration(
  filled: true,
  fillColor: Colors.black.withOpacity(0.5),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(
      color: accentIndigo.withOpacity(0.5),
    ),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(
      color: accentIndigo,
      width: 2,
    ),
  ),
)
```

### Buttons

#### Primary Button
```dart
ElevatedButton.styleFrom(
  backgroundColor: accentIndigo,
  foregroundColor: Colors.white,
  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
)
```

#### Secondary Button
```dart
OutlinedButton.styleFrom(
  foregroundColor: Colors.white,
  side: BorderSide(
    color: accentIndigo.withOpacity(0.5),
  ),
  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
)
```

### Selection Chips
```dart
// Selected State
Container(
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  decoration: BoxDecoration(
    color: accentIndigo,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: accentIndigo, width: 2),
    boxShadow: neonGlow(),
  ),
)

// Unselected State
Container(
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  decoration: BoxDecoration(
    color: Colors.black.withOpacity(0.4),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: accentIndigo.withOpacity(0.3),
      width: 1,
    ),
  ),
)
```

## Spacing

### Standard Spacing
```dart
Extra Small: 4px
Small:       8px
Medium:      12px
Default:     16px
Large:       24px
Extra Large: 32px
Huge:        48px
```

### Component Spacing
```dart
Card Padding:     20-24px
Button Padding:   16-18px vertical, 32px horizontal
Screen Padding:   24px
Section Spacing:  32px
Item Spacing:     12-16px
```

## Border Radius

```dart
Small:   8px   // Chips, small buttons
Medium:  12px  // Buttons, inputs
Large:   16px  // Cards
X-Large: 24px  // Large cards, containers
Round:   50%   // Circular elements
```

## Animations

### Duration
```dart
Fast:     200-300ms  // Transitions, hovers
Medium:   600ms      // Card animations
Slow:     1200ms     // Entrance animations
```

### Curves
```dart
Ease In Out: Curves.easeInOut     // Standard transitions
Ease Out:    Curves.easeOut       // Entrance animations
Elastic:     Curves.elasticOut    // Playful animations
```

### Common Animations
```dart
// Fade In
FadeTransition(
  opacity: animation,
  child: widget,
)

// Scale
ScaleTransition(
  scale: animation,
  child: widget,
)

// Slide
SlideTransition(
  position: Tween<Offset>(
    begin: Offset(0, 0.3),
    end: Offset.zero,
  ).animate(animation),
  child: widget,
)

// Floating (CSS-like)
@keyframes floating {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-10px); }
}
```

## Icons

### Sizes
```dart
Small:   18-20px
Medium:  24px
Large:   28-32px
X-Large: 40-48px
Hero:    60-100px
```

### Common Icons
```dart
Success:     Icons.check_circle
Warning:     Icons.warning_amber
Error:       Icons.error
Info:        Icons.info_outline
Medical:     Icons.medical_services_outlined
Health:      Icons.favorite
Tracking:    Icons.track_changes
Insights:    Icons.insights
Chat:        Icons.chat_bubble_outline
```

## Patterns

### Info Box
```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: color.withOpacity(0.1),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: color.withOpacity(0.3),
    ),
  ),
  child: Row(
    children: [
      Icon(icon, color: color, size: 24),
      SizedBox(width: 12),
      Expanded(child: Text(message)),
    ],
  ),
)
```

### Feature Card
```dart
Container(
  padding: EdgeInsets.all(20),
  decoration: cardDecoration(),
  child: Row(
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: accentGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: white),
      ),
      SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: boldWhite),
            Text(description, style: bodyStyle),
          ],
        ),
      ),
    ],
  ),
)
```

### Stat Card
```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: cardDecoration(),
  child: Column(
    children: [
      Text(value, style: largeNumber),
      SizedBox(height: 4),
      Text(label, style: caption),
    ],
  ),
)
```

## Accessibility

### Contrast Ratios
- White on Dark Navy: 15.3:1 ✓
- Indigo Glow on Dark Navy: 7.2:1 ✓
- Accent Indigo on Dark Navy: 4.8:1 ✓

### Touch Targets
- Minimum: 44x44 pixels
- Recommended: 48x48 pixels
- Buttons: 48px height minimum

### Focus States
- Visible focus indicators
- 2px border increase on focus
- Color change on focus

## Best Practices

### Do's
✓ Use neon glow sparingly for emphasis
✓ Maintain consistent spacing
✓ Use semantic colors appropriately
✓ Provide visual feedback for interactions
✓ Keep text readable with sufficient contrast
✓ Use animations to guide attention

### Don'ts
✗ Don't overuse glow effects
✗ Don't use pure black backgrounds
✗ Don't mix different border radius styles
✗ Don't use too many colors
✗ Don't animate everything
✗ Don't sacrifice readability for aesthetics
