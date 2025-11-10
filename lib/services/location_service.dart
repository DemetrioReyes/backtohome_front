import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Verifica si los permisos están concedidos
  static Future<bool> hasPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  /// Solicita permisos de ubicación
  static Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  /// Verifica si el servicio de ubicación está habilitado
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Obtiene la ubicación actual del usuario
  static Future<Position?> getCurrentLocation() async {
    try {
      // Verificar si el servicio de ubicación está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || 
            permission == LocationPermission.deniedForever) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Obtener ubicación con precisión media y más tiempo
      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 20),
        );
      } catch (e) {
        // Si falla con precisión media, intentar con baja precisión
        try {
          return await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 15),
          );
        } catch (_) {
          return null;
        }
      }
    } catch (e) {
      return null;
    }
  }

  /// Obtiene la última ubicación conocida (más rápido)
  static Future<Position?> getLastKnownLocation() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      // Solo usar si es reciente (menos de 5 minutos)
      if (position != null) {
        final now = DateTime.now();
        final age = now.difference(position.timestamp);
        if (age.inMinutes < 5) {
          return position;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

