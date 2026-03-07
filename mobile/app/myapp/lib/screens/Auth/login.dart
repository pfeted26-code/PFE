// Import dart:math library — available for math operations if ever needed
import 'dart:math' as math;

// Import Flutter's core UI framework — provides all widgets, colors, animations, themes
import 'package:flutter/material.dart';

// Import the ForgotPasswordScreen from the local forget.dart file
import 'forget.dart';




// ─── Login Screen ─────────────────────────────────────────────────────────────

// StatefulWidget because this screen has dynamic state (loading, errors, animations)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key}); // Passes the widget key up to the parent class

  @override
  // Creates and returns the mutable state object for this widget
  State<LoginScreen> createState() => _LoginScreenState();
}

// The state class — TickerProviderStateMixin allows using multiple AnimationControllers at once
class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {

  // ── Text Controllers ────────────────────────────────────────────────────────

  // Controls the email text field — used to read/write its value
  final _emailController = TextEditingController();

  // Controls the password text field — used to read/write its value
  final _passwordController = TextEditingController();

  // Tracks focus (active/inactive) state of the email field
  final _emailFocus = FocusNode();

  // Tracks focus (active/inactive) state of the password field
  final _passwordFocus = FocusNode();

  // ── UI State Variables ──────────────────────────────────────────────────────

  // True while the simulated login request is running — shows a spinner on the button
  bool _loading = false;

  // Toggles between showing password as plain text or hidden dots
  bool _showPassword = false;

  // Holds a global error message to display (null means no error shown)
  String? _error;

  // Holds a success message to display after successful login (null means hidden)
  String? _success;

  // Maps field names ('email', 'password') to their individual validation error messages
  final Map<String, String> _fieldErrors = {};

  // ── Animation Controllers ───────────────────────────────────────────────────

  // Controls the pulsing animation of the first background blob (4s cycle)
  late AnimationController _blob1Controller;

  // Controls the pulsing animation of the second background blob (5s cycle)
  late AnimationController _blob2Controller;

  // Controls the pulsing animation of the third background blob (6s cycle)
  late AnimationController _blob3Controller;

  // Controls the logo scale animation triggered on mouse hover
  late AnimationController _logoController;

  // The actual scale value (1.0 → 1.1) driven by _logoController
  late Animation<double> _logoScale;

  // ── Lifecycle: initState ────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState(); // Always call super.initState() first

    // Set up blob 1: 4-second animation that loops back and forth (reverse: true = ping-pong)
    _blob1Controller = AnimationController(
      vsync: this, // 'this' provides the ticker — requires TickerProviderStateMixin
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true); // Start looping immediately

