class AppUser {
  final String id;
  final String name;
  final String phone;
  final String role; // OWNER, MANAGER, CASHIER
  final String businessId;
  final String businessName;
  final String? token;

  AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.businessId,
    required this.businessName,
    this.token,
  });

  bool get isOwner   => role == UserRole.owner;
  bool get isManager => role == UserRole.manager || isOwner;
  bool get isCashier => role == UserRole.cashier;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id:           json['id'],
        name:         json['name'],
        phone:        json['phone'],
        role:         json['role'],
        businessId:   json['businessId'],
        businessName: json['businessName'],
        token:        json['token'],
      );

  Map<String, dynamic> toJson() => {
        'id':           id,
        'name':         name,
        'phone':        phone,
        'role':         role,
        'businessId':   businessId,
        'businessName': businessName,
      };
}

class UserRole {
  static const String owner   = 'OWNER';
  static const String manager = 'MANAGER';
  static const String cashier = 'CASHIER';
}
