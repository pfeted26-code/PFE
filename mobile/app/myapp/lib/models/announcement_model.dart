class AnnouncementViewModel {
  final String userId;
  final DateTime? viewedAt;

  const AnnouncementViewModel({
    required this.userId,
    this.viewedAt,
  });

  factory AnnouncementViewModel.fromJson(dynamic value) {
    if (value is String) {
      return AnnouncementViewModel(userId: value);
    }

    if (value is Map) {
      final dynamic user = value['utilisateur'] ?? value['user'];

      return AnnouncementViewModel(
        userId: AnnouncementModel.parseId(user),
        viewedAt: DateTime.tryParse(
          (value['dateVue'] ?? value['viewedAt'] ?? '').toString(),
        ),
      );
    }

    return const AnnouncementViewModel(userId: '');
  }
}

class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final String type;
  final String priority;
  final String recipientType;
  final String authorId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;
  final bool pinned;
  final bool? viewedForCurrentUser;
  final int viewCount;
  final List<AnnouncementViewModel> views;
  final List<String> specificClassIds;
  final List<String> specificUserIds;
  final List<String> multipleRoles;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.priority,
    required this.recipientType,
    required this.authorId,
    required this.createdAt,
    this.updatedAt,
    this.expiresAt,
    this.pinned = false,
    this.viewedForCurrentUser,
    this.viewCount = 0,
    this.views = const <AnnouncementViewModel>[],
    this.specificClassIds = const <String>[],
    this.specificUserIds = const <String>[],
    this.multipleRoles = const <String>[],
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> input) {
    final dynamic wrapped =
        input['announcement'] ?? input['annonce'] ?? input['data'];

    final Map<String, dynamic> json = wrapped is Map
        ? Map<String, dynamic>.from(wrapped)
        : input;

    final List<AnnouncementViewModel> parsedViews =
        _parseViews(json['vues'] ?? json['viewedBy']);

    final int parsedCount = _parseInt(
      json['nombreVues'] ??
          json['viewCount'] ??
          json['viewsCount'] ??
          parsedViews.length,
    );

    return AnnouncementModel(
      id: parseId(json['_id'] ?? json['id']),
      title: _readString(json['titre'] ?? json['title']),
      content: _readString(json['contenu'] ?? json['content']),
      type: _readString(json['type'], fallback: 'info'),
      priority: _readString(
        json['priorite'] ?? json['priority'],
        fallback: 'normal',
      ),
      recipientType: _readString(
        json['destinataires'] ?? json['recipientType'],
        fallback: 'all',
      ),
      authorId: parseId(
        json['auteur'] ??
            json['author'] ??
            json['createdBy'] ??
            json['admin'],
      ),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']),
      expiresAt: _parseDate(
        json['dateExpiration'] ??
            json['expiresAt'] ??
            json['expirationDate'],
      ),
      pinned: _parseBool(
        json['pinned'] ??
            json['epinglee'] ??
            json['estEpinglee'] ??
            json['isPinned'],
      ),
      viewedForCurrentUser: _parseNullableBool(
        json['isViewed'] ??
            json['hasViewed'] ??
            json['vueParUtilisateur'],
      ),
      viewCount: parsedCount,
      views: parsedViews,
      specificClassIds: _parseIdList(
        json['classesSpecifiques'] ?? json['specificClasses'],
      ),
      specificUserIds: _parseIdList(
        json['utilisateursSpecifiques'] ?? json['specificUsers'],
      ),
      multipleRoles: _parseStringList(
        json['rolesMultiples'] ?? json['multipleRoles'],
      ),
    );
  }

  AnnouncementModel copyWith({
    String? id,
    String? title,
    String? content,
    String? type,
    String? priority,
    String? recipientType,
    String? authorId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    bool? pinned,
    bool? viewedForCurrentUser,
    int? viewCount,
    List<AnnouncementViewModel>? views,
    List<String>? specificClassIds,
    List<String>? specificUserIds,
    List<String>? multipleRoles,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      recipientType: recipientType ?? this.recipientType,
      authorId: authorId ?? this.authorId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      pinned: pinned ?? this.pinned,
      viewedForCurrentUser:
          viewedForCurrentUser ?? this.viewedForCurrentUser,
      viewCount: viewCount ?? this.viewCount,
      views: views ?? this.views,
      specificClassIds: specificClassIds ?? this.specificClassIds,
      specificUserIds: specificUserIds ?? this.specificUserIds,
      multipleRoles: multipleRoles ?? this.multipleRoles,
    );
  }

  bool isViewedBy(String? currentUserId) {
    if (viewedForCurrentUser == true) return true;

    final String id = currentUserId?.trim() ?? '';
    if (id.isEmpty) return false;

    return views.any(
      (AnnouncementViewModel view) => view.userId == id,
    );
  }

  bool get isExpired {
    final DateTime? expiration = expiresAt;
    return expiration != null && expiration.isBefore(DateTime.now());
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id.isNotEmpty) '_id': id,
      'titre': title,
      'contenu': content,
      'type': type,
      'priorite': priority,
      'destinataires': recipientType,
      if (authorId.isNotEmpty) 'auteur': authorId,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (expiresAt != null)
        'dateExpiration': expiresAt!.toIso8601String(),
      'pinned': pinned,
      'nombreVues': viewCount,
      if (specificClassIds.isNotEmpty)
        'classesSpecifiques': specificClassIds,
      if (specificUserIds.isNotEmpty)
        'utilisateursSpecifiques': specificUserIds,
      if (multipleRoles.isNotEmpty) 'rolesMultiples': multipleRoles,
    };
  }

  static String parseId(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;

    if (value is Map) {
      return _readString(value['_id'] ?? value['id']);
    }

    return value.toString();
  }

  static String _readString(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) return fallback;

    final String result = value.toString().trim();
    return result.isEmpty ? fallback : result;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;

    final String normalized = value?.toString().toLowerCase() ?? '';
    return normalized == 'true' || normalized == '1';
  }

  static bool? _parseNullableBool(dynamic value) {
    if (value == null) return null;
    return _parseBool(value);
  }

  static List<AnnouncementViewModel> _parseViews(dynamic value) {
    if (value is! List) return const <AnnouncementViewModel>[];

    return value
        .map(AnnouncementViewModel.fromJson)
        .where(
          (AnnouncementViewModel view) => view.userId.isNotEmpty,
        )
        .toList();
  }

  static List<String> _parseIdList(dynamic value) {
    if (value is! List) return const <String>[];

    return value
        .map(parseId)
        .where((String id) => id.isNotEmpty)
        .toList();
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is! List) return const <String>[];

    return value
        .map((dynamic item) => item.toString())
        .where((String item) => item.isNotEmpty)
        .toList();
  }

  @override
  String toString() {
    return 'AnnouncementModel(id: $id, title: $title)';
  }
}