    // Set up blob 2: same but 5-second cycle for a slightly different rhythm
    _blob2Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    // Set up blob 3: slowest blob at 6 seconds for layered depth effect
    _blob3Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    // Set up logo animation: 600ms duration, does NOT auto-play (triggered by hover)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Define the scale animation: smoothly scales from 1.0 to 1.1 with ease-in-out curve
    _logoScale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );
  }

  // ── Lifecycle: dispose ──────────────────────────────────────────────────────

  @override
  void dispose() {
    // Dispose all controllers to free memory and avoid memory leaks when screen is removed
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _blob1Controller.dispose();
    _blob2Controller.dispose();
    _blob3Controller.dispose();
    _logoController.dispose();
    super.dispose(); // Always call super.dispose() last
  }

  // ── Validation ──────────────────────────────────────────────────────────────

  // Validates the form fields — returns true if valid, false if any errors found
  bool _validate() {
    _fieldErrors.clear(); // Clear previous validation errors before re-checking

    final email = _emailController.text.trim();    // Read email and remove whitespace
    final password = _passwordController.text;     // Read password as-is (spaces allowed)

    // Check if email is empty
    if (email.isEmpty) {
      _fieldErrors['email'] = 'Email is required';
    // Check if email matches a standard email format using regex
    } else if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      _fieldErrors['email'] = 'Invalid email address';
    }

    // Check if password is empty
    if (password.isEmpty) {
      _fieldErrors['password'] = 'Password is required';
    // Check if password meets minimum length requirement
    } else if (password.length < 6) {
      _fieldErrors['password'] = 'Password must be at least 6 characters';
    }

    setState(() {}); // Trigger a UI rebuild so error messages appear under fields
    return _fieldErrors.isEmpty; // Return true only if there are no errors
  }

  // ── Submit Handler ──────────────────────────────────────────────────────────

  // Called when the user taps "Sign In" — validates then simulates a login
  Future<void> _handleSubmit() async {
    // Clear any previously shown error or success messages
    setState(() {
      _error = null;
      _success = null;
    });

    // Stop here if validation fails — error messages will be shown by _validate()
    if (!_validate()) return;

    // Show the loading spinner on the button
    setState(() => _loading = true);

    // Simulate a 1-second network delay for realistic UI feedback
    await Future.delayed(const Duration(seconds: 1));

    // TODO: Replace this block with a real API call when the backend is ready
    // For now, just show a success message after the delay
    setState(() {
      _loading = false;                              // Hide the spinner
      _success = 'Login successful! Redirecting...'; // Show the success banner
    });
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack( // Stack layers multiple widgets on top of each other
        children: [

          // ── Layer 1: Dark gradient background ──────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,    // Gradient starts at top-left
                end: Alignment.bottomRight,  // Gradient ends at bottom-right
                colors: [
                  Color(0xFF020617), // slate-950 — very dark navy at top-left
                  Color(0xFF0F172A), // slate-900 — slightly lighter in the center
                  Color(0xFF020617), // slate-950 — back to dark at bottom-right
                ],
              ),
            ),
          ),

          // ── Layer 2: Animated glowing blob — top-left area ─────────────────
          _AnimatedBlob(
            controller: _blob1Controller,           // Drives this blob's pulse animation
            alignment: const Alignment(-0.5, -0.5), // Positioned in the top-left quadrant
            colors: const [
              Color(0x4D7C3AED), // Purple at 30% opacity
              Color(0x4D2563EB), // Blue at 30% opacity
              Color(0x4D0891B2), // Cyan at 30% opacity
            ],
          ),

          // ── Layer 3: Animated glowing blob — bottom-right area ─────────────
          _AnimatedBlob(
            controller: _blob2Controller,          // Drives this blob's pulse animation
            alignment: const Alignment(0.5, 0.5),  // Positioned in the bottom-right quadrant
            colors: const [
              Color(0x4DDC2626), // Red/pink at 30% opacity
              Color(0x4D7C3AED), // Purple at 30% opacity
              Color(0x4D2563EB), // Blue at 30% opacity
            ],
          ),

          // ── Layer 4: Large animated glowing blob — centered ─────────────────
          _AnimatedBlob(
            controller: _blob3Controller,   // Drives this blob's pulse animation
            alignment: Alignment.center,    // Centered on the screen
            colors: const [
              Color(0x330891B2), // Cyan at ~20% opacity
              Color(0x332563EB), // Blue at ~20% opacity
            ],
            size: 700, // Larger than default (400) — creates a wide soft glow
          ),

          // ── Layer 5: Faint grid lines drawn over the background ─────────────
          CustomPaint(
            painter: _GridPainter(), // Custom painter that draws horizontal/vertical lines
            size: Size.infinite,     // Covers the entire screen
          ),

          // ── Layer 6: The login card — centered and scrollable ───────────────
          Center(
            child: SingleChildScrollView( // Allows scrolling on small screens
              padding: const EdgeInsets.all(24), // 24px padding around the card
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440), // Card max width: 440px
                child: _buildCard(), // Renders the login card
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Card Builder ──────────────────────────────────────────────────────────

  // Builds the semi-transparent frosted card that contains all login UI elements
  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24), // Smooth rounded corners on the card
        border: Border.all(
          color: const Color(0x801E293B), // Slate-800 at 50% opacity — subtle border
          width: 1,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x990F172A), // Slate-900 at ~60% opacity — semi-transparent dark card
            Color(0x990F172A),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x337C3AED), // Purple glow behind the card
            blurRadius: 60,           // Large blur for a wide soft shadow
            spreadRadius: -10,        // Negative spread keeps it tight to the card
            offset: Offset(0, 20),    // Shadow appears 20px below the card
          ),
        ],
      ),
      // ClipRRect ensures the inner decoration respects the card's rounded corners
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          // Inner gradient adds a subtle purple-to-cyan color sheen on the card surface
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0x1A7C3AED), // Purple at 10% opacity — top-left tint
                Colors.transparent, // Transparent in the middle
                Color(0x1A0891B2), // Cyan at 10% opacity — bottom-right tint
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32), // 32px inner padding on all sides
            child: Column(
              mainAxisSize: MainAxisSize.min, // Column only as tall as its children need
              children: [
                _buildHeader(),          // Logo + "Welcome Back" title + subtitle
                const SizedBox(height: 32),
                _buildAlerts(),          // Error/success banners (only visible when needed)
                _buildForm(),            // Email + password fields + Sign In button
                const SizedBox(height: 24),
                _buildDivider(),         // "EDUNEX PORTAL" branded divider
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Header Builder ────────────────────────────────────────────────────────

  // Builds the logo icon with hover animation, the gradient title, and the subtitle
  Widget _buildHeader() {
    return Column(
      children: [

        // Logo container — scales up slightly when the mouse hovers over it
        MouseRegion(
          onEnter: (_) => _logoController.forward(),  // Play scale-up animation on hover
          onExit: (_) => _logoController.reverse(),   // Reverse animation when hover ends
          child: ScaleTransition(
            scale: _logoScale, // Connects the animation value to the widget's scale
            child: Container(
              width: 96,  // Logo box width in logical pixels
              height: 96, // Logo box height in logical pixels
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24), // Rounded square shape
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF7C3AED), // Purple
                    Color(0xFF2563EB), // Blue
                    Color(0xFF0891B2), // Cyan
                  ],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x807C3AED), // Purple glow at 50% opacity
                    blurRadius: 24,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Color(0x600891B2), // Cyan glow at 37% opacity — spreads wider
                    blurRadius: 40,
                    spreadRadius: -5,
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.2), // Subtle white border for glass effect
                  width: 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [

                  // Inner highlight — makes the top-left corner look lit (3D/glass effect)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.2), // Bright top-left highlight
                            Colors.transparent,             // Fades to transparent
                          ],
                        ),
                      ),
                    ),
                  ),

                  // School/graduation cap icon centered in the logo box
                  const Icon(
                    Icons.school_rounded,
                    size: 48,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.white38, // Soft white glow around the icon
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // "Welcome Back" title with a purple → blue → cyan gradient text effect
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFC084FC), // purple-400
              Color(0xFF60A5FA), // blue-400
              Color(0xFF22D3EE), // cyan-400
            ],
          ).createShader(bounds), // Applies gradient as a paint shader over the text area
          child: const Text(
            'Welcome Back',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800, // Extra bold
              color: Colors.white,          // Must be white so ShaderMask can color it
              letterSpacing: -0.5,          // Tighter letter spacing for a modern look
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Subtitle below the title — dimmed to create visual hierarchy
        Text(
          'Enter your credentials to access your portal',
          style: TextStyle(
            fontSize: 15,
            color: Colors.white.withOpacity(0.5), // 50% opacity white
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ─── Alerts Builder ────────────────────────────────────────────────────────

  // Renders error or success banners — only visible when state is not null
  Widget _buildAlerts() {
    return Column(
      children: [
        // Show red error banner only if _error has a value
        if (_error != null) ...[
          _Alert(message: _error!, isError: true), // Red styled alert
          const SizedBox(height: 16),
        ],
        // Show green success banner only if _success has a value
        if (_success != null) ...[
          _Alert(message: _success!, isError: false), // Green styled alert
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  // ─── Form Builder ──────────────────────────────────────────────────────────

  // Builds the full form: email field, password field, and Sign In button
  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Align labels to the left edge
      children: [

        // Email section
        _FieldLabel(label: 'Email Address', opacity: 0.4), // Dimmed label above the field
        const SizedBox(height: 8),
        _buildEmailField(), // The styled email text input
        // Show inline validation error below email field if present
        if (_fieldErrors['email'] != null) ...[
          const SizedBox(height: 6),
          _FieldError(message: _fieldErrors['email']!), // Red error with icon
        ],

        const SizedBox(height: 20),

        // Password label row — label on the left, forgot password link on the right
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _FieldLabel(label: 'Password', opacity: 0.9), // Bright label on the left
            GestureDetector(
              onTap: () {
                // Navigate to ForgotPasswordScreen when the link is tapped
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                );
              },
              child: const Text(
                'Forget password?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF60A5FA), // Blue signals this is a tappable link
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildPasswordField(), // The styled password text input
        // Show inline validation error below password field if present
        if (_fieldErrors['password'] != null) ...[
          const SizedBox(height: 6),
          _FieldError(message: _fieldErrors['password']!), // Red error with icon
        ],

        const SizedBox(height: 24),

        _buildSubmitButton(), // The gradient "Sign In" button
      ],
    );
  }

  // ─── Email Field ───────────────────────────────────────────────────────────

  Widget _buildEmailField() {
    return _StyledTextField(
      controller: _emailController,              // Binds the email text controller
      focusNode: _emailFocus,                    // Binds the email focus node
      hintText: 'you@example.com',               // Placeholder shown when empty
      keyboardType: TextInputType.emailAddress,  // Shows email keyboard on mobile
      prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20), // Envelope icon on left
      focusColor: const Color(0xFF60A5FA),       // Blue glow when field is focused
      onSubmitted: (_) => _passwordFocus.requestFocus(), // Move focus to password on "next"
      onChanged: (_) {
        // Clear the email validation error as soon as the user starts typing again
        if (_fieldErrors.containsKey('email')) {
          setState(() => _fieldErrors.remove('email'));
        }
      },
      enabled: !_loading, // Disable the field while loading simulation is running
    );
  }

  // ─── Password Field ────────────────────────────────────────────────────────

  Widget _buildPasswordField() {
    return _StyledTextField(
      controller: _passwordController,       // Binds the password text controller
      focusNode: _passwordFocus,             // Binds the password focus node
      hintText: 'Enter your password',       // Placeholder shown when empty
      obscureText: !_showPassword,           // Hides text as dots when _showPassword is false
      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20), // Lock icon on left
      focusColor: const Color(0xFFC084FC),   // Purple glow when field is focused
      // Eye icon on right side — tapping it toggles password visibility
      suffixIcon: GestureDetector(
        onTap: () => setState(() => _showPassword = !_showPassword), // Toggle visibility
        child: Icon(
          _showPassword
              ? Icons.visibility_off_outlined // "Hide" icon when password is visible
              : Icons.visibility_outlined,    // "Show" icon when password is hidden
          size: 20,
          color: Colors.white38, // Dimmed so it doesn't distract from input
        ),
      ),
      onSubmitted: (_) => _handleSubmit(), // Submit the form when keyboard "done" is pressed
      onChanged: (_) {
        // Clear the password validation error as soon as the user starts typing again
        if (_fieldErrors.containsKey('password')) {
          setState(() => _fieldErrors.remove('password'));
        }
      },
      enabled: !_loading, // Disable the field while loading simulation is running
    );
  }

  // ─── Submit Button ─────────────────────────────────────────────────────────

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity, // Stretch to full card width
      height: 52,             // Fixed height for a comfortable tap target
      child: DecoratedBox(
        // Gradient background — ElevatedButton doesn't natively support gradients
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF7C3AED), // Purple
              Color(0xFF2563EB), // Blue
              Color(0xFF0891B2), // Cyan
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.4), // Purple glow below button
              blurRadius: 20,
              offset: const Offset(0, 8), // Shadow 8px below the button
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _loading ? null : _handleSubmit, // null disables button while loading
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent, // Let the gradient show through
            shadowColor: Colors.transparent,      // Disable default Material shadow
            foregroundColor: Colors.white,         // White text and ripple color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Match the outer container radius
            ),
          ),
          // Show spinner while loading, otherwise show "Sign In" text
          child: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,                                 // Thin spinner line
                    valueColor: AlwaysStoppedAnimation(Colors.white), // White spinner
                  ),
                )
              : const Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3, // Slight spacing for cleaner button text
                  ),
                ),
        ),
      ),
    );
  }

  // ─── Divider Builder ───────────────────────────────────────────────────────

  // Builds the "EDUNEX PORTAL" branded divider at the bottom of the card
  Widget _buildDivider() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Faint horizontal line spanning the full card width
        Divider(color: Colors.white.withOpacity(0.08)), // Very faint white line

        // Brand label centered over the line — its background hides the line behind it
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.9), // Matches card bg to hide line behind it
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'EDUNEX PORTAL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,                       // Wide spacing gives a badge/stamp feel
              color: Colors.white.withOpacity(0.35),  // Very dim — subtle watermark branding
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

