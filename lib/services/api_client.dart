import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mime/mime.dart';
import '../config/app_config.dart';

class ApiClient {
  final http.Client _client = http.Client();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String get baseUrl => AppConfig.apiBaseUrl + AppConfig.apiVersion;

  Future<String?> getToken() async {
    return await _storage.read(key: AppConfig.tokenKey);
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConfig.tokenKey, value: token);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: AppConfig.tokenKey);
  }

  Future<Map<String, String>> getHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParams);
      final headers = await getHeaders(includeAuth: requiresAuth);

      final response = await _client.get(uri, headers: headers);

      return _handleResponse<T>(response);
    } on SocketException {
      return ApiResponse.error('No hay conexión a internet');
    } catch (e) {
      return ApiResponse.error('Error inesperado: $e');
    }
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final headers = await getHeaders(includeAuth: requiresAuth);

      final response = await _client.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse<T>(response);
    } on SocketException {
      return ApiResponse.error('No hay conexión a internet');
    } catch (e) {
      return ApiResponse.error('Error inesperado: $e');
    }
  }

  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final headers = await getHeaders(includeAuth: requiresAuth);

      final response = await _client.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse<T>(response);
    } on SocketException {
      return ApiResponse.error('No hay conexión a internet');
    } catch (e) {
      return ApiResponse.error('Error inesperado: $e');
    }
  }

  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final headers = await getHeaders(includeAuth: requiresAuth);

      final response = await _client.patch(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse<T>(response);
    } on SocketException {
      return ApiResponse.error('No hay conexión a internet');
    } catch (e) {
      return ApiResponse.error('Error inesperado: $e');
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final headers = await getHeaders(includeAuth: requiresAuth);

      final response = await _client.delete(uri, headers: headers);

      return _handleResponse<T>(response);
    } on SocketException {
      return ApiResponse.error('No hay conexión a internet');
    } catch (e) {
      return ApiResponse.error('Error inesperado: $e');
    }
  }

  Future<ApiResponse<T>> postMultipart<T>(
    String endpoint, {
    required Map<String, String> fields,
    Map<String, File>? files,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      if (requiresAuth) {
        final token = await getToken();
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }

      // Add fields
      request.fields.addAll(fields);

      // Add files
      if (files != null && files.isNotEmpty) {
        for (final entry in files.entries) {
          final file = entry.value;
          final filePath = file.path;
          final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';
          MediaType? mediaType;
          try {
            mediaType = MediaType.parse(mimeType);
          } catch (_) {
            mediaType = null;
          }

          final multipartFile = await http.MultipartFile.fromPath(
            entry.key,
            filePath,
            contentType: mediaType,
          );
          request.files.add(multipartFile);
        }
      }

      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse<T>(response);
    } on SocketException {
      return ApiResponse.error('No hay conexión a internet');
    } catch (e) {
      return ApiResponse.error('Error inesperado: $e');
    }
  }

  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParams]) {
    final path = baseUrl + endpoint;
    if (queryParams != null && queryParams.isNotEmpty) {
      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');
      return Uri.parse('$path?$queryString');
    }
    return Uri.parse(path);
  }

  ApiResponse<T> _handleResponse<T>(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    if (statusCode >= 200 && statusCode < 300) {
      if (body.isEmpty) {
        return ApiResponse.success(null);
      }
      try {
        final data = jsonDecode(body);
        return ApiResponse.success(data);
      } catch (e) {
        return ApiResponse.error('Error al procesar la respuesta');
      }
    } else {
      String errorMessage = 'Error desconocido';
      try {
        final errorData = jsonDecode(body);
        errorMessage = errorData['detail'] ?? errorData['message'] ?? errorMessage;
      } catch (_) {
        errorMessage = 'Error $statusCode';
      }
      return ApiResponse.error(errorMessage, statusCode: statusCode);
    }
  }

  void dispose() {
    _client.close();
  }
}

class ApiResponse<T> {
  final T? data;
  final String? error;
  final int? statusCode;
  final bool isSuccess;

  ApiResponse._({
    this.data,
    this.error,
    this.statusCode,
    required this.isSuccess,
  });

  factory ApiResponse.success(T? data) {
    return ApiResponse._(
      data: data,
      isSuccess: true,
    );
  }

  factory ApiResponse.error(String error, {int? statusCode}) {
    return ApiResponse._(
      error: error,
      statusCode: statusCode,
      isSuccess: false,
    );
  }
}
