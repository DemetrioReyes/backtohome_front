import '../models/alert.dart';
import 'api_client.dart';

class AlertService {
  final ApiClient _apiClient;

  AlertService(this._apiClient);

  Future<AlertListResult> getMyAlerts({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    try {
      final response = await _apiClient.get(
        '/alerts/me',
        queryParams: {
          'limit': limit,
          'offset': offset,
          'unread_only': unreadOnly,
        },
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data as List<dynamic>;
        final alerts = data
            .map((json) => Alert.fromJson(json as Map<String, dynamic>))
            .toList();
        return AlertListResult.success(alerts);
      }

      return AlertListResult.error(
        response.error ?? 'Error al obtener alertas',
      );
    } catch (e) {
      return AlertListResult.error('Error inesperado: $e');
    }
  }

  Future<AlertStatsResult> getAlertStats() async {
    try {
      final response = await _apiClient.get('/alerts/stats');

      if (response.isSuccess && response.data != null) {
        final stats =
            AlertStats.fromJson(response.data as Map<String, dynamic>);
        return AlertStatsResult.success(stats);
      }

      return AlertStatsResult.error(
        response.error ?? 'Error al obtener estadísticas',
      );
    } catch (e) {
      return AlertStatsResult.error('Error inesperado: $e');
    }
  }

  Future<bool> markAlertAsRead(String alertId) async {
    try {
      final response = await _apiClient.patch('/alerts/$alertId/read');
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateAlertInteraction(
    String alertId,
    InteractionType interaction,
  ) async {
    try {
      final response = await _apiClient.patch(
        '/alerts/$alertId/interaction',
        body: {'interaction_type': interaction.value},
      );
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }
}

class AlertListResult {
  final List<Alert>? alerts;
  final String? error;
  final bool isSuccess;

  AlertListResult._({
    this.alerts,
    this.error,
    required this.isSuccess,
  });

  factory AlertListResult.success(List<Alert> alerts) {
    return AlertListResult._(
      alerts: alerts,
      isSuccess: true,
    );
  }

  factory AlertListResult.error(String error) {
    return AlertListResult._(
      error: error,
      isSuccess: false,
    );
  }
}

class AlertStatsResult {
  final AlertStats? stats;
  final String? error;
  final bool isSuccess;

  AlertStatsResult._({
    this.stats,
    this.error,
    required this.isSuccess,
  });

  factory AlertStatsResult.success(AlertStats stats) {
    return AlertStatsResult._(
      stats: stats,
      isSuccess: true,
    );
  }

  factory AlertStatsResult.error(String error) {
    return AlertStatsResult._(
      error: error,
      isSuccess: false,
    );
  }
}