// A styled, animated text input that glows on focus and supports prefix/suffix icons
class _StyledTextField extends StatefulWidget {
  final TextEditingController controller;  // Reads and controls the field's text value
  final FocusNode focusNode;               // Detects whether the field is currently focused
  final String hintText;                   // Placeholder text shown when the field is empty
  final bool obscureText;                  // If true, hides the text (used for passwords)
  final TextInputType? keyboardType;       // Sets the keyboard type (email, number, etc.)
  final Widget prefixIcon;                 // Icon on the left inside the field
  final Widget? suffixIcon;                // Optional icon on the right (e.g., eye for password)
  final Color focusColor;                  // Border and glow color when the field is active
  final ValueChanged<String>? onSubmitted; // Callback when user presses "done" on keyboard
  final ValueChanged<String>? onChanged;   // Callback every time the text changes
  final bool enabled;                      // False = greyed out and non-interactive

  const _StyledTextField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    this.obscureText = false,    // Default: text is visible
    this.keyboardType,
    required this.prefixIcon,
    this.suffixIcon,
    required this.focusColor,
    this.onSubmitted,
    this.onChanged,
    this.enabled = true,         // Default: field is enabled
  });

  @override
  State<_StyledTextField> createState() => _StyledTextFieldState();
}

// State for _StyledTextField — tracks focus to animate the border and glow
class _StyledTextFieldState extends State<_StyledTextField> {
  bool _focused = false; // True when this field currently has keyboard focus

