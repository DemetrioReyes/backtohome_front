class AppConfig {
  // API Configuration
  static const String apiBaseUrl = 'https://returtohome-api.onrender.com'; // API desplegada en Render
  static const String apiVersion = '/api';

  // Firebase Configuration
  static const String firebaseSenderId = '628343819365'; // Firebase Cloud Messaging Sender ID
  static const String firebaseProjectId = 'backtohome-d6663';

  // App Configuration
  static const String appName = 'BackToHome';
  static const String appVersion = '1.0.0';

  // Default Values
  static const double defaultRadius = 20.0; // km
  static const double maxRadius = 100.0; // km
  static const double minRadius = 1.0; // km

  // Limits
  static const int maxActiveReports = 2;
  static const int maxPhotosPerReport = 5;
  static const int maxPhotoSizeMB = 5;

  // Map Configuration
  static const double defaultLat = 18.4861; // Santo Domingo
  static const double defaultLng = -69.9312;
  static const double defaultZoom = 12.0;

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String fcmTokenKey = 'fcm_token';
}
