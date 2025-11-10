import 'dart:io';
import '../models/sighting.dart';
import 'api_client.dart';

class SightingService {
  final ApiClient _apiClient;

  SightingService(this._apiClient);

  Future<SightingResult> reportSighting({
    required SightingCreate data,
    File? photo,
  }) async {
    try {
      final fields = <String, String>{
        'missing_person_id': data.missingPersonId,
        'sighting_latitude': data.latitude.toString(),
        'sighting_longitude': data.longitude.toString(),
        if (data.address != null) 'sighting_address': data.address!,
        'sighting_date': data.sightingDate.toIso8601String(),
        if (data.description != null) 'description': data.description!,
      };

      final files = <String, File>{};
      if (photo != null) {
        files['photo'] = photo;
      }

      final response = await _apiClient.postMultipart(
        '/sightings/',
        fields: fields,
        files: files.isEmpty ? null : files,
      );

      if (response.isSuccess && response.data != null) {
        final sighting =
            Sighting.fromJson(response.data as Map<String, dynamic>);
        return SightingResult.success(sighting);
      }

      return SightingResult.error(
        response.error ?? 'Error al reportar avistamiento',
      );
    } catch (e) {
      return SightingResult.error('Error inesperado: $e');
    }
  }

  Future<SightingListResult> getSightingsForMissingPerson(String reportId) async {
    try {
      final response =
          await _apiClient.get('/sightings/missing-person/$reportId');

      if (response.isSuccess && response.data != null) {
        final data = response.data as List<dynamic>;
        final sightings = data
            .map((json) => Sighting.fromJson(json as Map<String, dynamic>))
            .toList();
        return SightingListResult.success(sightings);
      }

      return SightingListResult.error(
        response.error ?? 'Error al obtener avistamientos',
      );
    } catch (e) {
      return SightingListResult.error('Error inesperado: $e');
    }
  }

  Future<SightingListResult> getMySightings() async {
    try {
      final response = await _apiClient.get('/sightings/me');

      if (response.isSuccess && response.data != null) {
        final data = response.data as List<dynamic>;
        final sightings = data
            .map((json) => Sighting.fromJson(json as Map<String, dynamic>))
            .toList();
        return SightingListResult.success(sightings);
      }

      return SightingListResult.error(
        response.error ?? 'Error al obtener mis avistamientos',
      );
    } catch (e) {
      return SightingListResult.error('Error inesperado: $e');
    }
  }
}

class SightingResult {
  final Sighting? sighting;
  final String? error;
  final bool isSuccess;

  SightingResult._({
    this.sighting,
    this.error,
    required this.isSuccess,
  });

  factory SightingResult.success(Sighting sighting) {
    return SightingResult._(
      sighting: sighting,
      isSuccess: true,
    );
  }

  factory SightingResult.error(String error) {
    return SightingResult._(
      error: error,
      isSuccess: false,
    );
  }
}

class SightingListResult {
  final List<Sighting>? sightings;
  final String? error;
  final bool isSuccess;

  SightingListResult._({
    this.sightings,
    this.error,
    required this.isSuccess,
  });

  factory SightingListResult.success(List<Sighting> sightings) {
    return SightingListResult._(
      sightings: sightings,
      isSuccess: true,
    );
  }

  factory SightingListResult.error(String error) {
    return SightingListResult._(
      error: error,
      isSuccess: false,
    );
  }
}


