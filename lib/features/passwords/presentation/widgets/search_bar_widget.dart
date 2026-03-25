import 'package:flutter/material.dart';

/// Reusable search bar widget with realtime filtering.
class SearchBarWidget extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String hintText;

  const SearchBarWidget({
    super.key,
    required this.onChanged,
    this.hintText = 'Search by site, username, or URL',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SearchBar(
        hintText: hintText,
        leading: const Icon(Icons.search),
        onChanged: onChanged,
        elevation: WidgetStateProperty.all(0),
        backgroundColor: WidgetStateProperty.all(
          Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(128),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }
}
