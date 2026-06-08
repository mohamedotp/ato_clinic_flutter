import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/appointment.dart';
import '../../providers/appointments_provider.dart';
import '../../providers/patients_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/services_provider.dart';
import '../../services/treasury_service.dart';

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
  static const _primary = Color(0xFF0D9488);
  static const _followUpColor = Color(0xFF7C3AED);

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _notesController;
  late TextEditingController _queueController;
  late TextEditingController _priceController;

  // ── Main appointment ──
  DateTime _selectedDate = DateTime.now();
  String? _selectedPatientId;
  AppointmentStatus _selectedStatus = AppointmentStatus.scheduled;
  String _selectedType = 'appointment';
  List<String> _selectedServiceIds = [];
  double _totalPrice = 0.0;

  // ── Follow-up / consultation ──
  bool _hasFollowUp = false;
  DateTime _followUpDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay? _followUpTime;

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
      _followUpDate = widget.initialDate!.add(const Duration(days: 7));
    }
    _priceController = TextEditingController(text: _totalPrice > 0 ? _totalPrice.toString() : '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    _queueController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedPatientId == null) return;
    setState(() => _isLoading = true);

    _totalPrice = double.tryParse(_priceController.text) ?? 0.0;
    final queueNumber = int.tryParse(_queueController.text);

    try {
      final authState = ref.read(authProvider);
      if (authState is! AuthAuthenticated) return;
      final clinicId = authState.profile?.clinicId;

      // 1) Save the main appointment
      final data = {
        'clinic_id': clinicId,
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

      // 2b) تسجيل في الخزينة تلقائياً عند اختيار "مكتمل" + السعر > 0
      if (_selectedStatus == AppointmentStatus.completed && _totalPrice > 0 && clinicId != null) {
        final patients = ref.read(patientsProvider).valueOrNull;
        final patientName = patients?.firstWhere(
          (p) => p.id == _selectedPatientId,
          orElse: () => patients!.first,
        ).fullName ?? 'مريض';

        await TreasuryService().addTransaction({
          'clinic_id': clinicId,
          'type': 'income',
          'amount': _totalPrice,
          'category': 'زيارات مرضى',
          'description': 'إيراد موعد مكتمل: $patientName',
          'payment_method': 'cash',
          'reference_type': 'patient',
          'reference_id': _selectedPatientId,
          'transaction_date': DateTime.now().toIso8601String(),
        });
      }

      // 3) If follow-up enabled, create a second consultation appointment
      if (_hasFollowUp && widget.appointment == null) {
        DateTime followUpDateTime = _followUpDate;
        if (_followUpTime != null) {
          followUpDateTime = DateTime(
            _followUpDate.year,
            _followUpDate.month,
            _followUpDate.day,
            _followUpTime!.hour,
            _followUpTime!.minute,
          );
        }
        await service.addAppointment({
          'clinic_id': clinicId,
          'patient_id': _selectedPatientId,
          'notes': 'متابعة: ${_notesController.text.isNotEmpty ? _notesController.text : "موعد سابق"}',
          'appointment_date': followUpDateTime.toIso8601String(),
          'status': AppointmentStatus.scheduled.name,
          'type': 'consultation',
          'service_ids': <String>[],
          'total_price': 0,
        });
      }

      ref.invalidate(appointmentsProvider);
      if (mounted) {
        Navigator.pop(context);
        if (_selectedStatus == AppointmentStatus.completed && _totalPrice > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text('\u062a\u0645 \u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u0645\u0648\u0639\u062f \u0643\u0645\u0643\u062a\u0645\u0644 \u0648\u0625\u0636\u0627\u0641\u0629 \u0627\u0644\u0645\u0628\u0644\u063a \u0644\u0644\u062e\u0632\u064a\u0646\u0629 \u2705'),
                ],
              ),
              backgroundColor: const Color(0xFF006D63),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(patientsProvider);
    final servicesAsync = ref.watch(servicesProvider);
    final isEditing = widget.appointment != null;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isEditing ? 'تعديل موعد' : 'جدولة موعد جديد',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Patient selector
              patientsAsync.when(
                data: (patients) => SearchAnchor(
                  builder: (ctx, controller) {
                    if (_selectedPatientId != null && controller.text.isEmpty) {
                      try {
                        final p = patients.firstWhere((p) => p.id == _selectedPatientId);
                        controller.text = p.fullName;
                      } catch (_) {}
                    }
                    return TextFormField(
                      controller: controller,
                      readOnly: true,
                      textAlign: TextAlign.right,
                      onTap: () => controller.openView(),
                      decoration: _customInputDecoration(
                        label: 'اختر المريض',
                        icon: Icons.person_search,
                        
                        suffixIcon: _selectedPatientId != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  setState(() => _selectedPatientId = null);
                                  controller.clear();
                                },
                              )
                            : const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ),
                      validator: (_) => _selectedPatientId == null ? 'يرجى اختيار مريض' : null,
                    );
                  },
                  isFullScreen: false,
                  viewConstraints: const BoxConstraints(maxHeight: 300),
                  suggestionsBuilder: (ctx, controller) {
                    final q = controller.text.toLowerCase();
                    return patients
                        .where((p) => p.fullName.toLowerCase().contains(q))
                        .map((p) => ListTile(
                              title: Text(p.fullName, textAlign: TextAlign.right),
                              subtitle: Text(p.phone ?? '', textAlign: TextAlign.right),
                              onTap: () {
                                setState(() => _selectedPatientId = p.id);
                                controller.closeView(p.fullName);
                              },
                            ));
                  },
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 16),

              // Main date picker
              _buildDateTile(
                label: 'تاريخ الموعد',
                date: _selectedDate,
                icon: Icons.calendar_today,
                iconColor: _primary,
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: _selectedDate.isBefore(now) ? _selectedDate : now,
                    lastDate: now.add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
              const SizedBox(height: 16),

              // Queue number
              TextFormField(
                controller: _queueController,
                textAlign: TextAlign.right,
                keyboardType: TextInputType.number,
                decoration: _customInputDecoration(
                  label: 'رقم الحجز',
                  hintText: 'مثال: 1، 2، 3...',
                  icon: Icons.numbers,
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'يرجى إدخال رقم الحجز' : null,
              ),
              const SizedBox(height: 16),

              // Type
              DropdownButtonFormField<String>(
                value: _selectedType,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                items: const [
                  DropdownMenuItem(value: 'appointment', child: Text('موعد عام', textAlign: TextAlign.right)),
                  DropdownMenuItem(value: 'examination', child: Text('كشف عادي', textAlign: TextAlign.right)),
                  DropdownMenuItem(value: 'consultation', child: Text('استشارة', textAlign: TextAlign.right)),
                  DropdownMenuItem(value: 'session', child: Text('جلسة', textAlign: TextAlign.right)),
                ],
                onChanged: (val) => setState(() => _selectedType = val!),
                decoration: _customInputDecoration(
                  label: 'نوع الموعد',
                  icon: Icons.category_outlined,
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                textAlign: TextAlign.right,
                maxLines: 2,
                decoration: _customInputDecoration(
                  label: 'ملاحظات',
                  icon: Icons.notes_outlined,
                ),
              ),
              const SizedBox(height: 16),

              // Services
              servicesAsync.when(
                data: (services) {
                  if (services.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text('الخدمات المرتبطة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey[200]!),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.end,
                          children: services.map((s) {
                            final isSel = _selectedServiceIds.contains(s.id);
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              child: FilterChip(
                                label: Text(
                                  '${s.name} (${s.price})',
                                  style: TextStyle(fontSize: 13, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : Colors.black87),
                                ),
                                selected: isSel,
                                onSelected: (sel) => setState(() {
                                  if (sel) {
                                    _selectedServiceIds.add(s.id);
                                    _totalPrice += s.price;
                                  } else {
                                    _selectedServiceIds.remove(s.id);
                                    _totalPrice -= s.price;
                                  }
                                  _priceController.text = _totalPrice.toString();
                                }),
                                selectedColor: _primary,
                                checkmarkColor: Colors.white,
                                backgroundColor: Colors.grey[100],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: isSel ? _primary : Colors.grey[300]!),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        textAlign: TextAlign.right,
                        keyboardType: TextInputType.number,
                        decoration: _customInputDecoration(
                          label: 'السعر الإجمالي (يمكن تعديله)',
                          icon: Icons.attach_money,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),

              // Status
              DropdownButtonFormField<AppointmentStatus>(
                value: _selectedStatus,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                items: AppointmentStatus.values
                    .map((s) => DropdownMenuItem(value: s, child: Text(_statusLabel(s), textAlign: TextAlign.right)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedStatus = val!),
                decoration: _customInputDecoration(
                  label: 'الحالة',
                  icon: Icons.info_outline,
                ),
              ),

              // ══════════════════════════════════════
              // Follow-up section (new appointments only)
              // ══════════════════════════════════════
              if (!isEditing) ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 8),

                // Toggle
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() {
                      _hasFollowUp = !_hasFollowUp;
                      if (_hasFollowUp) {
                        _followUpDate = _selectedDate.add(const Duration(days: 7));
                      }
                    }),
                    borderRadius: BorderRadius.circular(16),
                    hoverColor: _followUpColor.withValues(alpha: 0.05),
                    highlightColor: _followUpColor.withValues(alpha: 0.1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: _hasFollowUp ? _followUpColor.withValues(alpha: 0.06) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _hasFollowUp ? _followUpColor.withValues(alpha: 0.4) : Colors.grey[200]!,
                        ),
                        boxShadow: _hasFollowUp ? [BoxShadow(color: _followUpColor.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))] : [],
                      ),
                      child: Row(
                        children: [
                          Switch.adaptive(
                            value: _hasFollowUp,
                            activeColor: _followUpColor,
                            onChanged: (v) => setState(() {
                              _hasFollowUp = v;
                              if (v) _followUpDate = _selectedDate.add(const Duration(days: 7));
                            }),
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'إضافة موعد متابعة / استشارة',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: _hasFollowUp ? _followUpColor : Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'اختياري',
                                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _hasFollowUp ? _followUpColor.withValues(alpha: 0.1) : Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.event_repeat,
                              color: _hasFollowUp ? _followUpColor : Colors.grey[500],
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Follow-up date & time
                if (_hasFollowUp) ...[
                  const SizedBox(height: 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _followUpColor.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _followUpColor.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(Icons.event_repeat, color: _followUpColor, size: 16),
                            const SizedBox(width: 6),
                            const Text(
                              'تفاصيل موعد المتابعة',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _followUpColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildDateTile(
                          label: 'يوم المتابعة',
                          date: _followUpDate,
                          icon: Icons.calendar_month,
                          iconColor: _followUpColor,
                          onTap: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _followUpDate,
                              firstDate: now,
                              lastDate: now.add(const Duration(days: 365)),
                            );
                            if (picked != null) setState(() => _followUpDate = picked);
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildTimeTile(
                          label: _followUpTime != null
                              ? _followUpTime!.format(context)
                              : 'اختر وقت المتابعة (اختياري)',
                          hasValue: _followUpTime != null,
                          color: _followUpColor,
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _followUpTime ?? TimeOfDay.now(),
                            );
                            if (picked != null) setState(() => _followUpTime = picked);
                          },
                          onClear: _followUpTime != null
                              ? () => setState(() => _followUpTime = null)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              (_hasFollowUp && !isEditing)
                                  ? 'حفظ الموعد + موعد المتابعة'
                                  : 'حفظ الموعد',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _customInputDecoration({
    required String label,
    required IconData icon,
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(icon, color: _primary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey[50],
      hoverColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildDateTile({
    required String label,
    required DateTime date,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: iconColor.withValues(alpha: 0.05),
        highlightColor: iconColor.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey[50],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('yyyy/MM/dd - EEEE', 'ar').format(date),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeTile({
    required String label,
    required bool hasValue,
    required Color color,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: color.withValues(alpha: 0.05),
        highlightColor: color.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: hasValue ? color.withValues(alpha: 0.5) : Colors.grey[200]!),
            borderRadius: BorderRadius.circular(16),
            color: hasValue ? color.withValues(alpha: 0.04) : Colors.grey[50],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: hasValue ? color.withValues(alpha: 0.1) : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.access_time_rounded, color: hasValue ? color : Colors.grey[600], size: 22),
              ),
              if (onClear != null) ...[
                const SizedBox(width: 12),
                InkWell(
                  onTap: onClear,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.red, size: 16),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                label,
                style: TextStyle(
                  fontWeight: hasValue ? FontWeight.bold : FontWeight.normal,
                  fontSize: 15,
                  color: hasValue ? Colors.black87 : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.confirmed: return 'مؤكد';
      case AppointmentStatus.cancelled: return 'ملغي';
      case AppointmentStatus.completed: return 'مكتمل';
      case AppointmentStatus.no_show: return 'لم يحضر';
      case AppointmentStatus.scheduled: return 'مجدول';
    }
  }
}
