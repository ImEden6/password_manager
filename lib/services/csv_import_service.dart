import 'dart:io';

import 'package:csv/csv.dart';

import '../features/passwords/data/database_service.dart';
import '../features/passwords/data/models/password_entry.dart';

/// Imports passwords from CSV files exported by Chrome, Bitwarden, or LastPass.
///
/// Supported CSV column headers (case-insensitive):
/// - Chrome: name, url, username, password
/// - Bitwarden: name, login_uri, login_username, login_password, notes
/// - LastPass: url, username, password, extra, name, grouping
class CsvImportService {
  final DatabaseService _databaseService;

  CsvImportService(this._databaseService);

  /// Import from a CSV file. Returns the number of entries imported.
  Future<int> importFromCsv(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    final rows = const CsvToListConverter().convert(content, eol: '\n');

    if (rows.isEmpty) return 0;

    // First row is headers.
    final headers =
        rows[0].map((h) => h.toString().trim().toLowerCase()).toList();

    int count = 0;
    final now = DateTime.now();

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < headers.length) continue;

      final map = <String, String>{};
      for (int j = 0; j < headers.length; j++) {
        map[headers[j]] = row[j].toString().trim();
      }

      // Normalize column names across different password manager exports.
      final siteName = map['name'] ?? map['title'] ?? map['url'] ?? '';
      final siteUrl = map['url'] ?? map['login_uri'] ?? '';
      final username =
          map['username'] ?? map['login_username'] ?? map['user'] ?? '';
      final password =
          map['password'] ?? map['login_password'] ?? '';
      final notes = map['notes'] ?? map['extra'] ?? '';
      final category =
          map['grouping'] ?? map['folder'] ?? map['group'] ?? 'Imported';

      if (siteName.isEmpty || password.isEmpty) continue;

      final entry = PasswordEntry(
        siteName: siteName,
        siteUrl: siteUrl.isNotEmpty ? siteUrl : null,
        username: username,
        password: password,
        notes: notes.isNotEmpty ? notes : null,
        category: category,
        createdAt: now,
        updatedAt: now,
        lastAccessedAt: now,
      );

      // insertEntry handles encryption internally.
      await _databaseService.insertEntry(entry);
      count++;
    }

    return count;
  }
}
