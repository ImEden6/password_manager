import 'package:flutter/material.dart';

/// Visual password strength indicator bar.
///
/// Evaluates strength based on length, character variety, and common patterns.
/// Displays a color-coded bar with label: Weak, Medium, Strong, Very Strong.
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final strength = _calculateStrength(password);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Animated strength bar.
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 6,
            child: LinearProgressIndicator(
              value: strength.value,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(strength.color),
            ),
          ),
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            strength.label,
            key: ValueKey(strength.label),
            style: theme.textTheme.labelSmall?.copyWith(
              color: strength.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Calculate password strength from 0.0 to 1.0.
  static _PasswordStrength _calculateStrength(String password) {
    if (password.isEmpty) {
      return _PasswordStrength(0, 'Enter a password', Colors.grey);
    }

    double score = 0;

    // Length scoring.
    if (password.length >= 4) score += 0.1;
    if (password.length >= 8) score += 0.15;
    if (password.length >= 12) score += 0.15;
    if (password.length >= 16) score += 0.1;

    // Character variety.
    if (password.contains(RegExp(r'[a-z]'))) score += 0.1;
    if (password.contains(RegExp(r'[A-Z]'))) score += 0.1;
    if (password.contains(RegExp(r'[0-9]'))) score += 0.1;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score += 0.15;

    // Bonus for mixed types.
    int types = 0;
    if (password.contains(RegExp(r'[a-z]'))) types++;
    if (password.contains(RegExp(r'[A-Z]'))) types++;
    if (password.contains(RegExp(r'[0-9]'))) types++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) types++;
    if (types >= 3) score += 0.05;

    score = score.clamp(0.0, 1.0);

    if (score < 0.3) {
      return _PasswordStrength(score, 'Weak', const Color(0xFFE53935));
    } else if (score < 0.55) {
      return _PasswordStrength(score, 'Medium', const Color(0xFFFFA726));
    } else if (score < 0.8) {
      return _PasswordStrength(score, 'Strong', const Color(0xFF66BB6A));
    } else {
      return _PasswordStrength(score, 'Very Strong', const Color(0xFF43A047));
    }
  }
}

class _PasswordStrength {
  final double value;
  final String label;
  final Color color;

  const _PasswordStrength(this.value, this.label, this.color);
}
