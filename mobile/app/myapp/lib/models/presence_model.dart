class PresenceCourseModel {
  final String id;
  final String name;
  final String code;

  const PresenceCourseModel({
    required this.id,
    required this.name,
    required this.code,
  });

  factory PresenceCourseModel.fromJson(dynamic value) {
    if (value is String) {
      return PresenceCourseModel(
        id: value,
        name: 'Unknown Course',
        code: 'N/A',
      );
    }

    if (value is Map) {
      return PresenceCourseModel(
        id: PresenceModel.parseId(value),
        name: (
          value['nom'] ??
          value['name'] ??
          value['titre'] ??
          'Unknown Course'
        ).toString(),
        code: (
          value['code'] ??
          value['courseCode'] ??
          'N/A'
        ).toString(),
      );
    }

    return const PresenceCourseModel(
      id: '',
      name: 'Unknown Course',
      code: 'N/A',
    );
  }
}

class PresenceSeanceModel {
  final String id;
  final PresenceCourseModel course;

  const PresenceSeanceModel({
    required this.id,
    required this.course,
  });

  factory PresenceSeanceModel.fromJson(dynamic value) {
    if (value is String) {
      return PresenceSeanceModel(
        id: value,
        course: const PresenceCourseModel(
          id: '',
          name: 'Unknown Course',
          code: 'N/A',
        ),
      );
    }

    if (value is Map) {
      return PresenceSeanceModel(
        id: PresenceModel.parseId(value),
        course: PresenceCourseModel.fromJson(
          value['cours'] ?? value['course'],
        ),
      );
    }

    return const PresenceSeanceModel(
      id: '',
      course: PresenceCourseModel(
        id: '',
        name: 'Unknown Course',
        code: 'N/A',
      ),
    );
  }
}

class PresenceModel {
  final String id;
  final bool present;
  final String status;
  final DateTime date;
  final String studentId;
  final PresenceSeanceModel seance;

  const PresenceModel({
    required this.id,
    required this.present,
    required this.status,
    required this.date,
    required this.studentId,
    required this.seance,
  });

  factory PresenceModel.fromJson(Map<String, dynamic> input) {
    final dynamic wrapped =
        input['presence'] ?? input['data'];

    final Map<String, dynamic> json = wrapped is Map
        ? Map<String, dynamic>.from(wrapped)
        : input;

    final String rawStatus = (
      json['statut'] ??
      json['status'] ??
      ''
    ).toString();

    final bool isPresent = _parsePresence(
      json['presente'] ??
      json['present'] ??
      rawStatus,
    );

    return PresenceModel(
      id: parseId(json['_id'] ?? json['id']),
      present: isPresent,
      status: rawStatus.isNotEmpty
          ? rawStatus
          : (isPresent ? 'présent' : 'absent'),
      date: _parseDate(
            json['date'] ??
            json['datePresence'] ??
            json['createdAt'],
          ) ??
          DateTime.now(),
      studentId: parseId(
        json['etudiant'] ??
        json['student'] ??
        json['studentId'],
      ),
      seance: PresenceSeanceModel.fromJson(
        json['seance'] ?? json['session'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id.isNotEmpty) '_id': id,
      'statut': present ? 'présent' : 'absent',
      'presente': present,
      'date': date.toIso8601String(),
      if (studentId.isNotEmpty) 'etudiant': studentId,
      if (seance.id.isNotEmpty) 'seance': seance.id,
    };
  }

  bool get isPresent => present;

  static String parseId(dynamic value) {
    if (value == null) return '';

    if (value is String) return value;

    if (value is Map) {
      return (
        value['_id'] ??
        value['id'] ??
        ''
      ).toString();
    }

    return value.toString();
  }

  static bool _parsePresence(dynamic value) {
    if (value is bool) return value;

    final String normalized = value
        ?.toString()
        .trim()
        .toLowerCase() ??
        '';

    return <String>{
      'true',
      '1',
      'present',
      'présent',
      'presente',
      'présente',
    }.contains(normalized);
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  @override
  String toString() {
    return 'PresenceModel(id: $id, '
        '${present ? "Present" : "Absent"}, '
        'date: $date)';
  }
}
