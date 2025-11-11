import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/alert.dart';
import '../../services/alert_service.dart';
import '../reports/missing_person_detail_screen.dart';

class AlertsTab extends StatefulWidget {
  const AlertsTab({super.key});

  @override
  State<AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends State<AlertsTab> {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  bool _unreadOnly = false;
  bool _isLoadingAlerts = true;
  bool _isLoadingStats = true;
  String? _alertsError;
  String? _statsError;
  List<Alert> _alerts = const [];
  AlertStats? _stats;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll({bool showLoaders = true}) async {
    if (showLoaders) {
      setState(() {
        _isLoadingAlerts = true;
        _isLoadingStats = true;
        _alertsError = null;
        _statsError = null;
      });
    }

    final alertService = context.read<AlertService>();
    final alertsResult =
        await alertService.getMyAlerts(unreadOnly: _unreadOnly);
    final statsResult = await alertService.getAlertStats();

    if (!mounted) return;

    setState(() {
      _isLoadingAlerts = false;
      _isLoadingStats = false;

      if (alertsResult.isSuccess) {
        _alerts = alertsResult.alerts ?? [];
        _alertsError = null;
      } else {
        _alerts = const [];
        _alertsError = alertsResult.error;
      }

      if (statsResult.isSuccess) {
        _stats = statsResult.stats;
        _statsError = null;
      } else {
        _stats = null;
        _statsError = statsResult.error;
      }
    });

    if (!statsResult.isSuccess && statsResult.error != null && showLoaders) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(statsResult.error!),
        ),
      );
    }
  }

  Future<void> _refreshStats() async {
    setState(() {
      _isLoadingStats = true;
    });
    final alertService = context.read<AlertService>();
    final statsResult = await alertService.getAlertStats();

    if (!mounted) return;

    setState(() {
      _isLoadingStats = false;
      if (statsResult.isSuccess) {
        _stats = statsResult.stats;
        _statsError = null;
      } else {
        _statsError = statsResult.error;
      }
    });
  }

  Future<Alert?> _markAsRead(Alert alert) async {
    if (alert.isRead) return alert;

    final alertService = context.read<AlertService>();
    final success = await alertService.markAlertAsRead(alert.id);

    if (!mounted) return null;

    if (success) {
      final updatedAlert = alert.copyWith(isRead: true);
      setState(() {
        _alerts = _alerts
            .map((item) => item.id == updatedAlert.id ? updatedAlert : item)
            .toList();
      });
      _refreshStats();
      return updatedAlert;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo marcar la alerta como leída'),
        ),
      );
      return null;
    }
  }

  Future<Alert?> _updateInteraction(
    Alert alert,
    InteractionType interaction, {
    bool showFeedback = true,
  }) async {
    final alertService = context.read<AlertService>();
    final success =
        await alertService.updateAlertInteraction(alert.id, interaction);

    if (!mounted) return null;

    if (success) {
      final updatedAlert = alert.copyWith(
        interactionType: interaction.value,
        interactionAt: DateTime.now(),
      );
      setState(() {
        _alerts = _alerts
            .map((item) => item.id == updatedAlert.id ? updatedAlert : item)
            .toList();
      });
      _refreshStats();
      if (showFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marcado como ${interaction.displayName.toLowerCase()}'),
          ),
        );
      }
      return updatedAlert;
    } else if (showFeedback) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo actualizar la interacción'),
        ),
      );
    }
    return null;
  }

  Future<void> _openAlertDetail(Alert alert) async {
    final updatedAlert = await _markAsRead(alert);
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MissingPersonDetailScreen(
          reportId: alert.missingPersonId,
        ),
      ),
    );

    if (!mounted) return;

    final latestAlert =
        updatedAlert ??
        _alerts.firstWhere(
          (item) => item.id == alert.id,
          orElse: () => alert,
        );

    await _updateInteraction(
      latestAlert,
      InteractionType.viewed,
      showFeedback: false,
    );
  }

  void _toggleFilter(bool unreadOnly) {
    if (_unreadOnly == unreadOnly) return;
    setState(() {
      _unreadOnly = unreadOnly;
    });
    _fetchAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas'),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: () => _fetchAll(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _fetchAll(showLoaders: false),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoadingAlerts && _alerts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        children: const [
          SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (_alertsError != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        children: [
          _buildStatsSection(),
          const SizedBox(height: AppTheme.paddingLarge),
          _buildFilterRow(),
          const SizedBox(height: AppTheme.paddingLarge),
          _ErrorState(
            message: _alertsError!,
            onRetry: _fetchAll,
          ),
        ],
      );
    }

    if (_alerts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        children: [
          _buildStatsSection(),
          const SizedBox(height: AppTheme.paddingLarge),
          _buildFilterRow(),
          const SizedBox(height: AppTheme.paddingLarge),
          const _EmptyState(),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.paddingLarge),
      itemCount: _alerts.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildStatsSection();
        }
        if (index == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppTheme.paddingLarge),
              _buildFilterRow(),
              const SizedBox(height: AppTheme.paddingLarge),
            ],
          );
        }

        final alert = _alerts[index - 2];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.paddingMedium),
          child: _AlertCard(
            alert: alert,
            dateFormat: _dateFormat,
            onMarkAsRead: () => _markAsRead(alert),
            onInteractionSelected: (interaction) =>
                _updateInteraction(alert, interaction),
            onOpenDetail: () => _openAlertDetail(alert),
          ),
        );
      },
    );
  }

  Widget _buildStatsSection() {
    if (_isLoadingStats) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.paddingLarge,
            vertical: AppTheme.paddingXLarge,
          ),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_stats == null) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.insights_outlined,
                      color: AppTheme.warningColor),
                  const SizedBox(width: AppTheme.paddingSmall),
                  Text(
                    'Sin datos de estadísticas',
                    style: AppTheme.titleMedium.copyWith(
                      color: AppTheme.warningColor,
                    ),
                  ),
                ],
              ),
              if (_statsError != null) ...[
                const SizedBox(height: AppTheme.paddingSmall),
                Text(
                  _statsError!,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.paddingMedium),
              OutlinedButton.icon(
                onPressed: _refreshStats,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final stats = _stats!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppTheme.paddingLarge),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alertas recibidas',
                      style: AppTheme.bodySmall.copyWith(
                        color: Colors.white.withAlpha(204),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${stats.total}',
                      style: AppTheme.headlineLarge.copyWith(
                        color: Colors.white,
                        fontSize: 34,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enviadas a tu cuenta',
                      style: AppTheme.bodySmall.copyWith(
                        color: Colors.white.withAlpha(204),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppTheme.paddingMedium),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(46),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${stats.unread}',
                      style: AppTheme.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sin leer',
                      style: AppTheme.bodySmall.copyWith(
                        color: Colors.white.withAlpha(219),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.paddingLarge),
        Row(
          children: [
            Expanded(
              child: _MiniStatCard(
                icon: Icons.visibility_outlined,
                label: 'Vistas',
                value: stats.viewed,
                color: AppTheme.secondaryColor,
              ),
            ),
            const SizedBox(width: AppTheme.paddingMedium),
            Expanded(
              child: _MiniStatCard(
                icon: Icons.thumb_up_alt_outlined,
                label: 'Útiles',
                value: stats.helpful,
                color: AppTheme.successColor,
              ),
            ),
            const SizedBox(width: AppTheme.paddingMedium),
            Expanded(
              child: _MiniStatCard(
                icon: Icons.block_outlined,
                label: 'Ignoradas',
                value: stats.ignored,
                color: AppTheme.errorColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filtrar',
          style: AppTheme.titleMedium,
        ),
        const SizedBox(height: AppTheme.paddingSmall),
        Wrap(
          spacing: AppTheme.paddingSmall,
          children: [
            ChoiceChip(
              label: const Text('Todas'),
              selected: !_unreadOnly,
              onSelected: (selected) => _toggleFilter(false),
            ),
            ChoiceChip(
              label: const Text('Solo sin leer'),
              selected: _unreadOnly,
              onSelected: (selected) => _toggleFilter(true),
            ),
          ],
        ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Alert alert;
  final DateFormat dateFormat;
  final VoidCallback onOpenDetail;
  final Future<Alert?> Function() onMarkAsRead;
  final Future<Alert?> Function(InteractionType) onInteractionSelected;

  const _AlertCard({
    required this.alert,
    required this.dateFormat,
    required this.onOpenDetail,
    required this.onMarkAsRead,
    required this.onInteractionSelected,
  });

  Color _statusColor(bool isRead) {
    return isRead ? AppTheme.successColor : AppTheme.warningColor;
  }

  Color _interactionColor(String? interactionType) {
    switch (interactionType) {
      case 'helpful':
        return AppTheme.successColor;
      case 'ignored':
        return AppTheme.errorColor;
      case 'viewed':
        return AppTheme.secondaryColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final missingPerson = alert.missingPerson;
    final photoUrl = missingPerson?.photoUrl ?? '';
    final interactionColor = _interactionColor(alert.interactionType);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        onTap: onOpenDetail,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    child: photoUrl.isNotEmpty
                        ? Image.network(
                            photoUrl,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 72,
                              height: 72,
                              color: AppTheme.textHint,
                              child: const Icon(Icons.person, size: 32),
                            ),
                          )
                        : Container(
                            width: 72,
                            height: 72,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMedium,
                              ),
                            ),
                            child: const Icon(Icons.person_outline, size: 32),
                          ),
                  ),
                  const SizedBox(width: AppTheme.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                missingPerson?.fullName ?? 'Persona desconocida',
                                style: AppTheme.titleMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(alert.isRead).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                alert.isRead ? 'Leída' : 'Sin leer',
                                style: AppTheme.bodySmall.copyWith(
                                  color: _statusColor(alert.isRead),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enviada: ${dateFormat.format(alert.sentAt.toLocal())}',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        if (alert.distanceKm != null)
                          Padding(
                            padding:
                                const EdgeInsets.only(top: AppTheme.paddingSmall),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.place_outlined,
                                  size: 18,
                                  color: AppTheme.secondaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  alert.distanceDisplay,
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.secondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.paddingMedium),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: interactionColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    alert.interactionDisplayName,
                    style: AppTheme.bodySmall.copyWith(
                      color: interactionColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (alert.interactionAt != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      dateFormat.format(alert.interactionAt!.toLocal()),
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppTheme.paddingMedium),
              Row(
                children: [
                  if (!alert.isRead)
                    OutlinedButton.icon(
                      onPressed: () {
                        onMarkAsRead();
                      },
                      icon: const Icon(Icons.mark_email_read_outlined),
                      label: const Text('Marcar leída'),
                    ),
                  const Spacer(),
                  PopupMenuButton<InteractionType>(
                    tooltip: 'Actualizar interacción',
                    onSelected: (interaction) {
                      onInteractionSelected(interaction);
                    },
                    itemBuilder: (context) {
                      return InteractionType.values
                          .map(
                            (interaction) => PopupMenuItem<InteractionType>(
                              value: interaction,
                              child: Text(interaction.displayName),
                            ),
                          )
                          .toList();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.paddingMedium,
                        vertical: AppTheme.paddingSmall,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.12),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.more_horiz, color: AppTheme.primaryColor),
                          SizedBox(width: 6),
                          Text(
                            'Acciones',
                            style: TextStyle(color: AppTheme.primaryColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingMedium,
        vertical: AppTheme.paddingSmall,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: color.withAlpha(46),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withAlpha(31),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(height: AppTheme.paddingSmall),
          Text(
            '$value',
            style: AppTheme.headlineSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.paddingLarge),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryColor.withOpacity(0.1),
          ),
          child: const Icon(
            Icons.notifications_paused_outlined,
            size: 48,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.paddingLarge),
        Text(
          'Sin alertas por ahora',
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppTheme.paddingSmall),
        Text(
          'Cuando se detecten personas desaparecidas cerca de tu ubicación,\nlas verás aquí inmediatamente.',
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function({bool showLoaders}) onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.paddingLarge),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.errorColor.withOpacity(0.1),
          ),
          child: const Icon(
            Icons.error_outline,
            size: 48,
            color: AppTheme.errorColor,
          ),
        ),
        const SizedBox(height: AppTheme.paddingLarge),
        Text(
          'No se pudieron cargar las alertas',
          style: AppTheme.titleMedium.copyWith(
            color: AppTheme.errorColor,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.paddingSmall),
        Text(
          message,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.paddingMedium),
        FilledButton.icon(
          onPressed: () => onRetry(showLoaders: true),
          icon: const Icon(Icons.refresh),
          label: const Text('Intentar de nuevo'),
        ),
      ],
    );
  }
}
