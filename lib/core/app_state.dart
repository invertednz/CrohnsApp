import 'package:flutter/material.dart';
import 'package:gut_md/screens/onboarding/onboarding_data.dart';

/// Global app state that persists across screens.
///
/// Tracked data itself lives in the backend (`BackendServiceProvider`); this
/// only holds UI state shared between tabs.
class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  // Selected date (shared across all tracking pages). Always a calendar day
  // with no time part.
  DateTime _selectedDate = _today();
  DateTime get selectedDate => _selectedDate;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void setSelectedDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    if (day == _selectedDate) return;
    _selectedDate = day;
    notifyListeners();
  }

  // User's onboarding data
  OnboardingData? _onboardingData;
  OnboardingData? get onboardingData => _onboardingData;

  void setOnboardingData(OnboardingData data) {
    _onboardingData = data;
    notifyListeners();
  }

  // Quick access to user's lists from onboarding
  List<String> get userMedications => _onboardingData?.medications ?? [];
  List<SupplementEntry> get userSupplements => _onboardingData?.supplements ?? [];
  List<SymptomEntry> get userSymptoms => _onboardingData?.currentSymptoms ?? [];
  List<String> get userDietFlags => _onboardingData?.dietFlags ?? [];

  /// Clears per-user state on sign out so the next account starts fresh.
  void reset() {
    _selectedDate = _today();
    _onboardingData = null;
    notifyListeners();
  }
}
