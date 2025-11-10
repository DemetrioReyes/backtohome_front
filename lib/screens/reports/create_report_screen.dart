import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/missing_person.dart';
import '../../services/location_service.dart';
import '../../services/missing_person_service.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _ageController = TextEditingController();
  final _physicalDescriptionController = TextEditingController();
  final _clothingDescriptionController = TextEditingController();
  final _medicalConditionsController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _circumstancesController = TextEditingController();
  final _additionalInfoController = TextEditingController();
  final _lastSeenAddressController = TextEditingController();

  String? _selectedGender;
  File? _selectedPhoto;
  DateTime? _lastSeenDate;
  TimeOfDay? _lastSeenTime;
  double? _lastSeenLatitude;
  double? _lastSeenLongitude;
  String? _lastSeenAddress;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _nicknameController.dispose();
    _ageController.dispose();
    _physicalDescriptionController.dispose();
    _clothingDescriptionController.dispose();
    _medicalConditionsController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    _relationshipController.dispose();
    _circumstancesController.dispose();
    _additionalInfoController.dispose();
    _lastSeenAddressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (!mounted || picked == null) return;

    setState(() {
      _selectedPhoto = File(picked.path);
    });
  }

  Future<void> _pickLastSeenDateTime() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _lastSeenDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      helpText: 'Selecciona la fecha de la última vez visto',
    );

    if (!mounted || selectedDate == null) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _lastSeenTime ?? TimeOfDay.fromDateTime(now),
      helpText: 'Selecciona la hora de la última vez visto',
    );

    if (!mounted || selectedTime == null) return;

    setState(() {
      _lastSeenDate = selectedDate;
      _lastSeenTime = selectedTime;
    });
  }

  Future<void> _pickLocation() async {
    final serviceEnabled = await LocationService.isLocationServiceEnabled();
    if (!mounted) return;

    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activa los servicios de ubicación para continuar'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (!mounted) return;

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permiso de ubicación denegado'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }
    }



    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El permiso de ubicación está bloqueado permanentemente. Ve a ajustes para habilitarlo.',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    Position? position;
    try {
      position = await LocationService.getCurrentLocation();
    } catch (_) {
      position = await LocationService.getLastKnownLocation();
    }

    if (!mounted) return;

    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener la ubicación actual'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _lastSeenLatitude = position!.latitude;
      _lastSeenLongitude = position.longitude;
      _lastSeenAddress = 'Lat: ${position.latitude.toStringAsFixed(4)}, '
          'Lng: ${position.longitude.toStringAsFixed(4)}';
      _lastSeenAddressController.text = _lastSeenAddress ?? '';
    });
  }

  MissingPersonCreate? _buildPayload() {
    if (!_formKey.currentState!.validate()) {
      return null;
    }

    if (_selectedPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una foto principal'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return null;
    }

    if (_lastSeenLatitude == null || _lastSeenLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona la última ubicación vista'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return null;
    }

    if (_lastSeenDate == null || _lastSeenTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona la fecha y hora de la última vez visto'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return null;
    }

    final date = DateTime(
      _lastSeenDate!.year,
      _lastSeenDate!.month,
      _lastSeenDate!.day,
      _lastSeenTime!.hour,
      _lastSeenTime!.minute,
    );

    return MissingPersonCreate(
      fullName: _fullNameController.text.trim(),
      nickname:
          _nicknameController.text.trim().isEmpty ? null : _nicknameController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      gender: _selectedGender!,
      physicalDescription: _physicalDescriptionController.text.trim(),
      clothingDescription: _clothingDescriptionController.text.trim(),
      medicalConditions: _medicalConditionsController.text.trim().isEmpty
          ? null
          : _medicalConditionsController.text.trim(),
      lastSeenLatitude: _lastSeenLatitude!,
      lastSeenLongitude: _lastSeenLongitude!,
      lastSeenAddress: () {
        final address = _lastSeenAddressController.text.trim();
        if (address.isNotEmpty) return address;
        return _lastSeenAddress;
      }(),
      lastSeenDate: date.toUtc(),
      contactName: _contactNameController.text.trim(),
      contactPhone: _contactPhoneController.text.trim(),
      contactEmail: _contactEmailController.text.trim().isEmpty
          ? null
          : _contactEmailController.text.trim(),
      relationship: _relationshipController.text.trim(),
      circumstances: _circumstancesController.text.trim(),
      additionalInfo: _additionalInfoController.text.trim().isEmpty
          ? null
          : _additionalInfoController.text.trim(),
    );
  }

  Future<void> _submit() async {
    final payload = _buildPayload();
    if (payload == null || _selectedPhoto == null) {
      return;
    }

    if (kDebugMode) {
      debugPrint('=== Intentando crear reporte ===');
      debugPrint('Payload a enviar: ${payload.toJson()}');
      debugPrint('Foto seleccionada: ${_selectedPhoto!.path}');
    }

    setState(() => _isSubmitting = true);

    final service = context.read<MissingPersonService>();
    final result = await service.createReport(
      data: payload,
      photo: _selectedPhoto!,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (result.isSuccess) {
      if (kDebugMode) {
        debugPrint('Reporte creado correctamente: ${result.person!.id}');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reporte creado exitosamente'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      if (kDebugMode) {
        debugPrint('Fallo al crear reporte: ${result.error}');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Error al crear el reporte'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear reporte'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Completa la información para crear el reporte de la persona desaparecida.',
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: AppTheme.paddingLarge),
                _FormSectionCard(
                  icon: Icons.badge_outlined,
                  title: 'Identidad',
                  children: [
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa el nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.paddingSmall),
                    TextFormField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        labelText: 'Apodo (opcional)',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: AppTheme.paddingSmall),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Edad',
                              prefixIcon: Icon(Icons.cake_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingresa la edad';
                              }
                              final age = int.tryParse(value);
                              if (age == null || age <= 0) {
                                return 'Edad inválida';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: AppTheme.paddingSmall),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedGender,
                            decoration: const InputDecoration(
                              labelText: 'Género',
                              prefixIcon: Icon(Icons.wc_outlined),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'male', child: Text('Masculino')),
                              DropdownMenuItem(value: 'female', child: Text('Femenino')),
                              DropdownMenuItem(value: 'other', child: Text('Otro')),
                            ],
                            onChanged: (value) => setState(() => _selectedGender = value),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Selecciona el género';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.paddingLarge),
                _FormSectionCard(
                  icon: Icons.description_outlined,
                  title: 'Descripción',
                  children: [
                    TextFormField(
                      controller: _physicalDescriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción física',
                        prefixIcon: Icon(Icons.accessibility_new),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Describe los rasgos físicos';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.paddingSmall),
                    TextFormField(
                      controller: _clothingDescriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Última vestimenta',
                        prefixIcon: Icon(Icons.checkroom_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Describe la ropa';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.paddingSmall),
                    TextFormField(
                      controller: _medicalConditionsController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Condiciones médicas (opcional)',
                        prefixIcon: Icon(Icons.health_and_safety_outlined),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.paddingLarge),
                _FormSectionCard(
                  icon: Icons.place_outlined,
                  title: 'Última vez visto',
                  children: [
                    InkWell(
                      onTap: _pickLocation,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Selecciona ubicación',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        child: Text(
                          _lastSeenAddress ?? 'Toca para elegir en el mapa',
                          style: _lastSeenAddress == null
                              ? AppTheme.bodyMedium.copyWith(color: AppTheme.textHint)
                              : AppTheme.bodyMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.paddingSmall),
                    TextFormField(
                      controller: _lastSeenAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Dirección exacta (opcional)',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                      onChanged: (value) {
                        final trimmed = value.trim();
                        _lastSeenAddress = trimmed.isEmpty ? null : trimmed;
                      },
                    ),
                    const SizedBox(height: AppTheme.paddingSmall),
                    InkWell(
                      onTap: _pickLastSeenDateTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha y hora',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(
                          _lastSeenDate == null || _lastSeenTime == null
                              ? 'Selecciona fecha y hora'
                              : '${_lastSeenDate!.day.toString().padLeft(2, '0')}/'
                                  '${_lastSeenDate!.month.toString().padLeft(2, '0')}/'
                                  '${_lastSeenDate!.year} '
                                  '${_lastSeenTime!.format(context)}',
                          style: _lastSeenDate == null || _lastSeenTime == null
                              ? AppTheme.bodyMedium.copyWith(color: AppTheme.textHint)
                              : AppTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.paddingLarge),
                _FormSectionCard(
                  icon: Icons.support_agent_outlined,
                  title: 'Contacto de referencia',
                  children: [
                    TextFormField(
                      controller: _contactNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del contacto',
                        prefixIcon: Icon(Icons.person_pin_circle_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa el nombre del contacto';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.paddingSmall),
                    TextFormField(
                      controller: _contactPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono del contacto',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa el teléfono del contacto';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.paddingSmall),
                    TextFormField(
                      controller: _contactEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo del contacto (opcional)',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null;
                        }
                        final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Correo inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.paddingSmall),
                    TextFormField(
                      controller: _relationshipController,
                      decoration: const InputDecoration(
                        labelText: 'Relación con el desaparecido',
                        prefixIcon: Icon(Icons.family_restroom_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Describe la relación';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.paddingLarge),
                _FormSectionCard(
                  icon: Icons.report_problem_outlined,
                  title: 'Circunstancias',
                  children: [
                    TextFormField(
                      controller: _circumstancesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Circunstancias de la desaparición',
                        prefixIcon: Icon(Icons.report_problem_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Describe las circunstancias';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.paddingSmall),
                    TextFormField(
                      controller: _additionalInfoController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Información adicional (opcional)',
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.paddingLarge),
                _FormSectionCard(
                  icon: Icons.image_outlined,
                  title: 'Foto principal',
                  children: [
                    Center(
                      child: _selectedPhoto == null
                          ? OutlinedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.add_a_photo_outlined),
                              label: const Text('Seleccionar foto'),
                            )
                          : Column(
                              children: [
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusMedium),
                                  child: Image.file(
                                    _selectedPhoto!,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.paddingSmall),
                                TextButton.icon(
                                  onPressed: _pickImage,
                                  icon: const Icon(Icons.change_circle_outlined),
                                  label: const Text('Cambiar foto'),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.paddingLarge),
                FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(_isSubmitting ? 'Enviando...' : 'Crear reporte'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _FormSectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
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
                Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.paddingSmall),
                Text(
                  title,
                  style: AppTheme.headlineSmall,
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
