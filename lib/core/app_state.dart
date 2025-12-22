import 'package:flutter/material.dart';
import 'package:gut_md/screens/onboarding/onboarding_data.dart';

/// Global app state that persists across screens
class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  // Selected date (shared across all tracking pages)
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;
  
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
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

  // Daily tracking state - "Had All" tracking
  final Map<String, bool> _hadAllSupplements = {};
  final Map<String, bool> _hadAllMedications = {};
  final Map<String, bool> _hadAllDiet = {};

  String get _dateKey => '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}';

  bool getHadAllSupplements(String dateKey) => _hadAllSupplements[dateKey] ?? false;
  bool getHadAllMedications(String dateKey) => _hadAllMedications[dateKey] ?? false;
  bool getHadAllDiet(String dateKey) => _hadAllDiet[dateKey] ?? false;

  void setHadAllSupplements(bool value) {
    _hadAllSupplements[_dateKey] = value;
    notifyListeners();
  }

  void setHadAllMedications(bool value) {
    _hadAllMedications[_dateKey] = value;
    notifyListeners();
  }

  void setHadAllDiet(bool value) {
    _hadAllDiet[_dateKey] = value;
    notifyListeners();
  }

  // Current date key for convenience
  String get currentDateKey => _dateKey;
}
