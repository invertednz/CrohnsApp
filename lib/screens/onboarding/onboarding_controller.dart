import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gut_md/core/app_state.dart';
import 'package:gut_md/core/backend_service_provider.dart';
import 'onboarding_data.dart';

class OnboardingController extends ChangeNotifier {
  final OnboardingData data = OnboardingData();
  int currentStep = 0;
  
  final int totalSteps = 18;

  /// Last step of the personal quiz (Commitment); the paywall follows.
  static const int lastQuizStep = 15;
  
  void nextStep() {
    if (currentStep < totalSteps - 1) {
      currentStep++;
      notifyListeners();
    }
  }
  
  void previousStep() {
    if (currentStep > 0) {
      currentStep--;
      notifyListeners();
    }
  }
  
  void goToStep(int step) {
    if (step >= 0 && step < totalSteps) {
      currentStep = step;
      notifyListeners();
    }
  }
  
  void setGoal(String goal) {
    data.goal = goal;
    notifyListeners();
  }
  
  void toggleDietFlag(String flag) {
    if (data.dietFlags.contains(flag)) {
      data.dietFlags.remove(flag);
    } else {
      data.dietFlags.add(flag);
    }
    notifyListeners();
  }
  
  void addDietFlag(String flag) {
    if (flag.trim().isNotEmpty && !data.dietFlags.contains(flag)) {
      data.dietFlags.add(flag);
      notifyListeners();
    }
  }
  
  void removeDietFlag(String flag) {
    data.dietFlags.remove(flag);
    notifyListeners();
  }
  
  void addSupplement(SupplementEntry supplement) {
    if (supplement.name.trim().isNotEmpty) {
      data.supplements.add(supplement);
      notifyListeners();
    }
  }
  
  void removeSupplement(int index) {
    if (index >= 0 && index < data.supplements.length) {
      data.supplements.removeAt(index);
      notifyListeners();
    }
  }
  
  void updateSupplement(int index, SupplementEntry supplement) {
    if (index >= 0 && index < data.supplements.length) {
      data.supplements[index] = supplement;
      notifyListeners();
    }
  }
  
  void toggleLifestyle(String item) {
    if (data.lifestyle.contains(item)) {
      data.lifestyle.remove(item);
    } else {
      data.lifestyle.add(item);
    }
    notifyListeners();
  }
  
  void addLifestyle(String item) {
    if (item.trim().isNotEmpty && !data.lifestyle.contains(item)) {
      data.lifestyle.add(item);
      notifyListeners();
    }
  }
  
  void removeLifestyle(String item) {
    data.lifestyle.remove(item);
    notifyListeners();
  }
  
  void toggleMedication(String medication) {
    if (data.medications.contains(medication)) {
      data.medications.remove(medication);
    } else {
      data.medications.add(medication);
    }
    notifyListeners();
  }
  
  void addMedication(String medication) {
    if (medication.trim().isNotEmpty && !data.medications.contains(medication)) {
      data.medications.add(medication);
      notifyListeners();
    }
  }
  
  void removeMedication(String medication) {
    data.medications.remove(medication);
    notifyListeners();
  }
  
  void addSymptom(SymptomEntry symptom) {
    if (symptom.name.trim().isNotEmpty && 
        !data.currentSymptoms.any((s) => s.name == symptom.name)) {
      data.currentSymptoms.add(symptom);
      notifyListeners();
    }
  }
  
  void removeSymptom(String symptomName) {
    data.currentSymptoms.removeWhere((s) => s.name == symptomName);
    notifyListeners();
  }
  
  void updateSymptomSeverity(String symptomName, String severity) {
    final index = data.currentSymptoms.indexWhere((s) => s.name == symptomName);
    if (index != -1) {
      data.currentSymptoms[index].severity = severity;
      notifyListeners();
    }
  }
  
  bool hasSymptom(String symptomName) {
    return data.currentSymptoms.any((s) => s.name == symptomName);
  }
  
