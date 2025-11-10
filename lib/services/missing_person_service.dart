import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/missing_person.dart';
import 'api_client.dart';

class MissingPersonService {
  final ApiClient _apiClient;

  MissingPersonService(this._apiClient);

  Future<MissingPerson?> _fetchFullReport(Map<String, dynamic> summary) async {
    final id = summary['id'] as String?;
    if (id == null) {
      if (kDebugMode) {
        debugPrint('Resumen sin ID: $summary');
      }
      return null;
    }

    try {
      final detailResponse = await _apiClient.get('/missing-persons/$id');
      if (detailResponse.isSuccess && detailResponse.data != null) {
        return MissingPerson.fromJson(
            detailResponse.data as Map<String, dynamic>);
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Error obteniendo detalle para $id: $e');
        debugPrint('$stack');
      }
    }

    return _buildMissingPersonFromSummary(summary);
  }

  MissingPerson _buildMissingPersonFromSummary(
      Map<String, dynamic> summary) {
    final createdAt = DateTime.tryParse(summary['created_at'] as String? ?? '') ??
        DateTime.now();

    return MissingPerson(
      id: summary['id'] as String? ?? '',
      reporterId: summary['reporter_id'] as String? ?? '',
      fullName: summary['full_name'] as String? ?? 'Sin nombre',
      nickname: summary['nickname'] as String?,
      age: (summary['age'] as num?)?.toInt() ?? 0,
      gender: summary['gender'] as String? ?? 'unknown',
      physicalDescription:
          summary['physical_description'] as String? ?? 'Sin descripción',
      clothingDescription:
          summary['clothing_description'] as String? ?? 'Sin datos',
      medicalConditions: summary['medical_conditions'] as String?,
      photoUrl: summary['photo_url'] as String? ?? '',
      additionalPhotos: null,
      lastSeenLocation: LocationData(
        latitude: (summary['last_seen_latitude'] as num?)?.toDouble() ?? 0,
        longitude: (summary['last_seen_longitude'] as num?)?.toDouble() ?? 0,
        address: summary['last_seen_address'] as String?,
        city: summary['last_seen_city'] as String?,
        province: summary['last_seen_province'] as String?,
      ),
      lastSeenDate:
          DateTime.tryParse(summary['last_seen_date'] as String? ?? '') ?? createdAt,
      contactName: summary['contact_name'] as String? ?? 'Sin nombre',
      contactPhone: summary['contact_phone'] as String? ?? 'Sin teléfono',
      contactEmail: summary['contact_email'] as String?,
      relationship: summary['relationship'] as String? ?? 'Sin relación',
      circumstances:
          summary['circumstances'] as String? ?? 'Sin información disponible',
      additionalInfo: summary['additional_info'] as String?,
      status: summary['status'] as String? ?? 'unknown',
      createdAt: createdAt,
      updatedAt:
          DateTime.tryParse(summary['updated_at'] as String? ?? '') ?? createdAt,
      editCount: summary['edit_count'] as int?,
      distanceKm:
          (summary['distance_km'] as num?)?.toDouble(),
      stats: MissingPersonStats(
        alertsSent: summary['alerts_sent'] as int? ?? 0,
        sightings: summary['sightings_count'] as int? ?? 0,
        foundReports: summary['found_reports_count'] as int? ?? 0,
      ),
    );
  }

  Future<MissingPersonResult> createReport({
    required MissingPersonCreate data,
    required File photo,
    List<File>? additionalPhotos,
  }) async {
    try {
      final json = data.toJson();
      final fields = <String, String>{};
      json.forEach((key, value) {
        if (value != null) {
          fields[key] = value.toString();
        }
      });

      final files = <String, File>{'photo': photo};

      if (kDebugMode) {
        debugPrint('=== Crear Missing Person ===');
        debugPrint('Campos (JSON): $json');
        debugPrint('Campos (multipart): $fields');
        debugPrint('Foto principal: ${photo.path}');
        final fileExists = await photo.exists();
        final fileSize = fileExists ? await photo.length() : -1;
        debugPrint('Foto existe: $fileExists, tamaño: $fileSize bytes');
      }

      final response = await _apiClient.postMultipart(
        '/missing-persons/',
        fields: fields,
        files: files,
      );

      if (kDebugMode) {
        debugPrint(
            'Respuesta crear reporte -> status: ${response.statusCode}, éxito: ${response.isSuccess}');
        debugPrint('Datos: ${response.data}');
        debugPrint('Error: ${response.error}');
      }

      if (response.isSuccess && response.data != null) {
        final person = MissingPerson.fromJson(
            response.data as Map<String, dynamic>);
        return MissingPersonResult.success(person);
      } else {
        return MissingPersonResult.error(
            response.error ?? 'Error al crear reporte');
      }
    } catch (e) {
      return MissingPersonResult.error('Error inesperado: $e');
    }
  }

