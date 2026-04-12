import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/patient.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patients_provider.dart';

class PatientsListScreen extends ConsumerStatefulWidget {
  const PatientsListScreen({super.key});

  @override
  ConsumerState<PatientsListScreen> createState() => _PatientsListScreenState();
}

class _PatientsListScreenState extends ConsumerState<PatientsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize search listener if needed
  }

  void _showAddEditDialog([Patient? patient]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEditPatientBottomSheet(patient: patient),
    );
  }

  Future<void> _deletePatient(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المريض', textAlign: TextAlign.right),
        content: const Text('هل أنت متأكد من حذف هذا المريض نهائياً؟', textAlign: TextAlign.right),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(patientService).deletePatient(id);
      ref.invalidate(patientsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المريض بنجاح')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(searchedPatientsProvider);
    const primaryColor = Color(0xFF006D63);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('إدارة المرضى', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                textAlign: TextAlign.right,
                onChanged: (val) => ref.read(patientSearchProvider.notifier).state = val,
                decoration: InputDecoration(
                  hintText: 'البحث بالاسم أو رقم الهاتف...',
                  prefixIcon: const Icon(Icons.search, color: primaryColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
          ),

          // Patients List
          Expanded(
            child: patientsAsync.when(
              data: (patients) {
                if (patients.isEmpty) {
                  return const Center(child: Text('لا يوجد مرضى مطابقين للبحث'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    final patient = patients[index];
                    return _PatientCard(
                      patient: patient,
                      onEdit: () => _showAddEditDialog(patient),
                      onDelete: () => _deletePatient(patient.id),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('خطأ: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: const Color(0xFF00302D),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة مريض', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final Patient patient;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PatientCard({
    required this.patient,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.02)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Actions
          Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.push('/workspace/${patient.id}'),
                    icon: const Icon(Icons.dashboard_customize_outlined, color: Color(0xFF006D63), size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF006D63).withOpacity(0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(36, 36),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF10B981), size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981).withOpacity(0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(36, 36),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.05),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size(36, 36),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Patient Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  patient.fullName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  patient.phone ?? 'لا يوجد هاتف',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                if (patient.patientCode != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      patient.patientCode!,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Color(0xFF006D63).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                patient.fullName[0],
                style: const TextStyle(
                  color: Color(0xFF006D63),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddEditPatientBottomSheet extends ConsumerStatefulWidget {
  final Patient? patient;
  const _AddEditPatientBottomSheet({this.patient});

  @override
  ConsumerState<_AddEditPatientBottomSheet> createState() => _AddEditPatientBottomSheetState();
}

class _AddEditPatientBottomSheetState extends ConsumerState<_AddEditPatientBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _codeController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.patient?.fullName);
    _phoneController = TextEditingController(text: widget.patient?.phone);
    _codeController = TextEditingController(text: widget.patient?.patientCode);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authState = ref.read(authProvider);
      if (authState is! AuthAuthenticated) return;
      
      final clinicId = authState.profile?.id; // Assuming profile ID or another way to get clinic_id
      // Fetch clinic_id logic might be more complex, but for now:
      final cId = widget.patient?.clinicId ?? authState.profile?.id; // Placeholder

      final data = {
        'full_name': _nameController.text,
        'phone': _phoneController.text,
        'patient_code': _codeController.text,
        'clinic_id': cId,
        'status': 'active',
      };

      if (widget.patient != null) {
        await ref.read(patientService).updatePatient(widget.patient!.id, data);
      } else {
        await ref.read(patientService).addPatient(data);
      }

      ref.invalidate(patientsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                widget.patient != null ? 'تعديل بيانات المريض' : 'إضافة مريض جديد',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              _buildField('اسم المريض الكامل', _nameController, Icons.person_outline),
              const SizedBox(height: 20),
              _buildField('رقم الهاتف', _phoneController, Icons.phone_outlined, TextInputType.phone),
              const SizedBox(height: 20),
              _buildField('كود المريض (اختياري)', _codeController, Icons.tag),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00302D),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(widget.patient != null ? 'حفظ التعديلات' : 'إضافة المريض الآن', 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, [TextInputType? type]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          textAlign: TextAlign.right,
          keyboardType: type,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
          validator: (val) => val == null || val.isEmpty ? 'هذا الحقل مطلوب' : null,
        ),
      ],
    );
  }
}
