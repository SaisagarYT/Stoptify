import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the JWT bearer token issued by `/api/auth/register` or
/// `/api/auth/login` across app restarts.
class TokenStorage {
  TokenStorage() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'stoptify_jwt_token';

  Future<String?> read() => _storage.read(key: _key);

  Future<void> save(String token) => _storage.write(key: _key, value: token);

  Future<void> clear() => _storage.delete(key: _key);
}
