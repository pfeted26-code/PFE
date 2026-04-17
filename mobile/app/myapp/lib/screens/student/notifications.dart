import 'dart:async';
import 'package:flutter/material.dart';
import 'package:EduNex/services/notification_service.dart';
import 'package:EduNex/models/notification_model.dart';
import 'package:EduNex/services/user_service.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFF0B0D14);
  static const bgCard = Color(0xFF13151F);
  static const bgCardHover = Color(0xFF181B27);
  static const border = Color(0xFF252838);
  static const textPrimary = Color(0xFFF1F3FF);
  static const textMuted = Color(0xFF6B7094);
  static const danger = Color(0xFFEF4444);
  static const dangerBg = Color(0x22EF4444);
  static const successBg = Color(0xFF052E1A);
  static const successBorder = Color(0xFF22C55E);
  static const successText = Color(0xFF86EFAC);
  static const errorBg = Color(0xFF2D0A0A);
  static const errorBorder = Color(0xFFEF4444);
  static const errorText = Color(0xFFFCA5A5);
  static const accentNew = Color(0xFF10B981); // "New" badge
}

// ─── Type → gradient + icon (mirrors React COLORS / ICONS maps) ───────────────
List<Color> _gradientFor(String? type) {
  switch (type) {
    case 'success':
      return [const Color(0xFF10B981), const Color(0xFF6366F1)];
    case 'warning':
      return [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
    case 'info':
      return [const Color(0xFF8B5CF6), const Color(0xFF6366F1)];
    case 'demande':
      return [const Color(0xFF3B82F6), const Color(0xFF06B6D4)];
    case 'annonce':
      return [const Color(0xFFA855F7), const Color(0xFFEC4899)];
    default:
      return [const Color(0xFF8B5CF6), const Color(0xFF10B981)];
  }
}

IconData _iconFor(String? type) {
  switch (type) {
    case 'success':
      return Icons.check_circle_outline_rounded;
    case 'warning':
      return Icons.error_outline_rounded;
    case 'info':
      return Icons.info_outline_rounded;
    case 'demande':
      return Icons.notifications_outlined;
    case 'annonce':
      return Icons.info_outline_rounded;
    default:
      return Icons.notifications_outlined;
  }
}

// ─── Toast model ──────────────────────────────────────────────────────────────
class _Toast {
  final String message;
  final bool isError;
  const _Toast(this.message, {this.isError = false});
}

// ─── Page ─────────────────────────────────────────────────────────────────────
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with TickerProviderStateMixin {
  List<NotificationModel> notifications = [];
  bool isLoading = true;
  String? error;

  // Toast
  _Toast? _toast;
  Timer? _toastTimer;
  late AnimationController _toastController;
  late Animation<double> _toastAnim;

  // Button loading states
  bool _markAllLoading = false;
  bool _deleteAllLoading = false;

  // Card animation controllers (staggered entrance)
  final List<AnimationController> _cardControllers = [];
  final List<Animation<double>> _cardSlide = [];
  final List<Animation<double>> _cardFade = [];

  @override
  void initState() {
    super.initState();
    _toastController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _toastAnim = CurvedAnimation(
      parent: _toastController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeIn,
    );
    loadNotifications();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _toastController.dispose();
    for (final c in _cardControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Data ────────────────────────────────────────────────────────────────────

  Future<void> loadNotifications() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final user = await UserService.instance.getProfile();
      final list = await NotificationService.instance.getByUser(user.id ?? '');
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _setupCardAnims(list.length);
      if (mounted) {
        setState(() {
          notifications = list;
          isLoading = false;
        });
        _runEntrance();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  void _setupCardAnims(int count) {
    for (final c in _cardControllers) {
      c.dispose();
    }
    _cardControllers.clear();
    _cardSlide.clear();
    _cardFade.clear();
    for (int i = 0; i < count; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 420),
      );
      _cardControllers.add(ctrl);
      _cardSlide.add(
        Tween<double>(begin: 20, end: 0).animate(
          CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic),
        ),
      );
      _cardFade.add(CurvedAnimation(parent: ctrl, curve: Curves.easeOut));
    }
  }

  void _runEntrance() {
    for (int i = 0; i < _cardControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 80), () {
        if (mounted) _cardControllers[i].forward();
      });
    }
  }

  // ── Toast ────────────────────────────────────────────────────────────────────

  void _showToast(String msg, {bool isError = false}) {
    _toastTimer?.cancel();
    setState(() => _toast = _Toast(msg, isError: isError));
    _toastController.forward(from: 0);
    _toastTimer = Timer(const Duration(milliseconds: 2200), () async {
      await _toastController.reverse();
      if (mounted) setState(() => _toast = null);
    });
  }

  // ── Actions ──────────────────────────────────────────────────────────────────

  Future<void> markAsRead(String id) async {
    try {
      await NotificationService.instance.markAsRead(id);
      setState(() {
        final i = notifications.indexWhere((n) => n.id == id);
        if (i != -1) {
          notifications[i] = NotificationModel(
            id: notifications[i].id,
            titre: notifications[i].titre,
            message: notifications[i].message,
            type: notifications[i].type,
            userId: notifications[i].userId,
            lu: true,
            createdAt: notifications[i].createdAt,
          );
        }
      });
      _showToast('Notification marked as read');
    } catch (e) {
      _showToast('Failed to mark as read', isError: true);
    }
  }

  Future<void> _handleMarkAllAsRead() async {
    setState(() => _markAllLoading = true);
    try {
      final unread = notifications.where((n) => !n.lu).toList();
      for (final n in unread) {
        await NotificationService.instance.markAsRead(n.id);
      }
      setState(() {
        notifications = notifications
            .map((n) => NotificationModel(
                  id: n.id,
                  titre: n.titre,
                  message: n.message,
                  type: n.type,
                  userId: n.userId,
                  lu: true,
                  createdAt: n.createdAt,
                ))
            .toList();
      });
      _showToast('All notifications marked as read');
    } catch (e) {
      _showToast('Failed to mark all as read', isError: true);
    }
    if (mounted) setState(() => _markAllLoading = false);
  }

  Future<void> deleteNotif(String id) async {
    final idx = notifications.indexWhere((n) => n.id == id);
    try {
      await NotificationService.instance.delete(id);
      setState(() {
        notifications.removeWhere((n) => n.id == id);
        if (idx >= 0 && idx < _cardControllers.length) {
          _cardControllers[idx].dispose();
          _cardControllers.removeAt(idx);
          _cardSlide.removeAt(idx);
          _cardFade.removeAt(idx);
        }
      });
      _showToast('Notification deleted');
    } catch (e) {
      _showToast('Failed to delete notification', isError: true);
    }
  }

  Future<void> _handleDeleteAll() async {
    setState(() => _deleteAllLoading = true);
    try {
      final user = await UserService.instance.getProfile();
// await NotificationService.instance.deleteAllByUser(user.id ?? '');
// await NotificationService.instance.deleteAll('');
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Delete all not implemented yet'))
);
      setState(() {
        notifications.clear();
        for (final c in _cardControllers) {
          c.dispose();
        }
        _cardControllers.clear();
        _cardSlide.clear();
        _cardFade.clear();
      });
      _showToast('All notifications deleted');
    } catch (e) {
      _showToast('Failed to delete all notifications', isError: true);
    }
    if (mounted) setState(() => _deleteAllLoading = false);
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────────

  void _confirmDeleteOne(NotificationModel notif) {
    showDialog(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Delete Notification',
        description:
            'Are you sure you want to delete this notification? This action cannot be undone.',
        confirmLabel: 'Delete',
        onConfirm: () {
          Navigator.of(context).pop();
          deleteNotif(notif.id);
        },
      ),
    );
  }

  void _confirmDeleteAll() {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setSt) {
        return _ConfirmDialog(
          title: 'Delete ALL Notifications',
          descriptionWidget: RichText(
            text: const TextSpan(
              style: TextStyle(color: _C.textMuted, fontSize: 14, height: 1.5),
              children: [
                TextSpan(text: 'Are you sure you want to delete '),
                TextSpan(
                  text: 'ALL',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: _C.errorText),
                ),
                TextSpan(
                    text:
                        ' your notifications? This action cannot be undone.'),
              ],
            ),
          ),
          confirmLabel: 'Delete All',
          loading: _deleteAllLoading,
          onConfirm: () async {
            await _handleDeleteAll();
            if (mounted) Navigator.of(context).pop();
          },
        );
      }),
    );
  }

  // ── Computed ─────────────────────────────────────────────────────────────────

  int get unreadCount => notifications.where((n) => !n.lu).length;

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
          // Toast overlay — top-right, slides from top (matches React)
          if (_toast != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: FadeTransition(
                opacity: _toastAnim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.4),
                    end: Offset.zero,
                  ).animate(_toastAnim),
                  child: _ToastWidget(toast: _toast!),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1D27),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.border),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: _C.textMuted, size: 16),
                ),
              ),
              const SizedBox(width: 14),
              // Gradient "Notifications" title
              ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  colors: [
                    Color(0xFF8B5CF6),
                    Color(0xFF6366F1),
                    Color(0xFF10B981),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ).createShader(r),
                child: const Text(
                  'Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Unread badge (like React's <Badge>)
              if (unreadCount > 0 && !isLoading)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _C.accentNew,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$unreadCount new',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.only(left: 54),
            child: Text(
              'Your academic updates',
              style: TextStyle(
                color: _C.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 18),
          // Action buttons row (Mark All Read + Delete All)
          if (!isLoading && notifications.isNotEmpty)
            Row(
              children: [
                if (unreadCount > 0) ...[
                  _HeaderButton(
                    label: _markAllLoading ? 'Marking…' : 'Mark All Read',
                    icon: Icons.check_circle_outline_rounded,
                    loading: _markAllLoading,
                    onTap: _markAllLoading ? null : _handleMarkAllAsRead,
                    outlined: true,
                  ),
                  const SizedBox(width: 10),
                ],
                _HeaderButton(
                  label: 'Delete All',
                  icon: Icons.delete_outline_rounded,
                  loading: false,
                  onTap: _confirmDeleteAll,
                  danger: true,
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (isLoading) return _buildLoading();
    if (error != null) return _buildError();
    if (notifications.isEmpty) return _buildEmpty();
    return _buildList();
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: const Color(0xFF8B5CF6),
              backgroundColor: const Color(0x338B5CF6),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Loading notifications…',
              style: TextStyle(color: _C.textMuted, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _C.dangerBg,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.wifi_off_rounded, color: _C.danger, size: 32),
            ),
            const SizedBox(height: 20),
            const Text('Something went wrong',
                style: TextStyle(
                    color: _C.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _C.textMuted, fontSize: 13)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: loadNotifications,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Try Again',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF13151F),
              shape: BoxShape.circle,
              border: Border.all(color: _C.border, width: 1.5),
            ),
            child: const Icon(Icons.notifications_none_rounded,
                color: _C.textMuted, size: 40),
          ),
          const SizedBox(height: 20),
          const Text('No new notifications',
              style: TextStyle(
                  color: _C.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text("You're all caught up!",
              style: TextStyle(color: _C.textMuted, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: loadNotifications,
      color: const Color(0xFF8B5CF6),
      backgroundColor: const Color(0xFF1A1D27),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final anim = index < _cardControllers.length;
          final card = _NotifCard(
            notif: notifications[index],
            onMarkRead: markAsRead,
            onDelete: _confirmDeleteOne,
          );
          if (!anim) return card;
          return AnimatedBuilder(
            animation: _cardControllers[index],
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _cardSlide[index].value),
              child: Opacity(opacity: _cardFade[index].value, child: child),
            ),
            child: card,
          );
        },
      ),
    );
  }
}

