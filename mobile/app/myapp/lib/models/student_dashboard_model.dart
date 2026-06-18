class DashboardStatModel {
  final String title;
  final String value;
  final String icon;
  final String color;
  final String change;

  const DashboardStatModel({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.change,
  });

  factory DashboardStatModel.fromJson(dynamic input) {
    if (input is! Map) {
      return const DashboardStatModel(
        title: 'Statistic',
        value: '0',
        icon: '',
        color: '',
        change: '+0',
      );
    }

    final Map<dynamic, dynamic> json = input;

    return DashboardStatModel(
      title: _readString(
        json['title'] ??
            json['label'] ??
            json['name'],
        fallback: 'Statistic',
      ),
      value: _readString(
        json['value'] ??
            json['count'] ??
            json['total'],
        fallback: '0',
      ),
      icon: _readString(json['icon']),
      color: _readString(json['color']),
      change: _readString(
        json['change'] ??
            json['variation'] ??
            json['trend'],
        fallback: '+0',
      ),
    );
  }
}

class DashboardActivityModel {
  final String action;
  final String user;
  final String time;
  final String icon;
  final DateTime? createdAt;

  const DashboardActivityModel({
    required this.action,
    required this.user,
    required this.time,
    required this.icon,
    this.createdAt,
  });

  factory DashboardActivityModel.fromJson(dynamic input) {
    if (input is! Map) {
      return const DashboardActivityModel(
        action: 'Activity',
        user: '',
        time: '',
        icon: '',
      );
    }

    final Map<dynamic, dynamic> json = input;

    return DashboardActivityModel(
      action: _readString(
        json['action'] ??
            json['title'] ??
            json['message'] ??
            json['description'],
        fallback: 'Activity',
      ),
      user: _readString(
        json['user'] ??
            json['author'] ??
            json['subtitle'] ??
            json['name'],
      ),
      time: _readString(
        json['time'] ??
            json['relativeTime'] ??
            json['dateLabel'],
      ),
      icon: _readString(json['icon']),
      createdAt: _readDate(
        json['createdAt'] ??
            json['date'] ??
            json['timestamp'],
      ),
    );
  }
}

class DashboardSessionModel {
  final String id;
  final String title;
  final DateTime? startAt;

  const DashboardSessionModel({
    required this.id,
    required this.title,
    this.startAt,
  });

  factory DashboardSessionModel.fromJson(dynamic input) {
    if (input is! Map) {
      return const DashboardSessionModel(
        id: '',
        title: 'Session',
      );
    }

    final Map<dynamic, dynamic> json = input;

    return DashboardSessionModel(
      id: _parseId(json['_id'] ?? json['id']),
      title: _readString(
        json['title'] ??
            json['nom'] ??
            json['name'] ??
            json['cours']?['nom'],
        fallback: 'Session',
      ),
      startAt: _readDate(
        json['startAt'] ??
            json['dateDebut'] ??
            json['date'] ??
            json['heureDebut'],
      ),
    );
  }
}

class StudentDashboardModel {
  final List<DashboardStatModel> stats;
  final List<DashboardActivityModel> recentActivity;
  final List<DashboardSessionModel> todaysSessions;
  final String? studentName;

  const StudentDashboardModel({
    required this.stats,
    required this.recentActivity,
    required this.todaysSessions,
    this.studentName,
  });

  factory StudentDashboardModel.fromJson(
    Map<String, dynamic> input,
  ) {
    final dynamic wrapped =
        input['dashboard'] ??
        input['data'] ??
        input['result'];

    final Map<String, dynamic> json = wrapped is Map
        ? Map<String, dynamic>.from(wrapped)
        : input;

    return StudentDashboardModel(
      stats: _parseList(json['stats'])
          .map(DashboardStatModel.fromJson)
          .toList(),
      recentActivity: _parseList(
        json['recentActivity'] ??
            json['recentActivities'] ??
            json['activities'],
      ).map(DashboardActivityModel.fromJson).toList(),
      todaysSessions: _parseList(
        json['todaysSessions'] ??
            json['todaySessions'] ??
            json['sessionsToday'],
      ).map(DashboardSessionModel.fromJson).toList(),
      studentName: _nullableString(
        json['studentName'] ??
            json['userName'] ??
            json['name'] ??
            json['user']?['nom'] ??
            json['user']?['name'],
      ),
    );
  }

  DashboardStatModel? findStat(
    List<String> keywords,
  ) {
    for (final DashboardStatModel stat in stats) {
      final String title = stat.title.toLowerCase();

      if (keywords.any(
        (String keyword) =>
            title.contains(keyword.toLowerCase()),
      )) {
        return stat;
      }
    }

    return null;
  }

  String statValueAt(
    int index, {
    String fallback = '0',
  }) {
    if (index < 0 || index >= stats.length) {
      return fallback;
    }

    final String value = stats[index].value.trim();
    return value.isEmpty ? fallback : value;
  }
}

List<dynamic> _parseList(dynamic value) {
  if (value is List) return value;
  return const <dynamic>[];
}

String _readString(
  dynamic value, {
  String fallback = '',
}) {
  if (value == null) return fallback;

  final String result = value.toString().trim();
  return result.isEmpty ? fallback : result;
}

String? _nullableString(dynamic value) {
  final String result = _readString(value);
  return result.isEmpty ? null : result;
}

String _parseId(dynamic value) {
  if (value == null) return '';

  if (value is String) return value;

  if (value is Map) {
    return _readString(
      value['_id'] ?? value['id'],
    );
  }

  return value.toString();
}

DateTime? _readDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
