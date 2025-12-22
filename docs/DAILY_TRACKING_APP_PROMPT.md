# Daily Tracking App - Feature Implementation Prompt

Use this prompt to implement a comprehensive daily tracking system for health/habit apps. This architecture supports per-day data tracking, onboarding integration, and a streamlined user experience.

---

## Overview

Build a daily tracking app with the following core features:
1. **Shared Calendar State** - Date selection persists across all pages
2. **Quick Tracking Home Page** - Fast daily check-ins with "Had All" / "Different" buttons
3. **Detailed Tracking Pages** - Per-item tracking with AM/PM toggles, severity selectors, etc.
4. **Onboarding Integration** - User's selections from onboarding become their default tracking list
5. **Streak Counter** - Gamification to encourage daily tracking
6. **Daily Logs** - Free-form text and photo entries

---

## 1. Shared App State (Global Singleton)

Create a global state manager that persists across all screens:

```dart
class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  // Shared selected date across all tracking pages
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;
  
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  // User's onboarding data (medications, supplements, symptoms, etc.)
  OnboardingData? _onboardingData;
  
  // Quick access getters for user's tracking lists
  List<String> get userMedications => _onboardingData?.medications ?? [];
  List<SupplementEntry> get userSupplements => _onboardingData?.supplements ?? [];
  List<SymptomEntry> get userSymptoms => _onboardingData?.currentSymptoms ?? [];
}
```

**Key Benefits:**
- When user changes date on Home page, Symptoms/Supplements/Medications pages all show the same date
- User doesn't have to re-select the date on each page
- Centralized access to onboarding data

---

## 2. Home Page Structure

### Header Section
- App title/logo
- **Streak Badge** (top right) - Shows consecutive days with tracking data
  - Fire icon 🔥 with day count
  - Semi-transparent pill-shaped container

### Calendar Bar
- Horizontal scrollable week view
- Highlights selected date
- Tapping a date updates shared app state

### "How Are You Feeling?" Section
- 5 emoji options: 😫 Terrible → 😄 Great
- Per-day state - each day saves its own selection
- Visual feedback with colored borders when selected

### Quick Tracking Grid (2x2)
Four compact cards for quick daily tracking:

| Card | Purpose |
|------|---------|
| **Bowel Motions** | Counter with +/- buttons |
| **Supplements** | "Had All" / "Different" buttons |
| **Medications** | "Had All" / "Different" buttons |
| **Diet** | "Had All" / "Different" buttons |

**Button Behavior:**
- **"Had All"** (green) - Marks as complete for the day, saves to state
- **"Different"** (amber) - Marks as incomplete AND navigates to the detailed page for that category

```dart
Widget _buildCompactGuideCard(String title, IconData icon, bool? followed, Function(bool?) onChanged, int tabIndex) {
  // "Had All" button
  GestureDetector(
    onTap: () => onChanged(true),
    child: Container(/* green styling when selected */),
  ),
  // "Different" button  
  GestureDetector(
    onTap: () {
      onChanged(false);
      if (tabIndex >= 0) widget.onNavigateToTab!(tabIndex);
    },
    child: Container(/* amber styling when selected */),
  ),
}
```

### Health Insights Section
Show **actual tracked data**, not made-up values:
- Days Tracked (total count)
- Average Feeling (calculated from mood selections)
- Current Streak
- Summary text: "Supplements taken: X days • Medications: Y days"

### Daily Logs Section
- List of text/photo entries for the selected day
- Each entry shows: description, time, optional digest score
- "No logs yet" placeholder when empty

### Bottom Input Bar
- Photo capture button (camera icon)
- Text input field for quick logging
- Send button
- **Styled to match app theme** (dark background, light text)

---

## 3. Detailed Tracking Pages (Symptoms, Supplements, Medications)

Each page follows the same pattern:

### Structure
1. **Header** - Title + subtitle
2. **Calendar Bar** - Same shared date as home page
3. **Quick Actions** - "Mark All Taken/Had All" + "Clear All/None Today"
4. **My Items List** - User's items from onboarding (tap to mark for today)
5. **Add Custom Section** - Text field to add custom items
6. **Add From Common** - List of common items not yet in user's list

### Per-Day Tracking Logic

```dart
// Per-day data storage
final Map<String, Set<String>> _takenByDate = {};      // dateKey -> set of taken item names
final Map<String, Map<String, bool>> _takenAMByDate = {}; // for AM/PM toggles
final Map<String, Map<String, bool>> _takenPMByDate = {};

String get _dateKey => '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}';

Set<String> get _takenToday => _takenByDate[_dateKey] ?? {};
```

### Loading from Onboarding

