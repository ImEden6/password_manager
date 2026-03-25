import 'dart:convert';

import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'database_service.dart';
import 'encryption_service.dart';

/// Handles encrypted JSON backup export and import.
///
/// Exported JSON contains all entries with passwords still encrypted
/// (as stored in SQLite). The backup wrapper itself is additionally
/// encrypted with the app's AES key so backups are useless without
/// the original device keys.
class BackupService {
  final DatabaseService _databaseService;
  final EncryptionService _encryptionService;

  BackupService(this._databaseService, this._encryptionService);

  /// Export all entries as an encrypted JSON file and share.
  Future<void> exportBackup() async {
    final entries = await _databaseService.getAllEntriesRaw();
    final jsonString = jsonEncode({
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'entries': entries,
    });

    // Encrypt the entire JSON payload.
    final encrypted = _encryptionService.encryptText(jsonString);

    // Write to a temp file for sharing.
    final dir = Directory.systemTemp;
    final file = File(p.join(dir.path, 'password_manager_backup.enc'));
    await file.writeAsString(encrypted);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Password Manager Encrypted Backup',
    );
  }

  /// Import entries from an encrypted JSON backup file.
  Future<int> importBackup(String filePath) async {
    final file = File(filePath);
    final encrypted = await file.readAsString();

    // Decrypt the wrapper.
    final jsonString = _encryptionService.decryptText(encrypted);
    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    final entries = data['entries'] as List<dynamic>;
    int count = 0;

    for (final entry in entries) {
      await _databaseService.insertRaw(entry as Map<String, dynamic>);
      count++;
    }

    return count;
  }
}
