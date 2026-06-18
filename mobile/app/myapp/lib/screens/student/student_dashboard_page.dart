import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/student_dashboard_model.dart';
import '../../services/dashboard_service.dart';

class StudentDashboardPage extends StatefulWidget {
  final String? studentName;

  const StudentDashboardPage({
    super.key,
    this.studentName,
  });

  @override
  State<StudentDashboardPage> createState() =>
      _StudentDashboardPageState();
}

class _StudentDashboardPageState
    extends State<StudentDashboardPage>
    with WidgetsBindingObserver {
  static const Color _background =
      Color(0xFF070B14);
  static const Color _surface =
      Color(0xFF0E1625);
  static const Color _surfaceSoft =
      Color(0xFF131D2E);
  static const Color _border =
      Color(0xFF263449);
  static const Color _text =
      Color(0xFFF8FAFC);
  static const Color _muted =
      Color(0xFF94A3B8);
  static const Color _primary =
      Color(0xFF7C5CFC);
  static const Color _secondary =
      Color(0xFF4F8CFF);
  static const Color _accent =
      Color(0xFF34D399);

  final DashboardService _service =
      DashboardService.instance;

  Timer? _timer;
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  StudentDashboardModel? _dashboard;
  String? _resolvedStudentName;
  bool _argumentsResolved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _timer = Timer.periodic(
      const Duration(seconds: 30),
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

    String? argumentName;

    if (arguments is String) {
      argumentName = arguments;
    } else if (arguments is Map) {
      argumentName = (
        arguments['studentName'] ??
        arguments['userName'] ??
        arguments['name']
      )?.toString();
    }

    final String constructorName =
        widget.studentName?.trim() ?? '';

    _resolvedStudentName =
        constructorName.isNotEmpty
            ? constructorName
            : argumentName?.trim();

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

    setState(() {
      _refreshing = true;
      if (showLoader) _loading = true;
      if (!silent) _error = null;
    });

    try {
      final StudentDashboardModel result =
          await _service.getStudentDashboard();

      if (!mounted) return;

      setState(() {
        _dashboard = result;
        _error = null;
      });
    } catch (error) {
      if (!mounted || silent) return;

      setState(() {
        _error = _readableError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _refreshing = false;
        });
      }
    }
  }

  String get _displayName {
    final String explicit =
        _resolvedStudentName?.trim() ?? '';

    if (explicit.isNotEmpty) return explicit;

    final String fromApi =
        _dashboard?.studentName?.trim() ?? '';

    return fromApi.isEmpty ? 'Student' : fromApi;
  }

  List<_FeatureData> get _features {
    final StudentDashboardModel? dashboard =
        _dashboard;

    final String courses = dashboard
            ?.findStat(<String>[
              'course',
              'cours',
              'enrolled',
            ])
            ?.value ??
        dashboard?.statValueAt(0) ??
        '0';

    final String attendance = dashboard
            ?.findStat(<String>[
              'attendance',
              'presence',
            ])
            ?.value ??
        dashboard?.statValueAt(1) ??
        '0';

    final String grade = dashboard
            ?.findStat(<String>[
              'grade',
              'gpa',
              'note',
              'average',
            ])
            ?.value ??
        dashboard?.statValueAt(3) ??
        '0';

    final int todayCount =
        dashboard?.todaysSessions.length ?? 0;

    return <_FeatureData>[
      _FeatureData(
        title: 'My Courses',
        description:
            'Access your course materials',
        icon: Icons.menu_book_rounded,
        route: '/courses',
        count: '$courses Active',
        stats: '85% Avg Progress',
        gradient: const <Color>[
          Color(0xFF7C5CFC),
          Color(0xFF4F8CFF),
          Color(0xFF34D399),
        ],
      ),
      _FeatureData(
        title: 'Timetable',
        description: 'Check your schedule',
        icon: Icons.calendar_month_rounded,
        route: '/timetable',
        count: todayCount > 0
            ? '$todayCount Today'
            : 'This Week',
        stats: 'View schedule',
        gradient: const <Color>[
          Color(0xFF4F8CFF),
          Color(0xFF34D399),
          Color(0xFF7C5CFC),
        ],
      ),
      _FeatureData(
        title: 'Exams & Notes',
        description: 'View grades and exams',
        icon: Icons.description_rounded,
        route: '/exams',
        count: '3 Upcoming',
        stats: '$grade GPA',
        gradient: const <Color>[
          Color(0xFF34D399),
          Color(0xFF4F8CFF),
          Color(0xFF7C5CFC),
        ],
      ),
      _FeatureData(
        title: 'Attendance',
        description: 'Track your presence',
        icon: Icons.how_to_reg_rounded,
        route: '/attendance',
        count: '$attendance Rate',
        stats: 'View details',
        gradient: const <Color>[
          Color(0xFF7C5CFC),
          Color(0xFF34D399),
          Color(0xFF4F8CFF),
        ],
      ),
      const _FeatureData(
        title: 'Requests',
        description: 'Manage your requests',
        icon: Icons.send_rounded,
        route: '/requests',
        count: 'View Requests',
        stats: 'Track status',
        gradient: <Color>[
          Color(0xFF4F8CFF),
          Color(0xFF7C5CFC),
          Color(0xFF34D399),
        ],
      ),
      const _FeatureData(
        title: 'Messages',
        description: 'Read your messages',
        icon: Icons.chat_bubble_rounded,
        route: '/messages',
        count: 'Open Inbox',
        stats: 'Stay connected',
        gradient: <Color>[
          Color(0xFF34D399),
          Color(0xFF7C5CFC),
          Color(0xFF4F8CFF),
        ],
      ),
    ];
  }

  List<_StatData> get _stats {
    final List<DashboardStatModel> apiStats =
        _dashboard?.stats ??
            const <DashboardStatModel>[];

    if (apiStats.isEmpty) {
      return const <_StatData>[
        _StatData(
          label: 'Enrolled Courses',
          value: '0',
          change: '+0',
          icon: Icons.menu_book_rounded,
          gradient: <Color>[
            Color(0xFF34D399),
            Color(0xFF4F8CFF),
          ],
        ),
        _StatData(
          label: 'Upcoming Exams',
          value: '0',
          change: '+0',
          icon: Icons.description_rounded,
          gradient: <Color>[
            Color(0xFF7C5CFC),
            Color(0xFF34D399),
          ],
        ),
        _StatData(
          label: 'Attendance Rate',
          value: '0%',
          change: '+0%',
          icon: Icons.how_to_reg_rounded,
          gradient: <Color>[
            Color(0xFF4F8CFF),
            Color(0xFF7C5CFC),
          ],
        ),
        _StatData(
          label: 'Average Grade',
          value: '0',
          change: '+0',
          icon: Icons.workspace_premium_rounded,
          gradient: <Color>[
            Color(0xFF34D399),
            Color(0xFF7C5CFC),
          ],
        ),
      ];
    }

    final List<List<Color>> gradients =
        const <List<Color>>[
      <Color>[
        Color(0xFF34D399),
        Color(0xFF4F8CFF),
      ],
      <Color>[
        Color(0xFF7C5CFC),
        Color(0xFF34D399),
      ],
      <Color>[
        Color(0xFF4F8CFF),
        Color(0xFF7C5CFC),
      ],
      <Color>[
        Color(0xFF34D399),
        Color(0xFF7C5CFC),
      ],
    ];

    return List<_StatData>.generate(
      apiStats.length > 4 ? 4 : apiStats.length,
      (int index) {
        final DashboardStatModel stat =
            apiStats[index];

        return _StatData(
          label: stat.title,
          value: stat.value,
          change: stat.change,
          icon: _statIcon(stat.icon, stat.title),
          gradient:
              gradients[index % gradients.length],
        );
      },
    );
  }

  void _openRoute(String route) {
    Navigator.pushNamed(context, route);
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
                  if (_loading)
                    const _LoadingView()
                  else if (_error != null)
                    _ErrorState(
                      message: _error!,
                      onRetry: _load,
                    )
                  else ...<Widget>[
                    _buildWelcome(),
                    const SizedBox(height: 22),
                    _buildStats(),
                    const SizedBox(height: 22),
                    _buildFeatureGrid(),
                    const SizedBox(height: 22),
                    _RecentActivityCard(
                      activities:
                          _dashboard?.recentActivity ??
                              const <
                                  DashboardActivityModel>[],
                      onViewAll: () =>
                          _openRoute(
                        '/notifications',
                      ),
                    ),
                    const SizedBox(height: 22),
                    _PerformanceBanner(
                      onContinue: () =>
                          _openRoute('/courses'),
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

  Widget _buildWelcome() {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: <Color>[
                _primary,
                _secondary,
                _accent,
              ],
            ),
            borderRadius:
                BorderRadius.circular(16),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x557C5CFC),
                blurRadius: 18,
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 27,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
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
                child: Text(
                  'Welcome back, $_displayName!',
                  style: const TextStyle(
                    fontSize: 28,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                "Here's what's happening with your studies today.",
                style: TextStyle(
                  color: _muted,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    final List<_StatData> stats = _stats;

    return GridView.builder(
      itemCount: stats.length,
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.12,
      ),
      itemBuilder: (
        BuildContext context,
        int index,
      ) {
        return _DashboardStatCard(
          data: stats[index],
        );
      },
    );
  }

  Widget _buildFeatureGrid() {
    final List<_FeatureData> features =
        _features;

    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        final int columns =
            constraints.maxWidth >= 650 ? 2 : 1;

        return GridView.builder(
          itemCount: features.length,
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio:
                columns == 1 ? 1.55 : 1.2,
          ),
          itemBuilder: (
            BuildContext context,
            int index,
          ) {
            final _FeatureData feature =
                features[index];

            return _FeatureCard(
              feature: feature,
              onTap: () =>
                  _openRoute(feature.route),
            );
          },
        );
      },
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  final _StatData data;

  const _DashboardStatCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color:
            _StudentDashboardPageState._surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              _StudentDashboardPageState._border,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x23000000),
            blurRadius: 15,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -25,
            right: -25,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: data.gradient,
                ),
                shape: BoxShape.circle,
              ),
              foregroundDecoration:
                  const BoxDecoration(
                color: Color(0xCC0E1625),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: data.gradient,
                      ),
                      borderRadius:
                          BorderRadius.circular(13),
                    ),
                    child: Icon(
                      data.icon,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _StudentDashboardPageState
                              ._surfaceSoft,
                      borderRadius:
                          BorderRadius.circular(50),
                    ),
                    child: Text(
                      data.change,
                      style: const TextStyle(
                        color:
                            _StudentDashboardPageState
                                ._muted,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: <Widget>[
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment:
                        Alignment.centerLeft,
                    child: Text(
                      data.value,
                      style: const TextStyle(
                        color:
                            _StudentDashboardPageState
                                ._text,
                        fontSize: 27,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.label,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      color:
                          _StudentDashboardPageState
                              ._muted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final _FeatureData feature;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.feature,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          _StudentDashboardPageState._surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  _StudentDashboardPageState
                      ._border,
            ),
          ),
          child: Stack(
            children: <Widget>[
              Positioned(
                top: -45,
                right: -40,
                child: Container(
                  width: 135,
                  height: 135,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: feature.gradient,
                    ),
                    shape: BoxShape.circle,
                  ),
                  foregroundDecoration:
                      const BoxDecoration(
                    color: Color(0xDD0E1625),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors:
                                feature.gradient,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            16,
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: feature
                                  .gradient.first
                                  .withOpacity(0.25),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                        child: Icon(
                          feature.icon,
                          color: Colors.white,
                          size: 27,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _StudentDashboardPageState
                                  ._surfaceSoft,
                          borderRadius:
                              BorderRadius.circular(
                            50,
                          ),
                          border: Border.all(
                            color:
                                _StudentDashboardPageState
                                    ._border,
                          ),
                        ),
                        child: Text(
                          feature.count,
                          style: const TextStyle(
                            color:
                                _StudentDashboardPageState
                                    ._text,
                            fontSize: 10.5,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    feature.title,
                    style: const TextStyle(
                      color:
                          _StudentDashboardPageState
                              ._text,
                      fontSize: 19,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    feature.description,
                    style: const TextStyle(
                      color:
                          _StudentDashboardPageState
                              ._muted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          feature.stats,
                          style: const TextStyle(
                            color:
                                _StudentDashboardPageState
                                    ._muted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFFC4B5FD),
                        size: 22,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  final List<DashboardActivityModel>
      activities;
  final VoidCallback onViewAll;

  const _RecentActivityCard({
    required this.activities,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            _StudentDashboardPageState._surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              _StudentDashboardPageState._border,
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
                      _StudentDashboardPageState
                          ._primary,
                      _StudentDashboardPageState
                          ._secondary,
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.notifications_rounded,
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
                    'Recent Activity',
                    style: TextStyle(
                      color:
                          _StudentDashboardPageState
                              ._text,
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Last 24 hours',
                    style: TextStyle(
                      color:
                          _StudentDashboardPageState
                              ._muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (activities.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 25,
              ),
              child: Center(
                child: Column(
                  children: <Widget>[
                    Icon(
                      Icons
                          .notifications_none_rounded,
                      color: Color(0xFF526179),
                      size: 48,
                    ),
                    SizedBox(height: 9),
                    Text(
                      'No recent activity',
                      style: TextStyle(
                        color:
                            _StudentDashboardPageState
                                ._muted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...activities.take(6).map(
              (DashboardActivityModel activity) =>
                  _ActivityRow(
                activity: activity,
              ),
            ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    const Color(0xFFC4B5FD),
                side: const BorderSide(
                  color:
                      _StudentDashboardPageState
                          ._border,
                ),
                minimumSize:
                    const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              onPressed: onViewAll,
              icon: const Icon(
                Icons.chevron_right_rounded,
              ),
              label:
                  const Text('View All Activity'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final DashboardActivityModel activity;

  const _ActivityRow({
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color:
                _StudentDashboardPageState
                    ._border,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 41,
            height: 41,
            decoration: BoxDecoration(
              color: const Color(0x337C5CFC),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              _activityIcon(activity.icon),
              color:
                  const Color(0xFFC4B5FD),
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  activity.action,
                  style: const TextStyle(
                    color:
                        _StudentDashboardPageState
                            ._text,
                    fontSize: 13.5,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                if (activity.user.isNotEmpty) ...<
                    Widget>[
                  const SizedBox(height: 3),
                  Text(
                    activity.user,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      color:
                          _StudentDashboardPageState
                              ._muted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  activity.time.isNotEmpty
                      ? activity.time
                      : _relativeTime(
                          activity.createdAt,
                        ),
                  style: const TextStyle(
                    color:
                        _StudentDashboardPageState
                            ._muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceBanner extends StatelessWidget {
  final VoidCallback onContinue;

  const _PerformanceBanner({
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0x337C5CFC),
            Color(0x224F8CFF),
            Color(0x2234D399),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              _StudentDashboardPageState._border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 51,
                height: 51,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[
                      _StudentDashboardPageState
                          ._primary,
                      _StudentDashboardPageState
                          ._secondary,
                      _StudentDashboardPageState
                          ._accent,
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "You're doing great!",
                      style: TextStyle(
                        color:
                            _StudentDashboardPageState
                                ._text,
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Your performance is above average. '
                      'Keep up the excellent work!',
                      style: TextStyle(
                        color:
                            _StudentDashboardPageState
                                ._muted,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize:
                    const Size.fromHeight(46),
                backgroundColor:
                    _StudentDashboardPageState
                        ._primary,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              onPressed: onContinue,
              child:
                  const Text('Continue Learning'),
            ),
          ),
        ],
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
        vertical: 100,
      ),
      child: Column(
        children: <Widget>[
          CircularProgressIndicator(
            color:
                _StudentDashboardPageState
                    ._primary,
          ),
          SizedBox(height: 16),
          Text(
            'Loading dashboard...',
            style: TextStyle(
              color:
                  _StudentDashboardPageState
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
            _StudentDashboardPageState._surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF7F3340),
        ),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.notifications_off_outlined,
            color: Color(0xFFFB7185),
            size: 51,
          ),
          const SizedBox(height: 13),
          const Text(
            'Failed to load dashboard',
            style: TextStyle(
              color:
                  _StudentDashboardPageState
                      ._text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color:
                  _StudentDashboardPageState
                      ._muted,
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

class _StatData {
  final String label;
  final String value;
  final String change;
  final IconData icon;
  final List<Color> gradient;

  const _StatData({
    required this.label,
    required this.value,
    required this.change,
    required this.icon,
    required this.gradient,
  });
}

class _FeatureData {
  final String title;
  final String description;
  final IconData icon;
  final String route;
  final String count;
  final String stats;
  final List<Color> gradient;

  const _FeatureData({
    required this.title,
    required this.description,
    required this.icon,
    required this.route,
    required this.count,
    required this.stats,
    required this.gradient,
  });
}

IconData _statIcon(
  String rawIcon,
  String title,
) {
  final String value =
      '$rawIcon $title'.toLowerCase();

  if (value.contains('📚') ||
      value.contains('course') ||
      value.contains('cours')) {
    return Icons.menu_book_rounded;
  }

  if (value.contains('📝') ||
      value.contains('exam') ||
      value.contains('assignment')) {
    return Icons.description_rounded;
  }

  if (value.contains('📈') ||
      value.contains('attendance') ||
      value.contains('presence')) {
    return Icons.trending_up_rounded;
  }

  if (value.contains('🎓') ||
      value.contains('grade') ||
      value.contains('gpa') ||
      value.contains('note')) {
    return Icons.workspace_premium_rounded;
  }

  if (value.contains('👥') ||
      value.contains('message')) {
    return Icons.chat_bubble_rounded;
  }

  if (value.contains('👨‍🏫') ||
      value.contains('teacher')) {
    return Icons.how_to_reg_rounded;
  }

  return Icons.insights_rounded;
}

IconData _activityIcon(String rawIcon) {
  switch (rawIcon.trim()) {
    case '📩':
      return Icons.send_rounded;
    case '📝':
      return Icons.description_rounded;
    case '📊':
      return Icons.trending_up_rounded;
    case '👨‍🏫':
      return Icons.how_to_reg_rounded;
    case '📚':
      return Icons.menu_book_rounded;
    case '👥':
      return Icons.chat_bubble_rounded;
    case '🔔':
    default:
      return Icons.notifications_rounded;
  }
}

String _relativeTime(DateTime? value) {
  if (value == null) return '';

  final Duration difference =
      DateTime.now().difference(value.toLocal());

  if (difference.isNegative ||
      difference.inMinutes < 1) {
    return 'Just now';
  }

  if (difference.inHours < 1) {
    return '${difference.inMinutes}m ago';
  }

  if (difference.inHours < 24) {
    return '${difference.inHours}h ago';
  }

  return '${difference.inDays}d ago';
}

String _readableError(Object error) {
  final String message = error
      .toString()
      .replaceFirst('Exception: ', '')
      .trim();

  return message.isEmpty
      ? 'Failed to load dashboard data.'
      : message;
}
