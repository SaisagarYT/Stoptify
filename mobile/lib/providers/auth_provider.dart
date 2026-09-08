import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/user.dart';
import 'core_providers.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({AuthStatus? status, AppUser? user, bool? isLoading, String? error}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._api) : super(const AuthState()) {
    _bootstrap();
  }

  final ApiClient _api;

  Future<void> _bootstrap() async {
    final token = await _api.tokenStorage.read();
    if (token == null || token.isEmpty) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final envelope = await _api.get(ApiEndpoints.me);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: AppUser.fromJson(envelope.data as Map<String, dynamic>),
      );
    } catch (_) {
      await _api.tokenStorage.clear();
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> register({required String name, required String email, required String password}) {
    return _authenticate(
      ApiEndpoints.register,
      {'name': name, 'fullName': name, 'email': email, 'password': password},
    );
  }

  Future<bool> login({required String email, required String password}) {
    return _authenticate(ApiEndpoints.login, {'email': email, 'password': password});
  }

  Future<bool> _authenticate(String path, Map<String, dynamic> body) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final envelope = await _api.post(path, body: body);
      final data = envelope.data as Map<String, dynamic>;
      final token = data['token'] as String;
      await _api.tokenStorage.save(token);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: AppUser.fromJson(data['user'] as Map<String, dynamic>),
        isLoading: false,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _api.tokenStorage.clear();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(apiClientProvider));
});
