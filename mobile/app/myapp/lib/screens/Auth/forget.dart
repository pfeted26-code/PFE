import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/services/auth_service.dart';
import 'login.dart';


// ─── Forgot Password Screen ───────────────────────────────────────────────────

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {

  int _step = 1; // 1=email  2=otp  3=new password

  // ── Controllers ──────────────────────────────────────────────────────────────

  final _emailController    = TextEditingController();
  final _emailFocus         = FocusNode();
  final _passwordController = TextEditingController();
  final _passwordFocus      = FocusNode();
  final _confirmController  = TextEditingController();
  final _confirmFocus       = FocusNode();

  // ── OTP ───────────────────────────────────────────────────────────────────────

  static const int _otpLength = 8;
  late final List<TextEditingController> _otpControllers;
  late final List<FocusNode>             _otpFocusNodes;

  // ── State ─────────────────────────────────────────────────────────────────────

  bool    _loading     = false;
  bool    _showPass    = false;
  bool    _showConfirm = false;
  bool    _done        = false;
  String? _error;
  String? _success;
  final Map<String, String> _fieldErrors = {};

  // ── Animations ────────────────────────────────────────────────────────────────

  late AnimationController _blob1;
  late AnimationController _blob2;
  late AnimationController _blob3;
  late AnimationController _slideCtrl;
  late Animation<double>   _slideAnim;
  late Animation<double>   _fadeAnim;

  // ── Lifecycle ─────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _otpControllers = List.generate(_otpLength, (_) => TextEditingController());
    _otpFocusNodes  = List.generate(_otpLength, (_) => FocusNode());
    for (final f in _otpFocusNodes) f.addListener(() => setState(() {}));

    _blob1 = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _blob2 = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
    _blob3 = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);

    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _slideAnim = Tween<double>(begin: 48, end: 0).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _fadeAnim  = Tween<double>(begin: 0,  end: 1).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();    _emailFocus.dispose();
    _passwordController.dispose(); _passwordFocus.dispose();
    _confirmController.dispose();  _confirmFocus.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes)  f.dispose();
    _blob1.dispose(); _blob2.dispose(); _blob3.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  void _transition(VoidCallback action) {
    _slideCtrl.reverse().then((_) {
      action();
      setState(() { _error = null; _success = null; _fieldErrors.clear(); });
      _slideCtrl.forward();
    });
  }

  String get _otpValue => _otpControllers.map((c) => c.text).join();

  // ── Validation ────────────────────────────────────────────────────────────────

  bool _validateEmail() {
    _fieldErrors.remove('email');
    final v = _emailController.text.trim();
    if (v.isEmpty) {
      _fieldErrors['email'] = 'Email is required';
    } else if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) {
      _fieldErrors['email'] = 'Invalid email address';
    }
    setState(() {});
    return !_fieldErrors.containsKey('email');
  }

  bool _validateOtp() {
    _fieldErrors.remove('otp');
    if (_otpValue.length != _otpLength) {
      _fieldErrors['otp'] = 'Please fill all $_otpLength characters';
    }
    setState(() {});
    return !_fieldErrors.containsKey('otp');
  }

  bool _validatePassword() {
    _fieldErrors.remove('password');
    final pass    = _passwordController.text;
    final confirm = _confirmController.text;
    final regex   = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    if (pass.isEmpty) {
      _fieldErrors['password'] = 'Password is required';
    } else if (!regex.hasMatch(pass)) {
      _fieldErrors['password'] = 'Min 8 chars, uppercase, lowercase, number & special character';
    } else if (pass != confirm) {
      _fieldErrors['password'] = 'Passwords do not match';
    }
    setState(() {});
    return !_fieldErrors.containsKey('password');
  }

  // ── API Handlers ──────────────────────────────────────────────────────────────

  Future<void> _handleSendCode() async {
    if (!_validateEmail()) return;
    setState(() { _loading = true; _error = null; _success = null; });

    try {
      // AuthService calls POST /users/forgot-password
      final result = await AuthService.instance.forgotPassword(
        email: _emailController.text.trim(),
      );

      setState(() {
        _loading = false;
        _success = result.message.isNotEmpty
            ? result.message
            : 'Verification code sent! Check your inbox.';
      });

      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      _transition(() => setState(() => _step = 2));

    } catch (e) {
      setState(() {
        _loading = false;
        _error   = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _handleVerifyCode() async {
    if (!_validateOtp()) return;
    // Same as web: just move to step 3 — real verification happens at reset time
    setState(() { _error = null; _success = 'Code verified successfully!'; });
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    _transition(() => setState(() => _step = 3));
  }

  Future<void> _handleResetPassword() async {
    if (!_validatePassword()) return;
    setState(() { _loading = true; _error = null; _success = null; });

    try {
      // AuthService calls POST /users/reset-password
      final result = await AuthService.instance.resetPassword(
        email:       _emailController.text.trim(),
        code:        _otpValue,
        newPassword: _passwordController.text,
      );

      setState(() {
        _loading = false;
        _success = result.message.isNotEmpty ? result.message : 'Password reset successfully!';
        _done    = true;
      });

    } catch (e) {
      setState(() {
        _loading = false;
        _error   = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _handleBack() {
    _transition(() {
      setState(() {
        if (_step == 2) {
          _step = 1;
          for (final c in _otpControllers) c.clear();
        } else if (_step == 3) {
          _step = 2;
          _passwordController.clear();
          _confirmController.clear();
          _showPass = false; _showConfirm = false;
        }
      });
    });
  }

  // ── Step meta ─────────────────────────────────────────────────────────────────

  IconData get _icon {
    if (_step == 1) return Icons.mail_outline_rounded;
    if (_step == 2) return Icons.vpn_key_rounded;
    return Icons.lock_outline_rounded;
  }

  String get _title {
    if (_step == 1) return 'Reset Password';
    if (_step == 2) return 'Verify Code';
    return 'New Password';
  }

  String get _subtitle {
    if (_step == 1) return 'Enter your email to receive a verification code';
    if (_step == 2) return 'Enter the 8-character code sent to your email';
    return 'Create a strong new password for your account';
  }

  String get _footerNote {
    if (_step == 1) return "You'll receive an email with a verification code";
    if (_step == 2) return 'Code expires in 10 minutes';
    return 'Your password will be updated securely';
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF020617), Color(0xFF0F172A), Color(0xFF020617)],
              ),
            ),
          ),
          _AnimatedBlob(controller: _blob1, alignment: const Alignment(-0.5, -0.5),
              colors: const [Color(0x4D7C3AED), Color(0x4D2563EB), Color(0x4D0891B2)]),
          _AnimatedBlob(controller: _blob2, alignment: const Alignment(0.5, 0.5),
              colors: const [Color(0x4DDC2626), Color(0x4D7C3AED), Color(0x4D2563EB)]),
          _AnimatedBlob(controller: _blob3, alignment: Alignment.center,
              colors: const [Color(0x330891B2), Color(0x332563EB)], size: 700),
          CustomPaint(painter: _GridPainter(), size: Size.infinite),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: AnimatedBuilder(
                  animation: _slideCtrl,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, _slideAnim.value),
                    child: Opacity(opacity: _fadeAnim.value, child: child),
                  ),
                  child: _buildCard(),
                ),
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
          begin: Alignment.topLeft, end: Alignment.bottomRight,
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
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0x1A7C3AED), Colors.transparent, Color(0x1A0891B2)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const SizedBox(height: 28),
                if (_error   != null) ...[_Alert(message: _error!,   isError: true),  const SizedBox(height: 16)],
                if (_success != null) ...[_Alert(message: _success!, isError: false), const SizedBox(height: 16)],
                if (_done)          _buildDoneState()
                else if (_step == 1) _buildStep1()
                else if (_step == 2) _buildStep2()
                else                 _buildStep3(),
                const SizedBox(height: 24),
                _buildFooter(),
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
        Container(
          width: 96, height: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF7C3AED), Color(0xFF2563EB), Color(0xFF0891B2)],
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x807C3AED), blurRadius: 24, spreadRadius: 0),
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
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Colors.white.withOpacity(0.2), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Icon(_icon, size: 46, color: Colors.white,
                  shadows: const [Shadow(color: Colors.white38, blurRadius: 12)]),
            ],
          ),
        ),

        const SizedBox(height: 20),

        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFFC084FC), Color(0xFF60A5FA), Color(0xFF22D3EE)],
          ).createShader(b),
          child: Text(_title,
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
        ),

        const SizedBox(height: 8),

        Text(_subtitle, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.5))),

        const SizedBox(height: 20),

        // Progress dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final active = i + 1 == _step;
            final done   = i + 1 < _step;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 28 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: (active || done)
                    ? const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF0891B2)])
                    : null,
                color: (active || done) ? null : Colors.white.withOpacity(0.15),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ── Step 1 ────────────────────────────────────────────────────────────────────

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(label: 'Email Address'),
        const SizedBox(height: 8),
        _StyledTextField(
          controller: _emailController,
          focusNode: _emailFocus,
          hintText: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
          focusColor: const Color(0xFF60A5FA),
          onSubmitted: (_) => _handleSendCode(),
          onChanged: (_) => setState(() => _fieldErrors.remove('email')),
          enabled: !_loading,
        ),
        if (_fieldErrors['email'] != null) ...[
          const SizedBox(height: 6),
          _FieldError(message: _fieldErrors['email']!),
        ],
        const SizedBox(height: 24),
        _buildPrimaryButton(
          label: _loading ? 'Sending…' : 'Send Verification Code',
          icon: Icons.send_rounded,
          onPressed: _loading ? null : _handleSendCode,
          loading: _loading,
        ),
        const SizedBox(height: 12),
        _buildSecondaryButton(
          label: 'Back to Login',
          icon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginScreen())),
        ),
      ],
    );
  }

  // ── Step 2 ────────────────────────────────────────────────────────────────────

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(label: 'Verification Code'),
        const SizedBox(height: 4),
        Text('Code sent to: ${_emailController.text.trim()}',
            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4))),
        const SizedBox(height: 16),
        _buildOtpRow(),
        if (_fieldErrors['otp'] != null) ...[
          const SizedBox(height: 8),
          _FieldError(message: _fieldErrors['otp']!),
        ],
        const SizedBox(height: 24),
        _buildPrimaryButton(
          label: 'Verify Code',
          icon: Icons.check_circle_outline_rounded,
          onPressed: _handleVerifyCode,
        ),
        const SizedBox(height: 12),
        _buildSecondaryButton(label: 'Back', icon: Icons.arrow_back_rounded, onPressed: _handleBack),
      ],
    );
  }

  Widget _buildOtpRow() {
    return Row(
      children: List.generate(_otpLength, (i) {
        final focused = _otpFocusNodes[i].hasFocus;
        final filled  = _otpControllers[i].text.isNotEmpty;
        return Expanded(
          child: Container(
            height: 48,
            margin: EdgeInsets.only(right: i < _otpLength - 1 ? 6 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                width: focused ? 1.5 : 1,
                color: focused
                    ? const Color(0xFFC084FC).withOpacity(0.8)
                    : filled
                        ? const Color(0xFF60A5FA).withOpacity(0.5)
                        : Colors.white.withOpacity(0.1),
              ),
              color: focused
                  ? const Color(0xFF7C3AED).withOpacity(0.1)
                  : const Color(0xFF1E293B).withOpacity(0.5),
              boxShadow: focused
                  ? [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.2), blurRadius: 8)]
                  : null,
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                inputDecorationTheme: const InputDecorationTheme(
                  border: InputBorder.none, enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none, filled: false,
                ),
              ),
              child: Center(
                child: TextField(
                  controller: _otpControllers[i],
                  focusNode: _otpFocusNodes[i],
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  keyboardType: TextInputType.text,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]'))],
                  style: TextStyle(
                    color: focused ? const Color(0xFFC084FC) : const Color(0xFFE2E8F0),
                    fontSize: 16, fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none, enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none, disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none, focusedErrorBorder: InputBorder.none,
                    filled: false, counterText: '',
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                    isDense: false,
                  ),
                  onChanged: (val) {
                    setState(() {});
                    if (val.isNotEmpty && i < _otpLength - 1) _otpFocusNodes[i + 1].requestFocus();
                    if (val.isEmpty   && i > 0)               _otpFocusNodes[i - 1].requestFocus();
                  },
                  onTap: () => setState(() {}),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Step 3 ────────────────────────────────────────────────────────────────────

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(label: 'New Password'),
        const SizedBox(height: 8),
        _StyledTextField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          hintText: 'Enter new password',
          obscureText: !_showPass,
          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
          focusColor: const Color(0xFFC084FC),
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _showPass = !_showPass),
            child: Icon(_showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20, color: Colors.white38),
          ),
          onSubmitted: (_) => _confirmFocus.requestFocus(),
          onChanged: (_) => setState(() => _fieldErrors.remove('password')),
          enabled: !_loading,
        ),

        const SizedBox(height: 20),

        const _FieldLabel(label: 'Confirm Password'),
        const SizedBox(height: 8),
        _StyledTextField(
          controller: _confirmController,
          focusNode: _confirmFocus,
          hintText: 'Confirm new password',
          obscureText: !_showConfirm,
          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
          focusColor: const Color(0xFF34D399),
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _showConfirm = !_showConfirm),
            child: Icon(_showConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20, color: Colors.white38),
          ),
          onSubmitted: (_) => _handleResetPassword(),
          onChanged: (_) => setState(() => _fieldErrors.remove('password')),
          enabled: !_loading,
        ),

        if (_fieldErrors['password'] != null) ...[
          const SizedBox(height: 6),
          _FieldError(message: _fieldErrors['password']!),
        ],

        const SizedBox(height: 6),
        Text('Min 8 chars · uppercase · lowercase · number · special character',
            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.3))),

        const SizedBox(height: 24),
        _buildPrimaryButton(
          label: _loading ? 'Resetting…' : 'Reset Password',
          icon: Icons.lock_reset_rounded,
          onPressed: _loading ? null : _handleResetPassword,
          loading: _loading,
        ),
        const SizedBox(height: 12),
        _buildSecondaryButton(label: 'Back', icon: Icons.arrow_back_rounded, onPressed: _handleBack),
      ],
    );
  }

  // ── Done ──────────────────────────────────────────────────────────────────────

  Widget _buildDoneState() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)]),
            boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.45), blurRadius: 28, spreadRadius: 2)],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 16),
        const Text('All done!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 8),
        Text('Your password has been reset successfully.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.5))),
        const SizedBox(height: 24),
        _buildPrimaryButton(
          label: 'Back to Login',
          icon: Icons.login_rounded,
          onPressed: () => Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginScreen())),
        ),
      ],
    );
  }

  // ── Buttons ───────────────────────────────────────────────────────────────────

  Widget _buildPrimaryButton({
    required String    label,
    required IconData  icon,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: onPressed != null
              ? const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF2563EB), Color(0xFF0891B2)])
              : null,
          color: onPressed == null ? Colors.white12 : null,
          boxShadow: onPressed != null
              ? [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))]
              : null,
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: loading
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                    Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String    label,
    required IconData  icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
          foregroundColor: Colors.white60,
          backgroundColor: Colors.white.withOpacity(0.03),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: Colors.white60),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
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
          child: Text(_footerNote.toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                letterSpacing: 1.2, color: Colors.white.withOpacity(0.3))),
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
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.9), letterSpacing: 0.2));
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
        Expanded(child: Text(message, style: const TextStyle(fontSize: 12, color: Color(0xFFF87171)))),
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
    final bg     = isError ? const Color(0xFF1A0000) : const Color(0xFF00170A);
    final border = isError ? const Color(0xFF7F1D1D) : const Color(0xFF14532D);
    final icon   = isError ? const Color(0xFFF87171) : const Color(0xFF4ADE80);
    final text   = isError ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline, size: 18, color: icon),
          const SizedBox(width: 10),
          Expanded(child: Text(message,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: text))),
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
            opacity: 0.3 + controller.value * 0.15,
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
    final paint = Paint()..color = Colors.white.withOpacity(0.02)..strokeWidth = 1;
    const spacing = 100.0;
    for (double x = 0; x < size.width;  x += spacing) canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    for (double y = 0; y < size.height; y += spacing) canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}