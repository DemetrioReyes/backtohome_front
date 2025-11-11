import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/missing_person_service.dart';
import '../../config/app_theme.dart';
import '../../models/missing_person.dart';
import '../reports/missing_person_detail_screen.dart';

class MyReportsTab extends StatefulWidget {
  const MyReportsTab({super.key});

  @override
  State<MyReportsTab> createState() => _MyReportsTabState();
}

class _MyReportsTabState extends State<MyReportsTab> {
  List<MissingPerson> _myReports = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMyReports();
  }

  Future<void> _loadMyReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final service = context.read<MissingPersonService>();
    final result = await service.getMyReports();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.isSuccess) {
          _myReports = result.persons ?? [];
        } else {
          _error = result.error;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reportes'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMyReports,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.errorColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMyReports,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_myReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.folder_outlined,
              size: 80,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes reportes activos',
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final created = await Navigator.of(context)
                    .pushNamed<bool>('/reports/create');
                if (created == true) {
                  _loadMyReports();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Crear Reporte'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      itemCount: _myReports.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.paddingMedium),
      itemBuilder: (context, index) {
        final report = _myReports[index];
        return _ReportCard(report: report);
      },
    );
  }
}

class _ReportCard extends StatelessWidget {
  final MissingPerson report;

  const _ReportCard({required this.report});

  Color _getStatusColor() {
    switch (report.status) {
      case 'active':
        return AppTheme.statusActive;
      case 'found':
        return AppTheme.statusFound;
      case 'cancelled':
        return AppTheme.statusCancelled;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final circumstancesText = report.circumstances.isNotEmpty
        ? report.circumstances
        : 'Sin información registrada';
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MissingPersonDetailScreen(
              reportId: report.id,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          gradient: const LinearGradient(
            colors: [Color(0xFFe1f5fe), Color(0xFFf1f8e9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  report.photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppTheme.textHint,
                    child: const Icon(Icons.person, size: 60),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          report.fullName,
                          style: AppTheme.headlineSmall,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor().withOpacity(0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          report.statusDisplayName,
                          style: AppTheme.bodySmall.copyWith(
                            color: _getStatusColor(),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${report.age} años • ${report.genderDisplayName}',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.paddingSmall),
                  Text(
                    circumstancesText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyMedium,
                  ),
                  if (report.stats != null) ...[
                    const SizedBox(height: AppTheme.paddingMedium),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatPill(
                          icon: Icons.campaign,
                          label: 'Alertas',
                          value: report.stats!.alertsSent.toString(),
                        ),
                        _StatPill(
                          icon: Icons.visibility,
                          label: 'Avistamientos',
                          value: report.stats!.sightings.toString(),
                        ),
                        _StatPill(
                          icon: Icons.location_searching,
                          label: 'Hallazgos',
                          value: report.stats!.foundReports.toString(),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatPill({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppTheme.primaryColor),
            const SizedBox(height: 4),
            Text(value,
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                )),
            Text(label, style: AppTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
