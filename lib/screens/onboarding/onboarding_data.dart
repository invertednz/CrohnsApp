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

/// Length of the free trial every plan starts with.
const int kTrialDays = 7;

/// Plans offered on the paywall. The app does not process payments: picking a
/// plan only records the choice on the user's profile.
enum SubscriptionPlan {
  annual('annual', 'Annual', 49, '/year'),
  monthly('monthly', 'Monthly', 9.99, '/month'),
  payItForward('pay_it_forward', 'Pay It Forward', 59, '/year'),
  discountedAnnual('discounted_annual', 'Annual (new member offer)', 29, '/year');

  final String id;
  final String displayName;
  final double price;
  final String period;
  const SubscriptionPlan(this.id, this.displayName, this.price, this.period);

  /// "$49", "$9.99".
  String get priceLabel =>
      '\$${price == price.roundToDouble() ? price.toStringAsFixed(0) : price.toStringAsFixed(2)}';

  static SubscriptionPlan fromId(String? id) => SubscriptionPlan.values.firstWhere(
        (p) => p.id == id,
        orElse: () => SubscriptionPlan.annual,
      );

  /// What a year on the annual plan saves compared with 12 monthly payments.
  static double get annualSavings => monthly.price * 12 - annual.price;

  /// [annualSavings] as a whole percentage of a year of monthly payments.
  static int get annualSavingsPercent => (annualSavings / (monthly.price * 12) * 100).round();
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
  /// Always false today: there is no payment processing in the app.
  bool hasPaid = false;
  DateTime? trialStartDate;
  DateTime? trialEndDate;
  String selectedPlan = SubscriptionPlan.annual.id;
  bool isPayItForward = false;
  bool isDiscounted = false;
  double planPrice = SubscriptionPlan.annual.price;

  /// The personalised starter plan shown at the end of the quiz
  /// (GutPlan.toJson), kept so Home can show it later.
  Map<String, dynamic>? plan;

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
      'isDiscounted': isDiscounted,
      'planPrice': planPrice,
      'plan': plan,
    };
  }

  factory OnboardingData.fromJson(Map<String, dynamic> json) {
    final data = OnboardingData();
    data.goal = json['goal'];
    final plan = json['plan'];
    data.plan = plan is Map ? Map<String, dynamic>.from(plan) : null;
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
            ?.whereType<Map>()
            .map((s) => SupplementEntry.fromJson(Map<String, dynamic>.from(s)))
            .toList() ??
        [];
    data.lifestyle = List<String>.from(json['lifestyle'] ?? []);
    data.medications = List<String>.from(json['medications'] ?? []);
    data.currentSymptoms = (json['currentSymptoms'] as List?)
            ?.whereType<Map>()
            .map((s) => SymptomEntry.fromJson(Map<String, dynamic>.from(s)))
            .toList() ??
        [];
    data.hasCompletedOnboarding = json['hasCompletedOnboarding'] ?? false;
    data.isOnTrial = json['isOnTrial'] ?? false;
    data.hasPaid = json['hasPaid'] ?? false;
    data.trialStartDate = DateTime.tryParse('${json['trialStartDate'] ?? ''}');
    data.trialEndDate = DateTime.tryParse('${json['trialEndDate'] ?? ''}');
    data.selectedPlan = json['selectedPlan'] ?? SubscriptionPlan.annual.id;
    data.isPayItForward = json['isPayItForward'] ?? false;
    data.isDiscounted = json['isDiscounted'] ?? false;
    data.planPrice = (json['planPrice'] as num?)?.toDouble() ??
        SubscriptionPlan.fromId(data.selectedPlan).price;
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
