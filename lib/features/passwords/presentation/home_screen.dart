import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/providers.dart';
import '../../auth/data/auth_service.dart';
import '../data/models/password_entry.dart';
import 'widgets/password_tile.dart';
import 'widgets/search_bar_widget.dart';
import 'entry_form_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../../core/constants.dart';

/// Main screen showing the list of password entries.
class HomeScreen extends StatefulWidget {
  final AuthService authService;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final bool useDynamicColor;
  final ValueChanged<bool> onToggleDynamicColor;

  const HomeScreen({
    super.key,
    required this.authService,
    required this.themeMode,
    required this.onToggleTheme,
    required this.useDynamicColor,
    required this.onToggleDynamicColor,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<PasswordProvider>().loadEntries();
    });
  }

  /// Authenticate user via Biometrics or PIN.
  Future<bool> _authenticateOrVerifyPin() async {
    final bioEnabled = await widget.authService.isBiometricEnabled();
    if (bioEnabled) {
      final authenticated =
          await widget.authService.authenticateWithBiometrics();
      if (authenticated) return true;
    }
    if (!mounted) return false;
    return _verifyPinDialog();
  }

  /// Show PIN dialog for identity verification.
  Future<bool> _verifyPinDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => const _PinVerifyDialog(),
        ) ??
        false;
  }

  void _deleteEntry(PasswordEntry entry) {
    final provider = context.read<PasswordProvider>();
    provider.deleteEntry(entry.id!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${entry.siteName} deleted'),
        duration: const Duration(seconds: AppConstants.undoWindowSeconds),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            provider.addEntry(entry);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(
            title: Text(
              'Passwords',
              style: theme.textTheme.titleLarge,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SettingsScreen(
                        authService: widget.authService,
                        themeMode: widget.themeMode,
                        onToggleTheme: widget.onToggleTheme,
                        useDynamicColor: widget.useDynamicColor,
                        onToggleDynamicColor: widget.onToggleDynamicColor,
                      ),
                    ),
                  );
                },
                tooltip: 'Settings',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: SearchBarWidget(
              onChanged: (query) {
                context.read<PasswordProvider>().search(query);
              },
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  'All',
                  ...AppConstants.categories,
                ].map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat),
                      selected: isSelected,
                       onSelected: (_) {
                        setState(() => _selectedCategory = cat);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          Consumer<PasswordProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final entries = _selectedCategory == 'All'
                  ? provider.entries
                  : provider.entries
                      .where((e) => e.category == _selectedCategory)
                      .toList();

              if (entries.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(theme),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry = entries[index];
                    return Dismissible(
                      key: ValueKey(entry.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.delete_outline,
                            color: theme.colorScheme.onError),
                      ),
                      onDismissed: (_) => _deleteEntry(entry),
                      child: PasswordTile(
                        entry: entry,
                        onTap: () async {
                          final authenticated = await _authenticateOrVerifyPin();
                          if (!authenticated) return;
                          await provider.touchEntry(entry.id!);
                          if (!context.mounted) return;
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EntryFormScreen(entry: entry),
                            ),
                          );
                          if (result == true) provider.loadEntries();
                        },
                        onToggleFavorite: () {
                          provider.toggleFavorite(
                              entry.id!, entry.isFavorite);
                        },
                        onDelete: () => _deleteEntry(entry),
                        onRequestReveal: () async {
                          final allowed = await _authenticateOrVerifyPin();
                          if (allowed) {
                            await provider.touchEntry(entry.id!);
                          }
                          return allowed;
                        },
                      ),
                    );
                  },
                  childCount: entries.length,
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EntryFormScreen()),
          );
          if (result == true) {
            if (context.mounted) {
              context.read<PasswordProvider>().loadEntries();
            }
          }
        },
        tooltip: 'Add password',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_open_outlined,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(100),
            ),
            const SizedBox(height: 24),
            Text(
              'No passwords yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first password',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PinVerifyDialog extends StatefulWidget {
  const _PinVerifyDialog();

  @override
  State<_PinVerifyDialog> createState() => _PinVerifyDialogState();
}

class _PinVerifyDialogState extends State<_PinVerifyDialog> {
  late final TextEditingController _pinController;

  @override
  void initState() {
    super.initState();
    _pinController = TextEditingController();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    return AlertDialog(
      title: const Text('Verify Identity'),
      content: TextField(
        controller: _pinController,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: 8,
        decoration: const InputDecoration(
          labelText: 'Enter your PIN',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final ok = await authService.verifyPin(_pinController.text);
            if (context.mounted) Navigator.of(context).pop(ok);
          },
          child: const Text('Verify'),
        ),
      ],
    );
  }
}
