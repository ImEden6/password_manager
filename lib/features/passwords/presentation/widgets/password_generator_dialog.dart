import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dialog for generating random passwords with configurable options, vals that gen'd passwords meet the requirements that are seleccted, 
/// and shows a warning if the user disables character types that produce weak passwords.
class PasswordGeneratorDialog extends StatefulWidget {
  const PasswordGeneratorDialog({super.key});

  @override
  State<PasswordGeneratorDialog> createState() =>
      _PasswordGeneratorDialogState();
}

class _PasswordGeneratorDialogState extends State<PasswordGeneratorDialog> {
  double _length = 16;
  bool _uppercase = true;
  bool _lowercase = true;
  bool _digits = true;
  bool _special = true;
  String _generated = '';

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    final random = Random.secure();
    String chars = '';
    List<String> required = [];

    if (_lowercase) {
      chars += 'abcdefghijklmnopqrstuvwxyz';
      required.add('abcdefghijklmnopqrstuvwxyz');
    }
    if (_uppercase) {
      chars += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      required.add('ABCDEFGHIJKLMNOPQRSTUVWXYZ');
    }
    if (_digits) {
      chars += '0123456789';
      required.add('0123456789');
    }
    if (_special) {
      chars += '!@#\$%^&*()-_=+[]{}|;:,.<>?';
      required.add('!@#\$%^&*()-_=+[]{}|;:,.<>?');
    }

    if (chars.isEmpty) {
      chars = 'abcdefghijklmnopqrstuvwxyz';
      required.add(chars);
    }

    final len = _length.round();

    // Ensure at least one character from each required group cause 
    List<String> password = [];
    for (final group in required) {
      password.add(group[random.nextInt(group.length)]);
    }

    // Fill remaining length with random chars 
    for (int i = password.length; i < len; i++) {
      password.add(chars[random.nextInt(chars.length)]);
    }

    // Shuffle to just avoid predictable positions
    password.shuffle(random);

    setState(() {
      _generated = password.join();
    });
  }

  bool get _isWeak {
    int types = 0;
    if (_lowercase) types++;
    if (_uppercase) types++;
    if (_digits) types++;
    if (_special) types++;
    return types < 2 || _length < 8;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Generate Password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Generated password display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                _generated,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Length slider.
            Text('Length: ${_length.round()}',
                style: theme.textTheme.titleSmall),
            Slider(
              value: _length,
              min: 4,
              max: 64,
              divisions: 60,
              label: _length.round().toString(),
              onChanged: (v) {
                setState(() => _length = v);
                _generate();
              },
            ),

            // Character type toggles
            SwitchListTile(
              dense: true,
              title: const Text('Lowercase (a-z)'),
              value: _lowercase,
              onChanged: (v) {
                setState(() => _lowercase = v);
                _generate();
              },
            ),
            SwitchListTile(
              dense: true,
              title: const Text('Uppercase (A-Z)'),
              value: _uppercase,
              onChanged: (v) {
                setState(() => _uppercase = v);
                _generate();
              },
            ),
            SwitchListTile(
              dense: true,
              title: const Text('Digits (0-9)'),
              value: _digits,
              onChanged: (v) {
                setState(() => _digits = v);
                _generate();
              },
            ),
            SwitchListTile(
              dense: true,
              title: const Text('Special (!@#\$%^&*)'),
              value: _special,
              onChanged: (v) {
                setState(() => _special = v);
                _generate();
              },
            ),

            // Weakness warning
            if (_isWeak) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: theme.colorScheme.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Weak password. Enable more character types or increase length.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _generate,
          child: const Text('Regenerate'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_generated),
          child: const Text('Use'),
        ),
      ],
    );
  }
}
