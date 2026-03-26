import 'package:flutter/material.dart';
import 'numeric_keypad.dart';

/// A TextFormField-like widget that uses a custom [NumericKeypad] via bottom sheet.
class NumericInputField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData? prefixIcon;
  final bool obscureText;
  final int maxLength;
  final String? Function(String?)? validator;

  const NumericInputField({
    super.key,
    required this.controller,
    required this.labelText,
    this.prefixIcon,
    this.obscureText = false,
    this.maxLength = 8,
    this.validator,
  });

  void _showKeypad(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              labelText,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setModalState) {
                return Column(
                  children: [
                    Text(
                      obscureText
                          ? '•' * controller.text.length
                          : controller.text,
                      style: const TextStyle(
                        fontSize: 32,
                        letterSpacing: 4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    NumericKeypad(
                      onDigitTap: (digit) {
                        if (controller.text.length < maxLength) {
                          setModalState(() {
                            controller.text += digit;
                          });
                        }
                      },
                      onDeleteTap: () {
                        if (controller.text.isNotEmpty) {
                          setModalState(() {
                            controller.text = controller.text
                                .substring(0, controller.text.length - 1);
                          });
                        }
                      },
                      onDoneTap: () => Navigator.pop(context),
                      isDoneEnabled: controller.text.length >= 4,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      obscureText: obscureText,
      onTap: () => _showKeypad(context),
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        border: const OutlineInputBorder(),
        hintText: 'Tap to enter',
      ),
      validator: validator,
    );
  }
}
