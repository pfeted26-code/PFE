import 'package:flutter/material.dart';

import '/models/auth_response_model.dart';
import '/services/auth_service.dart';
import 'forget.dart';


// ─── Login Screen ─────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {

  // ── Controllers ─────────────────────────────────────────────────────────────

  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus         = FocusNode();
  final _passwordFocus      = FocusNode();

  // ── UI State ─────────────────────────────────────────────────────────────────

  bool    _loading      = false;
  bool    _showPassword = false;
  String? _error;
  String? _success;
  final Map<String, String> _fieldErrors = {};

  // ── Animations ───────────────────────────────────────────────────────────────

  late AnimationController _blob1Controller;
  late AnimationController _blob2Controller;
  late AnimationController _blob3Controller;
  late AnimationController _logoController;
  late Animation<double>   _logoScale;

  // ── Lifecycle ─────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _blob1Controller = AnimationController(
      vsync: this, duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _blob2Controller = AnimationController(
      vsync: this, duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _blob3Controller = AnimationController(
      vsync: this, duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _logoController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    );

    _logoScale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _blob1Controller.dispose();
    _blob2Controller.dispose();
    _blob3Controller.dispose();
    _logoController.dispose();
    super.dispose();
  }

  // ── Validation ───────────────────────────────────────────────────────────────

  bool _validate() {
    _fieldErrors.clear();

    final email    = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      _fieldErrors['email'] = 'Email is required';
    } else if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      _fieldErrors['email'] = 'Invalid email address';
    }

    if (password.isEmpty) {
      _fieldErrors['password'] = 'Password is required';
    } else if (password.length < 6) {
      _fieldErrors['password'] = 'Password must be at least 6 characters';
    }

    setState(() {});
    return _fieldErrors.isEmpty;
  }

  // ── Submit ────────────────────────────────────────────────────────────────────

  Future<void> _handleSubmit() async {
    setState(() { _error = null; _success = null; });
    if (!_validate()) return;

    setState(() => _loading = true);

    try {
      // AuthService handles the API call + storing token/user automatically
      final AuthResponseModel auth = await AuthService.instance.login(
        email:    _emailController.text.trim(),
        password: _passwordController.text,
      );

      setState(() {
        _loading = false;
        _success = 'Login successful! Redirecting...';
      });

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      // Navigate based on role from the typed model
      switch (auth.user.role) {
        case 'admin':
          Navigator.pushReplacementNamed(context, '/admin');
          break;
        case 'enseignant':
          Navigator.pushReplacementNamed(context, '/teacher');
          break;
        case 'etudiant':
          Navigator.pushReplacementNamed(context, '/student');
          break;
        default:
          Navigator.pushReplacementNamed(context, '/login');
      }

    } catch (e) {
      setState(() {
        _loading = false;
        _error   = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF020617), Color(0xFF0F172A), Color(0xFF020617)],
              ),
            ),
          ),

          _AnimatedBlob(
            controller: _blob1Controller,
            alignment: const Alignment(-0.5, -0.5),
            colors: const [Color(0x4D7C3AED), Color(0x4D2563EB), Color(0x4D0891B2)],
          ),
          _AnimatedBlob(
            controller: _blob2Controller,
            alignment: const Alignment(0.5, 0.5),
            colors: const [Color(0x4DDC2626), Color(0x4D7C3AED), Color(0x4D2563EB)],
          ),
          _AnimatedBlob(
            controller: _blob3Controller,
            alignment: Alignment.center,
            colors: const [Color(0x330891B2), Color(0x332563EB)],
            size: 700,
          ),

          CustomPaint(painter: _GridPainter(), size: Size.infinite),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: _buildCard(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Card ──────────────────────────────────────────────────────────────────────

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x801E293B), width: 1),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x990F172A), Color(0x990F172A)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x337C3AED), blurRadius: 60, spreadRadius: -10, offset: Offset(0, 20)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x1A7C3AED), Colors.transparent, Color(0x1A0891B2)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildAlerts(),
                _buildForm(),
                const SizedBox(height: 24),
                _buildDivider(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        MouseRegion(
          onEnter: (_) => _logoController.forward(),
          onExit:  (_) => _logoController.reverse(),
          child: ScaleTransition(
            scale: _logoScale,
            child: Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7C3AED), Color(0xFF2563EB), Color(0xFF0891B2)],
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x807C3AED), blurRadius: 24),
                  BoxShadow(color: Color(0x600891B2), blurRadius: 40, spreadRadius: -5),
                ],
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white.withOpacity(0.2), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  const Icon(Icons.school_rounded, size: 48, color: Colors.white,
                    shadows: [Shadow(color: Colors.white38, blurRadius: 12)]),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFC084FC), Color(0xFF60A5FA), Color(0xFF22D3EE)],
          ).createShader(bounds),
          child: const Text(
            'Welcome Back',
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Enter your credentials to access your portal',
          style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.5)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Alerts ────────────────────────────────────────────────────────────────────

  Widget _buildAlerts() {
    return Column(
      children: [
        if (_error != null) ...[
          _Alert(message: _error!, isError: true),
          const SizedBox(height: 16),
        ],
        if (_success != null) ...[
          _Alert(message: _success!, isError: false),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  // ── Form ──────────────────────────────────────────────────────────────────────

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: 'Email Address', opacity: 0.4),
        const SizedBox(height: 8),
        _StyledTextField(
          controller: _emailController,
          focusNode: _emailFocus,
          hintText: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
          focusColor: const Color(0xFF60A5FA),
          onSubmitted: (_) => _passwordFocus.requestFocus(),
          onChanged: (_) {
            if (_fieldErrors.containsKey('email')) setState(() => _fieldErrors.remove('email'));
          },
          enabled: !_loading,
        ),
        if (_fieldErrors['email'] != null) ...[
          const SizedBox(height: 6),
          _FieldError(message: _fieldErrors['email']!),
        ],

        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _FieldLabel(label: 'Password', opacity: 0.9),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
              ),
              child: const Text(
                'Forget password?',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF60A5FA)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _StyledTextField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          hintText: 'Enter your password',
          obscureText: !_showPassword,
          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
          focusColor: const Color(0xFFC084FC),
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _showPassword = !_showPassword),
            child: Icon(
              _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20, color: Colors.white38,
            ),
          ),
          onSubmitted: (_) => _handleSubmit(),
          onChanged: (_) {
            if (_fieldErrors.containsKey('password')) setState(() => _fieldErrors.remove('password'));
          },
          enabled: !_loading,
        ),
        if (_fieldErrors['password'] != null) ...[
          const SizedBox(height: 6),
          _FieldError(message: _fieldErrors['password']!),
        ],

        const SizedBox(height: 24),
        _buildSubmitButton(),
      ],
    );
  }

  // ── Submit Button ─────────────────────────────────────────────────────────────

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF2563EB), Color(0xFF0891B2)],
          ),
          boxShadow: [
            BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: ElevatedButton(
          onPressed: _loading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _loading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)),
                )
              : const Text('Sign In',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
        ),
      ),
    );
  }

  // ── Divider ───────────────────────────────────────────────────────────────────

  Widget _buildDivider() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Divider(color: Colors.white.withOpacity(0.08)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'EDUNEX PORTAL',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: Colors.white.withOpacity(0.35)),
          ),
        ),
      ],
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _StyledTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode             focusNode;
  final String                hintText;
  final bool                  obscureText;
  final TextInputType?        keyboardType;
  final Widget                prefixIcon;
  final Widget?               suffixIcon;
  final Color                 focusColor;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool                  enabled;

  const _StyledTextField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
    required this.prefixIcon,
    this.suffixIcon,
    required this.focusColor,
    this.onSubmitted,
    this.onChanged,
    this.enabled = true,
  });

  @override
  State<_StyledTextField> createState() => _StyledTextFieldState();
}

