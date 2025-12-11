/// Supported digestive conditions
enum GutCondition {
  crohns('Crohn\'s Disease', 'An inflammatory bowel disease affecting the digestive tract'),
  ulcerativeColitis('Ulcerative Colitis', 'Inflammation and ulcers in the colon and rectum'),
  ibs('IBS', 'Irritable Bowel Syndrome - a common disorder affecting the large intestine'),
  ibd('IBD (Other)', 'Other inflammatory bowel disease'),
  celiac('Celiac Disease', 'An immune reaction to eating gluten'),
  gerd('GERD', 'Gastroesophageal reflux disease - chronic acid reflux'),
  other('Other Digestive Condition', 'Another digestive or gut health condition'),
  notSure('Not Sure / Undiagnosed', 'Experiencing symptoms but no formal diagnosis yet');

  final String displayName;
  final String description;
  const GutCondition(this.displayName, this.description);
}

class OnboardingData {
  String? goal;
  GutCondition? condition;
  List<GutCondition> conditions = []; // Support multiple conditions
  List<String> notificationTimes = [];
  List<String> dietFlags = [];
  List<SupplementEntry> supplements = [];
  List<String> lifestyle = [];
  List<String> medications = [];
  List<SymptomEntry> currentSymptoms = [];
  bool hasCompletedOnboarding = false;
  bool isOnTrial = false;
  bool hasPaid = false;
  DateTime? trialStartDate;
  DateTime? trialEndDate;
  String selectedPlan = 'annual';
  bool isPayItForward = false;
  bool isGiftedDiscount = false;
  double planPrice = 49;
  String? giftDonorName;

  OnboardingData();

  Map<String, dynamic> toJson() {
    return {
      'goal': goal,
      'condition': condition?.name,
      'conditions': conditions.map((c) => c.name).toList(),
      'notificationTimes': notificationTimes,
      'dietFlags': dietFlags,
      'supplements': supplements.map((s) => s.toJson()).toList(),
      'lifestyle': lifestyle,
      'medications': medications,
      'currentSymptoms': currentSymptoms.map((s) => s.toJson()).toList(),
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'isOnTrial': isOnTrial,
      'hasPaid': hasPaid,
      'trialStartDate': trialStartDate?.toIso8601String(),
      'trialEndDate': trialEndDate?.toIso8601String(),
      'selectedPlan': selectedPlan,
      'isPayItForward': isPayItForward,
      'isGiftedDiscount': isGiftedDiscount,
      'planPrice': planPrice,
      'giftDonorName': giftDonorName,
    };
  }

  factory OnboardingData.fromJson(Map<String, dynamic> json) {
    final data = OnboardingData();
    data.goal = json['goal'];
    // Parse condition
    if (json['condition'] != null) {
      try {
        data.condition = GutCondition.values.firstWhere(
          (c) => c.name == json['condition'],
        );
      } catch (_) {}
    }
    // Parse conditions list
    if (json['conditions'] != null) {
      data.conditions = (json['conditions'] as List)
          .map((c) {
            try {
              return GutCondition.values.firstWhere((gc) => gc.name == c);
            } catch (_) {
              return null;
            }
          })
          .whereType<GutCondition>()
          .toList();
    }
    data.notificationTimes = List<String>.from(json['notificationTimes'] ?? []);
    data.dietFlags = List<String>.from(json['dietFlags'] ?? []);
    data.supplements = (json['supplements'] as List?)
            ?.map((s) => SupplementEntry.fromJson(s))
            .toList() ??
        [];
    data.lifestyle = List<String>.from(json['lifestyle'] ?? []);
    data.medications = List<String>.from(json['medications'] ?? []);
    data.currentSymptoms = (json['currentSymptoms'] as List?)
            ?.map((s) => SymptomEntry.fromJson(s))
            .toList() ??
        [];
    data.hasCompletedOnboarding = json['hasCompletedOnboarding'] ?? false;
    data.isOnTrial = json['isOnTrial'] ?? false;
    data.hasPaid = json['hasPaid'] ?? false;
    data.trialStartDate = json['trialStartDate'] != null
        ? DateTime.parse(json['trialStartDate'])
        : null;
    data.trialEndDate = json['trialEndDate'] != null
        ? DateTime.parse(json['trialEndDate'])
        : null;
    data.selectedPlan = json['selectedPlan'] ?? 'annual';
    data.isPayItForward = json['isPayItForward'] ?? false;
    data.isGiftedDiscount = json['isGiftedDiscount'] ?? false;
    data.planPrice = (json['planPrice'] ?? 0).toDouble();
    data.giftDonorName = json['giftDonorName'];
    return data;
  }

  /// Get a display string for the user's conditions
  String get conditionDisplayString {
    if (conditions.isEmpty) {
      return condition?.displayName ?? 'Not specified';
    }
    return conditions.map((c) => c.displayName).join(', ');
  }
}

class SupplementEntry {
  String name;
  bool takesAM;
  bool takesPM;

  SupplementEntry({
    required this.name,
    this.takesAM = false,
    this.takesPM = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'takesAM': takesAM,
      'takesPM': takesPM,
    };
  }

  factory SupplementEntry.fromJson(Map<String, dynamic> json) {
    return SupplementEntry(
      name: json['name'],
      takesAM: json['takesAM'] ?? false,
      takesPM: json['takesPM'] ?? false,
    );
  }
}

class SymptomEntry {
  String name;
  String severity; // 'Mild', 'Moderate', 'Severe'
  bool isCustom;

  SymptomEntry({
    required this.name,
    this.severity = 'Moderate',
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'severity': severity,
      'isCustom': isCustom,
    };
  }

  factory SymptomEntry.fromJson(Map<String, dynamic> json) {
    return SymptomEntry(
      name: json['name'],
      severity: json['severity'] ?? 'Moderate',
      isCustom: json['isCustom'] ?? false,
    );
  }
}