  Future<MissingPersonListResult> getNearbyMissingPersons({
    double? radiusKm,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (radiusKm != null) queryParams['radius_km'] = radiusKm;
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;

      final response = await _apiClient.get(
        '/missing-persons/',
        queryParams: queryParams,
      );

      if (response.isSuccess && response.data != null) {
        final List<dynamic> data = response.data as List<dynamic>;
        final persons = <MissingPerson>[];
        for (final item in data) {
          if (item == null) {
            if (kDebugMode) {
              debugPrint('Elemento nulo en missing persons');
            }
            continue;
          }
          try {
            persons.add(MissingPerson.fromJson(item as Map<String, dynamic>));
          } catch (e, stack) {
            if (kDebugMode) {
              debugPrint('Error parseando persona: $item -> $e');
              debugPrint('$stack');
            }
          }
        }
        if (kDebugMode) {
          debugPrint('Total de reportes parseados: ${persons.length}');
        }
        return MissingPersonListResult.success(persons);
      } else {
        return MissingPersonListResult.error(
            response.error ?? 'Error al obtener reportes');
      }
    } catch (e) {
      return MissingPersonListResult.error('Error inesperado: $e');
    }
  }

  Future<MissingPersonListResult> getMyReports() async {
    try {
      final response = await _apiClient.get('/missing-persons/me');

      if (response.isSuccess && response.data != null) {
        final data = response.data as List<dynamic>;
        final futures = data
            .whereType<Map<String, dynamic>>()
            .map((summary) => _fetchFullReport(summary))
            .toList();

        final results = await Future.wait(futures);
        final persons = results.whereType<MissingPerson>().toList();
        return MissingPersonListResult.success(persons);
      }

      return MissingPersonListResult.error(
          response.error ?? 'Error al obtener mis reportes');
    } catch (e) {
      return MissingPersonListResult.error('Error inesperado: $e');
    }
  }

  Future<MissingPersonResult> getDetail(String reportId) async {
    try {
      final response = await _apiClient.get('/missing-persons/$reportId');

      if (response.isSuccess && response.data != null) {
        final person = MissingPerson.fromJson(
            response.data as Map<String, dynamic>);
        return MissingPersonResult.success(person);
      } else {
        return MissingPersonResult.error(
            response.error ?? 'Error al obtener detalle');
      }
    } catch (e) {
      return MissingPersonResult.error('Error inesperado: $e');
    }
  }

  Future<MissingPersonResult> updateReport({
    required String reportId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final response = await _apiClient.put(
        '/missing-persons/$reportId',
        body: updates,
      );

      if (response.isSuccess && response.data != null) {
        final person = MissingPerson.fromJson(
            response.data as Map<String, dynamic>);
        return MissingPersonResult.success(person);
      } else {
        return MissingPersonResult.error(
            response.error ?? 'Error al actualizar reporte');
      }
    } catch (e) {
      return MissingPersonResult.error('Error inesperado: $e');
    }
  }

  Future<bool> markAsFound(String reportId) async {
    try {
      final response = await _apiClient.patch(
        '/missing-persons/$reportId/mark-found',
      );

      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancelReport(String reportId) async {
    try {
      final response = await _apiClient.delete('/missing-persons/$reportId');

      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }
}

class MissingPersonResult {
  final MissingPerson? person;
  final String? error;
  final bool isSuccess;

  MissingPersonResult._({
    this.person,
    this.error,
    required this.isSuccess,
  });

  factory MissingPersonResult.success(MissingPerson person) {
    return MissingPersonResult._(
      person: person,
      isSuccess: true,
    );
  }

  factory MissingPersonResult.error(String error) {
    return MissingPersonResult._(
      error: error,
      isSuccess: false,
    );
  }
}

class MissingPersonListResult {
  final List<MissingPerson>? persons;
  final String? error;
  final bool isSuccess;

  MissingPersonListResult._({
    this.persons,
    this.error,
    required this.isSuccess,
  });

  factory MissingPersonListResult.success(List<MissingPerson> persons) {
    return MissingPersonListResult._(
      persons: persons,
      isSuccess: true,
    );
  }

  factory MissingPersonListResult.error(String error) {
    return MissingPersonListResult._(
      error: error,
      isSuccess: false,
    );
  }
}
