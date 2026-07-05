class SubscriptionStatus {
  final String status;
  final String tier;
  final DateTime? trialEndsAt;
  final DateTime? subscriptionEndsAt;
  final DateTime? graceEndsAt;
  final int? daysRemaining;
  final int? graceDaysRemaining;
  final int verificationCount;
  final int workerCount;

  SubscriptionStatus({
    required this.status,
    required this.tier,
    this.trialEndsAt,
    this.subscriptionEndsAt,
    this.graceEndsAt,
    this.daysRemaining,
    this.graceDaysRemaining,
    this.verificationCount = 0,
    this.workerCount = 0,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) =>
      SubscriptionStatus(
        status: json['status'] ?? 'TRIAL',
        tier: json['tier'] ?? 'STARTER',
        trialEndsAt: json['trialEndsAt'] != null
            ? DateTime.parse(json['trialEndsAt'])
            : null,
        subscriptionEndsAt: json['subscriptionEndsAt'] != null
            ? DateTime.parse(json['subscriptionEndsAt'])
            : null,
        graceEndsAt: json['graceEndsAt'] != null
            ? DateTime.parse(json['graceEndsAt'])
            : null,
        daysRemaining: json['daysRemaining'],
        graceDaysRemaining: json['graceDaysRemaining'],
        verificationCount: json['verificationCount'] ?? 0,
        workerCount: json['workerCount'] ?? 0,
      );

  bool get isTrial => status == 'TRIAL';
  bool get isActive => status == 'ACTIVE';
  bool get isGrace => status == 'GRACE';
  bool get isExpired => status == 'EXPIRED';
  bool get canVerify => !isExpired;
}

class SubscriptionPlan {
  final String tier;
  final String nameEn;
  final double monthlyPrice;
  final double yearlyPrice;
  final int maxCashiers;
  final int maxLocations;
  final List<String> features;

  SubscriptionPlan({
    required this.tier,
    required this.nameEn,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.maxCashiers,
    required this.maxLocations,
    required this.features,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) =>
      SubscriptionPlan(
        tier: json['tier'],
        nameEn: json['nameEn'],
        monthlyPrice: (json['monthlyPrice'] as num).toDouble(),
        yearlyPrice: (json['yearlyPrice'] as num).toDouble(),
        maxCashiers: json['maxCashiers'] ?? -1,
        maxLocations: json['maxLocations'] ?? 1,
        features: List<String>.from(json['features'] ?? []),
      );

  String get monthlyDisplay => 'ETB ${monthlyPrice.toStringAsFixed(0)}';
  String get yearlyDisplay => 'ETB ${yearlyPrice.toStringAsFixed(0)}';
  String get cashierDisplay =>
      maxCashiers == -1 ? 'Unlimited' : '$maxCashiers';
  String get locationDisplay =>
      maxLocations == -1 ? 'Unlimited' : '$maxLocations';
}

class SubscriptionPayment {
  final String id;
  final String transactionId;
  final double amount;
  final String tier;
  final int periodMonths;
  final DateTime paidAt;
  final DateTime? verifiedAt;
  final DateTime createdAt;

  SubscriptionPayment({
    required this.id,
    required this.transactionId,
    required this.amount,
    required this.tier,
    required this.periodMonths,
    required this.paidAt,
    this.verifiedAt,
    required this.createdAt,
  });

  factory SubscriptionPayment.fromJson(Map<String, dynamic> json) =>
      SubscriptionPayment(
        id: json['id'],
        transactionId: json['transactionId'],
        amount: (json['amount'] as num).toDouble(),
        tier: json['tier'],
        periodMonths: json['periodMonths'],
        paidAt: DateTime.parse(json['paidAt']),
        verifiedAt: json['verifiedAt'] != null
            ? DateTime.parse(json['verifiedAt'])
            : null,
        createdAt: DateTime.parse(json['createdAt']),
      );
}
