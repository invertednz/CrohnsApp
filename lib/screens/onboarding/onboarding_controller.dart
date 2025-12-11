import 'package:flutter/material.dart';
import 'onboarding_data.dart';

class OnboardingController extends ChangeNotifier {
  final OnboardingData data = OnboardingData();
  int currentStep = 0;
  bool showDiscountOffer = false;
  
  final int totalSteps = 15;
  
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
  
  void selectPlan({
    required String planId,
    required double price,
    bool isPayItForward = false,
    bool isGiftedDiscount = false,
    String? donorName,
  }) {
    data.selectedPlan = planId;
    data.planPrice = price;
    data.isPayItForward = isPayItForward;
    data.isGiftedDiscount = isGiftedDiscount;
    data.giftDonorName = donorName;
    notifyListeners();
  }

  void startTrial() {
    data.isOnTrial = true;
    data.trialStartDate = DateTime.now();
    data.trialEndDate = DateTime.now().add(const Duration(days: 7));
    notifyListeners();
  }

  void completePurchase() {
    data.hasPaid = true;
    data.isOnTrial = true;
    data.trialStartDate = DateTime.now();
    data.trialEndDate = DateTime.now().add(const Duration(days: 7));
    notifyListeners();
  }
  
  void completeOnboarding() {
    data.hasCompletedOnboarding = true;
    notifyListeners();
  }
  
  void triggerDiscountOffer() {
    showDiscountOffer = true;
    notifyListeners();
  }
  
  double get progress => (currentStep + 1) / totalSteps;
}
