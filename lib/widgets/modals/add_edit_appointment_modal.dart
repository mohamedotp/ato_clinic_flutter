import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/appointment.dart';
import '../../providers/appointments_provider.dart';
import '../../providers/patients_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/services_provider.dart';
import '../../services/appointment_service.dart';
import '../../models/medical_service.dart';

class AddEditAppointmentModal extends ConsumerStatefulWidget {
  final Appointment? appointment;
  final DateTime? initialDate;
  const AddEditAppointmentModal({super.key, this.appointment, this.initialDate});

  static void show(BuildContext context, {Appointment? appointment, DateTime? initialDate}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditAppointmentModal(appointment: appointment, initialDate: initialDate),
    );
  }

  @override
  ConsumerState<AddEditAppointmentModal> createState() => _AddEditAppointmentModalState();
}

class _AddEditAppointmentModalState extends ConsumerState<AddEditAppointmentModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _notesController;
  late TextEditingController _queueController;
  late TextEditingController _priceController;
  DateTime _selectedDate = DateTime.now();
  String? _selectedPatientId;
  AppointmentStatus _selectedStatus = AppointmentStatus.scheduled;
  String _selectedType = 'appointment';
  List<String> _selectedServiceIds = [];
  double _totalPrice = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.appointment?.notes);
    _queueController = TextEditingController(text: widget.appointment?.queueNumber?.toString());
    if (widget.appointment != null) {
      _selectedDate = widget.appointment!.appointmentDate ?? DateTime.now();
      _selectedPatientId = widget.appointment!.patientId;
      _selectedStatus = widget.appointment!.status;
      _selectedType = widget.appointment!.type;
      _selectedServiceIds = List.from(widget.appointment!.serviceIds);
      _totalPrice = widget.appointment!.totalPrice;
    } else if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }
    _priceController = TextEditingController(text: _totalPrice > 0 ? _totalPrice.toString() : '');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedPatientId == null) return;
    setState(() => _isLoading = true);
    
    _totalPrice = double.tryParse(_priceController.text) ?? 0.0;
    final queueNumber = int.tryParse(_queueController.text);
    
    try {
      final authState = ref.read(authProvider);
      if (authState is! AuthAuthenticated) return;
      
      final data = {
        'clinic_id': authState.profile?.clinicId,
        'patient_id': _selectedPatientId,
        'notes': _notesController.text,
        'appointment_date': _selectedDate.toIso8601String(),
        'queue_number': queueNumber,
        'status': _selectedStatus.name,
        'type': _selectedType,
        'service_ids': _selectedServiceIds,
        'total_price': _totalPrice,
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
    final servicesAsync = ref.watch(servicesProvider);

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
                data: (patients) {
                  final initialPatient = _selectedPatientId != null 
                    ? patients.firstWhere((p) => p.id == _selectedPatientId, orElse: () => patients.first)
                    : null;
                    
                  return SearchAnchor(
                    builder: (BuildContext context, SearchController controller) {
                      // Update controller text if a patient is selected but text is empty
                      if (_selectedPatientId != null && controller.text.isEmpty) {
                         final p = patients.firstWhere((p) => p.id == _selectedPatientId);
                         controller.text = p.fullName;
                      }
                      
                      return TextFormField(
                        controller: controller,
                        readOnly: true,
                        textAlign: TextAlign.right,
                        onTap: () => controller.openView(),
                        decoration: InputDecoration(
                          labelText: 'اختر المريض',
                          prefixIcon: const Icon(Icons.person_search),
                          border: const OutlineInputBorder(),
                          suffixIcon: _selectedPatientId != null 
                            ? IconButton(
                                icon: const Icon(Icons.clear), 
                                onPressed: () {
                                  setState(() => _selectedPatientId = null);
                                  controller.clear();
                                }
                              )
                            : null,
                        ),
                        validator: (value) => _selectedPatientId == null ? 'يرجى اختيار مريض' : null,
                      );
                    },
                    isFullScreen: false,
                    viewConstraints: const BoxConstraints(maxHeight: 300),
                    suggestionsBuilder: (BuildContext context, SearchController controller) {
                      final String query = controller.text.toLowerCase();
                      final filtered = patients.where((p) => p.fullName.toLowerCase().contains(query)).toList();
                      
                      return filtered.map((p) => ListTile(
                        title: Text(p.fullName, textAlign: TextAlign.right),
                        subtitle: Text(p.phone ?? '', textAlign: TextAlign.right),
                        onTap: () {
                          setState(() => _selectedPatientId = p.id);
                          controller.closeView(p.fullName);
                        },
                      ));
                    },
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(DateFormat('yyyy/MM/dd').format(_selectedDate), textAlign: TextAlign.right),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final now = DateTime.now();
                  final initialPickerDate = _selectedDate.isBefore(now) ? _selectedDate : now;
                  final picked = await showDatePicker(
                    context: context, 
                    initialDate: _selectedDate.isBefore(now) ? _selectedDate : _selectedDate, // Still use _selectedDate as initial
                    firstDate: _selectedDate.isBefore(now) ? _selectedDate : now, 
                    lastDate: now.add(const Duration(days: 365))
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _queueController,
                textAlign: TextAlign.right,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'رقم الحجز',
                  hintText: 'مثال: 1، 2، 3...',
                  prefixIcon: Icon(Icons.numbers),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'يرجى إدخال رقم الحجز' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                textAlign: TextAlign.right,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'ملاحظات', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: const [
                  DropdownMenuItem(value: 'appointment', child: Text('موعد عام', textAlign: TextAlign.right)),
                  DropdownMenuItem(value: 'examination', child: Text('كشف عادي', textAlign: TextAlign.right)),
                  DropdownMenuItem(value: 'consultation', child: Text('استشارة', textAlign: TextAlign.right)),
                  DropdownMenuItem(value: 'session', child: Text('جلسة', textAlign: TextAlign.right)),
                ],
                onChanged: (val) => setState(() => _selectedType = val!),
                decoration: const InputDecoration(labelText: 'نوع الموعد', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              servicesAsync.when(
                data: (services) {
                  if (services.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: Text('الخدمات المرتبطة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.end,
                          children: services.map((s) {
                            final isSelected = _selectedServiceIds.contains(s.id);
                            return FilterChip(
                              label: Text('${s.name} (${s.price})', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedServiceIds.add(s.id);
                                    _totalPrice += s.price;
                                  } else {
                                    _selectedServiceIds.remove(s.id);
                                    _totalPrice -= s.price;
                                  }
                                  _priceController.text = _totalPrice.toString();
                                });
                              },
                              selectedColor: const Color(0xFF0D9488),
                              checkmarkColor: Colors.white,
                              backgroundColor: Colors.white,
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        textAlign: TextAlign.right,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'السعر الإجمالي (يمكن تعديله)', 
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error loading services: $e'),
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
                width: MediaQuery.sizeOf(context).width,
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
