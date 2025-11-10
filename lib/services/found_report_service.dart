import 'dart:io';
import '../models/found_report.dart';
import 'api_client.dart';
import 'package:flutter/foundation.dart';

class FoundReportService {
  final ApiClient _apiClient;

  FoundReportService(this._apiClient);

  Future<FoundReportResult> reportFoundPerson({
    required FoundReportCreate data,
    File? photo,
  }) async {
    try {
      final fields = <String, String>{
        'missing_person_id': data.missingPersonId,
        'found_latitude': data.latitude.toString(),
        'found_longitude': data.longitude.toString(),
        if (data.address != null) 'found_address': data.address!,
        'found_date': data.foundDate.toIso8601String(),
        if (data.description != null) 'description': data.description!,
        if (data.contactInfo != null) 'contact_info': data.contactInfo!,
      };

      final files = <String, File>{};
      if (photo != null) {
        files['photo'] = photo;
      }

      final response = await _apiClient.postMultipart(
        '/found-reports/',
        fields: fields,
        files: files.isEmpty ? null : files,
      );

      if (response.isSuccess) {
        if (response.data == null) {
          if (kDebugMode) {
            debugPrint(
                'Reporte encontrado sin cuerpo (status ${response.statusCode})');
          }
          return FoundReportResult.error(
            'El servidor no devolvió datos del hallazgo',
          );
        }

        try {
          final report =
              FoundReport.fromJson(response.data as Map<String, dynamic>);
          return FoundReportResult.success(report);
        } catch (e, stack) {
          if (kDebugMode) {
            debugPrint('Error parseando hallazgo: ${response.data} -> $e');
            debugPrint('$stack');
          }
          return FoundReportResult.error('Respuesta inválida del servidor');
        }
      }

      return FoundReportResult.error(
        response.error ?? 'Error al reportar hallazgo',
      );
    } catch (e) {
      return FoundReportResult.error('Error inesperado: $e');
    }
  }

  Future<FoundReportListResult> getFoundReportsForMissingPerson(
      String reportId) async {
    try {
      final response =
          await _apiClient.get('/found-reports/missing-person/$reportId');

      if (response.isSuccess && response.data != null) {
        final raw = response.data;
        final List<dynamic> dataList = raw is List ? raw : [raw];
        final reports = dataList
            .whereType<Map<String, dynamic>>()
            .map(FoundReport.fromJson)
            .toList();
        return FoundReportListResult.success(reports);
      }

      return FoundReportListResult.error(
        response.error ?? 'Error al obtener hallazgos',
      );
    } catch (e) {
      return FoundReportListResult.error('Error inesperado: $e');
    }
  }

  Future<FoundReportListResult> getMyFoundReports() async {
    try {
      final response = await _apiClient.get('/found-reports/me');

      if (response.isSuccess && response.data != null) {
        final data = response.data as List<dynamic>;
        final reports = data
            .map((json) => FoundReport.fromJson(json as Map<String, dynamic>))
            .toList();
        return FoundReportListResult.success(reports);
      }

      return FoundReportListResult.error(
        response.error ?? 'Error al obtener mis hallazgos',
      );
    } catch (e) {
      return FoundReportListResult.error('Error inesperado: $e');
    }
  }

  Future<bool> confirmFoundReport(String reportId) async {
    try {
      final response =
          await _apiClient.patch('/found-reports/$reportId/confirm');
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectFoundReport(String reportId) async {
    try {
      final response =
          await _apiClient.patch('/found-reports/$reportId/reject');
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }
}

class FoundReportResult {
  final FoundReport? report;
  final String? error;
  final bool isSuccess;

  FoundReportResult._({
    this.report,
    this.error,
    required this.isSuccess,
  });

  factory FoundReportResult.success(FoundReport report) {
    return FoundReportResult._(
      report: report,
      isSuccess: true,
    );
  }

  factory FoundReportResult.error(String error) {
    return FoundReportResult._(
      error: error,
      isSuccess: false,
    );
  }
}

class FoundReportListResult {
  final List<FoundReport>? reports;
  final String? error;
  final bool isSuccess;

  FoundReportListResult._({
    this.reports,
    this.error,
    required this.isSuccess,
  });

  factory FoundReportListResult.success(List<FoundReport> reports) {
    return FoundReportListResult._(
      reports: reports,
      isSuccess: true,
    );
  }

  factory FoundReportListResult.error(String error) {
    return FoundReportListResult._(
      error: error,
      isSuccess: false,
    );
  }
}


