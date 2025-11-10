import 'missing_person.dart';
import 'sighting.dart';

class FoundReport {
  final String id;
  final String missingPersonId;
  final String reportedBy;
  final LocationData location;
  final DateTime foundDate;
  final String? description;
  final String? photoUrl;
  final String status;
  final String? confirmedBy;
  final DateTime? confirmedAt;
  final String? rejectionReason;
  final DateTime createdAt;
  final ReporterInfo? reporter;
  final String? contactInfo;

  FoundReport({
    required this.id,
    required this.missingPersonId,
    required this.reportedBy,
    required this.location,
    required this.foundDate,
    this.description,
    this.photoUrl,
    required this.status,
    this.confirmedBy,
    this.confirmedAt,
    this.rejectionReason,
    required this.createdAt,
    this.reporter,
    this.contactInfo,
  });

  factory FoundReport.fromJson(Map<String, dynamic> json) {
    return FoundReport(
      id: json['id'] as String,
      missingPersonId: json['missing_person_id'] as String,
      reportedBy: json['reported_by'] as String,
      location: _mapFoundLocation(json['location'], json),
      foundDate: DateTime.parse(json['found_date'] as String),
      description: json['description'] as String?,
      photoUrl: json['photo_url'] as String?,
      status: json['status'] as String,
      confirmedBy: json['confirmed_by'] as String?,
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'] as String)
          : null,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      reporter: _mapReporter(json),
      contactInfo: json['contact_info'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'missing_person_id': missingPersonId,
      'reported_by': reportedBy,
      'location': location.toJson(),
      'found_latitude': location.latitude,
      'found_longitude': location.longitude,
      'found_address': location.address,
      'found_date': foundDate.toIso8601String(),
      'description': description,
      'photo_url': photoUrl,
      'status': status,
      'confirmed_by': confirmedBy,
      'confirmed_at': confirmedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
      'contact_info': contactInfo,
    };
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isRejected => status == 'rejected';

  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'confirmed':
        return 'Confirmado';
      case 'rejected':
        return 'Rechazado';
      default:
        return status;
    }
  }
}

LocationData _mapFoundLocation(
  dynamic locationJson,
  Map<String, dynamic> fallbackJson,
) {
  if (locationJson is Map<String, dynamic>) {
    return LocationData.fromJson(locationJson);
  }

  double? latitude;
  double? longitude;

  final rawLat = fallbackJson['found_latitude'];
  final rawLng = fallbackJson['found_longitude'];

  if (rawLat is num) {
    latitude = rawLat.toDouble();
  } else if (rawLat is String) {
    latitude = double.tryParse(rawLat);
  }

  if (rawLng is num) {
    longitude = rawLng.toDouble();
  } else if (rawLng is String) {
    longitude = double.tryParse(rawLng);
  }

  return LocationData(
    latitude: latitude ?? 0,
    longitude: longitude ?? 0,
    address: fallbackJson['found_address'] as String?,
    city: null,
    province: null,
  );
}

ReporterInfo? _mapReporter(Map<String, dynamic> json) {
  if (json['reporter'] != null) {
    return ReporterInfo.fromJson(json['reporter'] as Map<String, dynamic>);
  }
  final name = json['reporter_name'] as String?;
  final phone = json['reporter_phone'] as String?;
  if (name == null && phone == null) {
    return null;
  }
  return ReporterInfo(id: json['reported_by'] as String, fullName: name ?? 'Desconocido', phone: phone);
}

class FoundReportCreate {
  final String missingPersonId;
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime foundDate;
  final String? description;
  final String? contactInfo;

  FoundReportCreate({
    required this.missingPersonId,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.foundDate,
    this.description,
    this.contactInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'missing_person_id': missingPersonId,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'found_date': foundDate.toIso8601String(),
      'description': description,
      'contact_info': contactInfo,
    };
  }
}

enum FoundReportStatus {
  pending,
  confirmed,
  rejected,
}

extension FoundReportStatusExtension on FoundReportStatus {
  String get value {
    switch (this) {
      case FoundReportStatus.pending:
        return 'pending';
      case FoundReportStatus.confirmed:
        return 'confirmed';
      case FoundReportStatus.rejected:
        return 'rejected';
    }
  }

  String get displayName {
    switch (this) {
      case FoundReportStatus.pending:
        return 'Pendiente';
      case FoundReportStatus.confirmed:
        return 'Confirmado';
      case FoundReportStatus.rejected:
        return 'Rechazado';
    }
  }
}
