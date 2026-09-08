import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'token_storage.dart';

/// Standard `{ success, message, data }` envelope returned by every
/// Stoptify endpoint.
class ApiEnvelope {
  final bool success;
  final String message;
  final dynamic data;

  const ApiEnvelope(
      {required this.success, required this.message, required this.data});

  factory ApiEnvelope.fromJson(Map<String, dynamic> json) {
    return ApiEnvelope(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Thin wrapper around Dio configured for the Stoptify backend.
///
/// Base URL matches the spec: `http://localhost:5050`. Override via
/// `--dart-define=API_BASE_URL=...` for staging/prod builds.
String _resolveBaseUrl() {
  const envUrl = String.fromEnvironment('API_BASE_URL');
  if (envUrl.isNotEmpty) return envUrl;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:5050';
  }
  return 'http://localhost:5050';
}

class ApiClient {
  ApiClient({TokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? TokenStorage() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _resolveBaseUrl(),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.read();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );

    // Verbose network logging in debug builds only.
    assert(() {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: false,
          requestBody: true,
          responseBody: true,
          compact: true,
        ),
      );
      return true;
    }());
  }

  late final Dio _dio;
  final TokenStorage _tokenStorage;

  TokenStorage get tokenStorage => _tokenStorage;

  Future<ApiEnvelope> get(String path, {Map<String, dynamic>? query}) {
    return _request(() => _dio.get(path, queryParameters: query));
  }

  Future<ApiEnvelope> post(String path,
      {Map<String, dynamic>? body, FormData? formData}) {
    return _request(() => _dio.post(path, data: formData ?? body));
  }

  Future<ApiEnvelope> _request(Future<Response> Function() call) async {
    try {
      final response = await call();
      return ApiEnvelope.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : e.message ?? 'Network error';
      throw ApiException(message, statusCode: e.response?.statusCode);
    }
  }
}
