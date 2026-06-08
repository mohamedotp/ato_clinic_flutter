import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/patient.dart';
import '../../models/profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patients_provider.dart';
import '../../providers/audit_provider.dart';
import '../../services/insurance_service.dart';
import '../../models/insurance_company.dart';
import 'patient_finance_tab.dart';

final _insuranceSvcProvider = Provider((ref) => InsuranceService());
final _insCompaniesProvider = FutureProvider.family<List<InsuranceCompany>, String>((ref, clinicId) {
  return ref.read(_insuranceSvcProvider).getCompanies(clinicId);
});

class PatientsListScreen extends ConsumerStatefulWidget {
  const PatientsListScreen({super.key});

  @override
  ConsumerState<PatientsListScreen> createState() => _PatientsListScreenState();
}

enum ViewMode { list, grid }

class _PatientsListScreenState extends ConsumerState<PatientsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  ViewMode _viewMode = ViewMode.list;

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
      final authState = ref.read(authProvider);
      final clinicId = authState is AuthAuthenticated ? authState.profile?.clinicId : null;
      final userName = authState is AuthAuthenticated ? authState.profile?.fullName : '';
      
      final patients = ref.read(searchedPatientsProvider).valueOrNull ?? [];
      final patient = patients.where((p) => p.id == id).firstOrNull;
      final patientName = patient?.fullName ?? id;
      final patientJson = patient?.toJson();

      await ref.read(patientService).deletePatient(id);

      if (clinicId != null) {
        await ref.read(auditServiceProvider).logEvent(
          clinicId: clinicId,
          userId: authState is AuthAuthenticated ? authState.profile?.id ?? '' : '',
          action: 'delete_patient',
          tableName: 'patients',
          recordId: id,
          description: 'تم حذف المريض $patientName بواسطة $userName',
          oldValues: patientJson,
        );
      }

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(_viewMode == ViewMode.list ? Icons.grid_view_rounded : Icons.list_rounded),
            onPressed: () => setState(() => _viewMode = _viewMode == ViewMode.list ? ViewMode.grid : ViewMode.list),
            tooltip: 'تغيير طريقة العرض',
          ),
          const SizedBox(width: 8),
        ],
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
                    color: Colors.black.withValues(alpha: 0.03),
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

          // Patients Display
          Expanded(
            child: patientsAsync.when(
              data: (patients) {
                if (patients.isEmpty) {
                  return const Center(child: Text('لا يوجد مرضى مطابقين للبحث'));
                }

                if (_viewMode == ViewMode.grid) {
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: patients.length,
                    itemBuilder: (context, index) {
                      final patient = patients[index];
                      return _PatientGridItem(
                        patient: patient,
                        onEdit: () => _showAddEditDialog(patient),
                        onDelete: () => _deletePatient(patient.id),
                      );
                    },
                  );
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


class _PatientCard extends ConsumerWidget {
  final Patient patient;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PatientCard({
    required this.patient,
    required this.onEdit,
    required this.onDelete,
  });

  static void _showFinanceSheet(BuildContext context, String patientId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAF9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'الحسابات المالية',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: PatientFinanceTab(patientId: patientId),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isReceptionist = authState is AuthAuthenticated && authState.profile?.role == UserRole.receptionist;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.02)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: isReceptionist ? null : () => context.push('/workspace/${patient.id}'),
        borderRadius: BorderRadius.circular(24),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF006D63).withValues(alpha: 0.1), const Color(0xFF006D63).withValues(alpha: 0.2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF006D63).withValues(alpha: 0.1)),
              ),
              child: Center(
                child: Text(
                  patient.fullName.isNotEmpty ? patient.fullName[0] : '?',
                  style: const TextStyle(
                    color: Color(0xFF006D63),
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Patient Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (patient.fullName.contains('Visitor'))
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.message, size: 16, color: Colors.green),
                        ),
                      Flexible(
                        child: Text(
                          patient.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    patient.phone ?? 'لا يوجد هاتف',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (patient.fullName.contains('Visitor'))
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                          ),
                          child: const Text(
                            'مريض جديد من واتساب',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.green),
                          ),
                        ),
                      if (patient.patientCode != null && patient.patientCode!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            patient.patientCode!,
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.blueGrey),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // زر الحسابات
                if (!isReceptionist)
                  IconButton(
                    onPressed: () => _showFinanceSheet(context, patient.id),
                    icon: const Icon(Icons.account_balance_wallet_rounded,
                        color: Color(0xFF006D63), size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF006D63).withValues(alpha: 0.06),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(40, 40),
                    ),
                    tooltip: 'الحسابات المالية',
                  ),
                if (!isReceptionist) const SizedBox(width: 4),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined,
                      color: Color(0xFF10B981), size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF10B981).withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(40, 40),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(40, 40),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientGridItem extends ConsumerWidget {
  final Patient patient;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PatientGridItem({
    required this.patient,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isReceptionist = authState is AuthAuthenticated && authState.profile?.role == UserRole.receptionist;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: isReceptionist ? null : () => context.push('/workspace/${patient.id}'),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF006D63).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    patient.fullName.isNotEmpty ? patient.fullName[0] : '?',
                    style: const TextStyle(
                      color: Color(0xFF006D63),
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                patient.fullName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                patient.phone ?? '-',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      minimumSize: const Size(32, 32),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF10B981), size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      minimumSize: const Size(32, 32),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
  late TextEditingController _insuranceNumberController;
  String? _selectedInsuranceId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.patient?.fullName);
    _phoneController = TextEditingController(text: widget.patient?.phone);
    _codeController = TextEditingController(text: widget.patient?.patientCode);
    _insuranceNumberController = TextEditingController(text: widget.patient?.insuranceNumber);
    _selectedInsuranceId = widget.patient?.insuranceCompanyId;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authState = ref.read(authProvider);
      if (authState is! AuthAuthenticated) return;
      
      final clinicId = authState.profile?.clinicId;
      if (clinicId == null) return;
      
      final cId = widget.patient?.clinicId ?? clinicId;

      final data = {
        'full_name': _nameController.text,
        'phone': _phoneController.text,
        'patient_code': _codeController.text,
        'insurance_company_id': _selectedInsuranceId,
        'insurance_number': _insuranceNumberController.text.isNotEmpty ? _insuranceNumberController.text : null,
        'clinic_id': cId,
        'status': 'active',
      };

      if (widget.patient != null) {
        await ref.read(patientService).updatePatient(widget.patient!.id, data);
        await ref.read(auditServiceProvider).logEvent(
          clinicId: cId,
          userId: authState.profile?.id ?? '',
          action: 'update_patient',
          tableName: 'patients',
          recordId: widget.patient!.id,
          description: 'تم تعديل بيانات المريض ${widget.patient!.fullName} بواسطة ${authState.profile?.fullName}',
          oldValues: widget.patient!.toJson(),
          newValues: data,
        );
      } else {
        await ref.read(patientService).addPatient(data);
        await ref.read(auditServiceProvider).logEvent(
          clinicId: cId,
          userId: authState.profile?.id ?? '',
          action: 'create_patient',
          tableName: 'patients',
          description: 'تم تسجيل مريض جديد باسم ${_nameController.text} بواسطة ${authState.profile?.fullName}',
          newValues: data,
        );
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
              const SizedBox(height: 20),
              _buildInsuranceSelector(),
              const SizedBox(height: 20),
              if (_selectedInsuranceId != null) ...[
                _buildField('رقم بوليصة التأمين', _insuranceNumberController, Icons.badge_outlined),
                const SizedBox(height: 20),
              ],
              const SizedBox(height: 20),
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

  Widget _buildInsuranceSelector() {
    final authState = ref.watch(authProvider);
    final clinicId = authState is AuthAuthenticated ? authState.profile?.clinicId : null;
    if (clinicId == null) return const SizedBox.shrink();

    final companiesAsync = ref.watch(_insCompaniesProvider(clinicId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text('شركة التأمين (اختياري)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        companiesAsync.when(
          data: (companies) {
            return DropdownButtonFormField<String>(
              value: _selectedInsuranceId,
              isExpanded: true,
              hint: const Text('بدون تأمين', textAlign: TextAlign.right),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[50],
                prefixIcon: const Icon(Icons.health_and_safety_outlined, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('بدون تأمين', textAlign: TextAlign.right)),
                ...companies.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, textAlign: TextAlign.right))),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedInsuranceId = val;
                  if (val == null) _insuranceNumberController.clear();
                });
              },
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => const Text('خطأ في تحميل شركات التأمين'),
        ),
      ],
    );
  }
}