  @override
  void initState() {
    super.initState();
    // Listen for focus changes and rebuild the widget whenever focus state changes
    widget.focusNode.addListener(() {
      setState(() => _focused = widget.focusNode.hasFocus); // hasFocus = true when active
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200), // Animate border/glow changes smoothly
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          // Highlight border with focus color when active, faint white when inactive
          color: _focused
              ? widget.focusColor.withOpacity(0.7)
              : Colors.white.withOpacity(0.1),
          width: _focused ? 1.5 : 1, // Slightly thicker border when focused
        ),
        color: const Color(0xFF1E293B).withOpacity(0.5), // Semi-transparent dark field background
        // Glow shadow only appears when the field is focused
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: widget.focusColor.withOpacity(0.15), // Soft colored outer glow
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : null, // No glow when not focused
      ),
      child: TextField(
        controller: widget.controller,      // Bind the external text controller
        focusNode: widget.focusNode,        // Bind the external focus node
        obscureText: widget.obscureText,    // Show or hide the text
        keyboardType: widget.keyboardType,  // Set keyboard type (email, etc.)
        onSubmitted: widget.onSubmitted,    // Forward the submit callback
        onChanged: widget.onChanged,        // Forward the text change callback
        enabled: widget.enabled,            // Enable or disable the field
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFFE2E8F0), // Slate-200 — light grey text readable on dark background
        ),
        decoration: InputDecoration(
          hintText: widget.hintText, // Placeholder text
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)), // Very faint placeholder

          // Prefix icon — color changes based on focus state
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10), // Space around the icon
            child: IconTheme(
              data: IconThemeData(
                color: _focused ? widget.focusColor : Colors.white38, // Colored when focused
                size: 20,
              ),
              child: widget.prefixIcon, // The icon widget passed from the parent
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0), // Remove default icon padding
          // Suffix icon rendered only if provided
          suffixIcon: widget.suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: widget.suffixIcon,
                )
              : null, // Nothing on the right if no suffix icon provided
          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0), // Remove default icon padding
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16, // Comfortable tap target height inside the field
          ),
          border: InputBorder.none, // Remove default underline — we draw our own border
        ),
      ),
    );
  }
}

