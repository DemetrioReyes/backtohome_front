import 'package:flutter/foundation.dart';

class MissingPerson {
  final String id;
  final String reporterId;
  final String fullName;
  final String? nickname;
  final int age;
  final String gender;
  final String physicalDescription;
  final String clothingDescription;
  final String? medicalConditions;
  final String photoUrl;
  final List<String>? additionalPhotos;
  final LocationData lastSeenLocation;
  final DateTime lastSeenDate;
  final String contactName;
  final String contactPhone;
  final String? contactEmail;
  final String relationship;
  final String circumstances;
  final String? additionalInfo;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? editCount;
  final double? distanceKm;
  final MissingPersonStats? stats;

  MissingPerson({
    required this.id,
    required this.reporterId,
    required this.fullName,
    this.nickname,
    required this.age,
    required this.gender,
    required this.physicalDescription,
    required this.clothingDescription,
    this.medicalConditions,
    required this.photoUrl,
    this.additionalPhotos,
    required this.lastSeenLocation,
    required this.lastSeenDate,
    required this.contactName,
    required this.contactPhone,
    this.contactEmail,
    required this.relationship,
    required this.circumstances,
    this.additionalInfo,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.editCount,
    this.distanceKm,
    this.stats,
  });

  factory MissingPerson.fromJson(Map<String, dynamic> json) {
    return MissingPerson(
      id: _stringValue(json, 'id'),
      reporterId: _stringValue(json, 'reporter_id'),
      fullName: _stringValue(json, 'full_name', defaultValue: 'Sin nombre'),
      nickname: json['nickname'] as String?,
      age: (json['age'] as num? ?? 0).toInt(),
      gender: _stringValue(json, 'gender', defaultValue: 'unknown'),
      physicalDescription:
          _stringValue(json, 'physical_description', defaultValue: 'Sin descripción'),
      clothingDescription: _stringValue(json, 'clothing_description', defaultValue: 'Sin datos'),
      medicalConditions: json['medical_conditions'] as String?,
      photoUrl: _stringValue(json, 'photo_url'),
      additionalPhotos: json['additional_photos'] != null
          ? List<String>.from(json['additional_photos'] as List)
          : null,
      lastSeenLocation:
          _mapLastSeenLocation(json['last_seen_location'], json),
      lastSeenDate: DateTime.parse(json['last_seen_date'] as String),
      contactName: _stringValue(json, 'contact_name', defaultValue: 'Sin nombre'),
      contactPhone: _stringValue(json, 'contact_phone', defaultValue: 'Sin teléfono'),
      contactEmail: json['contact_email'] as String?,
      relationship: _stringValue(json, 'relationship', defaultValue: 'Sin relación'),
      circumstances:
          _stringValue(json, 'circumstances', defaultValue: 'Sin información'),
      additionalInfo: json['additional_info'] as String?,
      status: _stringValue(json, 'status', defaultValue: 'unknown'),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      editCount: json['edit_count'] as int?,
      distanceKm: json['distance_km'] != null
          ? (json['distance_km'] as num).toDouble()
          : null,
      stats: json['stats'] != null
          ? MissingPersonStats.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporter_id': reporterId,
      'full_name': fullName,
      'nickname': nickname,
      'age': age,
      'gender': gender,
      'physical_description': physicalDescription,
      'clothing_description': clothingDescription,
      'medical_conditions': medicalConditions,
      'photo_url': photoUrl,
      'additional_photos': additionalPhotos,
      'last_seen_location': lastSeenLocation.toJson(),
      'last_seen_latitude': lastSeenLocation.latitude,
      'last_seen_longitude': lastSeenLocation.longitude,
      'last_seen_address': lastSeenLocation.address,
      'last_seen_city': lastSeenLocation.city,
      'last_seen_province': lastSeenLocation.province,
      'last_seen_date': lastSeenDate.toIso8601String(),
      'contact_name': contactName,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'relationship': relationship,
      'circumstances': circumstances,
      'additional_info': additionalInfo,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'edit_count': editCount,
      'distance_km': distanceKm,
    };
  }

  bool get isActive => status == 'active';
  bool get isFound => status == 'found';
  bool get isCancelled => status == 'cancelled';