class _StyledTextFieldState extends State<_StyledTextField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() => setState(() => _focused = widget.focusNode.hasFocus));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focused ? widget.focusColor.withOpacity(0.7) : Colors.white.withOpacity(0.1),
          width: _focused ? 1.5 : 1,
        ),
        color: const Color(0xFF1E293B).withOpacity(0.5),
        boxShadow: _focused
            ? [BoxShadow(color: widget.focusColor.withOpacity(0.15), blurRadius: 12)]
            : null,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        onSubmitted: widget.onSubmitted,
        onChanged: widget.onChanged,
        enabled: widget.enabled,
        style: const TextStyle(fontSize: 15, color: Color(0xFFE2E8F0)),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: IconTheme(
              data: IconThemeData(color: _focused ? widget.focusColor : Colors.white38, size: 20),
              child: widget.prefixIcon,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: widget.suffixIcon != null
              ? Padding(padding: const EdgeInsets.only(right: 12), child: widget.suffixIcon)
              : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final double opacity;
  const _FieldLabel({required this.label, this.opacity = 0.9});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(opacity), letterSpacing: 0.2),
    );
  }
}

class _FieldError extends StatelessWidget {
  final String message;
  const _FieldError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.error_outline, size: 14, color: Color(0xFFF87171)),
        const SizedBox(width: 6),
        Text(message, style: const TextStyle(fontSize: 12, color: Color(0xFFF87171))),
      ],
    );
  }
}

class _Alert extends StatelessWidget {
  final String message;
  final bool   isError;
  const _Alert({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final bgColor     = isError ? const Color(0xFF1A0000) : const Color(0xFF00170A);
    final borderColor = isError ? const Color(0xFF7F1D1D) : const Color(0xFF14532D);
    final iconColor   = isError ? const Color(0xFFF87171) : const Color(0xFF4ADE80);
    final textColor   = isError ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0);
    final icon        = isError ? Icons.error_outline : Icons.check_circle_outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textColor)),
          ),
        ],
      ),
    );
  }
}

class _AnimatedBlob extends StatelessWidget {
  final AnimationController controller;
  final Alignment           alignment;
  final List<Color>         colors;
  final double              size;

  const _AnimatedBlob({
    required this.controller,
    required this.alignment,
    required this.colors,
    this.size = 400,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) => Align(
          alignment: alignment,
          child: Opacity(
            opacity: 0.3 + (controller.value * 0.15),
            child: Container(
              width: size, height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: colors),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 1;
    const spacing = 100.0;
    for (double x = 0; x < size.width;  x += spacing) canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    for (double y = 0; y < size.height; y += spacing) canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}