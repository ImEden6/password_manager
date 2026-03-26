import 'package:flutter/material.dart';
import '../data/auth_service.dart';

/// PIN setup screen shown on first launch.
///
/// Guides user to create a 4-8 digit master PIN with confirmation.
/// Uses a custom numeric keypad with 48dp touch targets.
class PinSetupScreen extends StatefulWidget {
  final AuthService authService;
  final VoidCallback onSetupComplete;

  const PinSetupScreen({
    super.key,
    required this.authService,
    required this.onSetupComplete,
  });

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  late final TextEditingController _pinController;
  late final FocusNode _focusNode;
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pinController = TextEditingController();
    _focusNode = FocusNode();

    // Explicitly request focus after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {
      _error = null;
      if (_isConfirming) {
        _confirmPin = value;
      } else {
        _pin = value;
      }
    });
  }

  Future<void> _onSubmit() async {
    if (!_isConfirming) {
      if (_pin.length < 4) {
        setState(() => _error = 'PIN must be at least 4 digits');
        return;
      }
      setState(() {
        _isConfirming = true;
        _pinController.clear();
      });
      _focusNode.requestFocus();
      return;
    }

    if (_confirmPin != _pin) {
      setState(() {
        _error = 'PINs do not match. Try again.';
        _confirmPin = '';
        _pinController.clear();
      });
      _focusNode.requestFocus();
      return;
    }

    await widget.authService.setPin(_pin);
    widget.onSetupComplete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentPin = _isConfirming ? _confirmPin : _pin;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                _isConfirming ? 'Confirm Your PIN' : 'Create a Master PIN',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _isConfirming
                    ? 'Enter the same PIN again'
                    : '4-8 digits to protect your passwords',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // PIN dots.
              GestureDetector(
                onTap: () => _focusNode.requestFocus(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    8,
                    (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < currentPin.length
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        border: i < currentPin.length
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
                  showCursor: false, // Hidden but functional
                  enableInteractiveSelection: false,

                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  onChanged: _onChanged,
                  onSubmitted: (_) => _onSubmit(),
                  decoration: const InputDecoration(counterText: ''),
                ),
              ),

              if (_error != null)
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),

              const Spacer(),

              // Submit button.
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: currentPin.length >= 4 ? _onSubmit : null,
                  child: Text(_isConfirming ? 'Confirm' : 'Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