// A small label displayed above each form field
class _FieldLabel extends StatelessWidget {
  final String label;       // The text to display
  final double opacity;     // Brightness of the label (0.0 = invisible, 1.0 = fully white)
  const _FieldLabel({required this.label, this.opacity = 0.9});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,              // Semi-bold for label feel
        color: Colors.white.withOpacity(opacity), // Dynamic brightness
        letterSpacing: 0.2,                       // Slight spacing for readability
      ),
    );
  }
}

// A small red error message shown below a field when validation fails
class _FieldError extends StatelessWidget {
  final String message; // The validation error message text
  const _FieldError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.error_outline, size: 14, color: Color(0xFFF87171)), // Small red warning icon
        const SizedBox(width: 6), // Space between icon and text
        Text(
          message,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFFF87171), // Red-400 — matches the icon color
          ),
        ),
      ],
    );
  }
}

// A colored banner that shows either an error (red) or success (green) message
class _Alert extends StatelessWidget {
  final String message; // The message text to display
  final bool isError;   // True = red error style, False = green success style
  const _Alert({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    // Choose colors dynamically based on whether this is an error or success alert
    final bgColor     = isError ? const Color(0xFF1A0000) : const Color(0xFF00170A); // Dark red or dark green bg
    final borderColor = isError ? const Color(0xFF7F1D1D) : const Color(0xFF14532D); // Red or green border
    final iconColor   = isError ? const Color(0xFFF87171) : const Color(0xFF4ADE80); // Red-400 or green-400 icon
    final textColor   = isError ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0); // Light red or light green text
    final icon        = isError ? Icons.error_outline : Icons.check_circle_outline;  // Warning or checkmark icon

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.6),              // Semi-transparent tinted background
        borderRadius: BorderRadius.circular(10),       // Slightly rounded corners
        border: Border.all(color: borderColor.withOpacity(0.5)), // Colored border matching alert type
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor), // Status icon (error or success)
          const SizedBox(width: 10),              // Space between icon and message
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textColor, // Text color matches alert type
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Animated Blob ────────────────────────────────────────────────────────────

