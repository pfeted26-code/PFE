import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/announcement_model.dart';
import '../../services/announcement_service.dart';

class StudentAnnouncementsPage extends StatefulWidget {
  final String? currentUserId;

  const StudentAnnouncementsPage({
    super.key,
    this.currentUserId,
  });

  @override
  State<StudentAnnouncementsPage> createState() =>
      _StudentAnnouncementsPageState();
}

class _StudentAnnouncementsPageState
    extends State<StudentAnnouncementsPage>
    with WidgetsBindingObserver {
  static const Color _background = Color(0xFF070B14);
  static const Color _surface = Color(0xFF0E1625);
  static const Color _surfaceSoft = Color(0xFF131D2E);
  static const Color _border = Color(0xFF263449);
  static const Color _text = Color(0xFFF8FAFC);
  static const Color _muted = Color(0xFF94A3B8);
  static const Color _primary = Color(0xFF7C5CFC);
  static const Color _secondary = Color(0xFF4F8CFF);

  final AnnouncementService _service =
      AnnouncementService.instance;

  final List<AnnouncementModel> _announcements =
      <AnnouncementModel>[];

  final Set<String> _locallyViewedIds = <String>{};

  Timer? _timer;
  bool _loading = true;
  bool _refreshing = false;
  String _filter = 'all';
  String? _resolvedUserId;
  bool _argumentsResolved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) {
        if (mounted && !_refreshing) {
          _load(showLoader: false, silent: true);
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

    String? argumentUserId;

    if (arguments is String) {
      argumentUserId = arguments;
    } else if (arguments is Map) {
      argumentUserId = (
        arguments['currentUserId'] ??
        arguments['userId'] ??
        arguments['studentId'] ??
        arguments['id']
      )?.toString();
    }

    final String constructorId =
        widget.currentUserId?.trim() ?? '';

    _resolvedUserId = constructorId.isNotEmpty
        ? constructorId
        : argumentUserId?.trim();

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
      _load(showLoader: false, silent: true);
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
    });

    try {
      final List<AnnouncementModel> result =
          await _service.getMyAnnouncements();

      result.removeWhere(
        (AnnouncementModel item) => item.isExpired,
      );

      result.sort(
        (AnnouncementModel a, AnnouncementModel b) {
          if (a.pinned != b.pinned) {
            return a.pinned ? -1 : 1;
          }

          return b.createdAt.compareTo(a.createdAt);
        },
      );

      if (!mounted) return;

      setState(() {
        _announcements
          ..clear()
          ..addAll(result);
      });
    } catch (error) {
      if (!silent && mounted) {
        _showMessage(
          _readableError(error),
          success: false,
        );
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

  bool _isUnread(AnnouncementModel announcement) {
    if (_locallyViewedIds.contains(announcement.id)) {
      return false;
    }

    return !announcement.isViewedBy(_resolvedUserId);
  }

  List<AnnouncementModel> get _visibleAnnouncements {
    if (_filter == 'unread') {
      return _announcements
          .where(_isUnread)
          .toList();
    }

    return List<AnnouncementModel>.from(
      _announcements,
    );
  }

  int get _unreadCount {
    return _announcements.where(_isUnread).length;
  }

  Future<void> _openAnnouncement(
    AnnouncementModel announcement,
  ) async {
    final bool unread = _isUnread(announcement);

    _showDetails(announcement);

    if (!unread) return;

    setState(() {
      _locallyViewedIds.add(announcement.id);

      final int index = _announcements.indexWhere(
        (AnnouncementModel item) =>
            item.id == announcement.id,
      );

      if (index >= 0) {
        _announcements[index] =
            announcement.copyWith(
          viewedForCurrentUser: true,
          viewCount: announcement.viewCount + 1,
        );
      }
    });

    try {
      await _service.markAsViewed(announcement.id);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _locallyViewedIds.remove(announcement.id);

        final int index = _announcements.indexWhere(
          (AnnouncementModel item) =>
              item.id == announcement.id,
        );

        if (index >= 0) {
          _announcements[index] =
              announcement;
        }
      });

      _showMessage(
        'Announcement opened, but it could not be marked as viewed.',
        success: false,
      );
    }
  }

  void _showDetails(
    AnnouncementModel announcement,
  ) {
    final _TypeStyle typeStyle =
        _typeStyle(announcement.type);

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.sizeOf(sheetContext).height *
                    0.88,
          ),
          decoration: const BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            border: Border(
              top: BorderSide(color: _border),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              28,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF42506A),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: typeStyle.gradient,
                        ),
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                      child: Icon(
                        typeStyle.icon,
                        color: Colors.white,
                        size: 29,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            announcement.title,
                            style: const TextStyle(
                              color: _text,
                              fontSize: 22,
                              height: 1.15,
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              _PriorityBadge(
                                priority:
                                    announcement.priority,
                              ),
                              _OutlineBadge(
                                label: announcement.type,
                              ),
                              if (announcement.pinned)
                                const _OutlineBadge(
                                  label: 'PINNED',
                                  icon:
                                      Icons.push_pin_rounded,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Message',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  announcement.content,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 16,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(color: _border),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: _DetailItem(
                        label: 'Posted',
                        value: _formatDateTime(
                          announcement.createdAt,
                        ),
                      ),
                    ),
                    if (announcement.expiresAt != null)
                      Expanded(
                        child: _DetailItem(
                          label: 'Expires',
                          value: _formatDateTime(
                            announcement.expiresAt!,
                          ),
                          valueColor:
                              const Color(0xFFFBBF24),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.visibility_outlined,
                      color: _muted,
                      size: 17,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Viewed by ${announcement.viewCount} '
                      '${announcement.viewCount == 1 ? 'student' : 'students'}',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMessage(
    String message, {
    bool success = true,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: success
              ? const Color(0xFF107C52)
              : const Color(0xFFA92E3B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          content: Row(
            children: <Widget>[
              Icon(
                success
                    ? Icons.check_circle_outline
                    : Icons.error_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final List<AnnouncementModel> items =
        _visibleAnnouncements;

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
                  18,
                  18,
                  34,
                ),
                children: <Widget>[
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildFilters(),
                  const SizedBox(height: 22),
                  if (_loading)
                    const _LoadingView()
                  else if (items.isEmpty)
                    _EmptyState(filter: _filter)
                  else
                    ...items.map(
                      (AnnouncementModel announcement) {
                        return Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 14,
                          ),
                          child: _AnnouncementCard(
                            announcement:
                                announcement,
                            unread:
                                _isUnread(announcement),
                            onTap: () =>
                                _openAnnouncement(
                              announcement,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0x332F5AFF),
            Color(0x222CA6FF),
            Color(0x117C5CFC),
          ],
        ),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: _border),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x25000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
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
                  gradient: const LinearGradient(
                    colors: <Color>[
                      _primary,
                      _secondary,
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(16),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x667C5CFC),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: Colors.white,
                  size: 29,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Announcements',
                    style: TextStyle(
                      color: _text,
                      fontSize: 27,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              if (_unreadCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: <Color>[
                        _primary,
                        _secondary,
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$_unreadCount new',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            'Stay updated with important information and events',
            style: TextStyle(
              color: _muted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: <Widget>[
        Expanded(
          child: _FilterButton(
            label: 'All',
            count: _announcements.length,
            selected: _filter == 'all',
            onTap: () =>
                setState(() => _filter = 'all'),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: _FilterButton(
            label: 'Unread',
            count: _unreadCount,
            icon: Icons.visibility_outlined,
            selected: _filter == 'unread',
            onTap: () =>
                setState(() => _filter = 'unread'),
          ),
        ),
      ],
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;
  final bool unread;
  final VoidCallback onTap;

  const _AnnouncementCard({
    required this.announcement,
    required this.unread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final _TypeStyle typeStyle =
        _typeStyle(announcement.type);

    return Material(
      color: _StudentAnnouncementsPageState._surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: unread
                  ? const Color(0xFF7058D8)
                  : _StudentAnnouncementsPageState
                      ._border,
              width: unread ? 1.6 : 1,
            ),
            boxShadow: unread
                ? const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x337C5CFC),
                      blurRadius: 18,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: <Widget>[
              Container(
                height: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: typeStyle.gradient,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors:
                              typeStyle.gradient,
                        ),
                        borderRadius:
                            BorderRadius.circular(14),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: typeStyle
                                .gradient.first
                                .withOpacity(0.25),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Icon(
                        typeStyle.icon,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: <Widget>[
                          Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            crossAxisAlignment:
                                WrapCrossAlignment
                                    .center,
                            children: <Widget>[
                              Text(
                                announcement.title,
                                style: const TextStyle(
                                  color:
                                      _StudentAnnouncementsPageState
                                          ._text,
                                  fontSize: 17,
                                  height: 1.2,
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
                              if (unread)
                                const _NewBadge(),
                              _PriorityBadge(
                                priority:
                                    announcement.priority,
                              ),
                              if (announcement.pinned)
                                const Icon(
                                  Icons.push_pin_rounded,
                                  color:
                                      Color(0xFFC4B5FD),
                                  size: 17,
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            announcement.content,
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              color:
                                  _StudentAnnouncementsPageState
                                      ._muted,
                              fontSize: 14,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 13),
                          Wrap(
                            spacing: 14,
                            runSpacing: 8,
                            children: <Widget>[
                              _MetaItem(
                                icon:
                                    Icons.schedule_rounded,
                                text: _relativeDate(
                                  announcement.createdAt,
                                ),
                              ),
                              _MetaItem(
                                icon: Icons
                                    .visibility_outlined,
                                text:
                                    '${announcement.viewCount} views',
                              ),
                              if (announcement
                                      .expiresAt !=
                                  null)
                                _MetaItem(
                                  icon: Icons
                                      .calendar_today_outlined,
                                  text:
                                      'Expires ${_shortDate(announcement.expiresAt!)}',
                                  color: const Color(
                                    0xFFFBBF24,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final int count;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? Colors.transparent
          : _StudentAnnouncementsPageState
              ._surface,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Ink(
          height: 50,
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: <Color>[
                      _StudentAnnouncementsPageState
                          ._primary,
                      _StudentAnnouncementsPageState
                          ._secondary,
                    ],
                  )
                : null,
            borderRadius:
                BorderRadius.circular(13),
            border: selected
                ? null
                : Border.all(
                    color:
                        _StudentAnnouncementsPageState
                            ._border,
                  ),
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(
                  icon,
                  color: selected
                      ? Colors.white
                      : _StudentAnnouncementsPageState
                          ._muted,
                  size: 18,
                ),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : _StudentAnnouncementsPageState
                          ._text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '($count)',
                style: TextStyle(
                  color: selected
                      ? Colors.white70
                      : _StudentAnnouncementsPageState
                          ._muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;

  const _PriorityBadge({
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    final _PriorityStyle style =
        _priorityStyle(priority);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: style.border),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          color: style.foreground,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[
            _StudentAnnouncementsPageState
                ._primary,
            _StudentAnnouncementsPageState
                ._secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(50),
      ),
      child: const Text(
        'NEW',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _OutlineBadge extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _OutlineBadge({
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: _StudentAnnouncementsPageState
            ._surfaceSoft,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color:
              _StudentAnnouncementsPageState
                  ._border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(
              icon,
              color:
                  _StudentAnnouncementsPageState
                      ._muted,
              size: 13,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color:
                  _StudentAnnouncementsPageState
                      ._muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _MetaItem({
    required this.icon,
    required this.text,
    this.color =
        _StudentAnnouncementsPageState._muted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _DetailItem({
    required this.label,
    required this.value,
    this.valueColor =
        _StudentAnnouncementsPageState._text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color:
                _StudentAnnouncementsPageState
                    ._muted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String filter;

  const _EmptyState({
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    final bool unread = filter == 'unread';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 58,
      ),
      decoration: BoxDecoration(
        color:
            _StudentAnnouncementsPageState
                ._surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              _StudentAnnouncementsPageState
                  ._border,
        ),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.campaign_outlined,
            color: Color(0xFF526179),
            size: 72,
          ),
          const SizedBox(height: 18),
          Text(
            unread
                ? "You're all caught up!"
                : 'No announcements yet',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color:
                  _StudentAnnouncementsPageState
                      ._text,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            unread
                ? 'All announcements have been read'
                : 'Check back later for updates!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color:
                  _StudentAnnouncementsPageState
                      ._muted,
              fontSize: 14,
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
      padding: EdgeInsets.symmetric(vertical: 70),
      child: Column(
        children: <Widget>[
          CircularProgressIndicator(
            color:
                _StudentAnnouncementsPageState
                    ._primary,
          ),
          SizedBox(height: 16),
          Text(
            'Loading announcements...',
            style: TextStyle(
              color:
                  _StudentAnnouncementsPageState
                      ._muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeStyle {
  final IconData icon;
  final List<Color> gradient;

  const _TypeStyle({
    required this.icon,
    required this.gradient,
  });
}

class _PriorityStyle {
  final Color background;
  final Color foreground;
  final Color border;

  const _PriorityStyle({
    required this.background,
    required this.foreground,
    required this.border,
  });
}

_TypeStyle _typeStyle(String rawType) {
  switch (rawType.trim().toLowerCase()) {
    case 'warning':
      return const _TypeStyle(
        icon: Icons.warning_amber_rounded,
        gradient: <Color>[
          Color(0xFFFBBF24),
          Color(0xFFF97316),
        ],
      );
    case 'urgent':
      return const _TypeStyle(
        icon: Icons.error_outline_rounded,
        gradient: <Color>[
          Color(0xFFFB7185),
          Color(0xFFDC2626),
        ],
      );
    case 'success':
      return const _TypeStyle(
        icon: Icons.check_circle_outline_rounded,
        gradient: <Color>[
          Color(0xFF34D399),
          Color(0xFF059669),
        ],
      );
    case 'event':
      return const _TypeStyle(
        icon: Icons.calendar_month_outlined,
        gradient: <Color>[
          Color(0xFFA78BFA),
          Color(0xFF7C3AED),
        ],
      );
    case 'maintenance':
      return const _TypeStyle(
        icon: Icons.settings_outlined,
        gradient: <Color>[
          Color(0xFF94A3B8),
          Color(0xFF475569),
        ],
      );
    case 'info':
    default:
      return const _TypeStyle(
        icon: Icons.info_outline_rounded,
        gradient: <Color>[
          Color(0xFF60A5FA),
          Color(0xFF2563EB),
        ],
      );
  }
}

_PriorityStyle _priorityStyle(String rawPriority) {
  switch (rawPriority.trim().toLowerCase()) {
    case 'low':
      return const _PriorityStyle(
        background: Color(0x221F2937),
        foreground: Color(0xFFCBD5E1),
        border: Color(0xFF3B4658),
      );
    case 'high':
      return const _PriorityStyle(
        background: Color(0x333D2507),
        foreground: Color(0xFFFBBF24),
        border: Color(0xFF76501B),
      );
    case 'urgent':
      return const _PriorityStyle(
        background: Color(0x332E1017),
        foreground: Color(0xFFFCA5A5),
        border: Color(0xFF7F3340),
      );
    case 'normal':
    default:
      return const _PriorityStyle(
        background: Color(0x33213F73),
        foreground: Color(0xFF93C5FD),
        border: Color(0xFF365F9A),
      );
  }
}

String _relativeDate(DateTime value) {
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

  if (difference.inDays < 7) {
    return '${difference.inDays}d ago';
  }

  return _shortDate(value);
}

String _shortDate(DateTime value) {
  final DateTime local = value.toLocal();
  return '${_twoDigits(local.day)}/'
      '${_twoDigits(local.month)}/'
      '${local.year}';
}

String _formatDateTime(DateTime value) {
  final DateTime local = value.toLocal();

  return '${_shortDate(local)} at '
      '${_twoDigits(local.hour)}:'
      '${_twoDigits(local.minute)}';
}

String _twoDigits(int value) {
  return value.toString().padLeft(2, '0');
}

String _readableError(Object error) {
  final String message = error
      .toString()
      .replaceFirst('Exception: ', '')
      .trim();

  return message.isEmpty
      ? 'Failed to load announcements.'
      : message;
}
