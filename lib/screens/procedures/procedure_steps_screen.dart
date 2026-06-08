import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../services/procedure_service.dart';
import '../../models/procedure.dart';
import '../../providers/patients_provider.dart';
import '../../providers/audit_provider.dart';

final _procSvcProvider = Provider((ref) => ProcedureService());

final _templatesProvider = FutureProvider.family<List<ProcedureTemplate>, String>((ref, clinicId) {
  return ref.read(_procSvcProvider).getTemplates(clinicId);
});

final _patientProceduresProvider = FutureProvider.family<List<PatientProcedure>, String>((ref, clinicId) {
  return ref.read(_procSvcProvider).getPatientProcedures(clinicId);
});

class ProcedureStepsScreen extends ConsumerStatefulWidget {
  const ProcedureStepsScreen({super.key});

  @override
  ConsumerState<ProcedureStepsScreen> createState() => _ProcedureStepsScreenState();
}

class _ProcedureStepsScreenState extends ConsumerState<ProcedureStepsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const primaryColor = Color(0xFF006D63);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _clinicId {
    final auth = ref.read(authProvider);
    return auth is AuthAuthenticated ? (auth.profile?.clinicId ?? '') : '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('خطوات الإجراءات', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: primaryColor),
            onPressed: () => _showOptions(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryColor,
          tabs: const [
            Tab(text: 'قوالب الإجراءات'),
            Tab(text: 'المرضى النشطين'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTemplatesTab(),
          _buildActiveProceduresTab(),
        ],
      ),
    );
  }

  Widget _buildTemplatesTab() {
    final templatesAsync = ref.watch(_templatesProvider(_clinicId));
    return templatesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (templates) {
        if (templates.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schema_outlined, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('لا توجد قوالب إجراءات', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showCreateTemplateSheet(context),
                  icon: const Icon(Icons.add),
                  label: const Text('إنشاء قالب'),
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(_templatesProvider(_clinicId)),
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: templates.length,
            itemBuilder: (context, i) => _TemplateCard(template: templates[i])
                .animate().fade(delay: Duration(milliseconds: i * 50)).slideY(begin: 0.1),
          ),
        );
      },
    );
  }

  Widget _buildActiveProceduresTab() {
    final proceduresAsync = ref.watch(_patientProceduresProvider(_clinicId));
    return proceduresAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (procedures) {
        final active = procedures.where((p) => p.status == 'in_progress').toList();
        if (active.isEmpty) {
          return const Center(child: Text('لا توجد إجراءات نشطة حالياً', style: TextStyle(color: Colors.grey)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: active.length,
          itemBuilder: (context, i) => _PatientProcedureCard(
            procedure: active[i],
            onStepComplete: (stepId) async {
              await ref.read(_procSvcProvider).completeStep(stepId);
              ref.invalidate(_patientProceduresProvider(_clinicId));
            },
          ).animate().fade(delay: Duration(milliseconds: i * 50)),
        );
      },
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.schema_outlined, color: primaryColor),
              title: const Text('إنشاء قالب إجراء جديد'),
              onTap: () { Navigator.pop(context); _showCreateTemplateSheet(context); },
            ),
            ListTile(
              leading: const Icon(Icons.person_add_outlined, color: primaryColor),
              title: const Text('بدء إجراء لمريض'),
              onTap: () { Navigator.pop(context); _showStartProcedureSheet(context); },
            ),
          ],
        ),
      ),
    );
  }

  void _showStartProcedureSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StartPatientProcedureSheet(
        clinicId: _clinicId,
        onSaved: () => ref.invalidate(_patientProceduresProvider(_clinicId)),
      ),
    );
  }

  void _showCreateTemplateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateTemplateSheet(
        clinicId: _clinicId,
        onSaved: () => ref.invalidate(_templatesProvider(_clinicId)),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final ProcedureTemplate template;
  const _TemplateCard({required this.template});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF006D63);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(template.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text('${template.steps.length} خطوة • ${template.totalSessions} جلسة',
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.list_alt, color: primaryColor),
        ),
        children: template.steps.map((step) => Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF8FAF9), borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                child: Center(child: Text('${step.stepNumber}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (step.description != null) Text(step.description!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    Text('${step.estimatedDurationMinutes} دقيقة', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

class _PatientProcedureCard extends StatelessWidget {
  final PatientProcedure procedure;
  final Function(String) onStepComplete;
  const _PatientProcedureCard({required this.procedure, required this.onStepComplete});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF006D63);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(procedure.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(procedure.patientName ?? 'مريض', style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${(procedure.progressPercentage * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            Text('${procedure.completedSteps}/${procedure.steps.length}',
                style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: procedure.progressPercentage,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation(primaryColor),
                minHeight: 6,
              ),
            ),
          ),
          ...procedure.steps.map((step) {
            final isCompleted = step.status == 'completed';
            return ListTile(
              leading: isCompleted
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : GestureDetector(
                      onTap: () => onStepComplete(step.id),
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(border: Border.all(color: primaryColor, width: 2), shape: BoxShape.circle),
                        child: Center(child: Text('${step.stepNumber}', style: const TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold))),
                      ),
                    ),
              title: Text(step.title, style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isCompleted ? Colors.grey : Colors.black87,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              )),
              subtitle: step.description != null ? Text(step.description!, style: const TextStyle(fontSize: 11)) : null,
            );
          }).toList(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _CreateTemplateSheet extends ConsumerStatefulWidget {
  final String clinicId;
  final VoidCallback onSaved;
  const _CreateTemplateSheet({required this.clinicId, required this.onSaved});

  @override
  ConsumerState<_CreateTemplateSheet> createState() => _CreateTemplateSheetState();
}

class _CreateTemplateSheetState extends ConsumerState<_CreateTemplateSheet> {
  final _nameCtrl = TextEditingController();
  final List<TextEditingController> _stepCtrls = [TextEditingController()];
  bool _loading = false;
  static const primaryColor = Color(0xFF006D63);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.80,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('إنشاء قالب إجراء', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(controller: _nameCtrl, textAlign: TextAlign.right,
                decoration: InputDecoration(labelText: 'اسم الإجراء', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 16),
            const Align(alignment: Alignment.centerRight, child: Text('الخطوات:', style: TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _stepCtrls.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextFormField(
                    controller: _stepCtrls[i],
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: 'الخطوة ${i + 1}',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: i > 0 ? IconButton(onPressed: () => setState(() => _stepCtrls.removeAt(i)), icon: const Icon(Icons.remove_circle_outline, color: Colors.red)) : null,
                    ),
                  ),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _stepCtrls.add(TextEditingController())),
              icon: const Icon(Icons.add, color: primaryColor),
              label: const Text('إضافة خطوة', style: TextStyle(color: primaryColor)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _loading || _nameCtrl.text.isEmpty ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('حفظ القالب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final steps = _stepCtrls.asMap().entries
          .where((e) => e.value.text.isNotEmpty)
          .map((e) => {'step_number': e.key + 1, 'title': e.value.text})
          .toList();

      await ref.read(_procSvcProvider).createTemplate(
        {'clinic_id': widget.clinicId, 'name': _nameCtrl.text, 'total_sessions': steps.length},
        steps,
      );
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _StartPatientProcedureSheet extends ConsumerStatefulWidget {
  final String clinicId;
  final VoidCallback onSaved;
  const _StartPatientProcedureSheet({required this.clinicId, required this.onSaved});

  @override
  ConsumerState<_StartPatientProcedureSheet> createState() => _StartPatientProcedureSheetState();
}

class _StartPatientProcedureSheetState extends ConsumerState<_StartPatientProcedureSheet> {
  String? _selectedPatientId;
  String? _selectedTemplateId;
  bool _loading = false;
  static const primaryColor = Color(0xFF006D63);

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(patientsProvider);
    final templatesAsync = ref.watch(_templatesProvider(widget.clinicId));

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        height: 380,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('بدء إجراء لمريض', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            // Dropdown 1: Patients
            patientsAsync.when(
              data: (patients) {
                return DropdownButtonFormField<String>(
                  value: _selectedPatientId,
                  isExpanded: true,
                  hint: const Text('اختر المريض', textAlign: TextAlign.right),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[50],
                    prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                  items: patients.map((p) => DropdownMenuItem(
                    value: p.id,
                    child: Text(p.fullName, textAlign: TextAlign.right),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedPatientId = val),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => const Text('خطأ في تحميل المرضى'),
            ),
            const SizedBox(height: 16),

            // Dropdown 2: Templates
            templatesAsync.when(
              data: (templates) {
                return DropdownButtonFormField<String>(
                  value: _selectedTemplateId,
                  isExpanded: true,
                  hint: const Text('اختر قالب الإجراء', textAlign: TextAlign.right),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[50],
                    prefixIcon: const Icon(Icons.schema_outlined, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                  items: templates.map((t) => DropdownMenuItem(
                    value: t.id,
                    child: Text(t.name, textAlign: TextAlign.right),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedTemplateId = val),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => const Text('خطأ في تحميل قوالب الإجراءات'),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading || _selectedPatientId == null || _selectedTemplateId == null
                    ? null
                    : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00302D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('بدء الإجراء الطبي الآن', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedPatientId == null || _selectedTemplateId == null) return;
    setState(() => _loading = true);
    try {
      final templates = ref.read(_templatesProvider(widget.clinicId)).valueOrNull ?? [];
      final template = templates.firstWhere((t) => t.id == _selectedTemplateId);
      
      final patients = ref.read(patientsProvider).valueOrNull ?? [];
      final patient = patients.firstWhere((p) => p.id == _selectedPatientId);

      // Create procedure data
      final procedureData = {
        'clinic_id': widget.clinicId,
        'patient_id': _selectedPatientId,
        'template_id': _selectedTemplateId,
        'title': template.name,
        'status': 'in_progress',
        'estimated_sessions': template.totalSessions,
      };

      // Map template steps to patient procedure steps
      final steps = template.steps.map((s) => {
        'clinic_id': widget.clinicId,
        'step_number': s.stepNumber,
        'title': s.title,
        'description': s.description,
        'estimated_duration_minutes': s.estimatedDurationMinutes,
        'status': 'pending',
      }).toList();

      await ref.read(_procSvcProvider).startProcedure(procedureData, steps);

      // Log security audit log!
      final authState = ref.read(authProvider);
      final staffName = authState is AuthAuthenticated ? authState.profile?.fullName ?? '' : '';
      final staffId = authState is AuthAuthenticated ? authState.profile?.id ?? '' : '';
      
      await ref.read(auditServiceProvider).logEvent(
        clinicId: widget.clinicId,
        userId: staffId,
        action: 'start_procedure',
        tableName: 'patient_procedures',
        description: 'قام الطبيب/الموظف $staffName ببدء إجراء طبي "${template.name}" للمريض ${patient.fullName}',
        newValues: procedureData,
      );

      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
