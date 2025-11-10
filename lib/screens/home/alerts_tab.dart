import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

class AlertsTab extends StatelessWidget {
  const AlertsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.notifications_outlined,
              size: 80,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Sistema de Alertas',
              style: AppTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Aquí recibirás notificaciones de personas desaparecidas cerca de tu ubicación',
                style: AppTheme.bodyMedium
                    .copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
