import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/appointment.dart';
import '../../providers/appointments_provider.dart';
import '../../providers/patients_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/appointment_service.dart';

class AddEditAppointmentModal extends ConsumerStatefulWidget {
  final Appointment? appointment;
  const AddEditAppointmentModal({super.key, this.appointment});

  static void show(BuildContext context, {Appointment? appointment}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditAppointmentModal(appointment: appointment),
    );
  }

  @override
  ConsumerState<AddEditAppointmentModal> createState() => _AddEditAppointmentModalState();
}

class _AddEditAppointmentModalState extends ConsumerState<AddEditAppointmentModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _notesController;
  late TextEditingController _timeController;
  DateTime _selectedDate = DateTime.now();
  String? _selectedPatientId;
  AppointmentStatus _selectedStatus = AppointmentStatus.scheduled;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.appointment?.notes);
    _timeController = TextEditingController(text: widget.appointment?.appointmentTime);
    if (widget.appointment != null) {
      _selectedDate = widget.appointment!.appointmentDate ?? DateTime.now();
      _selectedPatientId = widget.appointment!.patientId;
      _selectedStatus = widget.appointment!.status;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedPatientId == null) return;
    setState(() => _isLoading = true);
    try {
      final authState = ref.read(authProvider);
      if (authState is! AuthAuthenticated) return;
      
      final data = {
        'clinic_id': authState.profile?.clinicId,
        'patient_id': _selectedPatientId,
        'notes': _notesController.text,
        'appointment_date': _selectedDate.toIso8601String(),
        'appointment_time': _timeController.text,
        'status': _selectedStatus.name,
      };

      final service = ref.read(appointmentService);
      if (widget.appointment != null) {
        await service.updateAppointment(widget.appointment!.id, data);
      } else {
        await service.addAppointment(data);
      }

      ref.invalidate(appointmentsProvider);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(patientsProvider);

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 24, right: 24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Text(widget.appointment == null ? 'جدولة موعد جديد' : 'تعديل موعد', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              patientsAsync.when(
                data: (patients) => DropdownButtonFormField<String>(
                  value: _selectedPatientId,
                  items: patients.map((p) => DropdownMenuItem(value: p.id, child: Text(p.fullName, textAlign: TextAlign.right))).toList(),
                  onChanged: (val) => setState(() => _selectedPatientId = val),
                  decoration: const InputDecoration(labelText: 'اختر المريض', border: OutlineInputBorder()),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error loading patients'),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(DateFormat('yyyy/MM/dd').format(_selectedDate), textAlign: TextAlign.right),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timeController,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(labelText: 'الوقت (مثال: 10:30 AM)', prefixIcon: Icon(Icons.access_time), border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                textAlign: TextAlign.right,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'ملاحظات', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AppointmentStatus>(
                value: _selectedStatus,
                items: AppointmentStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(_getStatusLabel(s), textAlign: TextAlign.right))).toList(),
                onChanged: (val) => setState(() => _selectedStatus = val!),
                decoration: const InputDecoration(labelText: 'الحالة', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('حفظ الموعد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusLabel(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed: return 'مؤكد';
      case AppointmentStatus.cancelled: return 'ملغي';
      case AppointmentStatus.completed: return 'مكتمل';
      case AppointmentStatus.no_show: return 'لم يحضر';
      case AppointmentStatus.scheduled: return 'مجدول';
    }
  }
}
