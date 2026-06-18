import 'package:flutter/material.dart';
import '../../models/user_model.dart';

// ─── Nav Item Model ───────────────────────────────────────────────────────────

class _NavItem {
  final String   path;
  final String   label;
  final IconData icon;
  const _NavItem({required this.path, required this.label, required this.icon});
}

const _navItems = [
  _NavItem(path: 'dashboard',              label: 'Dashboard',     icon: Icons.dashboard_rounded),
  _NavItem(path: 'courses',       label: 'courses',       icon: Icons.menu_book_rounded),
  _NavItem(path: 'timetable',     label: 'Timetable',     icon: Icons.calendar_month_rounded),
  _NavItem(path: 'exams',         label: 'Exams & Notes', icon: Icons.description_rounded),
  _NavItem(path: 'attendance',    label: 'Attendance',    icon: Icons.how_to_reg_rounded),
  _NavItem(path: 'announcements', label: 'Announcements', icon: Icons.campaign_rounded),
  _NavItem(path: 'requests',      label: 'Requests',      icon: Icons.send_rounded),
  _NavItem(path: 'messages',      label: 'Messages',      icon: Icons.chat_bubble_outline_rounded),
  _NavItem(path: 'notifications', label: 'Notifications', icon: Icons.notifications_none_rounded),
  _NavItem(path: 'chatbot',       label: 'EduBot',        icon: Icons.smart_toy_rounded),
];

// ─── Student Sidebar ──────────────────────────────────────────────────────────

class StudentSidebar extends StatefulWidget {
  final String                  currentPath;
  final void Function(String)   onNavigate;
  final bool                    isCollapsed;
  final VoidCallback            onToggleCollapse;
  final String?                 studentName;
  final String?                 studentEmail;
  final String?                 avatarUrl;
  final UserModel?              user;

  const StudentSidebar({
    super.key,
    required this.currentPath,
    required this.onNavigate,
    this.isCollapsed = false,
    required this.onToggleCollapse,
    this.studentName,
    this.studentEmail,
    this.avatarUrl,
    this.user,
  });

  @override
  State<StudentSidebar> createState() => _StudentSidebarState();
}

