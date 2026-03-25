import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants.dart';

/// Copies text to clipboard and auto-clears after [AppConstants.clipboardClearSeconds].
Future<void> copyToClipboard(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Copied! Auto-clears in ${AppConstants.clipboardClearSeconds}s',
      ),
      duration: const Duration(seconds: 3),
    ),
  );

  // Auto-clear clipboard after timeout.
  Future.delayed(
    Duration(seconds: AppConstants.clipboardClearSeconds),
    () => Clipboard.setData(const ClipboardData(text: '')),
  );
}
