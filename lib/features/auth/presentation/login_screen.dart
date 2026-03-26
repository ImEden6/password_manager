import 'dart:async';

import 'package:flutter/material.dart';
import '../data/auth_service.dart';

/// Login screen with PIN entry, biometric auth, and lockout countdown.
///
/// After 3 failed PIN attempts, the user is locked out for 30 seconds
/// with a visible countdown timer.
class LoginScreen extends StatefulWidget {
  final AuthService authService;
  final VoidCallback onLoginSuccess;

  const LoginScreen({
    super.key,
    required this.authService,
    required this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _pinController;
  late final FocusNode _focusNode;
  String _pin = '';
  String? _error;
  bool _isLockedOut = false;
  int _remainingLockSeconds = 0;
  Timer? _lockTimer;

  @override
  void initState() {
    super.initState();
    _pinController = TextEditingController();
    _focusNode = FocusNode();
    _checkLockout();
    
    // Explicitly request focus after the first frame to ensure keyboard shows up.
    // This is more robust than just 'autofocus: true' on Android 15.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isLockedOut) {
        _focusNode.requestFocus();
      }
    });

    // Delay biometric attempt slightly to avoid focus collision on startup.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _attemptBiometric();
    });
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _checkLockout() async {
    final lockEnd = await widget.authService.getLockoutEnd();
    if (lockEnd != null) {
      _startLockoutTimer(lockEnd);
    }
  }

  void _startLockoutTimer(DateTime lockEnd) {
    setState(() {
      _isLockedOut = true;
      _remainingLockSeconds =
          lockEnd.difference(DateTime.now()).inSeconds.clamp(0, AuthService.lockoutSeconds);
    });

    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining =
          lockEnd.difference(DateTime.now()).inSeconds.clamp(0, AuthService.lockoutSeconds);
      if (remaining <= 0) {
        timer.cancel();
        setState(() {
          _isLockedOut = false;
          _remainingLockSeconds = 0;
          _error = null;
        });
        _focusNode.requestFocus();
      } else {
        setState(() => _remainingLockSeconds = remaining);
      }
    });
  }

  Future<void> _attemptBiometric() async {
    if (await widget.authService.isBiometricEnabled() &&
        await widget.authService.isBiometricAvailable()) {
      final success = await widget.authService.authenticateWithBiometrics();
      if (success) {
        widget.onLoginSuccess();
      }
    }
  }

  Future<void> _onSubmit() async {
    if (_isLockedOut || _pin.length < 4) return;

    final success = await widget.authService.verifyPin(_pin);
    if (success) {
      widget.onLoginSuccess();
    } else {
      final lockEnd = await widget.authService.getLockoutEnd();
      if (lockEnd != null) {
        _startLockoutTimer(lockEnd);
        setState(() {
          _error = 'Too many attempts. Locked for ${AuthService.lockoutSeconds}s.';
          _pin = '';
          _pinController.clear();
        });
      } else {
        final remaining = await widget.authService.getRemainingAttempts();
        setState(() {
          _error = 'Wrong PIN. $remaining attempts remaining.';
          _pin = '';
          _pinController.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lock icon with hero animation.
              Hero(
                tag: 'lock_icon',
                child: Icon(
                  Icons.shield_outlined,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome Back',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your PIN to unlock',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // PIN dots.
              GestureDetector(
                onTap: () => _focusNode.requestFocus(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    8,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < _pin.length
                            ? (_error != null
                                ? theme.colorScheme.error
                                : theme.colorScheme.primary)
                            : theme.colorScheme.surfaceContainerHighest,
                        border: i < _pin.length
                            ? null
                            : Border.all(
                                color: theme.colorScheme.outline, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Hidden TextField to trigger native numeric keyboard.
              SizedBox(
                height: 0,
                width: 0,
                child: TextField(
                  controller: _pinController,
                  focusNode: _focusNode,
                  autofocus: true,
                  showCursor: false, // Hidden but focusable
                  enableInteractiveSelection: false,

                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  onChanged: (v) => setState(() => _pin = v),
                  onSubmitted: (_) => _onSubmit(),
                  decoration: const InputDecoration(counterText: ''),
                ),
              ),

              // Error or lockout message.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isLockedOut
                    ? Text(
                        'Locked. Try again in ${_remainingLockSeconds}s',
                        key: ValueKey('lockout_$_remainingLockSeconds'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : _error != null
                        ? Text(
                            _error!,
                            key: ValueKey(_error),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          )
                        : const SizedBox.shrink(),
              ),

              const Spacer(),

              // Submit + biometric buttons row.
              Row(
                children: [
                  // Biometric button.
                  FutureBuilder<bool>(
                    future: widget.authService.isBiometricEnabled(),
                    builder: (context, snapshot) {
                      if (snapshot.data != true) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: IconButton.filled(
                          icon: const Icon(Icons.fingerprint),
                          iconSize: 32,
                          onPressed: _isLockedOut ? null : _attemptBiometric,
                          style: IconButton.styleFrom(
                            minimumSize: const Size(56, 56),
                          ),
                        ),
                      );
                    },
                  ),

                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed:
                            (!_isLockedOut && _pin.length >= 4) ? _onSubmit : null,
                        child: const Text('Unlock'),
                      ),
                    ),
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
