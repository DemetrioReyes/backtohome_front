import '../models/user.dart';
import 'api_client.dart';

class UserService {
  final ApiClient _apiClient;

  UserService(this._apiClient);

  Future<UserProfileResult> getMyProfile() async {
    try {
      final response = await _apiClient.get('/users/me/profile');

      if (response.isSuccess && response.data != null) {
        final profile =
            UserProfile.fromJson(response.data as Map<String, dynamic>);
        return UserProfileResult.success(profile);
      }

      return UserProfileResult.error(
        response.error ?? 'Error al obtener el perfil del usuario',
      );
    } catch (e) {
      return UserProfileResult.error('Error inesperado: $e');
    }
  }

  Future<UserProfileResult> updateProfile({
    required String fullName,
    String? phone,
  }) async {
    try {
      final body = <String, dynamic>{
        'full_name': fullName,
        if (phone != null) 'phone': phone,
      };

      final response = await _apiClient.put(
        '/users/me/profile',
        body: body,
      );

      if (response.isSuccess && response.data != null) {
        final profile =
            UserProfile.fromJson(response.data as Map<String, dynamic>);
        return UserProfileResult.success(profile);
      }

      return UserProfileResult.error(
        response.error ?? 'Error al actualizar el perfil',
      );
    } catch (e) {
      return UserProfileResult.error('Error inesperado: $e');
    }
  }

  Future<UserSettingsResult> updateSettings({
    double? notificationRadius,
    String? fcmToken,
    bool? pushEnabled,
    bool? emailEnabled,
  }) async {
    try {
      final body = <String, dynamic>{
        if (notificationRadius != null)
          'notification_radius': notificationRadius,
        if (fcmToken != null) 'fcm_token': fcmToken,
        if (pushEnabled != null) 'push_enabled': pushEnabled,
        if (emailEnabled != null) 'email_enabled': emailEnabled,
      };

      final response = await _apiClient.put(
        '/users/me/settings',
        body: body,
      );

      if (response.isSuccess && response.data != null) {
        final settings =
            UserSettings.fromJson(response.data as Map<String, dynamic>);
        return UserSettingsResult.success(settings);
      }

      return UserSettingsResult.error(
        response.error ?? 'Error al actualizar las configuraciones',
      );
    } catch (e) {
      return UserSettingsResult.error('Error inesperado: $e');
    }
  }
}

class UserProfileResult {
  final UserProfile? profile;
  final String? error;
  final bool isSuccess;

  UserProfileResult._({
    this.profile,
    this.error,
    required this.isSuccess,
  });

  factory UserProfileResult.success(UserProfile profile) {
    return UserProfileResult._(
      profile: profile,
      isSuccess: true,
    );
  }

  factory UserProfileResult.error(String error) {
    return UserProfileResult._(
      error: error,
      isSuccess: false,
    );
  }
}

class UserSettingsResult {
  final UserSettings? settings;
  final String? error;
  final bool isSuccess;

  UserSettingsResult._({
    this.settings,
    this.error,
    required this.isSuccess,
  });

  factory UserSettingsResult.success(UserSettings settings) {
    return UserSettingsResult._(
      settings: settings,
      isSuccess: true,
    );
  }

  factory UserSettingsResult.error(String error) {
    return UserSettingsResult._(
      error: error,
      isSuccess: false,
    );
  }
}


