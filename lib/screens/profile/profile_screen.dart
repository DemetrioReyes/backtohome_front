import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../config/app_theme.dart';
import '../../services/notification_service.dart';
import '../../models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final authService = context.read<AuthService>();
    final user = await authService.getCachedUser();

    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authService = context.read<AuthService>();
      final notificationService = context.read<NotificationService>();

      await notificationService.clearStoredToken();
      await authService.logout();

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_user == null) {
      return const Center(
        child: Text('No se pudo cargar el perfil'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.paddingLarge),
      child: Column(
        children: [
          // Profile Header
          CircleAvatar(
            radius: 50,
            backgroundColor: AppTheme.primaryColor,
            child: _user!.profilePhotoUrl != null
                ? ClipOval(
                    child: Image.network(
                      _user!.profilePhotoUrl!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  )
                : Text(
                    _user!.fullName[0].toUpperCase(),
                    style: AppTheme.headlineLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            _user!.fullName,
            style: AppTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _user!.email,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),

          // Profile Options
          _ProfileOption(
            icon: Icons.person_outline,
            title: 'Editar Perfil',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Editar perfil - Por implementar')),
              );
            },
          ),
          _ProfileOption(
            icon: Icons.location_on_outlined,
            title: 'Mi Ubicación',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mi ubicación - Por implementar')),
              );
            },
          ),
          _ProfileOption(
            icon: Icons.settings_outlined,
            title: 'Configuración',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Configuración - Por implementar')),
              );
            },
          ),
          _ProfileOption(
            icon: Icons.help_outline,
            title: 'Ayuda y Soporte',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ayuda - Por implementar')),
              );
            },
          ),
          _ProfileOption(
            icon: Icons.info_outline,
            title: 'Acerca de',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'BackToHome',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(
                  Icons.home_rounded,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
                children: [
                  const Text(
                    'BackToHome es una plataforma sin fines de lucro para ayudar a encontrar personas desaparecidas en República Dominicana.',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _ProfileOption(
            icon: Icons.logout,
            title: 'Cerrar Sesión',
            onTap: _handleLogout,
            isDestructive: true,
          ),
          const SizedBox(height: 32),

          // Version Info
          Text(
            'Versión 1.0.0',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textHint),
          ),
        ],
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppTheme.errorColor : AppTheme.textPrimary;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: AppTheme.paddingMedium),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.bodyLarge.copyWith(color: color),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
