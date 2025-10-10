class OnboardingData {
  String? goal;
  List<String> notificationTimes = [];
  List<String> dietFlags = [];
  List<SupplementEntry> supplements = [];
  List<String> lifestyle = [];
  List<String> medications = [];
  List<String> currentSymptoms = [];
  bool hasCompletedOnboarding = false;
  bool isOnTrial = false;
  bool hasPaid = false;
  DateTime? trialStartDate;
  DateTime? trialEndDate;

  OnboardingData();

  Map<String, dynamic> toJson() {
    return {
      'goal': goal,
      'notificationTimes': notificationTimes,
      'dietFlags': dietFlags,
      'supplements': supplements.map((s) => s.toJson()).toList(),
      'lifestyle': lifestyle,
      'medications': medications,
      'currentSymptoms': currentSymptoms,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'isOnTrial': isOnTrial,
      'hasPaid': hasPaid,
      'trialStartDate': trialStartDate?.toIso8601String(),
      'trialEndDate': trialEndDate?.toIso8601String(),
    };
  }

  factory OnboardingData.fromJson(Map<String, dynamic> json) {
    final data = OnboardingData();
    data.goal = json['goal'];
    data.notificationTimes = List<String>.from(json['notificationTimes'] ?? []);
    data.dietFlags = List<String>.from(json['dietFlags'] ?? []);
    data.supplements = (json['supplements'] as List?)
            ?.map((s) => SupplementEntry.fromJson(s))
            .toList() ??
        [];
    data.lifestyle = List<String>.from(json['lifestyle'] ?? []);
    data.medications = List<String>.from(json['medications'] ?? []);
    data.currentSymptoms = List<String>.from(json['currentSymptoms'] ?? []);
    data.hasCompletedOnboarding = json['hasCompletedOnboarding'] ?? false;
    data.isOnTrial = json['isOnTrial'] ?? false;
    data.hasPaid = json['hasPaid'] ?? false;
    data.trialStartDate = json['trialStartDate'] != null
        ? DateTime.parse(json['trialStartDate'])
        : null;
    data.trialEndDate = json['trialEndDate'] != null
        ? DateTime.parse(json['trialEndDate'])
        : null;
    return data;
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
