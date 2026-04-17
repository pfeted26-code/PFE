// ─── NotificationModel ─────────────────────────────────────────────────────────
// Matches backend notificationSchema

class NotificationModel {
  final String id;
  final String? titre;

  final String message;
  final String type; // 'announcement', 'grade', 'presence', etc.
  final String userId;
  final bool lu;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.titre,
    required this.message,
    required this.type,
    required this.userId,
    this.lu = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'] ?? '',
      titre: json['titre']?.toString(),

      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'default',
      userId: json['user']?.toString() ?? '',
      lu: json['lu']?.toString().toLowerCase() == 'true' ?? false,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'titre': titre,
    'message': message,
    'type': type,
    'user': userId,
    'lu': lu,
    'createdAt': createdAt.toIso8601String(),
  };

  @override
  String toString() => 'NotificationModel(id: $id, $titre [${lu ? 'read' : 'unread'}])';
}

