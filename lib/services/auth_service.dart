import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../config/app_config.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  Future<AuthResult> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required DateTime dateOfBirth,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/register',
        body: {
          'email': email,
          'password': password,
          'full_name': fullName,
          'phone': phone,
          'date_of_birth': dateOfBirth.toIso8601String().split('T')[0],
        },
        requiresAuth: false,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final token = data['access_token'] as String;
        final userData = data['user'] as Map<String, dynamic>;

        await _apiClient.saveToken(token);
        await _saveUserData(userData);

        final user = User.fromJson(userData);
        return AuthResult.success(user);
      } else {
        return AuthResult.error(response.error ?? 'Error al registrar');
      }
    } catch (e) {
      return AuthResult.error('Error inesperado: $e');
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/login',
        body: {
          'email': email,
          'password': password,
        },
        requiresAuth: false,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final token = data['access_token'] as String;
        final userData = data['user'] as Map<String, dynamic>;

        await _apiClient.saveToken(token);
        await _saveUserData(userData);

        final user = User.fromJson(userData);
        return AuthResult.success(user);
      } else {
        return AuthResult.error(response.error ?? 'Error al iniciar sesión');
      }
    } catch (e) {
      return AuthResult.error('Error inesperado: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } catch (e) {
      // Ignore errors on logout
    } finally {
      await _apiClient.deleteToken();
      await _clearUserData();
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final response = await _apiClient.get('/auth/me');

      if (response.isSuccess && response.data != null) {
        final userData = response.data as Map<String, dynamic>;
        await _saveUserData(userData);
        return User.fromJson(userData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isAuthenticated() async {
    final token = await _apiClient.getToken();
    if (token == null || token.isEmpty) {
      return false;
    }
    
    // Verificar que el token sea válido consultando el usuario actual
    try {
      final user = await getCurrentUser();
      return user != null;
    } catch (e) {
      // Si falla, el token probablemente está expirado
      await _apiClient.deleteToken();
      await _clearUserData();
      return false;
    }
  }

  Future<User?> getCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(AppConfig.userKey);
      if (userJson != null) {
        final userData = jsonDecode(userJson) as Map<String, dynamic>;
        return User.fromJson(userData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.userKey, jsonEncode(userData));
  }

  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.userKey);
  }

  /// Actualiza la ubicación del usuario en su perfil
  Future<bool> updateUserLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Endpoint correcto: PUT /users/me/location con formato plano
      final response = await _apiClient.put(
        '/users/me/location',
        body: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      if (response.isSuccess) {
        // Actualizar datos del usuario en cache
        await getCurrentUser();
        if (kDebugMode) {
          print('Ubicación actualizada exitosamente en el perfil');
        }
        return true;
      }
      
      // Log del error para debugging
      if (kDebugMode) {
        print('Error al actualizar ubicación: ${response.error} (Status: ${response.statusCode})');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Excepción al actualizar ubicación: $e');
      }
      return false;
    }
  }
}

class AuthResult {
  final User? user;
  final String? error;
  final bool isSuccess;

  AuthResult._({
    this.user,
    this.error,
    required this.isSuccess,
  });

  factory AuthResult.success(User user) {
    return AuthResult._(
      user: user,
      isSuccess: true,
    );
  }

  factory AuthResult.error(String error) {
    return AuthResult._(
      error: error,
      isSuccess: false,
    );
  }
}
