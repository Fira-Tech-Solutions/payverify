import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String transactionId;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String senderName;

  @HiveField(4)
  final String senderPhone;

  @HiveField(5)
  final String paymentMethod; // CBE, TeleBirr, Awash, etc.

  @HiveField(6)
  final String status; // PENDING, VERIFIED, MISMATCH, EXPIRED

  @HiveField(7)
  final DateTime timestamp;

  @HiveField(8)
  final String? workerName;

  @HiveField(9)
  final String? rawSms;

  @HiveField(10)
  final String businessId;

  Transaction({
    required this.id,
    required this.transactionId,
    required this.amount,
    required this.senderName,
    required this.senderPhone,
    required this.paymentMethod,
    required this.status,
    required this.timestamp,
    this.workerName,
    this.rawSms,
    required this.businessId,
  });

  Transaction copyWith({String? status, String? workerName}) {
    return Transaction(
      id: id,
      transactionId: transactionId,
      amount: amount,
      senderName: senderName,
      senderPhone: senderPhone,
      paymentMethod: paymentMethod,
      status: status ?? this.status,
      timestamp: timestamp,
      workerName: workerName ?? this.workerName,
      rawSms: rawSms,
      businessId: businessId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'transactionId': transactionId,
        'amount': amount,
        'senderName': senderName,
        'senderPhone': senderPhone,
        'paymentMethod': paymentMethod,
        'status': status,
        'timestamp': timestamp.toIso8601String(),
        'workerName': workerName,
        'businessId': businessId,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'],
        transactionId: json['transactionId'],
        amount: (json['amount'] as num).toDouble(),
        senderName: json['senderName'] ?? '',
        senderPhone: json['senderPhone'] ?? '',
        paymentMethod: json['paymentMethod'],
        status: json['status'],
        timestamp: DateTime.parse(json['timestamp']),
        workerName: json['workerName'],
        rawSms: json['rawSms'],
        businessId: json['businessId'],
      );
}

// Payment method constants
class PaymentMethod {
  static const String teleBirr = 'TeleBirr';
  static const String cbe = 'CBE';
  static const String awash = 'Awash';
  static const String dashen = 'Dashen';
  static const String abyssinia = 'Abyssinia';
  static const String amole = 'Amole';
  static const String helloCash = 'HelloCash';

  static const List<String> all = [
    teleBirr, cbe, awash, dashen, abyssinia, amole, helloCash
  ];

  static String smsAddress(String method) {
    switch (method) {
      case cbe:      return '841';
      case teleBirr: return 'TeleBirr';
      case awash:    return 'AwashBank';
      case amole:    return 'Amole';
      default:       return method;
    }
  }
}

// Transaction status constants
class TxStatus {
  static const String pending  = 'PENDING';
  static const String verified = 'VERIFIED';
  static const String mismatch = 'MISMATCH';
  static const String expired  = 'EXPIRED';
}
