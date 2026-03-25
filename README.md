# Password Manager

A secure, Flutter-based password manager utilizing industry-standard cryptographic practices.

## Features

### Encryption & Security
*   **AES-256-CBC Encryption**: All sensitive fields (passwords, usernames, custom notes) are encrypted using AES-256 in CBC mode.
*   **Dynamic Initialization Vectors (IV)**: Each entry generates a unique, cryptographically secure IV stored alongside the ciphertext, preventing pattern-based attacks.
*   **Secure Key Storage**: Encryption keys and IVs are managed via `flutter_secure_storage`, which utilizes the **Android Keystore** and **iOS Keychain** to ensure secrets never touch persistent storage in plaintext.

### Authentication
*   **Salted SHA-256 Hashing**: The Master PIN is never stored directly. Instead, it is hashed with a unique salt using SHA-256 before being persisted.
*   **Biometric Integration**: Supports **Fingerprint** and **Face ID** authentication via `local_auth`, with a secure fallback to the system-level PIN/Pattern.
*   **Intelligent Lockout**: Protects against brute-force attacks by enforcing a 30-second lockout after 3 consecutive failed attempts.

### Data Management
*   **Encrypted Backups**: Exports full database snapshots as encrypted `.enc` JSON files, requiring the original device's secure keys for restoration.
*   **Multi-Platform Import**: Bridges the gap between managers by supporting CSV imports from **Google Chrome**, **Bitwarden**, and **LastPass**.
*   **Smart Organization**: Category-based filtering (Social, Work, Finance, etc.) and a real-time search engine for rapid access.
*   **Safe Deletion**: Implements a "Soft Delete" pattern with an immediate undo window to prevent accidental data loss.

### User Experience
*   **Material 3 Design**: Fully compliant with modern Material Design standards for a fluid and accessible interface.
*   **Amoled Dark Mode**: Includes an OLED-optimized dark theme to reduce battery consumption and eye strain.
*   **Dynamic Material You**: Leverages Android 12+ dynamic coloring to adapt the app's palette to the user's wallpaper.

## Technical Stack
*   **Framework**: Flutter (Dart)
*   **Local Database**: SQLite (via `sqflite`)
*   **Secure Storage**: Android Keystore / iOS Keychain
*   **State Management**: Provider

