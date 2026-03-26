import 'package:flutter/material.dart';

/// A custom numeric keypad for PIN entry.
///
/// Avoids system keyboard issues and provides a consistent touch-optimized experience.
class NumericKeypad extends StatelessWidget {
  final Function(String) onDigitTap;
  final VoidCallback onDeleteTap;
  final VoidCallback? onDoneTap;
  final Widget? leadingAction;
  final bool isDoneEnabled;

  const NumericKeypad({
    super.key,
    required this.onDigitTap,
    required this.onDeleteTap,
    this.onDoneTap,
    this.leadingAction,
    this.isDoneEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKey('1'),
            _buildKey('2'),
            _buildKey('3'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKey('4'),
            _buildKey('5'),
            _buildKey('6'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKey('7'),
            _buildKey('8'),
            _buildKey('9'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            leadingAction != null
                ? Expanded(child: leadingAction!)
                : const Spacer(),
            _buildKey('0'),
            _buildActionKey(
              Icons.backspace_outlined,
              onDeleteTap,
            ),
          ],
        ),
        if (onDoneTap != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: isDoneEnabled ? onDoneTap : null,
              child: const Text('Continue'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildKey(String digit) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: InkWell(
          onTap: () => onDigitTap(digit),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              digit,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey(IconData icon, VoidCallback? onTap, {Color? color}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 64,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 28,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