  String get statusDisplayName {
    switch (status) {
      case 'active':
        return 'Activo';
      case 'found':
        return 'Encontrado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  String get genderDisplayName {
    switch (gender) {
      case 'male':
        return 'Masculino';
      case 'female':
        return 'Femenino';
      case 'other':
        return 'Otro';
      default:
        return gender;
    }
  }
}

LocationData _mapLastSeenLocation(
  dynamic lastSeenLocationJson,
  Map<String, dynamic> fallbackJson,
) {
  if (lastSeenLocationJson is Map<String, dynamic>) {
    return LocationData.fromJson(lastSeenLocationJson);
  }

  double? latitude;
  double? longitude;

  final rawLat = fallbackJson['last_seen_latitude'];
  final rawLng = fallbackJson['last_seen_longitude'];

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

  final rawAddress = fallbackJson['last_seen_address'] as String?;
  if ((latitude == null || longitude == null) && rawAddress != null) {
    final regex = RegExp(r'Lat:\s*([-0-9.]+),\s*Lng:\s*([-0-9.]+)');
    final match = regex.firstMatch(rawAddress);
    if (match != null) {
      latitude ??= double.tryParse(match.group(1)!);
      longitude ??= double.tryParse(match.group(2)!);
    }
  }

  return LocationData(
    latitude: latitude ?? 0,
    longitude: longitude ?? 0,
    address: fallbackJson['last_seen_address'] as String?,
    city: fallbackJson['last_seen_city'] as String?,
    province: fallbackJson['last_seen_province'] as String?,
  );
}

String _stringValue(Map<String, dynamic> json, String key,
    {String defaultValue = ''}) {
  if (!json.containsKey(key)) {
    if (kDebugMode) {
      debugPrint('Campo "$key" ausente en MissingPerson: $json');
    }
    return defaultValue;
  }
  final value = json[key];
  if (value == null) return defaultValue;
  if (value is String) return value;
  return value.toString();
}

class LocationData {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? province;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.province,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      city: json['city'] as String?,
      province: json['province'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'province': province,
    };
  }

  String get displayLocation {
    if (address != null) return address!;
    if (city != null && province != null) return '$city, $province';
    if (city != null) return city!;
    if (province != null) return province!;
    return 'Ubicación no disponible';
  }
}

class MissingPersonStats {
  final int alertsSent;
  final int sightings;
  final int foundReports;

  MissingPersonStats({
    required this.alertsSent,
    required this.sightings,
    required this.foundReports,
  });

  factory MissingPersonStats.fromJson(Map<String, dynamic> json) {
    return MissingPersonStats(
      alertsSent: json['alerts_sent'] as int? ?? 0,
      sightings: json['sightings'] as int? ?? 0,
      foundReports: json['found_reports'] as int? ?? 0,
    );
  }
}

class MissingPersonCreate {
  final String fullName;
  final String? nickname;
  final int age;
  final String gender;
  final String physicalDescription;
  final String clothingDescription;
  final String? medicalConditions;
  final double lastSeenLatitude;
  final double lastSeenLongitude;
  final String? lastSeenAddress;
  final DateTime lastSeenDate;
  final String contactName;
  final String contactPhone;
  final String? contactEmail;
  final String relationship;
  final String circumstances;
  final String? additionalInfo;

  MissingPersonCreate({
    required this.fullName,
    this.nickname,
    required this.age,
    required this.gender,
    required this.physicalDescription,
    required this.clothingDescription,
    this.medicalConditions,
    required this.lastSeenLatitude,
    required this.lastSeenLongitude,
    this.lastSeenAddress,
    required this.lastSeenDate,
    required this.contactName,
    required this.contactPhone,
    this.contactEmail,
    required this.relationship,
    required this.circumstances,
    this.additionalInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'nickname': nickname,
      'age': age,
      'gender': gender,
      'physical_description': physicalDescription,
      'clothing_description': clothingDescription,
      'medical_conditions': medicalConditions,
      'last_seen_latitude': lastSeenLatitude,
      'last_seen_longitude': lastSeenLongitude,
      'last_seen_address': lastSeenAddress,
      'last_seen_date': lastSeenDate.toUtc().toIso8601String(),
      'contact_name': contactName,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'relationship': relationship,
      'circumstances': circumstances,
      'additional_info': additionalInfo,
    };
  }
}
