import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/presence_model.dart';
import '../../services/presence_service.dart';

class StudentAttendancePage extends StatefulWidget {
  final String? studentId;

  const StudentAttendancePage({
    super.key,
    this.studentId,
  });

  @override
  State<StudentAttendancePage> createState() =>
      _StudentAttendancePageState();
}

class _StudentAttendancePageState
    extends State<StudentAttendancePage>
    with WidgetsBindingObserver {
  static const Color _background = Color(0xFF070B14);
  static const Color _surface = Color(0xFF0E1625);
  static const Color _surfaceSoft = Color(0xFF131D2E);
  static const Color _border = Color(0xFF263449);
  static const Color _text = Color(0xFFF8FAFC);
  static const Color _muted = Color(0xFF94A3B8);
  static const Color _primary = Color(0xFF7C5CFC);
  static const Color _secondary = Color(0xFF4F8CFF);
  static const Color _success = Color(0xFF34D399);
  static const Color _danger = Color(0xFFFB7185);

  final PresenceService _service =
      PresenceService.instance;

  Timer? _timer;
  String? _resolvedStudentId;
  bool _argumentsResolved = false;
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  _AttendanceData? _data;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) {
        if (mounted && !_refreshing) {
          _load(
            showLoader: false,
            silent: true,
          );
        }
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_argumentsResolved) return;
    _argumentsResolved = true;

    final Object? arguments =
        ModalRoute.of(context)?.settings.arguments;

    String? argumentStudentId;

    if (arguments is String) {
      argumentStudentId = arguments;
    } else if (arguments is Map) {
      argumentStudentId = (
        arguments['studentId'] ??
        arguments['userId'] ??
        arguments['id']
      )?.toString();
    }

    final String constructorId =
        widget.studentId?.trim() ?? '';

    _resolvedStudentId = constructorId.isNotEmpty
        ? constructorId
        : argumentStudentId?.trim();

    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed) {
      _load(
        showLoader: false,
        silent: true,
      );
    }
  }

  Future<void> _load({
    bool showLoader = true,
    bool silent = false,
  }) async {
    if (_refreshing) return;

    final String studentId =
        _resolvedStudentId?.trim() ?? '';

    if (studentId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Student ID is missing';
      });
      return;
    }

    setState(() {
      _refreshing = true;
      if (showLoader) _loading = true;
      if (!silent) _error = null;
    });

    try {
      final List<PresenceModel> presences =
          await _service.getStudentPresences(
        studentId,
      );

      final _AttendanceData computed =
          _computeAttendance(presences);

      if (!mounted) return;

      setState(() {
        _data = computed;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;

      if (!silent) {
        setState(() {
          _error = _readableError(error);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _refreshing = false;
        });
      }
    }
  }

  _AttendanceData _computeAttendance(
    List<PresenceModel> presences,
  ) {
    final Map<String, _CourseAccumulator>
        courseMap =
        <String, _CourseAccumulator>{};

    final List<_RecentAttendance> recent =
        <_RecentAttendance>[];

    for (final PresenceModel presence
        in presences) {
      final PresenceCourseModel course =
          presence.seance.course;

      final String courseId =
          course.id.isNotEmpty
              ? course.id
              : '${course.name}-${course.code}';

      final _CourseAccumulator accumulator =
          courseMap.putIfAbsent(
        courseId,
        () => _CourseAccumulator(
          id: courseId,
          name: course.name,
          code: course.code,
        ),
      );

      accumulator.total++;

      if (presence.isPresent) {
        accumulator.present++;
      } else {
        accumulator.absent++;
      }

      recent.add(
        _RecentAttendance(
          date: presence.date,
          course: course.name,
          code: course.code,
          present: presence.isPresent,
        ),
      );
    }

    final List<_CourseAttendance> courses =
        courseMap.values
            .map(
              (_CourseAccumulator value) =>
                  _CourseAttendance(
                id: value.id,
                name: value.name,
                code: value.code,
                present: value.present,
                absent: value.absent,
                total: value.total,
                percentage: value.total == 0
                    ? 0
                    : ((value.present /
                                value.total) *
                            100)
                        .round(),
              ),
            )
            .toList()
          ..sort(
            (_CourseAttendance a,
                    _CourseAttendance b) =>
                a.name.compareTo(b.name),
          );

    recent.sort(
      (_RecentAttendance a,
              _RecentAttendance b) =>
          b.date.compareTo(a.date),
    );

    final List<_RecentAttendance>
        recentAttendance =
        recent.take(5).toList();

    final int totalPresent = courses.fold(
      0,
      (int total, _CourseAttendance course) =>
          total + course.present,
    );

    final int totalAbsent = courses.fold(
      0,
      (int total, _CourseAttendance course) =>
          total + course.absent,
    );

    final int totalClasses =
        totalPresent + totalAbsent;

    final int overallPercentage =
        totalClasses == 0
            ? 0
            : ((totalPresent / totalClasses) *
                    100)
                .round();

    return _AttendanceData(
      courses: courses,
      recentAttendance: recentAttendance,
      overallPercentage: overallPercentage,
      totalPresent: totalPresent,
      totalAbsent: totalAbsent,
      totalClasses: totalClasses,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.15,
                  colors: <Color>[
                    Color(0x332F5AFF),
                    Color(0x00070B14),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              color: _primary,
              backgroundColor: _surfaceSoft,
              onRefresh: () =>
                  _load(showLoader: false),
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  18,
                  20,
                  18,
                  34,
                ),
                children: <Widget>[
                  _buildHeader(),
                  const SizedBox(height: 22),
                  if (_loading)
                    const _LoadingView()
                  else if (_error != null)
                    _ErrorState(
                      message: _error!,
                      onRetry: _load,
                    )
                  else if (_data == null ||
                      _data!.totalClasses == 0)
                    const _EmptyState()
                  else ...<Widget>[
                    _OverallCard(data: _data!),
                    const SizedBox(height: 22),
                    ..._data!.courses.map(
                      (_CourseAttendance course) =>
                          Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 14,
                        ),
                        child: _CourseCard(
                          course: course,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _RecentCard(
                      records:
                          _data!.recentAttendance,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: <Widget>[
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (Rect bounds) =>
              const LinearGradient(
            colors: <Color>[
              Color(0xFFA78BFA),
              Color(0xFF60A5FA),
              Color(0xFF34D399),
            ],
          ).createShader(bounds),
          child: const Text(
            'My Attendance',
            style: TextStyle(
              fontSize: 32,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Track your class attendance and presence record',
          style: TextStyle(
            color: _muted,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _OverallCard extends StatelessWidget {
  final _AttendanceData data;

  const _OverallCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0x332F5AFF),
            Color(0x222CA6FF),
            Color(0x1734D399),
          ],
        ),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color:
              _StudentAttendancePageState._border,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x25000000),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[
                      _StudentAttendancePageState
                          ._primary,
                      _StudentAttendancePageState
                          ._secondary,
                      _StudentAttendancePageState
                          ._success,
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Overall Attendance',
                      style: TextStyle(
                        color:
                            _StudentAttendancePageState
                                ._text,
                        fontSize: 20,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Academic Year ${_academicYear()}',
                      style: const TextStyle(
                        color:
                            _StudentAttendancePageState
                                ._muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _attendanceMessage(
              data.overallPercentage,
            ),
            style: const TextStyle(
              color:
                  _StudentAttendancePageState
                      ._muted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: _MetricBox(
                  value:
                      '${data.overallPercentage}%',
                  label: 'Total',
                  color:
                      _StudentAttendancePageState
                          ._primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricBox(
                  value:
                      data.totalPresent.toString(),
                  label: 'Present',
                  color:
                      _StudentAttendancePageState
                          ._success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricBox(
                  value:
                      data.totalAbsent.toString(),
                  label: 'Absent',
                  color:
                      _StudentAttendancePageState
                          ._danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final _CourseAttendance course;

  const _CourseCard({
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    final List<Color> gradient =
        _courseGradient(course.id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            _StudentAttendancePageState
                ._surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              _StudentAttendancePageState
                  ._border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      course.name,
                      style: const TextStyle(
                        color:
                            _StudentAttendancePageState
                                ._text,
                        fontSize: 18,
                        height: 1.2,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _CodeBadge(
                      code: course.code,
                    ),
                  ],
                ),
              ),
              Container(
                width: 53,
                height: 53,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                  ),
                  borderRadius:
                      BorderRadius.circular(14),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: gradient.first
                          .withOpacity(0.25),
                      blurRadius: 14,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '${course.percentage}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          _AttendanceProgress(
            value: course.percentage,
            gradient: gradient,
          ),
          const SizedBox(height: 17),
          Row(
            children: <Widget>[
              Expanded(
                child: _SmallMetric(
                  value: course.present,
                  label: 'Present',
                  color:
                      _StudentAttendancePageState
                          ._success,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _SmallMetric(
                  value: course.absent,
                  label: 'Absent',
                  color:
                      _StudentAttendancePageState
                          ._danger,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _SmallMetric(
                  value: course.total,
                  label: 'Total',
                  color:
                      _StudentAttendancePageState
                          ._text,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttendanceProgress extends StatelessWidget {
  final int value;
  final List<Color> gradient;

  const _AttendanceProgress({
    required this.value,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        final double width =
            constraints.maxWidth *
                (value.clamp(0, 100) / 100);

        return Container(
          height: 15,
          decoration: BoxDecoration(
            color:
                _StudentAttendancePageState
                    ._surfaceSoft,
            borderRadius:
                BorderRadius.circular(50),
          ),
          child: Stack(
            children: <Widget>[
              AnimatedContainer(
                duration:
                    const Duration(milliseconds: 700),
                width: width,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                  ),
                  borderRadius:
                      BorderRadius.circular(50),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color:
                          _progressGlow(value),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                right: 7,
                child: Align(
                  alignment:
                      Alignment.centerRight,
                  child: Text(
                    '$value%',
                    style: const TextStyle(
                      color:
                          _StudentAttendancePageState
                              ._text,
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecentCard extends StatelessWidget {
  final List<_RecentAttendance> records;

  const _RecentCard({
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            _StudentAttendancePageState
                ._surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              _StudentAttendancePageState
                  ._border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[
                      _StudentAttendancePageState
                          ._primary,
                      _StudentAttendancePageState
                          ._secondary,
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 11),
              const Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Recent Attendance',
                    style: TextStyle(
                      color:
                          _StudentAttendancePageState
                              ._text,
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Last 5 classes',
                    style: TextStyle(
                      color:
                          _StudentAttendancePageState
                              ._muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (records.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 22,
              ),
              child: Center(
                child: Text(
                  'No recent attendance records',
                  style: TextStyle(
                    color:
                        _StudentAttendancePageState
                            ._muted,
                  ),
                ),
              ),
            )
          else
            ...records.map(
              (_RecentAttendance record) =>
                  _RecentRow(record: record),
            ),
        ],
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  final _RecentAttendance record;

  const _RecentRow({
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = record.present
        ? _StudentAttendancePageState._success
        : _StudentAttendancePageState._danger;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color:
                _StudentAttendancePageState
                    ._border,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              record.present
                  ? Icons
                      .check_circle_outline_rounded
                  : Icons.cancel_outlined,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  record.course,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color:
                        _StudentAttendancePageState
                            ._text,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  record.code,
                  style: const TextStyle(
                    color:
                        _StudentAttendancePageState
                            ._muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: <Widget>[
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius:
                      BorderRadius.circular(50),
                ),
                child: Text(
                  record.present
                      ? 'Present'
                      : 'Absent',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _shortDate(record.date),
                style: const TextStyle(
                  color:
                      _StudentAttendancePageState
                          ._muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _MetricBox({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.25),
        ),
      ),
      child: Column(
        children: <Widget>[
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color:
                  _StudentAttendancePageState
                      ._muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallMetric extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _SmallMetric({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color:
            _StudentAttendancePageState
                ._surfaceSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color:
                  _StudentAttendancePageState
                      ._muted,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeBadge extends StatelessWidget {
  final String code;

  const _CodeBadge({
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color:
            _StudentAttendancePageState
                ._surfaceSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              _StudentAttendancePageState
                  ._border,
        ),
      ),
      child: Text(
        code,
        style: const TextStyle(
          color:
              _StudentAttendancePageState
                  ._muted,
          fontSize: 11,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        vertical: 80,
      ),
      child: Column(
        children: <Widget>[
          CircularProgressIndicator(
            color:
                _StudentAttendancePageState
                    ._primary,
          ),
          SizedBox(height: 16),
          Text(
            'Loading attendance...',
            style: TextStyle(
              color:
                  _StudentAttendancePageState
                      ._muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function({
    bool showLoader,
    bool silent,
  }) onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color:
            _StudentAttendancePageState
                ._surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF7F3340),
        ),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            color:
                _StudentAttendancePageState
                    ._danger,
            size: 50,
          ),
          const SizedBox(height: 13),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color:
                  _StudentAttendancePageState
                      ._danger,
            ),
          ),
          const SizedBox(height: 17),
          FilledButton(
            onPressed: () => onRetry(
              showLoader: true,
              silent: false,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 60,
      ),
      decoration: BoxDecoration(
        color:
            _StudentAttendancePageState
                ._surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              _StudentAttendancePageState
                  ._border,
        ),
      ),
      child: const Column(
        children: <Widget>[
          Icon(
            Icons.event_available_outlined,
            color: Color(0xFF526179),
            size: 72,
          ),
          SizedBox(height: 17),
          Text(
            'No attendance data available',
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  _StudentAttendancePageState
                      ._text,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Attendance records will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  _StudentAttendancePageState
                      ._muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceData {
  final List<_CourseAttendance> courses;
  final List<_RecentAttendance>
      recentAttendance;
  final int overallPercentage;
  final int totalPresent;
  final int totalAbsent;
  final int totalClasses;

  const _AttendanceData({
    required this.courses,
    required this.recentAttendance,
    required this.overallPercentage,
    required this.totalPresent,
    required this.totalAbsent,
    required this.totalClasses,
  });
}

class _CourseAccumulator {
  final String id;
  final String name;
  final String code;
  int present = 0;
  int absent = 0;
  int total = 0;

  _CourseAccumulator({
    required this.id,
    required this.name,
    required this.code,
  });
}

class _CourseAttendance {
  final String id;
  final String name;
  final String code;
  final int present;
  final int absent;
  final int total;
  final int percentage;

  const _CourseAttendance({
    required this.id,
    required this.name,
    required this.code,
    required this.present,
    required this.absent,
    required this.total,
    required this.percentage,
  });
}

class _RecentAttendance {
  final DateTime date;
  final String course;
  final String code;
  final bool present;

  const _RecentAttendance({
    required this.date,
    required this.course,
    required this.code,
    required this.present,
  });
}

List<Color> _courseGradient(String courseId) {
  const List<List<Color>> gradients =
      <List<Color>>[
    <Color>[
      Color(0xFF7C5CFC),
      Color(0xFF4F8CFF),
    ],
    <Color>[
      Color(0xFF4F8CFF),
      Color(0xFF34D399),
    ],
    <Color>[
      Color(0xFF34D399),
      Color(0xFF14B8A6),
    ],
    <Color>[
      Color(0xFFA78BFA),
      Color(0xFF7C3AED),
    ],
    <Color>[
      Color(0xFFF59E0B),
      Color(0xFFF97316),
    ],
  ];

  if (courseId.isEmpty) return gradients.first;

  final int index =
      courseId.codeUnitAt(0) % gradients.length;

  return gradients[index];
}

Color _progressGlow(int percentage) {
  if (percentage > 75) {
    return const Color(0x6634D399);
  }

  if (percentage > 50) {
    return const Color(0x66FBBF24);
  }

  return const Color(0x66FB7185);
}

String _academicYear() {
  final DateTime now = DateTime.now();

  if (now.month >= 9) {
    return '${now.year}-${now.year + 1}';
  }

  return '${now.year - 1}-${now.year}';
}

String _attendanceMessage(int percentage) {
  if (percentage >= 90) {
    return "You're maintaining excellent attendance! "
        'Keep up the great work.';
  }

  if (percentage >= 80) {
    return "You're doing well with your attendance. "
        'Keep it up!';
  }

  if (percentage >= 70) {
    return 'Your attendance is acceptable, but '
        "there's room for improvement.";
  }

  return 'Your attendance needs improvement. '
      'Please try to attend more classes.';
}

String _shortDate(DateTime value) {
  final DateTime local = value.toLocal();

  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[local.month - 1]} '
      '${local.day}';
}

String _readableError(Object error) {
  final String message = error
      .toString()
      .replaceFirst('Exception: ', '')
      .trim();

  return message.isEmpty
      ? 'Failed to load attendance data.'
      : message;
}
