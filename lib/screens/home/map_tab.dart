import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/missing_person_service.dart';
import '../../services/location_service.dart';
import '../../services/auth_service.dart';
import '../../config/app_theme.dart';
import '../../models/missing_person.dart';
import '../reports/missing_person_detail_screen.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  List<MissingPerson> _nearbyPersons = [];
  bool _isLoading = true;
  String? _error;
  double _radius = 20.0;
  Position? _currentLocation;

  @override
  void initState() {
    super.initState();
    _loadNearbyPersons();
  }

  Future<void> _loadNearbyPersons() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Paso 1: Verificar si el servicio de ubicación está habilitado
    final serviceEnabled = await LocationService.isLocationServiceEnabled();
    if (!mounted) return;

    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Los servicios de ubicación están desactivados. Por favor, actívalos en Configuración > Privacidad y Seguridad > Servicios de Ubicación';
        });
      }
      return;
    }

    // Paso 2: Verificar y solicitar permisos
    LocationPermission permission = await Geolocator.checkPermission();
    if (!mounted) return;
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'Se necesitan permisos de ubicación. Por favor, permite el acceso en la configuración de la app';
          });
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Los permisos de ubicación están denegados permanentemente. Por favor, habilítalos en Configuración > Backtohome App > Ubicación';
        });
      }
      return;
    }

    // Paso 3: Obtener ubicación
    Position? location;
    
    // Intentar obtener ubicación actual
    try {
      location = await LocationService.getCurrentLocation();
    } catch (e) {
      // Si falla, intentar con última conocida
      location = await LocationService.getLastKnownLocation();
    }

    // Si aún no hay ubicación, intentar una vez más con menor precisión
    if (location == null) {
      try {
        location = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        // Último intento con última ubicación conocida
        location = await LocationService.getLastKnownLocation();
      }
      if (!mounted) return;
    }

    // Si aún no hay ubicación, mostrar error específico
    if (location == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'No se pudo obtener tu ubicación. Asegúrate de que:\n\n• Los servicios de ubicación estén activados\n• La app tenga permisos de ubicación\n• Estés en un lugar con buena señal GPS';
        });
      }
      return;
    }

    _currentLocation = location;

    if (!mounted) return;

    // Actualizar ubicación en el perfil del usuario ANTES de buscar
    final authService = context.read<AuthService>();
    try {
      await authService.updateUserLocation(
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
      );
    } catch (e) {
      debugPrint('Error al actualizar ubicación: $e');
      // Continuar de todas formas, intentaremos buscar con la ubicación en los query params
    }

    if (!mounted) return;

    final service = context.read<MissingPersonService>();
    final result = await service.getNearbyMissingPersons(
      radiusKm: _radius,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.isSuccess) {
          _nearbyPersons = result.persons ?? [];
          _error = null;
        } else {
          // Traducir mensajes de error comunes del backend
          String errorMessage = result.error ?? 'Error desconocido';
          
          // Mensajes comunes del backend relacionados con ubicación
          final lowerError = errorMessage.toLowerCase();
          if (lowerError.contains('location') || 
              lowerError.contains('ubicación') ||
              lowerError.contains('update your location') ||
              lowerError.contains('actualiza tu ubicación')) {
            errorMessage = 'Por favor, actualiza tu ubicación en tu perfil primero';
          } else if (lowerError.contains('unauthorized') || 
                     lowerError.contains('no autorizado')) {
            errorMessage = 'Sesión expirada. Por favor, inicia sesión nuevamente';
          } else if (lowerError.contains('network') || 
                     lowerError.contains('conexión')) {
            errorMessage = 'Error de conexión. Verifica tu internet';
          }
          
          _error = errorMessage;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personas Desaparecidas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNearbyPersons,
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
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_off,
                size: 64,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: AppTheme.bodyLarge.copyWith(color: AppTheme.errorColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadNearbyPersons,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_nearbyPersons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay personas desaparecidas en tu área',
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Radio actual: ${_radius.toStringAsFixed(0)} km',
              style: AppTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      itemCount: _nearbyPersons.length,
      itemBuilder: (context, index) {
        final person = _nearbyPersons[index];
        return _MissingPersonCard(person: person);
      },
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
      ),
      builder: (context) {
        double tempRadius = _radius;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.paddingLarge,
            AppTheme.paddingLarge,
            AppTheme.paddingLarge,
            AppTheme.paddingMedium + 16,
          ),
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textHint,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.paddingLarge),
                Text(
                  'Filtrar por distancia',
                  style: AppTheme.headlineSmall,
                ),
                const SizedBox(height: AppTheme.paddingSmall),
                Text(
                  'Ajusta el radio de búsqueda para encontrar personas desaparecidas cerca de tu ubicación.',
                  style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: AppTheme.paddingLarge),
                _FilterTile(
                  label: 'Radio de búsqueda',
                  value: '${tempRadius.toStringAsFixed(0)} km',
                  icon: Icons.radar,
                ),
                Slider(
                  value: tempRadius,
                  min: 1.0,
                  max: 200.0,
                  divisions: 199,
                  label: '${tempRadius.toStringAsFixed(0)} km',
                  onChanged: (value) {
                    setState(() => tempRadius = value);
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _FilterChipButton(
                      label: '5 km',
                      value: 5,
                      onSelected: (value) {
                        setState(() => tempRadius = value);
                        Navigator.pop(context);
                        _radius = value;
                        _loadNearbyPersons();
                      },
                    ),
                    _FilterChipButton(
                      label: '10 km',
                      value: 10,
                      onSelected: (value) {
                        setState(() => tempRadius = value);
                        Navigator.pop(context);
                        _radius = value;
                        _loadNearbyPersons();
                      },
                    ),
                    _FilterChipButton(
                      label: '25 km',
                      value: 25,
                      onSelected: (value) {
                        setState(() => tempRadius = value);
                        Navigator.pop(context);
                        _radius = value;
                        _loadNearbyPersons();
                      },
                    ),
                    _FilterChipButton(
                      label: '50 km',
                      value: 50,
                      onSelected: (value) {
                        setState(() => tempRadius = value);
                        Navigator.pop(context);
                        _radius = value;
                        _loadNearbyPersons();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.paddingLarge),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _radius = tempRadius);
                    _loadNearbyPersons();
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Aplicar filtro'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MissingPersonCard extends StatelessWidget {
  final MissingPerson person;

  const _MissingPersonCard({required this.person});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingMedium),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MissingPersonDetailScreen(
                reportId: person.id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                child: Image.network(
                  person.photoUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
                    color: AppTheme.textHint,
                    child: const Icon(Icons.person, size: 40),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.paddingMedium),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.fullName,
                      style: AppTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${person.age} años • ${person.genderDisplayName}',
                      style: AppTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            person.lastSeenLocation.displayLocation,
                            style: AppTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (person.distanceKm != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.near_me,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${person.distanceKm!.toStringAsFixed(1)} km de distancia',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
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
      ),
    );
  }
}

class _FilterTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _FilterTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            foregroundColor: AppTheme.primaryColor,
            child: Icon(icon),
          ),
          const SizedBox(width: AppTheme.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onSelected;

  const _FilterChipButton({
    required this.label,
    required this.value,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
        ),
        onPressed: () {
          onSelected(value);
        },
        child: Text(label),
      ),
    );
  }
}
