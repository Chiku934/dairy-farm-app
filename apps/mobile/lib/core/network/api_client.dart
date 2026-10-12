import 'dart:async';
import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

/// Interceptor that deduplicates identical concurrent in-flight GET requests,
/// preventing redundant HTTP calls across the network during rapid UI renders.
class DeduplicationInterceptor extends Interceptor {
  final Map<String, Completer<Response>> _inFlight = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method.toUpperCase() != 'GET' || options.extra['skipDeduplication'] == true) {
      return handler.next(options);
    }

    final key = '${options.method}:${options.uri}';
    if (_inFlight.containsKey(key)) {
      _inFlight[key]!.future.then(
        (response) => handler.resolve(Response(
          requestOptions: options,
          data: response.data,
          statusCode: response.statusCode,
          statusMessage: response.statusMessage,
          headers: response.headers,
          isRedirect: response.isRedirect,
          redirects: response.redirects,
          extra: response.extra,
        )),
        onError: (err) {
          if (err is DioException) {
            handler.reject(err);
          } else {
            handler.reject(DioException(requestOptions: options, error: err));
          }
        },
      );
      return;
    }

    final completer = Completer<Response>();
    _inFlight[key] = completer;
    options.extra['_dedupKey'] = key;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final key = response.requestOptions.extra['_dedupKey'] as String?;
    if (key != null && _inFlight.containsKey(key)) {
      final completer = _inFlight.remove(key);
      completer?.complete(response);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final key = err.requestOptions.extra['_dedupKey'] as String?;
    if (key != null && _inFlight.containsKey(key)) {
      final completer = _inFlight.remove(key);
      completer?.completeError(err);
    }
    handler.next(err);
  }
}

class ApiClient {
  final Dio dio;
  final SecureStorageService? storage;

  ApiClient({String? baseUrl, this.storage})
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? 'http://10.0.2.2:3000/api/v1', // Android emulator default
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    dio.interceptors.add(DeduplicationInterceptor());
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Token injection hook
          if (storage != null && !options.headers.containsKey('Authorization')) {
            final token = await storage!.getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Check for 401 Unauthorized requiring token refresh
          final is401 = error.response?.statusCode == 401;
          final isAuthEndpoint = error.requestOptions.path.contains('/auth/login') ||
              error.requestOptions.path.contains('/auth/refresh');
          final isRetry = error.requestOptions.extra['isRetry'] == true;

          if (is401 && !isAuthEndpoint && !isRetry && storage != null) {
            try {
              final refreshToken = await storage!.getRefreshToken();
              if (refreshToken != null) {
                // Create dedicated un-intercepted Dio instance for refresh call
                final refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
                final refreshRes = await refreshDio.post(
                  '/auth/refresh',
                  data: {'refreshToken': refreshToken},
                );

                final envelope = refreshRes.data as Map<String, dynamic>;
                final data = (envelope['data'] ?? envelope) as Map<String, dynamic>;
                final newAccessToken = data['accessToken'] as String?;
                final newRefreshToken = data['refreshToken'] as String?;

                if (newAccessToken != null && newRefreshToken != null) {
                  await storage!.saveTokens(
                    accessToken: newAccessToken,
                    refreshToken: newRefreshToken,
                  );

                  // Retry the original request
                  final retryOptions = error.requestOptions;
                  retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                  retryOptions.extra['isRetry'] = true;

                  final retryResponse = await dio.fetch(retryOptions);
                  return handler.resolve(retryResponse);
                }
              }
            } catch (_) {
              await storage!.clearAll();
            }
          }

          return handler.next(error);
        },
      ),
    );
  }
}
