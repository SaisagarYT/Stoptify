import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../core/network/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(tokenStorage: ref.watch(tokenStorageProvider));
});
