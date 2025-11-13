class Referral {
  final String id;
  final String userId;
  final String referralCode;
  final int successfulReferrals;
  final double earnedRewards;
  final DateTime createdAt;
  final DateTime? lastReferralAt;
  final List<String> referredUserIds;
  
  static const double rewardPerReferral = 10.0;
  static const double maxRewardCap = 50.0;
  static const int maxReferrals = 5;

  Referral({
    required this.id,
    required this.userId,
    required this.referralCode,
    this.successfulReferrals = 0,
    this.earnedRewards = 0.0,
    required this.createdAt,
    this.lastReferralAt,
    List<String>? referredUserIds,
  }) : referredUserIds = referredUserIds ?? [];

  double get remainingRewardPotential => maxRewardCap - earnedRewards;
  int get remainingReferralSlots => maxReferrals - successfulReferrals;
  bool get hasReachedCap => earnedRewards >= maxRewardCap;
  double get progressPercent => (earnedRewards / maxRewardCap * 100).clamp(0, 100);
  
  String get badgeLevel {
    if (successfulReferrals >= 5) return 'Health Hero';
    if (successfulReferrals >= 3) return 'Community Champion';
    return 'None';
  }
  
  bool get hasBadge => successfulReferrals >= 3;

  Referral copyWith({
    String? id,
    String? userId,
    String? referralCode,
    int? successfulReferrals,
    double? earnedRewards,
    DateTime? createdAt,
    DateTime? lastReferralAt,
    List<String>? referredUserIds,
  }) {
    return Referral(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      referralCode: referralCode ?? this.referralCode,
      successfulReferrals: successfulReferrals ?? this.successfulReferrals,
      earnedRewards: earnedRewards ?? this.earnedRewards,
      createdAt: createdAt ?? this.createdAt,
      lastReferralAt: lastReferralAt ?? this.lastReferralAt,
      referredUserIds: referredUserIds ?? this.referredUserIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'referralCode': referralCode,
      'successfulReferrals': successfulReferrals,
      'earnedRewards': earnedRewards,
      'createdAt': createdAt.toIso8601String(),
      'lastReferralAt': lastReferralAt?.toIso8601String(),
      'referredUserIds': referredUserIds,
    };
  }

  factory Referral.fromJson(Map<String, dynamic> json) {
    return Referral(
      id: json['id'],
      userId: json['userId'],
      referralCode: json['referralCode'],
      successfulReferrals: json['successfulReferrals'] ?? 0,
      earnedRewards: (json['earnedRewards'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      lastReferralAt: json['lastReferralAt'] != null 
          ? DateTime.parse(json['lastReferralAt']) 
          : null,
      referredUserIds: List<String>.from(json['referredUserIds'] ?? []),
    );
  }
}
