import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/visit.dart';
import '../../providers/visits_provider.dart';
import '../../providers/patients_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/services_provider.dart';
import 'package:intl/intl.dart';

class VisitsListScreen extends ConsumerWidget {
  const VisitsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitsAsync = ref.watch(visitsProvider);
    const primaryColor = Color(0xFF006D63);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('سجل الزيارات', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          _buildMetrics(ref),
          Expanded(
            child: visitsAsync.when(
              data: (visits) => _buildVisitsList(context, ref, visits),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditVisit(context, ref),
        backgroundColor: primaryColor,
        child: const Icon(Icons.add_task, color: Colors.white),
      ),
    );
  }

  Widget _buildMetrics(WidgetRef ref) {
    final visitsAsync = ref.watch(visitsProvider);
    return visitsAsync.maybeWhen(
      data: (visits) {
        final totalRevenue = visits.fold(0.0, (sum, item) => sum + item.cost);
        final todayCount = visits.where((v) => v.visitDate?.day == DateTime.now().day).length;

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'إيرادات الحصيلة',
                  value: '${totalRevenue.toInt()} ر.س',
                  icon: Icons.account_balance_wallet_outlined,
                  color: const Color(0xFFE0F2F1),
                  iconColor: Colors.teal,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _MetricCard(
                  title: 'زيارات اليوم',
                  value: todayCount.toString(),
                  icon: Icons.trending_up,
                  color: const Color(0xFFFFF3E0),
                  iconColor: Colors.orange,
                ),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildVisitsList(BuildContext context, WidgetRef ref, List<Visit> visits) {
    if (visits.isEmpty) return const Center(child: Text('لا توجد زيارات مسجلة'));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: visits.length,
      itemBuilder: (context, index) {
        final visit = visits[index];
        return _VisitCard(
          visit: visit,
          onEdit: () => _showAddEditVisit(context, ref, visit),
          onDelete: () => _deleteVisit(context, ref, visit.id),
        );
      },
    );
  }

  void _showAddEditVisit(BuildContext context, WidgetRef ref, [Visit? visit]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEditVisitBottomSheet(visit: visit),
    );
  }

  Future<void> _deleteVisit(BuildContext context, WidgetRef ref, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الزيارة'),
        content: const Text('هل أنت متأكد من حذف هذا السجل؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(visitService).deleteVisit(id);
      ref.invalidate(visitsProvider);
    }
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color iconColor;

  const _MetricCard({required this.title, required this.value, required this.icon, required this.color, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor, size: 20)),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  final Visit visit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VisitCard({required this.visit, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.black.withOpacity(0.02))),
      child: Row(
        children: [
          Column(
            children: [
              IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey, size: 20)),
              IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20)),
            ],
          ),
          const Spacer(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(visit.patient?.fullName ?? 'مريض غير معروف', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(visit.diagnosis ?? 'لا يوجد تشخيص', style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFF1F8E9), borderRadius: BorderRadius.circular(8)),
                      child: Text('${visit.cost.toInt()} ر.س', style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Text(DateFormat('yyyy/MM/dd - hh:mm a').format(visit.visitDate ?? DateTime.now()), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: const Color(0xFF006D63).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Center(child: Text(visit.patient?.fullName[0] ?? 'أ', style: const TextStyle(color: Color(0xFF006D63), fontWeight: FontWeight.bold, fontSize: 20))),
          ),
        ],
      ),
    );
  }
}

class _AddEditVisitBottomSheet extends ConsumerStatefulWidget {
  final Visit? visit;
  const _AddEditVisitBottomSheet({this.visit});

  @override
  ConsumerState<_AddEditVisitBottomSheet> createState() => _AddEditVisitBottomSheetState();
}

class _AddEditVisitBottomSheetState extends ConsumerState<_AddEditVisitBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _diagnosisController;
  late TextEditingController _treatmentController;
  late TextEditingController _costController;
  String? _selectedPatientId;
  final List<String> _selectedServiceIds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _diagnosisController = TextEditingController(text: widget.visit?.diagnosis);
    _treatmentController = TextEditingController(text: widget.visit?.treatment);
    _costController = TextEditingController(text: widget.visit?.cost.toString() ?? '0');
    _selectedPatientId = widget.visit?.patientId;
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
        'diagnosis': _diagnosisController.text,
        'treatment': _treatmentController.text,
        'cost': double.tryParse(_costController.text) ?? 0,
        'status': 'completed',
        'visit_date': DateTime.now().toIso8601String(),
      };

      if (widget.visit != null) {
        await ref.read(visitService).updateVisit(widget.visit!.id, data, _selectedServiceIds);
      } else {
        await ref.read(visitService).addVisit(data, _selectedServiceIds);
      }

      ref.invalidate(visitsProvider);
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
              const Text('تسجيل زيارة جديدة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              // Patient Dropdown
              patientsAsync.when(
                data: (patients) => DropdownButtonFormField<String>(
                  value: _selectedPatientId,
                  items: patients.map((p) => DropdownMenuItem(value: p.id, child: Text(p.fullName, textAlign: TextAlign.right))).toList(),
                  onChanged: (val) => setState(() => _selectedPatientId = val),
                  decoration: const InputDecoration(labelText: 'اختر المريض', alignLabelWithHint: true, border: OutlineInputBorder()),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error loading patients'),
              ),
              const SizedBox(height: 16),
              _buildTextField('التشخيص', _diagnosisController, Icons.medical_information_outlined),
              const SizedBox(height: 16),
              _buildTextField('الخطة العلاجية', _treatmentController, Icons.healing_outlined, 3),
              const SizedBox(height: 16),
              _buildTextField('التكلفة (ر.س)', _costController, Icons.payments_outlined, 1, TextInputType.number),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00302D), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('حفظ الزيارة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, [int lines = 1, TextInputType type = TextInputType.text]) {
    return TextFormField(
      controller: controller,
      textAlign: TextAlign.right,
      maxLines: lines,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