// ─── Notification Card ────────────────────────────────────────────────────────
// Mirrors the React <Card> with gradient icon tile, "New" badge, hover overlay,
// mark-as-read ✓ button, and delete 🗑 button.

class _NotifCard extends StatefulWidget {
  const _NotifCard({
    required this.notif,
    required this.onMarkRead,
    required this.onDelete,
  });
  final NotificationModel notif;
  final Future<void> Function(String) onMarkRead;
  final void Function(NotificationModel) onDelete;

  @override
  State<_NotifCard> createState() => _NotifCardState();
}

class _NotifCardState extends State<_NotifCard> {
  bool _hovered = false;

  String _relativeDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notif;
    final isUnread = !n.lu;
    final gradient = _gradientFor(n.type);
    final icon = _iconFor(n.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
          decoration: BoxDecoration(
            color: _C.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.border),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: gradient.first.withOpacity(0.15),
                      blurRadius: 24,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    )
                  ]
                : [],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Gradient overlay (opacity-5 → opacity-10 on hover, like React)
              Positioned.fill(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: _hovered ? 0.10 : 0.05,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),
              // Card content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gradient icon tile (h-12 w-12 rounded-xl)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: gradient.first.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 16),
                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title + badges + action buttons
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  n.titre ?? '',
                                  style: const TextStyle(
                                    color: _C.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // "New" badge
                              if (isUnread)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _C.accentNew,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'New',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              // Mark as read ✓ button
                              if (isUnread) ...[
                                const SizedBox(width: 4),
                                _GhostIconButton(
                                  icon: Icons.check_circle_outline_rounded,
                                  color: const Color(0xFF22C55E),
                                  tooltip: 'Mark as read',
                                  onTap: () => widget.onMarkRead(n.id),
                                ),
                              ],
                              // Delete button
                              const SizedBox(width: 2),
                              _GhostIconButton(
                                icon: Icons.delete_outline_rounded,
                                color: _C.danger,
                                tooltip: 'Delete notification',
                                onTap: () => widget.onDelete(n),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Message
                          Text(
                            n.message,
                            style: const TextStyle(
                              color: _C.textMuted,
                              fontSize: 13,
                              height: 1.5,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // Date
                          Text(
                            _relativeDate(n.createdAt),
                            style: const TextStyle(
                              color: _C.textMuted,
                              fontSize: 11,
                            ),
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

// ─── Ghost icon button (matches React's variant="ghost" size="sm") ────────────
class _GhostIconButton extends StatefulWidget {
  const _GhostIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  State<_GhostIconButton> createState() => _GhostIconButtonState();
}

class _GhostIconButtonState extends State<_GhostIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip ?? '',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _pressed
                ? widget.color.withOpacity(0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(widget.icon, color: widget.color, size: 18),
        ),
      ),
    );
  }
}

// ─── Header action button ("Mark All Read" / "Delete All") ───────────────────
class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.onTap,
    this.outlined = false,
    this.danger = false,
  });
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback? onTap;
  final bool outlined;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final bg = danger
        ? _C.danger
        : outlined
            ? Colors.transparent
            : const Color(0xFF1A1D27);
    final fg = danger ? Colors.white : _C.textPrimary;
    final borderColor = outlined ? _C.border : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.5 : 1,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: fg,
                  ),
                )
              else
                Icon(icon, color: fg, size: 16),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: fg,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Toast widget (matches React's top-right success/error Alert) ─────────────
class _ToastWidget extends StatelessWidget {
  const _ToastWidget({required this.toast});
  final _Toast toast;

  @override
  Widget build(BuildContext context) {
    final bg = toast.isError ? _C.errorBg : _C.successBg;
    final border = toast.isError ? _C.errorBorder : _C.successBorder;
    final fg = toast.isError ? _C.errorText : _C.successText;
    final icon =
        toast.isError ? Icons.cancel_outlined : Icons.check_circle_outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: border, size: 18),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              toast.message,
              style: TextStyle(
                  color: fg, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Confirm dialog (Delete one / Delete all) ─────────────────────────────────
// Matches React's <Dialog> with title, description, Cancel + destructive button.

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    this.description,
    this.descriptionWidget,
    required this.confirmLabel,
    required this.onConfirm,
    this.loading = false,
  });
  final String title;
  final String? description;
  final Widget? descriptionWidget;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF13151F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: _C.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: _C.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            descriptionWidget ??
                Text(description ?? '',
                    style: const TextStyle(
                        color: _C.textMuted, fontSize: 14, height: 1.5)),
            const SizedBox(height: 24),
            Row(
              children: [
                // Cancel
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _C.border),
                      ),
                      alignment: Alignment.center,
                      child: const Text('Cancel',
                          style: TextStyle(
                              color: _C.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Confirm (destructive)
                Expanded(
                  child: GestureDetector(
                    onTap: loading ? null : onConfirm,
                    child: AnimatedOpacity(
                      opacity: loading ? 0.6 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _C.danger,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(confirmLabel,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}