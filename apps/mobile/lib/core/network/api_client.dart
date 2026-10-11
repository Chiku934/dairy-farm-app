import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio;

  ApiClient({String? baseUrl})
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
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Token injection hook
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          // Centralized error mapping
          return handler.next(error);
        },
      ),
    );
  }
}