// A pulsing circular gradient blob used as a decorative background element
class _AnimatedBlob extends StatelessWidget {
  final AnimationController controller; // Drives the opacity pulse animation
  final Alignment alignment;            // Where on the screen to position the blob
  final List<Color> colors;             // Gradient colors applied from center outward
  final double size;                    // Diameter of the circle in logical pixels

  const _AnimatedBlob({
    required this.controller,
    required this.alignment,
    required this.colors,
    this.size = 400, // Default diameter is 400px if not specified
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill( // Fill the full Stack so alignment positions the blob correctly
      child: AnimatedBuilder(
        animation: controller, // Rebuilds every animation frame
        builder: (_, __) => Align(
          alignment: alignment, // Position the blob at the specified screen location
          child: Opacity(
            // Opacity oscillates between 0.3 and 0.45 — creates a breathing pulse effect
            opacity: 0.3 + (controller.value * 0.15),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,                    // Perfect circle shape
                gradient: RadialGradient(colors: colors),  // Gradient radiates from center outward
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Grid Painter ─────────────────────────────────────────────────────────────

// Custom painter that draws an extremely faint grid as a background texture
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Define the paint style for the grid lines
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02) // Nearly invisible — just a subtle texture
      ..strokeWidth = 1;                        // 1-pixel thin lines

    const spacing = 100.0; // Distance between each grid line in logical pixels

    // Draw vertical lines across the full screen width
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint); // Line from top to bottom
    }

    // Draw horizontal lines across the full screen height
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint); // Line from left to right
    }
  }

  @override
  // Returns false — the grid never changes so it never needs to be repainted
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}