import 'package:flutter/foundation.dart';

import '../features/passwords/data/database_service.dart';
import '../features/passwords/data/models/password_entry.dart';

/// ChangeNotifier-based state management for the password list.
///
/// Uses [provider] for simplicity (suitable for a university project).
/// Manages the list of entries, search query, and CRUD operations.
class PasswordProvider extends ChangeNotifier {
  final DatabaseService _databaseService;

  List<PasswordEntry> _entries = [];
  String _searchQuery = '';
  bool _isLoading = false;

  PasswordProvider(this._databaseService);

  List<PasswordEntry> get entries => _entries;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  /// Load all entries from the database.
  Future<void> loadEntries() async {
    _isLoading = true;
    notifyListeners();

    if (_searchQuery.isEmpty) {
      _entries = await _databaseService.getAllEntries();
    } else {
      _entries = await _databaseService.searchEntries(_searchQuery);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Update the search query and reload entries.
  Future<void> search(String query) async {
    _searchQuery = query;
    await loadEntries();
  }

  /// Add a new entry.
  Future<void> addEntry(PasswordEntry entry) async {
    await _databaseService.insertEntry(entry);
    await loadEntries();
  }

  /// Update an existing entry.
  Future<void> updateEntry(PasswordEntry entry) async {
    await _databaseService.updateEntry(entry);
    await loadEntries();
  }

  /// Delete an entry by ID.
  Future<void> deleteEntry(int id) async {
    await _databaseService.deleteEntry(id);
    await loadEntries();
  }

  /// Touch an entry (update lastAccessedAt).
  Future<void> touchEntry(int id) async {
    await _databaseService.touchEntry(id);
    await loadEntries();
  }

  /// Toggle favorite status.
  Future<void> toggleFavorite(int id, bool currentValue) async {
    await _databaseService.toggleFavorite(id, currentValue);
    await loadEntries();
  }
}
