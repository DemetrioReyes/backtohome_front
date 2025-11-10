import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_theme.dart';
import '../../models/missing_person.dart';
import '../../models/found_report.dart';
import '../../services/missing_person_service.dart';
import '../../services/found_report_service.dart';
import 'report_found_person_screen.dart';

class MissingPersonDetailScreen extends StatefulWidget {
  final String reportId;

  const MissingPersonDetailScreen({super.key, required this.reportId});

  @override
  State<MissingPersonDetailScreen> createState() => _MissingPersonDetailScreenState();
}

class _MissingPersonDetailScreenState extends State<MissingPersonDetailScreen> {
  late Future<MissingPersonResult> _future;

  @override
  void initState() {
    super.initState();
    final service = context.read<MissingPersonService>();
    _future = service.getDetail(widget.reportId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del reporte'),
      ),
      body: FutureBuilder<MissingPersonResult>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.isSuccess || snapshot.data!.person == null) {
            final error = snapshot.data?.error ?? 'No se pudo obtener el reporte';
            return _ErrorView(
              message: error,
              onRetry: () {
                final service = context.read<MissingPersonService>();
                setState(() {
                  _future = service.getDetail(widget.reportId);
                });
              },
            );
          }

          final person = snapshot.data!.person!;
          return _DetailContent(person: person);
        },
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  final MissingPerson person;

  const _DetailContent({required this.person});

  Future<void> _openMap(BuildContext context, double lat, double lng) async {
    final googleMapsUrl = Uri.parse('comgooglemaps://?center=$lat,$lng&zoom=14');
    final appleMapsUrl = Uri.parse('http://maps.apple.com/?ll=$lat,$lng');
    final webMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
        return;
      }
      if (await canLaunchUrl(appleMapsUrl)) {
        await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
        return;
      }
      await launchUrl(webMapsUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir el mapa: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final lat = person.lastSeenLocation.latitude;
    final lng = person.lastSeenLocation.longitude;
    final hasValidLocation =
        lat != 0 && lng != 0 && lat.isFinite && lng.isFinite;
    final locationLabel = person.lastSeenLocation.displayLocation;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingLarge,
        vertical: AppTheme.paddingMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeroCard(person: person),
          const SizedBox(height: AppTheme.paddingLarge),
          _DetailSectionCard(
            icon: Icons.info_outline,
            title: 'Información general',
            children: [
              _InfoRow(label: 'Edad', value: '${person.age} años'),
              _InfoRow(label: 'Género', value: person.genderDisplayName),
              _InfoRow(label: 'Descripción física', value: person.physicalDescription),
              _InfoRow(label: 'Vestimenta', value: person.clothingDescription),
              if (person.medicalConditions != null)
                _InfoRow(
                  label: 'Condiciones médicas',
                  value: person.medicalConditions!,
                ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingLarge),
          _DetailSectionCard(
            icon: Icons.place_outlined,
            title: 'Última vez visto',
            children: [
              _InfoRow(
                label: 'Fecha y hora',
                value: dateFormat.format(person.lastSeenDate.toLocal()),
              ),
              const SizedBox(height: AppTheme.paddingSmall),
              if (hasValidLocation) ...[
                FilledButton.icon(
                  onPressed: () => _openMap(context, lat, lng),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Abrir en Google Maps'),
                ),
                if (locationLabel.isNotEmpty &&
                    locationLabel != 'Ubicación no disponible')
                  Padding(
                    padding: const EdgeInsets.only(top: AppTheme.paddingSmall),
                    child: Text(
                      locationLabel,
                      style: AppTheme.bodySmall,
                    ),
                  ),
              ] else
                Text(
                  locationLabel.isNotEmpty
                      ? locationLabel
                      : 'Ubicación no disponible',
                  style: AppTheme.bodyMedium.copyWith(
                    color: locationLabel.isNotEmpty
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingLarge),
          _DetailSectionCard(
            icon: Icons.support_agent_outlined,
            title: 'Contacto',
            children: [
              _InfoRow(label: 'Nombre', value: person.contactName),
              _InfoRow(label: 'Teléfono', value: person.contactPhone),
              if (person.contactEmail != null)
                _InfoRow(label: 'Correo', value: person.contactEmail!),
            ],
          ),
          const SizedBox(height: AppTheme.paddingLarge),
          _FoundReportsSection(missingPersonId: person.id),
          const SizedBox(height: AppTheme.paddingLarge),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReportFoundPersonScreen(person: person),
                ),
              );
            },
            icon: const Icon(Icons.volunteer_activism_outlined),
            label: const Text('Reportar persona encontrada'),
          ),
          const SizedBox(height: AppTheme.paddingLarge),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
            const SizedBox(height: AppTheme.paddingMedium),
            Text(
              message,
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.errorColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final MissingPerson person;

  const _HeroCard({required this.person});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: Image.network(
                person.photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppTheme.textHint,
                  child: const Icon(Icons.person, size: 80),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.fullName,
                  style: AppTheme.headlineMedium,
                ),
                if (person.nickname != null && person.nickname!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Apodo: ${person.nickname}',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                const SizedBox(height: AppTheme.paddingSmall),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(label: 'Edad', value: '${person.age} años'),
                    _InfoChip(label: 'Estado', value: person.statusDisplayName),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _DetailSectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  foregroundColor: AppTheme.primaryColor,
                  radius: 20,
                  child: Icon(icon),
                ),
                const SizedBox(width: AppTheme.paddingSmall),
                Text(
                  title,
                  style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
      label: Text(
        '$label: $value',
        style: AppTheme.bodySmall.copyWith(color: AppTheme.primaryColor),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'No disponible' : value,
              style: AppTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _FoundReportsSection extends StatefulWidget {
  final String missingPersonId;

  const _FoundReportsSection({required this.missingPersonId});

  @override
  State<_FoundReportsSection> createState() => _FoundReportsSectionState();
}

class _FoundReportsSectionState extends State<_FoundReportsSection> {
  late Future<FoundReportListResult> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchReports();
  }

  Future<FoundReportListResult> _fetchReports() {
    final service = context.read<FoundReportService>();
    return service.getFoundReportsForMissingPerson(widget.missingPersonId);
  }

  Future<void> _confirmReport(FoundReport report) async {
    final service = context.read<FoundReportService>();
    final success = await service.confirmFoundReport(report.id);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hallazgo confirmado correctamente'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      setState(() => _future = _fetchReports());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo confirmar el hallazgo'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FoundReportListResult>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.isSuccess) {
          final error = snapshot.data?.error ?? 'No se pudieron cargar los hallazgos';
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        foregroundColor: AppTheme.primaryColor,
                        child: const Icon(Icons.manage_search_outlined),
                      ),
                      const SizedBox(width: AppTheme.paddingSmall),
                      Text(
                        'Reportes de hallazgo',
                        style:
                            AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.paddingMedium),
                  Text(
                    error,
                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor),
                  ),
                ],
              ),
            ),
          );
        }

        final reports = snapshot.data!.reports ?? [];
        if (reports.isEmpty) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        foregroundColor: AppTheme.primaryColor,
                        child: const Icon(Icons.manage_search_outlined),
                      ),
                      const SizedBox(width: AppTheme.paddingSmall),
                      Text(
                        'Reportes de hallazgo',
                        style:
                            AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.paddingMedium),
                  Text(
                    'Aún no se han reportado hallazgos para esta persona.',
                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          foregroundColor: AppTheme.primaryColor,
                          child: const Icon(Icons.manage_search_outlined),
                        ),
                        const SizedBox(width: AppTheme.paddingSmall),
                        Text(
                          'Reportes de hallazgo',
                          style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.paddingMedium),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reports.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.paddingSmall),
                      itemBuilder: (context, index) {
                        final report = reports[index];
                        return _FoundReportCard(
                          report: report,
                          onConfirm: report.isPending
                              ? () => _confirmReport(report)
                              : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FoundReportCard extends StatelessWidget {
  final FoundReport report;
  final VoidCallback? onConfirm;

  const _FoundReportCard({required this.report, this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
      ),
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: AppTheme.paddingSmall),
              Text(
                dateFormat.format(report.foundDate.toLocal()),
                style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Chip(
                backgroundColor: report.isPending
                    ? AppTheme.warningColor.withOpacity(0.15)
                    : AppTheme.successColor.withOpacity(0.15),
                label: Text(
                  report.statusDisplayName,
                  style: AppTheme.bodySmall.copyWith(
                    color: report.isPending
                        ? AppTheme.warningColor
                        : AppTheme.successColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingSmall),
          if (report.location.address != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.place_outlined, size: 18),
                const SizedBox(width: AppTheme.paddingSmall),
                Expanded(
                  child: Text(
                    report.location.address!,
                    style: AppTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          if (report.description != null) ...[
            const SizedBox(height: AppTheme.paddingSmall),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.description_outlined, size: 18),
                const SizedBox(width: AppTheme.paddingSmall),
                Expanded(
                  child: Text(
                    report.description!,
                    style: AppTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
          if (report.contactInfo != null) ...[
            const SizedBox(height: AppTheme.paddingSmall),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 18),
                const SizedBox(width: AppTheme.paddingSmall),
                Text(
                  report.contactInfo!,
                  style: AppTheme.bodyMedium,
                ),
              ],
            ),
          ],
          if (report.reporter != null) ...[
            const SizedBox(height: AppTheme.paddingSmall),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 18),
                const SizedBox(width: AppTheme.paddingSmall),
                Expanded(
                  child: Text(
                    report.reporter!.fullName,
                    style: AppTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            if (report.reporter!.phone != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const SizedBox(width: 18),
                    const Icon(Icons.phone, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: AppTheme.paddingSmall),
                    Text(report.reporter!.phone!, style: AppTheme.bodySmall),
                  ],
                ),
              ),
          ],
          if (report.photoUrl != null) ...[
            const SizedBox(height: AppTheme.paddingMedium),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              child: Image.network(
                report.photoUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: AppTheme.textHint,
                  child: const Icon(Icons.image_not_supported_outlined, size: 48),
                ),
              ),
            ),
          ],
          if (onConfirm != null) ...[
            const SizedBox(height: AppTheme.paddingMedium),
            FilledButton.tonalIcon(
              onPressed: onConfirm,
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Confirmar hallazgo'),
            ),
          ],
        ],
      ),
    );
  }
}


