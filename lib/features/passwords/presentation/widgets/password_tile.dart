import 'package:flutter/material.dart';
import '../../data/models/password_entry.dart';
import '../../../../core/utils/clipboard_helper.dart';

/// List tile widget for a single password entry.
///
/// Shows site name, username, masked password, favorite star, and action icons.
/// Long site names are truncated with ellipsis (tested for 50+ chars).
/// Touch targets are minimum 48dp per Android guidelines.
class PasswordTile extends StatefulWidget {
  final PasswordEntry entry;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;
  final Future<bool> Function() onRequestReveal;

  const PasswordTile({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onDelete,
    required this.onRequestReveal,
  });

  @override
  State<PasswordTile> createState() => _PasswordTileState();
}

class _PasswordTileState extends State<PasswordTile> {
  bool _revealed = false;

  /// Get the appropriate icon for a category.
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'social':
        return Icons.people_outlined;
      case 'banking':
        return Icons.account_balance_outlined;
      case 'email':
        return Icons.email_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'work':
        return Icons.work_outlined;
      case 'gaming':
        return Icons.sports_esports_outlined;
      case 'streaming':
        return Icons.play_circle_outlined;
      default:
        return Icons.lock_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = widget.entry;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        // Ripple effect for Material feel.
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Category icon in a colored circle.
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(entry.category),
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Site name + username + masked password.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.siteName,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis, // Handles 50+ chars
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.username,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _revealed ? entry.password : '••••••••',
                        key: ValueKey(_revealed),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: _revealed
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Action icons – each with 48dp touch target.
              // Favorite star.
              IconButton(
                icon: Icon(
                  entry.isFavorite ? Icons.star : Icons.star_border,
                  color: entry.isFavorite
                      ? const Color(0xFFFFC107)
                      : theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: widget.onToggleFavorite,
                tooltip: entry.isFavorite ? 'Unfavorite' : 'Favorite',
                iconSize: 24,
                constraints: const BoxConstraints(
                    minWidth: 48, minHeight: 48), // 48dp touch target
              ),

              // Reveal / hide password.
              IconButton(
                icon: Icon(
                  _revealed ? Icons.visibility_off : Icons.visibility,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: () async {
                  if (_revealed) {
                    setState(() => _revealed = false);
                  } else {
                    final allowed = await widget.onRequestReveal();
                    if (allowed) {
                      setState(() => _revealed = true);
                    }
                  }
                },
                tooltip: _revealed ? 'Hide' : 'Reveal',
                iconSize: 24,
                constraints:
                    const BoxConstraints(minWidth: 48, minHeight: 48),
              ),

              // Copy to clipboard.
              IconButton(
                icon: Icon(
                  Icons.copy,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: () => copyToClipboard(context, entry.password),
                tooltip: 'Copy password',
                iconSize: 24,
                constraints:
                    const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
