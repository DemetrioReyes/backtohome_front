import 'missing_person.dart';

class Sighting {
  final String id;
  final String missingPersonId;
  final String reportedBy;
  final LocationData location;
  final DateTime sightingDate;
  final String? description;
  final String? photoUrl;
  final DateTime createdAt;
  final ReporterInfo? reporter;

  Sighting({
    required this.id,
    required this.missingPersonId,
    required this.reportedBy,
    required this.location,
    required this.sightingDate,
    this.description,
    this.photoUrl,
    required this.createdAt,
    this.reporter,
  });

  factory Sighting.fromJson(Map<String, dynamic> json) {
    return Sighting(
      id: json['id'] as String,
      missingPersonId: json['missing_person_id'] as String,
      reportedBy: json['reported_by'] as String,
      location:
          LocationData.fromJson(json['location'] as Map<String, dynamic>),
      sightingDate: DateTime.parse(json['sighting_date'] as String),
      description: json['description'] as String?,
      photoUrl: json['photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      reporter: json['reporter'] != null
          ? ReporterInfo.fromJson(json['reporter'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'missing_person_id': missingPersonId,
      'reported_by': reportedBy,
      'location': location.toJson(),
      'sighting_date': sightingDate.toIso8601String(),
      'description': description,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class SightingCreate {
  final String missingPersonId;
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime sightingDate;
  final String? description;

  SightingCreate({
    required this.missingPersonId,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.sightingDate,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'missing_person_id': missingPersonId,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'sighting_date': sightingDate.toIso8601String(),
      'description': description,
    };
  }
}

class ReporterInfo {
  final String id;
  final String fullName;
  final String? phone;

  ReporterInfo({
    required this.id,
    required this.fullName,
    this.phone,
  });

  factory ReporterInfo.fromJson(Map<String, dynamic> json) {
    return ReporterInfo(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
    );
  }
}
