/// Data model for a password entry.
///
/// All sensitive fields (password, pin, notes) are encrypted at rest
/// using AES-256. The [createdAt] field is immutable after creation.
class PasswordEntry {
  final int? id;
  final String siteName;
  final String? siteUrl;
  final String username;
  final String password; // Encrypted at rest
  final String? pin; // Encrypted at rest
  final String? notes; // Encrypted at rest
  final String category;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastAccessedAt;

  const PasswordEntry({
    this.id,
    required this.siteName,
    this.siteUrl,
    required this.username,
    required this.password,
    this.pin,
    this.notes,
    this.category = 'General',
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
    required this.lastAccessedAt,
  });

  /// Create from SQLite row map.
  factory PasswordEntry.fromMap(Map<String, dynamic> map) {
    return PasswordEntry(
      id: map['id'] as int?,
      siteName: map['siteName'] as String,
      siteUrl: map['siteUrl'] as String?,
      username: map['username'] as String,
      password: map['password'] as String,
      pin: map['pin'] as String?,
      notes: map['notes'] as String?,
      category: (map['category'] as String?) ?? 'General',
      isFavorite: (map['isFavorite'] as int?) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      lastAccessedAt:
          DateTime.fromMillisecondsSinceEpoch(map['lastAccessedAt'] as int),
    );
  }

  /// Convert to SQLite row map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'siteName': siteName,
      'siteUrl': siteUrl,
      'username': username,
      'password': password,
      'pin': pin,
      'notes': notes,
      'category': category,
      'isFavorite': isFavorite ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'lastAccessedAt': lastAccessedAt.millisecondsSinceEpoch,
    };
  }

  /// Copy with updated fields. [createdAt] is intentionally excluded
  /// to enforce immutability.
  PasswordEntry copyWith({
    int? id,
    String? siteName,
    String? siteUrl,
    String? username,
    String? password,
    String? pin,
    String? notes,
    String? category,
    bool? isFavorite,
    DateTime? updatedAt,
    DateTime? lastAccessedAt,
  }) {
    return PasswordEntry(
      id: id ?? this.id,
      siteName: siteName ?? this.siteName,
      siteUrl: siteUrl ?? this.siteUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      pin: pin ?? this.pin,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt, // NEVER changes
      updatedAt: updatedAt ?? this.updatedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
    );
  }
}