class _StudentSidebarState extends State<StudentSidebar>
    with SingleTickerProviderStateMixin {

  late AnimationController _animCtrl;
  late Animation<double>   _widthAnim;

  // ── FIX 1: track collapsed state as a proper bool, not derived from width ──
  bool _collapsed = false;

  static const double _expandedWidth  = 240;
  static const double _collapsedWidth = 68;

  static const _primary        = Color(0xFF6366F1);
  static const _secondary      = Color(0xFF8B5CF6);
  static const _bg             = Color(0xFF0F1117);
  static const _border         = Color(0xFF2A2D3A);
  static const _textPrimary    = Color(0xFFE2E8F0);
  static const _textSecondary  = Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();
    _collapsed = widget.isCollapsed;
    _animCtrl  = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 220),
      value:    widget.isCollapsed ? 0.0 : 1.0,
    );
    _widthAnim = Tween<double>(begin: _collapsedWidth, end: _expandedWidth)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(StudentSidebar old) {
    super.didUpdateWidget(old);
    if (old.isCollapsed != widget.isCollapsed) {
      if (widget.isCollapsed) {
        // Collapse: hide labels immediately, then animate width
        setState(() => _collapsed = true);
        _animCtrl.reverse();
      } else {
        // Expand: animate width first, show labels only when nearly done
        _animCtrl.forward().then((_) {
          if (mounted) setState(() => _collapsed = false);
        });
      }
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  String _getInitials() {
    final name  = widget.studentName ?? '';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    if (parts.isNotEmpty && parts.first.isNotEmpty) return parts.first[0].toUpperCase();
    return 'ST';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _widthAnim,
      builder: (_, __) => Container(
        width:  _widthAnim.value,
        height: double.infinity,
        decoration: BoxDecoration(
          color:    _bg,
          gradient: const LinearGradient(
            begin:  Alignment.topLeft,
            end:    Alignment.bottomRight,
            colors: [Color(0xFF0F1117), Color(0xFF13161F)],
          ),
          border: const Border(right: BorderSide(color: _border)),
        ),
        // Clip so nothing bleeds outside the animated width
        child: ClipRect(
          child: OverflowBox(
            alignment:  Alignment.centerLeft,
            maxWidth:   _expandedWidth,
            minWidth:   _collapsedWidth,
            child: SizedBox(
              width: _expandedWidth,
              height: double.infinity,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildMenu()),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: InkWell(
        onTap: widget.onToggleCollapse,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: _collapsed ? 0 : 16),
          child: Row(
            mainAxisAlignment: _collapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              // Logo
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    begin:  Alignment.topLeft,
                    end:    Alignment.bottomRight,
                    colors: [_primary, _secondary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:      _primary.withOpacity(0.4),
                      blurRadius: 12,
                      offset:     const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('E',
                    style: TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                ),
              ),
              if (!_collapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [_primary, _secondary],
                        ).createShader(b),
                        child: const Text('EduNex',
                          style: TextStyle(
                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                      const Text('Student Portal',
                        style: TextStyle(fontSize: 10, color: _textSecondary)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_left_rounded, color: _textSecondary, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Menu ──────────────────────────────────────────────────────────────────

  Widget _buildMenu() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _collapsed ? 8 : 12,
        vertical:   16,
      ),
      child: Column(
        children: _navItems
            .map((item) => _buildNavItem(item))
            .toList(),
      ),
    );
  }

  Widget _buildNavItem(_NavItem item) {
    final isActive = widget.currentPath == item.path;

    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height:   44,
      margin:   const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: isActive
            ? LinearGradient(colors: [
                _primary.withOpacity(0.15),
                _secondary.withOpacity(0.10),
              ])
            : null,
        border: isActive
            ? const Border(left: BorderSide(color: _primary, width: 3))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          hoverColor:   Colors.white.withOpacity(0.05),
          onTap:        () => widget.onNavigate(item.path),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: _collapsed ? 0 : 12),
            child: Row(
              mainAxisAlignment: _collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(item.icon,
                  size:  20,
                  color: isActive ? _primary : _textSecondary),
                if (!_collapsed) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      item.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize:   14,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        color:      isActive ? _textPrimary : _textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return _collapsed
        ? Tooltip(message: item.label, preferBelow: false, child: tile)
        : tile;
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    // ── FIX 2: proper avatar — no nested CircleAvatar+child conflict ──
    final hasAvatar = widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty;

    final avatar = Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        shape:  BoxShape.circle,
        border: Border.all(color: _primary.withOpacity(0.3), width: 2),
        // Show gradient background always; image painted on top if available
        gradient: hasAvatar
            ? null
            : const LinearGradient(
                begin:  Alignment.topLeft,
                end:    Alignment.bottomRight,
                colors: [_primary, _secondary],
              ),
                image: hasAvatar
                    ? DecorationImage(
                        image: NetworkImage(widget.avatarUrl!),
                        fit:   BoxFit.cover,
                        onError: (exception, stackTrace) {
                          print('Image load error: $exception');
                        },
                      )
                    : null,
      ),
      child: hasAvatar
          ? null
          : Center(
              child: Text(
                _getInitials(),
                style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
    );

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _border)),
      ),
      padding: EdgeInsets.all(_collapsed ? 8 : 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => widget.onNavigate('profile'),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _collapsed ? 0 : 8,
            vertical:   8,
          ),
          child: Row(
            mainAxisAlignment: _collapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              avatar,
              if (!_collapsed) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize:       MainAxisSize.min,
                    children: [
                      Text(
                        widget.user?.fullName ?? widget.studentName ?? 'Loading...',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, color: _textPrimary),
                      ),
                      Text(
                        widget.user?.email ?? widget.studentEmail ?? 'student@edunex.com',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: _textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}