import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../services/providers.dart';
import '../data/models/password_entry.dart';
import 'widgets/password_generator_dialog.dart';
import 'widgets/password_strength_indicator.dart';

/// Add / Edit password entry screen.
///
/// Shows form fields for all PasswordEntry properties, a password
/// strength indicator, and a password generator dialog.
/// On save: encrypts via provider, sets createdAt only on insert.
class EntryFormScreen extends StatefulWidget {
  final PasswordEntry? entry; // null = add mode, non-null = edit mode

  const EntryFormScreen({super.key, this.entry});

  @override
  State<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends State<EntryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _siteNameCtrl;
  late final TextEditingController _siteUrlCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _pinCtrl;
  late final TextEditingController _notesCtrl;
  late String _category;

  bool _isEditing = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _isEditing = e != null;
    _siteNameCtrl = TextEditingController(text: e?.siteName ?? '');
    _siteUrlCtrl = TextEditingController(text: e?.siteUrl ?? '');
    _usernameCtrl = TextEditingController(text: e?.username ?? '');
    _passwordCtrl = TextEditingController(text: e?.password ?? '');
    _pinCtrl = TextEditingController(text: e?.pin ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _category = e?.category ?? 'General';
  }

  @override
  void dispose() {
    _siteNameCtrl.dispose();
    _siteUrlCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _pinCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<PasswordProvider>();
    final now = DateTime.now();

    final entry = PasswordEntry(
      id: widget.entry?.id,
      siteName: _siteNameCtrl.text.trim(),
      siteUrl: _siteUrlCtrl.text.trim().isNotEmpty
          ? _siteUrlCtrl.text.trim()
          : null,
      username: _usernameCtrl.text.trim(),
      password: _passwordCtrl.text,
      pin: _pinCtrl.text.trim().isNotEmpty ? _pinCtrl.text.trim() : null,
      notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      category: _category,
      isFavorite: widget.entry?.isFavorite ?? false,
      createdAt: widget.entry?.createdAt ?? now, // Immutable on edit
      updatedAt: now,
      lastAccessedAt: widget.entry?.lastAccessedAt ?? now,
    );

    if (_isEditing) {
      await provider.updateEntry(entry);
    } else {
      await provider.addEntry(entry);
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _openGenerator() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => const PasswordGeneratorDialog(),
    );
    if (result != null) {
      setState(() {
        _passwordCtrl.text = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Entry' : 'Add Entry'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Site Name (required).
            TextFormField(
              controller: _siteNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Site Name *',
                prefixIcon: Icon(Icons.web),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Site URL (optional).
            TextFormField(
              controller: _siteUrlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL',
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Username (required).
            TextFormField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(
                labelText: 'Username *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Password (required) with visibility toggle and generator.
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password *',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(
                            () => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.casino_outlined),
                      tooltip: 'Generate password',
                      onPressed: _openGenerator,
                    ),
                  ],
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v.length < 4) return 'At least 4 characters';
                return null;
              },
              onChanged: (_) => setState(() {}), // Trigger strength update
            ),

            // Password strength indicator.
            PasswordStrengthIndicator(password: _passwordCtrl.text),
            const SizedBox(height: 16),

            // PIN (optional).
            TextFormField(
              controller: _pinCtrl,
              decoration: const InputDecoration(
                labelText: 'PIN (optional)',
                prefixIcon: Icon(Icons.pin_outlined),
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Notes / Security Q&A (optional).
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes / Security Q&A (optional)',
                prefixIcon: Icon(Icons.notes_outlined),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Category dropdown.
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: AppConstants.categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            const SizedBox(height: 24),

            // Timestamps display (edit mode only).
            if (_isEditing && widget.entry != null) ...[
              Divider(color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 8),
              Text(
                'Created: ${_formatDateTime(widget.entry!.createdAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Last modified: ${_formatDateTime(widget.entry!.updatedAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Last accessed: ${_formatDateTime(widget.entry!.lastAccessedAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
