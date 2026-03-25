/// App-wide constants.
class AppConstants {
  AppConstants._();

  /// Time in seconds before auto-lock after going to background.
  static const int autoLockTimeoutSeconds = 30;

  /// Duration for clipboard auto-clear in seconds.
  static const int clipboardClearSeconds = 30;

  /// Undo window duration for swipe-to-delete (seconds).
  static const int undoWindowSeconds = 8;

  /// Password categories available in the app.
  static const List<String> categories = [
    'General',
    'Social',
    'Banking',
    'Email',
    'Shopping',
    'Work',
    'Gaming',
    'Streaming',
    'Imported',
    'Other',
  ];
}
