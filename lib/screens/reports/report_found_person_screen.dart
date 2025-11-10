import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

import '../../config/app_theme.dart';
import '../../models/found_report.dart';
import '../../models/missing_person.dart';
import '../../services/found_report_service.dart';
import '../../services/location_service.dart';

class ReportFoundPersonScreen extends StatefulWidget {
  final MissingPerson person;

  const ReportFoundPersonScreen({super.key, required this.person});

  @override
  State<ReportFoundPersonScreen> createState() => _ReportFoundPersonScreenState();
}

class _ReportFoundPersonScreenState extends State<ReportFoundPersonScreen> {
  final _formKey = GlobalKey<FormState>();

  final _descriptionController = TextEditingController();
  final _contactInfoController = TextEditingController();
  final _addressController = TextEditingController();

  double? _latitude;
  double? _longitude;
  DateTime? _foundDate;
  TimeOfDay? _foundTime;
  File? _photo;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _contactInfoController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _photo = File(picked.path));
  }

  Future<void> _useCurrentLocation() async {
    final serviceEnabled = await LocationService.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activa los servicios de ubicación para continuar'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permiso de ubicación denegado'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    final position = await LocationService.getCurrentLocation();
    if (!mounted) return;
    if (position != null) {
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener la ubicación actual'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _pickFoundDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _foundDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      helpText: 'Fecha del hallazgo',
    );
    if (date == null) return;
    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _foundTime ?? TimeOfDay.fromDateTime(now),
      helpText: 'Hora del hallazgo',
    );
    if (time == null) return;
    if (!mounted) return;

    setState(() {
      _foundDate = date;
      _foundTime = time;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona la ubicación donde encontraste a la persona'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    if (_foundDate == null || _foundTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona la fecha y hora del hallazgo'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final dateTime = DateTime(
      _foundDate!.year,
      _foundDate!.month,
      _foundDate!.day,
      _foundTime!.hour,
      _foundTime!.minute,
    );

    final data = FoundReportCreate(
      missingPersonId: widget.person.id,
      latitude: _latitude!,
      longitude: _longitude!,
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      foundDate: dateTime.toUtc(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      contactInfo: _contactInfoController.text.trim().isEmpty
          ? null
          : _contactInfoController.text.trim(),
    );

    if (kDebugMode) {
      debugPrint('=== Reportar persona encontrada ===');
      debugPrint('Payload: ${data.toJson()}');
      debugPrint('Foto: ${_photo?.path}');
    }

    setState(() => _isSubmitting = true);

    final service = context.read<FoundReportService>();
    final result = await service.reportFoundPerson(
      data: data,
      photo: _photo,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hallazgo reportado correctamente'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Error al reportar hallazgo'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportar persona encontrada'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estás reportando a ${widget.person.fullName}',
                  style: AppTheme.titleMedium,
                ),
                const SizedBox(height: AppTheme.paddingLarge),
                _SectionLabel(text: 'Ubicación del hallazgo'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.paddingMedium),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    color: AppTheme.surfaceColor,
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              color: AppTheme.primaryColor),
                          const SizedBox(width: AppTheme.paddingSmall),
                          Expanded(
                            child: Text(
                              _latitude != null && _longitude != null
                                  ? 'Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)}'
                                  : 'Ubicación no seleccionada',
                              style: AppTheme.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _latitude != null && _longitude != null
                                    ? AppTheme.textPrimary
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.paddingSmall),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _useCurrentLocation,
                          icon: const Icon(Icons.my_location_outlined),
                          label: const Text('Usar mi ubicación actual'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.paddingSmall),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección (opcional)',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                ),
                const SizedBox(height: AppTheme.paddingLarge),
                _SectionLabel(text: 'Fecha y hora del hallazgo'),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.event_outlined, color: AppTheme.primaryColor),
                  title: Text(
                    _foundDate == null || _foundTime == null
                        ? 'Seleccionar fecha y hora'
                        : '${_foundDate!.day.toString().padLeft(2, '0')}/'
                            '${_foundDate!.month.toString().padLeft(2, '0')}/'
                            '${_foundDate!.year} '
                            '${_foundTime!.format(context)}',
                  ),
                  trailing: TextButton(
                    onPressed: _pickFoundDateTime,
                    child: const Text('Seleccionar'),
                  ),
                ),
                const SizedBox(height: AppTheme.paddingLarge),
                _SectionLabel(text: 'Detalles adicionales'),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: AppTheme.paddingSmall),
                TextFormField(
                  controller: _contactInfoController,
                  decoration: const InputDecoration(
                    labelText: 'Información de contacto (opcional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: AppTheme.paddingLarge),
                _SectionLabel(text: 'Foto (opcional)'),
                const SizedBox(height: AppTheme.paddingSmall),
                Center(
                  child: _photo == null
                      ? OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('Adjuntar foto'),
                        )
                      : Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              child: Image.file(
                                _photo!,
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
                const SizedBox(height: AppTheme.paddingLarge),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      _isSubmitting ? 'Enviando...' : 'Enviar reporte de hallazgo',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
      child: Text(
        text,
        style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

// TODO Implement this library.