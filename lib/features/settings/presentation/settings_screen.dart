import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../../auth/data/auth_service.dart';
import '../../passwords/data/backup_service.dart';
import '../../passwords/data/database_service.dart';
import '../../passwords/data/encryption_service.dart';
import '../../../services/csv_import_service.dart';
import '../../../services/providers.dart';

/// Settings screen with PIN management, biometrics, backup/import, and theme.
class SettingsScreen extends StatefulWidget {
  final AuthService authService;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final bool useDynamicColor;
  final ValueChanged<bool> onToggleDynamicColor;

  const SettingsScreen({
    super.key,
    required this.authService,
    required this.themeMode,
    required this.onToggleTheme,
    required this.useDynamicColor,
    required this.onToggleDynamicColor,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final available = await widget.authService.isBiometricAvailable();
    final enabled = await widget.authService.isBiometricEnabled();
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
    });
  }

  Future<void> _changePin() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _ChangePinDialog(authService: widget.authService),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN changed successfully')),
      );
    }
  }

  Future<void> _exportBackup() async {
    try {
      final backupService = context.read<BackupService>();
      await backupService.exportBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup exported!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );
      if (result == null || result.files.single.path == null) return;

      final filePath = result.files.single.path!;
      if (!mounted) return;

      final backupService = context.read<BackupService>();

      final count = await backupService.importBackup(filePath);
      if (mounted) {
        context.read<PasswordProvider>().loadEntries();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported $count entries from backup')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  Future<void> _importCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result == null || result.files.single.path == null) return;

      final filePath = result.files.single.path!;
      if (!mounted) return;

      final dbService = context.read<DatabaseService>();
      final csvService = CsvImportService(dbService);

      final count = await csvService.importFromCsv(filePath);
      if (mounted) {
        context.read<PasswordProvider>().loadEntries();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported $count entries from CSV')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV import failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _sectionHeader(theme, 'Security'),
          ListTile(
            leading: const Icon(Icons.pin_outlined),
            title: const Text('Change PIN'),
            subtitle: const Text('Update your master PIN'),
            onTap: _changePin,
          ),
          if (_biometricAvailable)
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: const Text('Biometric Unlock'),
              subtitle: const Text('Use fingerprint to unlock'),
              value: _biometricEnabled,
              onChanged: (v) async {
                final messenger = ScaffoldMessenger.of(context);
                if (v) {
                  final success =
                      await widget.authService.authenticateWithBiometrics();
                  if (success) {
                    await widget.authService.setBiometricEnabled(true);
                    setState(() => _biometricEnabled = true);
                  } else {
                    messenger.showSnackBar(
                      const SnackBar(
                          content: Text('Authentication failed. Try again.')),
                    );
                  }
                } else {
                  await widget.authService.setBiometricEnabled(false);
                  setState(() => _biometricEnabled = false);
                }
              },
            ),
          const Divider(),
          _sectionHeader(theme, 'Data'),
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: const Text('Export Encrypted Backup'),
            subtitle: const Text('Save or share a .enc backup file'),
            onTap: _exportBackup,
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Import from Backup'),
            subtitle: const Text('Restore from .enc backup file'),
            onTap: _importBackup,
          ),
          ListTile(
            leading: const Icon(Icons.table_chart_outlined),
            title: const Text('Import from CSV'),
            subtitle: const Text('Chrome, Bitwarden, LastPass exports'),
            onTap: _importCsv,
          ),
          const Divider(),
          _sectionHeader(theme, 'Appearance'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark Mode'),
            subtitle: const Text('OLED-optimized dark theme'),
            value: widget.themeMode == ThemeMode.dark,
            onChanged: (_) => widget.onToggleTheme(),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.palette_outlined),
            title: const Text('Dynamic Color'),
            subtitle: const Text('Adapt colors to wallpaper'),
            value: widget.useDynamicColor,
            onChanged: widget.onToggleDynamicColor,
          ),
          const Divider(),
          _sectionHeader(theme, 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Password Manager'),
            subtitle: const Text('Version 1.0.0 — UCCD3223'),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ChangePinDialog extends StatefulWidget {
  final AuthService authService;
  const _ChangePinDialog({required this.authService});

  @override
  State<_ChangePinDialog> createState() => _ChangePinDialogState();
}

class _ChangePinDialogState extends State<_ChangePinDialog> {
  late final TextEditingController _currentPinCtrl;
  late final TextEditingController _newPinCtrl;

  @override
  void initState() {
    super.initState();
    _currentPinCtrl = TextEditingController();
    _newPinCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _currentPinCtrl.dispose();
    _newPinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _currentPinCtrl,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 8,
            decoration: const InputDecoration(
              labelText: 'Current PIN',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _newPinCtrl,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 8,
            decoration: const InputDecoration(
              labelText: 'New PIN (4-8 digits)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final verified =
                await widget.authService.verifyPin(_currentPinCtrl.text);
            if (!verified) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Current PIN is incorrect')),
                );
              }
              return;
            }
            if (_newPinCtrl.text.length < 4) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('New PIN must be at least 4 digits')),
                );
              }
              return;
            }
            await widget.authService.setPin(_newPinCtrl.text);
            if (context.mounted) Navigator.of(context).pop(true);
          },
          child: const Text('Change'),
        ),
      ],
    );
  }
}
