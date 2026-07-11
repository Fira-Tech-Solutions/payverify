enum AppNotificationType { transaction, subscription, system }

class AppNotification {
  final String id;
  final String title;
  final String body;
  final AppNotificationType type;
  final DateTime createdAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  @override
  String toString() {
    return '$id|$title|$body|${type.name}|${createdAt.toIso8601String()}|$isRead';
  }

  factory AppNotification.fromString(String str) {
    final parts = str.split('|');
    return AppNotification(
      id: parts[0],
      title: parts[1],
      body: parts[2],
      type: AppNotificationType.values.firstWhere((e) => e.name == parts[3]),
      createdAt: DateTime.parse(parts[4]),
      isRead: parts[5] == 'true',
    );
  }
}