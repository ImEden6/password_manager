import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:password_manager/features/auth/presentation/login_screen.dart';
import 'package:password_manager/features/auth/presentation/pin_setup_screen.dart';
import 'package:password_manager/features/auth/data/auth_service.dart';
import 'package:password_manager/features/passwords/presentation/home_screen.dart';
import 'package:password_manager/features/passwords/presentation/entry_form_screen.dart';
import 'package:password_manager/services/providers.dart';
import 'package:password_manager/features/passwords/data/models/password_entry.dart';

// Manual Mocks for academic simplicity
class MockAuthService extends Fake implements AuthService {
  bool pinSet = false;
  bool biometricEnabled = false;
  int remainingAttempts = 3;
  DateTime? lockoutEnd;

  @override
  Future<bool> isPinSet() async => pinSet;

  @override
  Future<bool> isBiometricEnabled() async => biometricEnabled;

  @override
  Future<bool> isBiometricAvailable() async => true;

  @override
  Future<DateTime?> getLockoutEnd() async => lockoutEnd;

  @override
  Future<int> getRemainingAttempts() async => remainingAttempts;

  @override
  Future<bool> verifyPin(String pin) async {
    if (pin == '1234') {
      remainingAttempts = 3;
      return true;
    }
    remainingAttempts--;
    if (remainingAttempts <= 0) {
      lockoutEnd = DateTime.now().add(const Duration(seconds: 30));
    }
    return false;
  }

  @override
  Future<void> setPin(String pin) async {
    pinSet = true;
  }
}

class MockPasswordProvider extends ChangeNotifier implements PasswordProvider {
  List<PasswordEntry> _entries = [];
  bool _isLoading = false;

  @override
  List<PasswordEntry> get entries => _entries;
  @override
  String get searchQuery => '';
  @override
  bool get isLoading => _isLoading;

  @override
  Future<void> loadEntries() async {
    _isLoading = true;
    notifyListeners();
    _entries = [
      PasswordEntry(
        id: 1, siteName: 'Google', username: 'user@google.com', password: 'pw1',
        category: 'General', createdAt: DateTime.now(), updatedAt: DateTime.now(), lastAccessedAt: DateTime.now(),
      ),
      PasswordEntry(
        id: 2, siteName: 'Bank', username: 'richuser', password: 'pw2',
        category: 'Work', createdAt: DateTime.now(), updatedAt: DateTime.now(), lastAccessedAt: DateTime.now(),
      ),
    ];
    _isLoading = false;
    notifyListeners();
  }

  @override
  Future<void> search(String query) async {
    if (query.isEmpty) {
      await loadEntries();
      return;
    }
    _entries = _entries.where((e) => e.siteName.toLowerCase().contains(query.toLowerCase())).toList();
    notifyListeners();
  }

  @override
  Future<void> deleteEntry(int id) async {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  @override
  Future<void> addEntry(PasswordEntry entry) async {
    _entries.add(entry.copyWith(id: _entries.length + 1));
    notifyListeners();
  }

  @override Future<void> updateEntry(PasswordEntry entry) async {}
  @override Future<void> toggleFavorite(int id, bool isFavorite) async {}
  @override Future<void> touchEntry(int id) async {}
}

void main() {
  late MockAuthService mockAuth;
  late MockPasswordProvider mockProvider;

  setUp(() {
    mockAuth = MockAuthService();
    mockProvider = MockPasswordProvider();
  });

  Widget createTestableWidget(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PasswordProvider>.value(value: mockProvider),
        Provider<AuthService>.value(value: mockAuth),
      ],
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: child,
      ),
    );
  }

  void setupScreenSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
  }

  group('Authentication Flow Tests', () {
    testWidgets('PIN Setup Mismatch Flow', (WidgetTester tester) async {
      setupScreenSize(tester);
      await tester.pumpWidget(createTestableWidget(PinSetupScreen(
        authService: mockAuth,
        onSetupComplete: () {},
      )));

      // Step 1: Create
      for (var d in ['1', '2', '3', '4']) await tester.tap(find.text(d));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Your PIN'), findsOneWidget);

      // Step 2: Mismatch
      for (var d in ['4', '3', '2', '1']) await tester.tap(find.text(d));
      await tester.pump();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(find.textContaining('do not match'), findsOneWidget);
    });

    testWidgets('Login Lockout and Success Flow', (WidgetTester tester) async {
      setupScreenSize(tester);
      bool success = false;
      await tester.pumpWidget(createTestableWidget(LoginScreen(
        authService: mockAuth,
        onLoginSuccess: () => success = true,
      )));

      // Test Success
      for (var d in ['1', '2', '3', '4']) await tester.tap(find.text(d));
      await tester.pump();
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();
      expect(success, isTrue);

      // Reset for Lockout test
      success = false;
      mockAuth.remainingAttempts = 3;
      await tester.pumpWidget(createTestableWidget(LoginScreen(
        authService: mockAuth,
        onLoginSuccess: () => success = true,
      )));

      for (int i = 0; i < 3; i++) {
        for (var d in ['9', '9', '9', '9']) await tester.tap(find.text(d));
        await tester.pump();
        await tester.tap(find.text('Unlock'));
        await tester.pumpAndSettle();
      }

      expect(find.textContaining('Locked'), findsOneWidget);
      final unlockButton = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(unlockButton.onPressed, isNull);
    });
  });

  group('Password Management UX Tests', () {
    testWidgets('Search and Delete Flow', (WidgetTester tester) async {
      setupScreenSize(tester);
      await tester.pumpWidget(createTestableWidget(HomeScreen(
        authService: mockAuth,
        themeMode: ThemeMode.light,
        onToggleTheme: () {},
        useDynamicColor: false,
        onToggleDynamicColor: (_) {},
      )));

      await tester.pumpAndSettle(); // Initial load
      expect(find.text('Google'), findsOneWidget);

      // Search
      await tester.enterText(find.byType(SearchBar), 'Goo');
      await tester.pumpAndSettle();
      expect(find.text('Bank'), findsNothing);

      // Clear search
      await tester.enterText(find.byType(SearchBar), '');
      await tester.pumpAndSettle();
      expect(find.text('Bank'), findsOneWidget);

      // Delete (Swipe) - offset needs to be large enough for Dismissible
      await tester.drag(find.text('Bank'), const Offset(-600, 0));
      await tester.pumpAndSettle();
      
      expect(find.text('Bank'), findsNothing);
      expect(find.textContaining('deleted'), findsOneWidget);
    });

    testWidgets('Form Validation and Strength', (WidgetTester tester) async {
      setupScreenSize(tester);
      await tester.pumpWidget(createTestableWidget(const EntryFormScreen()));

      final pwField = find.widgetWithText(TextFormField, 'Password *');
      
      await tester.enterText(pwField, '123');
      await tester.pumpAndSettle();
      expect(find.text('Weak'), findsOneWidget);

      await tester.enterText(pwField, 'ComplexP@ssw0rd123!');
      await tester.pumpAndSettle();
      expect(find.text('Very Strong'), findsOneWidget);
    });
  });
}
