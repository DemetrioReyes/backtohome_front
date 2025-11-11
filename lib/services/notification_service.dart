import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import 'user_service.dart';

class NotificationService with ChangeNotifier {
  NotificationService({required bool firebaseAvailable})
      : _isFirebaseAvailable = firebaseAvailable;

  UserService? _userService;
  SharedPreferences? _preferences;
  StreamSubscription<String>? _tokenSubscription;
  Timer? _retryTimer;
  bool _isInitialized = false;
  bool _isPermissionChecked = false;
  bool _isFirebaseAvailable;
  String? _pendingToken;
  int _retryAttempts = 0;

  void updateDependencies({
    required UserService userService,
    required SharedPreferences preferences,
    bool? firebaseAvailable,
  }) {
    if (firebaseAvailable != null) {
      _isFirebaseAvailable = firebaseAvailable;
    }

    _userService = userService;
    _preferences = preferences;

    if (!_isFirebaseAvailable) {
      return;
    }

    if (!_isInitialized) {
      _isInitialized = true;
      unawaited(_initializeMessaging());
    } else if (_pendingToken != null) {
      unawaited(_syncTokenWithBackend(_pendingToken!, force: true));
    }
  }

  Future<void> _initializeMessaging() async {
    if (!_isFirebaseAvailable || Firebase.apps.isEmpty) return;

    try {
      await _ensurePermissions();
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final initialToken =
          await FirebaseMessaging.instance.getToken().catchError((e, stack) {
        if (kDebugMode) {
          debugPrint('Error obteniendo token inicial FCM: $e\n$stack');
        }
        return null;
      });
      if (initialToken != null) {
        await _syncTokenWithBackend(initialToken);
      }

      _tokenSubscription ??=
          FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        unawaited(_syncTokenWithBackend(token, force: true));
      });
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Error iniciando Firebase Messaging: $e\n$stack');
      }
    }
  }

  Future<void> _ensurePermissions() async {
    if (!_isFirebaseAvailable || Firebase.apps.isEmpty) return;
    if (_isPermissionChecked) return;
    _isPermissionChecked = true;

    final messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.getNotificationSettings();

    if (settings.authorizationStatus == AuthorizationStatus.notDetermined ||
        settings.authorizationStatus == AuthorizationStatus.denied) {
      settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (kDebugMode) {
        debugPrint(
            'Permisos de notificaciones: ${settings.authorizationStatus}');
      }
    }
  }

  Future<void> syncDeviceToken({bool force = false}) async {
    if (!_isFirebaseAvailable || Firebase.apps.isEmpty) return;
    try {
      await _ensurePermissions();

      final token =
          await FirebaseMessaging.instance.getToken().catchError((e, stack) {
        if (kDebugMode) {
          debugPrint('Error obteniendo token FCM: $e\n$stack');
        }
        return null;
      });
      if (token != null) {
        await _syncTokenWithBackend(token, force: force);
      } else {
        if (kDebugMode) {
          debugPrint(
            'No se pudo obtener token FCM (token nulo). Se reintentará automáticamente.',
          );
        }
        _scheduleRetry(_pendingToken ?? '');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Excepción en syncDeviceToken: $e\n$stack');
      }
    }
  }

  Future<void> _syncTokenWithBackend(
    String token, {
    bool force = false,
  }) async {
    if (token.isEmpty) return;

    if (kDebugMode) {
      debugPrint('Intentando sincronizar token FCM: $token (force: $force)');
    }

    final preferences = _preferences;
    final userService = _userService;

    if (preferences == null || userService == null) {
      _pendingToken = token;
      return;
    }

    final cachedToken = preferences.getString(AppConfig.fcmTokenKey);
    if (!force && cachedToken == token) {
      _pendingToken = null;
      return;
    }

    try {
      final result = await userService.updateSettings(fcmToken: token);

      if (result.isSuccess) {
        await preferences.setString(AppConfig.fcmTokenKey, token);
        _retryTimer?.cancel();
        _retryAttempts = 0;
        _pendingToken = null;
        if (kDebugMode) {
          debugPrint('Token FCM sincronizado correctamente');
        }
      } else {
        _pendingToken = token;
        if (kDebugMode) {
          debugPrint(
            'Fallo al sincronizar token FCM: ${result.error ?? 'Error desconocido'}',
          );
        }
        _scheduleRetry(token);
      }
    } catch (e, stack) {
      _pendingToken = token;
      if (kDebugMode) {
        debugPrint('Excepción al sincronizar token FCM: $e\n$stack');
      }
      _scheduleRetry(token);
    }
  }

  Future<void> clearStoredToken() async {
    _pendingToken = null;
    final preferences = _preferences;
    if (preferences != null) {
      await preferences.remove(AppConfig.fcmTokenKey);
    }
    _retryTimer?.cancel();
    _retryAttempts = 0;
  }

  void _scheduleRetry(String token) {
    if (token.isEmpty) {
      return;
    }
    _retryTimer?.cancel();
    _retryAttempts = math.min(_retryAttempts + 1, 6);
    final delaySeconds = math.min(60, math.pow(2, _retryAttempts).toInt());
    if (kDebugMode) {
      debugPrint(
          'Programando reintento para token FCM en $delaySeconds segundos (intento $_retryAttempts)');
    }
    _retryTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_isFirebaseAvailable || Firebase.apps.isEmpty) return;
      unawaited(_syncTokenWithBackend(token, force: true));
    });
  }

  @override
  void dispose() {
    _tokenSubscription?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }
}

