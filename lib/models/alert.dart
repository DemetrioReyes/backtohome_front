class Alert {
  final String id;
  final String missingPersonId;
  final String sentToUserId;
  final double? distanceKm;
  final DateTime sentAt;
  final bool isRead;
  final String? interactionType;
  final DateTime? interactionAt;
  final MissingPersonSummary? missingPerson;

  Alert({
    required this.id,
    required this.missingPersonId,
    required this.sentToUserId,
    this.distanceKm,
    required this.sentAt,
    this.isRead = false,
    this.interactionType,
    this.interactionAt,
    this.missingPerson,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as String,
      missingPersonId: json['missing_person_id'] as String,
      sentToUserId: json['sent_to_user_id'] as String,
      distanceKm: json['distance_km'] != null
          ? (json['distance_km'] as num).toDouble()
          : null,
      sentAt: DateTime.parse(json['sent_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
      interactionType: json['interaction_type'] as String?,
      interactionAt: json['interaction_at'] != null
          ? DateTime.parse(json['interaction_at'] as String)
          : null,
      missingPerson: json['missing_person'] != null
          ? MissingPersonSummary.fromJson(
              json['missing_person'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'missing_person_id': missingPersonId,
      'sent_to_user_id': sentToUserId,
      'distance_km': distanceKm,
      'sent_at': sentAt.toIso8601String(),
      'is_read': isRead,
      'interaction_type': interactionType,
      'interaction_at': interactionAt?.toIso8601String(),
    };
  }

  String get distanceDisplay {
    if (distanceKm == null) return 'Distancia desconocida';
    if (distanceKm! < 1) {
      return '${(distanceKm! * 1000).toInt()} metros';
    }
    return '${distanceKm!.toStringAsFixed(1)} km';
  }

  String get interactionDisplayName {
    switch (interactionType) {
      case 'viewed':
        return 'Visto';
      case 'ignored':
        return 'Ignorado';
      case 'helpful':
        return 'Útil';
      default:
        return 'Sin interacción';
    }
  }

  Alert copyWith({
    double? distanceKm,
    bool? isRead,
    String? interactionType,
    DateTime? interactionAt,
    MissingPersonSummary? missingPerson,
  }) {
    return Alert(
      id: id,
      missingPersonId: missingPersonId,
      sentToUserId: sentToUserId,
      distanceKm: distanceKm ?? this.distanceKm,
      sentAt: sentAt,
      isRead: isRead ?? this.isRead,
      interactionType: interactionType ?? this.interactionType,
      interactionAt: interactionAt ?? this.interactionAt,
      missingPerson: missingPerson ?? this.missingPerson,
    );
  }
}

class MissingPersonSummary {
  final String id;
  final String fullName;
  final int age;
  final String gender;
  final String photoUrl;
  final String status;

  MissingPersonSummary({
    required this.id,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.photoUrl,
    required this.status,
  });

  factory MissingPersonSummary.fromJson(Map<String, dynamic> json) {
    return MissingPersonSummary(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'Desconocido',
      age: json['age'] is int
          ? json['age'] as int
          : int.tryParse('${json['age']}') ?? 0,
      gender: json['gender'] as String? ?? 'unknown',
      photoUrl: json['photo_url'] as String? ?? '',
      status: json['status'] as String? ?? 'unknown',
    );
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

class AlertStats {
  final int total;
  final int unread;
  final int viewed;
  final int helpful;
  final int ignored;

  AlertStats({
    required this.total,
    required this.unread,
    required this.viewed,
    required this.helpful,
    required this.ignored,
  });

  factory AlertStats.fromJson(Map<String, dynamic> json) {
    return AlertStats(
      total: json['total'] as int? ?? 0,
      unread: json['unread'] as int? ?? 0,
      viewed: json['viewed'] as int? ?? 0,
      helpful: json['helpful'] as int? ?? 0,
      ignored: json['ignored'] as int? ?? 0,
    );
  }
}

enum InteractionType {
  viewed,
  ignored,
  helpful,
}

extension InteractionTypeExtension on InteractionType {
  String get value {
    switch (this) {
      case InteractionType.viewed:
        return 'viewed';
      case InteractionType.ignored:
        return 'ignored';
      case InteractionType.helpful:
        return 'helpful';
    }
  }

  String get displayName {
    switch (this) {
      case InteractionType.viewed:
        return 'Visto';
      case InteractionType.ignored:
        return 'Ignorar';
      case InteractionType.helpful:
        return 'Útil';
    }
  }
}
