import 'dart:ui';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/constants.dart';
import 'features/auth/data/auth_service.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/pin_setup_screen.dart';
import 'features/passwords/data/database_service.dart';
import 'features/passwords/data/encryption_service.dart';
import 'features/passwords/data/models/password_entry.dart';
import 'features/passwords/presentation/home_screen.dart';
import 'features/passwords/data/backup_service.dart';
import 'services/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise core services
  final encryptionService = EncryptionService();
  await encryptionService.init();

  final databaseService = DatabaseService(encryptionService);
  final authService = AuthService();

  runApp(
    MultiProvider(
      providers: [
        Provider<EncryptionService>.value(value: encryptionService),
        Provider<DatabaseService>.value(value: databaseService),
        Provider<AuthService>.value(value: authService),
        ProxyProvider2<DatabaseService, EncryptionService, BackupService>(
          update: (_, db, enc, __) => BackupService(db, enc),
        ),
        ChangeNotifierProvider(
          create: (_) => PasswordProvider(databaseService),
        ),
      ],
      child: PasswordManagerApp(authService: authService, databaseService: databaseService),
    ),
  );
}

/// Root app widget with theme switching and auto-lock lifecycle management
class PasswordManagerApp extends StatefulWidget {
  final AuthService authService;
  final DatabaseService databaseService;

  const PasswordManagerApp({
    super.key,
    required this.authService,
    required this.databaseService,
  });

  @override
  State<PasswordManagerApp> createState() => _PasswordManagerAppState();
}

class _PasswordManagerAppState extends State<PasswordManagerApp>
    with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.dark; // Default to OLED dark mode cus who likes light mode i aint a boomer
  bool _useDynamicColor = true;
  bool _isLocked = true;
  bool _showPrivacyBlur = false;
  DateTime? _backgroundTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Auto-lock when app goes to background when > 30 seconds
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundTime = DateTime.now();
      setState(() => _showPrivacyBlur = true);
    } else if (state == AppLifecycleState.resumed) {
      setState(() => _showPrivacyBlur = false);
      if (_backgroundTime != null) {
        final elapsed = DateTime.now().difference(_backgroundTime!).inSeconds;
        if (elapsed >= AppConstants.autoLockTimeoutSeconds) {
          setState(() => _isLocked = true);
        }
        _backgroundTime = null;
      }
    }
  }

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  void _toggleDynamicColor(bool value) {
    setState(() {
      _useDynamicColor = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final lightScheme = _useDynamicColor ? lightDynamic : null;
        final darkScheme = _useDynamicColor ? darkDynamic : null;

        return MaterialApp(
          title: 'Password Manager',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(lightScheme),
          darkTheme: AppTheme.darkTheme(darkScheme),
          themeMode: _themeMode,
          builder: (context, child) {
            return Stack(
              children: [
                if (child != null) child,
                if (_showPrivacyBlur) const _PrivacyBlurOverlay(),
              ],
            );
          },
          home: _isLocked
              ? _AuthGate(
                  authService: widget.authService,
                  databaseService: widget.databaseService,
                  onAuthenticated: () => setState(() => _isLocked = false),
                )
              : HomeScreen(
                  authService: widget.authService,
                  themeMode: _themeMode,
                  onToggleTheme: _toggleTheme,
                  useDynamicColor: _useDynamicColor,
                  onToggleDynamicColor: _toggleDynamicColor,
                ),
        );
      },
    );
  }
}

/// Blur overlay shown when app is in background (task switcher).
class _PrivacyBlurOverlay extends StatelessWidget {
  const _PrivacyBlurOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          color: Colors.black.withValues(alpha: 0.4),
          child: const Center(
            child: Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Gate that decides between PIN setup (first run) or login (returning user).
class _AuthGate extends StatefulWidget {
  final AuthService authService;
  final DatabaseService databaseService;
  final VoidCallback onAuthenticated;

  const _AuthGate({
    required this.authService,
    required this.databaseService,
    required this.onAuthenticated,
  });

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool? _isPinSet;

  @override
  void initState() {
    super.initState();
    _checkPin();
  }

  Future<void> _checkPin() async {
    final pinSet = await widget.authService.isPinSet();
    setState(() => _isPinSet = pinSet);
  }

  /// Seed the database with 5 demo entries on first setup.
  Future<void> _seedDemoEntries() async {
    final now = DateTime.now();
    final demoEntries = [
      PasswordEntry(
        siteName: 'Google',
        siteUrl: 'https://accounts.google.com',
        username: 'demo@gmail.com',
        password: 'D3m0Goo!2024',
        category: 'Email',
        createdAt: now,
        updatedAt: now,
        lastAccessedAt: now,
      ),
      PasswordEntry(
        siteName: 'Facebook',
        siteUrl: 'https://www.facebook.com',
        username: 'demo_user',
        password: 'Fb#SecPwd99',
        category: 'Social',
        createdAt: now,
        updatedAt: now,
        lastAccessedAt: now,
      ),
      PasswordEntry(
        siteName: 'Maybank2u',
        siteUrl: 'https://www.maybank2u.com.my',
        username: 'john_bank',
        password: 'B@nk\$ecure1!',
        pin: '123456',
        category: 'Banking',
        createdAt: now,
        updatedAt: now,
        lastAccessedAt: now,
      ),
      PasswordEntry(
        siteName: 'Steam',
        siteUrl: 'https://store.steampowered.com',
        username: 'gamer_pro',
        password: 'Gm!ng2024#',
        notes: 'Security Q: Pet name? Answer: Max',
        category: 'Gaming',
        createdAt: now,
        updatedAt: now,
        lastAccessedAt: now,
      ),
      PasswordEntry(
        siteName: 'Netflix',
        siteUrl: 'https://www.netflix.com',
        username: 'binge_watcher',
        password: 'N3tfl!xP@ss',
        category: 'Streaming',
        createdAt: now,
        updatedAt: now,
        lastAccessedAt: now,
      ),
    ];

    for (final entry in demoEntries) {
      await widget.databaseService.insertEntry(entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isPinSet == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isPinSet!) {
      return PinSetupScreen(
        authService: widget.authService,
        onSetupComplete: () async {
          await _seedDemoEntries();
          widget.onAuthenticated();
        },
      );
    }

    return LoginScreen(
      authService: widget.authService,
      onLoginSuccess: widget.onAuthenticated,
    );
  }
}