  SymptomEntry? getSymptom(String symptomName) {
    try {
      return data.currentSymptoms.firstWhere((s) => s.name == symptomName);
    } catch (e) {
      return null;
    }
  }
  
  void toggleNotificationTime(String time) {
    if (data.notificationTimes.contains(time)) {
      data.notificationTimes.remove(time);
    } else {
      data.notificationTimes.add(time);
    }
    notifyListeners();
  }
  
  /// Records the plan the user picked. Nothing is charged: the app has no
  /// payment processing, so this is only saved as a preference.
  void selectPlan(SubscriptionPlan plan) {
    data.selectedPlan = plan.id;
    data.planPrice = plan.price;
    data.isPayItForward = plan == SubscriptionPlan.payItForward;
    data.isDiscounted = plan == SubscriptionPlan.discountedAnnual;
    notifyListeners();
  }

  SubscriptionPlan get selectedPlan => SubscriptionPlan.fromId(data.selectedPlan);

  /// Starts the free trial. Keeps the original dates if it already started.
  void startTrial({DateTime? now}) {
    if (data.isOnTrial && data.trialEndDate != null) return;
    final start = now ?? DateTime.now();
    data.isOnTrial = true;
    data.trialStartDate = start;
    data.trialEndDate = start.add(const Duration(days: kTrialDays));
    notifyListeners();
  }

  /// Date the trial ends (or would end if started now).
  DateTime get trialEndDate =>
      data.trialEndDate ?? DateTime.now().add(const Duration(days: kTrialDays));

  /// Marks onboarding done and shares the answers with the rest of the app
  /// (Supps/Meds/Symptoms tabs read them from [AppState]).
  void completeOnboarding() {
    data.hasCompletedOnboarding = true;
    commitAnswers();
    notifyListeners();
  }

  /// Makes the answers so far available app-wide through [AppState].
  void commitAnswers() {
    AppState().setOnboardingData(data);
  }
  
  double get progress => (currentStep + 1) / totalSteps;
}

/// Persists onboarding answers for a signed-in user as a single `profile`
/// tracking entry, so they survive restarts and other devices, and the tabs
/// and AI can read them.
class OnboardingProfileStore {
  static const String trackingType = 'profile';
  static const String entryId = 'onboarding';

  /// The tracking entry saved for [data].
  static Map<String, dynamic> toEntry(OnboardingData data, {DateTime? now}) => {
        ...data.toJson(),
        'entry_id': entryId,
        'date': DateFormat('yyyy-MM-dd').format(now ?? DateTime.now()),
        'condition_display': data.conditionDisplayString,
      };

  /// Saves [data] for [userId] (default: the signed-in user). Returns false
  /// when nobody is signed in yet, so the caller can save after sign-up.
  static Future<bool> save(
    OnboardingData data, {
    String? userId,
    UnifiedTrackingService? tracking,
  }) async {
    if (tracking == null && !BackendServiceProvider.isInitialized) return false;
    final backend = tracking == null ? BackendServiceProvider.instance : null;
    final uid = userId ?? backend?.auth.currentUser?.id;
    if (uid == null) return false;
    await (tracking ?? backend!.tracking).trackEvent(
      userId: uid,
      type: trackingType,
      data: toEntry(data),
    );
    return true;
  }

  /// Loads the saved answers for [userId] and shares them through [AppState].
  /// Returns null when the user has no saved profile.
  static Future<OnboardingData?> restore(
    String userId, {
    UnifiedTrackingService? tracking,
  }) async {
    if (tracking == null && !BackendServiceProvider.isInitialized) return null;
    final source = tracking ?? BackendServiceProvider.instance.tracking;
    final entry = await source.getTrackingData(
      userId: userId,
      date: entryId,
      type: trackingType,
    );
    if (entry == null) return null;
    final data = OnboardingData.fromJson(entry);
    AppState().setOnboardingData(data);
    return data;
  }
}
