class User {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? profilePhotoUrl;
  final DateTime? dateOfBirth;
  final String role;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.profilePhotoUrl,
    this.dateOfBirth,
    required this.role,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      role: json['role'] as String? ?? 'user',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'profile_photo_url': profilePhotoUrl,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_active': isActive,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? profilePhotoUrl,
    DateTime? dateOfBirth,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? profilePhotoUrl;
  final DateTime? dateOfBirth;
  final UserLocation? location;
  final UserSettings? settings;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.profilePhotoUrl,
    this.dateOfBirth,
    this.location,
    this.settings,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      location: json['location'] != null
          ? UserLocation.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      settings: json['settings'] != null
          ? UserSettings.fromJson(json['settings'] as Map<String, dynamic>)
          : null,
    );
  }
}

class UserLocation {
  final double latitude;
  final double longitude;
  final DateTime? lastUpdated;

  UserLocation({
    required this.latitude,
    required this.longitude,
    this.lastUpdated,
  });

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class UserSettings {
  final double notificationRadius;
  final bool pushEnabled;
  final bool emailEnabled;

  UserSettings({
    required this.notificationRadius,
    this.pushEnabled = true,
    this.emailEnabled = true,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      notificationRadius:
          (json['notification_radius'] as num?)?.toDouble() ?? 20.0,
      pushEnabled: json['push_enabled'] as bool? ?? true,
      emailEnabled: json['email_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notification_radius': notificationRadius,
      'push_enabled': pushEnabled,
      'email_enabled': emailEnabled,
    };
  }

  UserSettings copyWith({
    double? notificationRadius,
    bool? pushEnabled,
    bool? emailEnabled,
  }) {
    return UserSettings(
      notificationRadius: notificationRadius ?? this.notificationRadius,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
    );
  }
}