```dart
@override
void initState() {
  super.initState();
  _loadFromOnboarding();
}

void _loadFromOnboarding() {
  if (_initialized) return;
  _initialized = true;
  
  final onboardingItems = _appState.userSupplements; // or userMedications, userSymptoms
  for (var item in onboardingItems) {
    _myItems.add(item.name);
    // Set defaults (e.g., AM/PM from onboarding)
  }
}
```

### Daily Tracking Card Design

```
┌─────────────────────────────────────────────┐
│ [Icon] Item Name                      [X/−] │
│        Description                          │
│ ─────────────────────────────────────────── │
│        Time/Severity:    [AM] [PM]          │
│                    or    [Mild][Mod][Severe]│
└─────────────────────────────────────────────┘
```

**Visual States:**
- **Not tracked today**: Dark/muted background, white border
- **Tracked today**: Colored background (green for taken, severity color for symptoms), colored border, checkmark icon

### Quick Action Buttons

```dart
Row(
  children: [
    Expanded(child: _buildQuickAction('Mark All Taken', Icons.check_circle_outline, AppTheme.healthGreen, _markAllTaken)),
    SizedBox(width: 10),
    Expanded(child: _buildQuickAction('Clear All', Icons.cancel_outlined, Colors.redAccent, _clearAllTaken)),
  ],
)
```

---

## 4. Streak Counter Implementation

```dart
int get _currentStreak {
  int streak = 0;
  DateTime checkDate = DateTime.now();
  
  for (int i = 0; i < 365; i++) {
    final key = '${checkDate.year}-${checkDate.month}-${checkDate.day}';
    final hasData = _feelingsByDate.containsKey(key) ||
        _bowelMovementsByDate.containsKey(key) ||
        _supplementsByDate.containsKey(key) ||
        _medicationsByDate.containsKey(key) ||
        (_logEntriesByDate[key]?.isNotEmpty ?? false);
    
    if (hasData) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else if (i == 0) {
      // Today has no data yet, check yesterday
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }
  return streak > 0 ? streak : 1;
}
```

---

## 5. Navigation Architecture

### Bottom Navigation Tabs
```
[Home] [Symptoms] [Supplements] [Medications] [Chat/More]
```

### Navigation from Home Quick Buttons
When user taps "Different" on a quick tracking card:
1. Mark that category as "not followed" for today
2. Navigate to the corresponding tab index
3. User lands on detailed page with same date selected

```dart
class HomeScreen extends StatefulWidget {
  // ...
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  // Pass callback to HomeContent
  HomeContent(onNavigateToTab: _navigateToTab),
}
```

---

## 6. Data Models

### Supplement Entry (with AM/PM)
```dart
class SupplementEntry {
  String name;
  bool takesAM;
  bool takesPM;
}
```

### Symptom Entry (with severity)
```dart
class SymptomEntry {
  String name;
  String severity; // 'Mild', 'Moderate', 'Severe'
  bool isCustom;
}
```

### Daily Log Entry
```dart
class DailyLogEntry {
  final String description;
  final String time;
  final double digestScore;
  final String? imagePath;
}
```

---

## 7. UI/UX Patterns

### Color Coding
- **Green** (`healthGreen`) - Positive/completed/taken/mild
- **Amber** - Warning/moderate/different
- **Red** - Severe/not taken/negative

### Card Styling
```dart
Container(
  padding: EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: isSelected ? color.withOpacity(0.15) : Colors.black.withOpacity(0.2),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
      color: isSelected ? color : Colors.white.withOpacity(0.1),
      width: isSelected ? 2 : 1,
    ),
  ),
)
```

### Section Labels
```dart
Text(
  'My Supplements - Tap to mark taken',
  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.7)),
)
```

---

## 8. Key Implementation Notes

1. **Per-Day State**: Always use date key (`YYYY-M-D`) to store/retrieve data for each day
2. **Onboarding First**: User's tracking list should start with what they selected during onboarding, not all common items
3. **Shared Date**: Use a singleton/global state for the selected date so all pages stay in sync
4. **Quick Actions**: "Mark All" and "Clear All" buttons make daily tracking fast
5. **Navigation Integration**: "Different" buttons should navigate to detailed pages
6. **Custom Items**: Always allow users to add their own items beyond the common list
7. **Visual Feedback**: Selected/tracked items should have distinct visual styling
8. **Streak Motivation**: Show streak prominently to encourage daily use

---

## Example User Flow

1. User opens app → sees Home page with today's date
2. Feeling good → taps 😄 Great
3. Took all supplements → taps "Had All" on Supplements card
4. Missed a medication → taps "Different" on Medications card
5. App navigates to Medications page (same date selected)
6. User marks which medications they took
7. Goes back to Home → streak updates

---

This architecture creates a frictionless daily tracking experience where users can quickly log their day in seconds, or dive into details when needed.
