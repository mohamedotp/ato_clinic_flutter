import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patients_provider.dart';
import '../../providers/staff_provider.dart';
import '../../services/treatment_plan_service.dart';
import '../../models/treatment_plan.dart';

final _planSvcProvider = Provider((ref) => TreatmentPlanService());

final _treatmentPlansProvider = FutureProvider.family<List<TreatmentPlan>, String>((ref, clinicId) {
  return ref.read(_planSvcProvider).getPlans(clinicId);
});

class TreatmentPlansScreen extends ConsumerWidget {
  const TreatmentPlansScreen({super.key});

  static const primaryColor = Color(0xFF006D63);

  String _clinicId(WidgetRef ref) {
    final auth = ref.read(authProvider);
    return auth is AuthAuthenticated ? (auth.profile?.clinicId ?? '') : '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clinicId = _clinicId(ref);
    final plansAsync = ref.watch(_treatmentPlansProvider(clinicId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('خطط العلاج', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: primaryColor),
            onPressed: () => _showCreateSheet(context, ref, clinicId),
          ),
        ],
      ),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (plans) {
          if (plans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('لا توجد خطط علاج', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateSheet(context, ref, clinicId),
                    icon: const Icon(Icons.add),
                    label: const Text('إنشاء خطة'),
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_treatmentPlansProvider(clinicId)),
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: plans.length,
              itemBuilder: (context, i) => _PlanCard(
                plan: plans[i],
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => _PlanDetailScreen(plan: plans[i], clinicId: clinicId,
                    onUpdate: () => ref.invalidate(_treatmentPlansProvider(clinicId))),
                )),
              ).animate().fade(delay: Duration(milliseconds: i * 50)).slideY(begin: 0.1),
            ),
          );
        },
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref, String clinicId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreatePlanSheet(
        clinicId: clinicId,
        onSaved: () => ref.invalidate(_treatmentPlansProvider(clinicId)),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final TreatmentPlan plan;
  final VoidCallback onTap;
  const _PlanCard({required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF006D63);
    final statusColors = {
      'active': Colors.blue, 'completed': Colors.green,
      'cancelled': Colors.red, 'on_hold': Colors.orange,
    };
    final color = statusColors[plan.status] ?? Colors.blue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(plan.statusLabel, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                Text(plan.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${plan.totalCost.toStringAsFixed(0)} ج.م', style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                Text(plan.patientName ?? 'مريض', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 10),
            // Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${plan.completedSessions}/${plan.sessions.length} جلسة', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text('${(plan.progressPercentage * 100).toStringAsFixed(0)}%', style: const TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: plan.progressPercentage,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanDetailScreen extends ConsumerStatefulWidget {
  final TreatmentPlan plan;
  final String clinicId;
  final VoidCallback onUpdate;
  const _PlanDetailScreen({required this.plan, required this.clinicId, required this.onUpdate});

  @override
  ConsumerState<_PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends ConsumerState<_PlanDetailScreen> {
  late TreatmentPlan _plan;
  static const primaryColor = Color(0xFF006D63);

  @override
  void initState() {
    super.initState();
    _plan = widget.plan;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: Text(_plan.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF006D63), Color(0xFF004D40)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_plan.patientName ?? 'مريض', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _PlanStat(label: 'المتبقي', value: '${_plan.remainingAmount.toStringAsFixed(0)} ج.م', color: Colors.redAccent),
                    _PlanStat(label: 'المدفوع', value: '${_plan.paidAmount.toStringAsFixed(0)} ج.م', color: Colors.greenAccent),
                    _PlanStat(label: 'الإجمالي', value: '${_plan.totalCost.toStringAsFixed(0)} ج.م', color: Colors.white),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _plan.progressPercentage,
                    backgroundColor: Colors.white30,
                    valueColor: const AlwaysStoppedAnimation(Colors.greenAccent),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${_plan.completedSessions}/${_plan.sessions.length} جلسة مكتملة',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ).animate().fade().scale(begin: const Offset(0.95, 0.95)),

          const SizedBox(height: 20),
          const Text('جلسات الخطة العلاجية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ..._plan.sessions.map((session) => _SessionTile(
            session: session,
            onComplete: () => _completeSession(session.id),
          ).animate().fade()),
        ],
      ),
    );
  }

  Future<void> _completeSession(String sessionId) async {
    await ref.read(_planSvcProvider).completeSession(sessionId);
    widget.onUpdate();
    final updated = await ref.read(_planSvcProvider).getPlanById(_plan.id);
    setState(() => _plan = updated);
  }
}

class _PlanStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _PlanStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  final TreatmentPlanSession session;
  final VoidCallback onComplete;
  const _SessionTile({required this.session, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF006D63);
    final isCompleted = session.status == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isCompleted ? Colors.green.shade200 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          if (!isCompleted)
            GestureDetector(
              onTap: onComplete,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.check, color: primaryColor, size: 16),
              ),
            )
          else
            const Icon(Icons.check_circle, color: Colors.green),
          const Spacer(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${session.sessionNumber}. ${session.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (session.description != null)
                  Text(session.description!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                if (session.scheduledAt != null)
                  Text(DateFormat('dd/MM/yyyy').format(session.scheduledAt!), style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatePlanSheet extends ConsumerStatefulWidget {
  final String clinicId;
  final VoidCallback onSaved;
  const _CreatePlanSheet({required this.clinicId, required this.onSaved});

  @override
  ConsumerState<_CreatePlanSheet> createState() => _CreatePlanSheetState();
}

class _CreatePlanSheetState extends ConsumerState<_CreatePlanSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _totalCostCtrl = TextEditingController(text: '0');
  String? _patientId;
  int _sessionCount = 3;
  bool _loading = false;
  static const primaryColor = Color(0xFF006D63);

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(patientsProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.80,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('إنشاء خطة علاجية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              patientsAsync.when(
                data: (patients) => DropdownButtonFormField<String>(
                  value: _patientId,
                  hint: const Text('اختر المريض'),
                  decoration: InputDecoration(labelText: 'المريض', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  items: patients.map((p) => DropdownMenuItem(value: p.id, child: Text(p.fullName))).toList(),
                  onChanged: (v) => setState(() => _patientId = v),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _titleCtrl, textAlign: TextAlign.right,
                  decoration: InputDecoration(labelText: 'عنوان الخطة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextFormField(controller: _descCtrl, textAlign: TextAlign.right, maxLines: 2,
                  decoration: InputDecoration(labelText: 'الوصف (اختياري)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextFormField(controller: _totalCostCtrl, textAlign: TextAlign.right, keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'التكلفة الإجمالية (ج.م)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(onPressed: () => setState(() => _sessionCount = (_sessionCount + 1).clamp(1, 50)),
                          icon: const Icon(Icons.add_circle_outline, color: primaryColor)),
                      Text('$_sessionCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(onPressed: () => setState(() => _sessionCount = (_sessionCount - 1).clamp(1, 50)),
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red)),
                    ],
                  ),
                  const Text('عدد الجلسات', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading || _patientId == null || _titleCtrl.text.isEmpty ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                  child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('إنشاء الخطة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final totalCost = double.tryParse(_totalCostCtrl.text) ?? 0;
      final authState = ref.read(authProvider);
      final doctorId = authState is AuthAuthenticated ? authState.profile?.id : null;

      final sessions = List.generate(_sessionCount, (i) => {
        'session_number': i + 1,
        'title': 'الجلسة ${i + 1}',
        'status': 'pending',
        'cost': _sessionCount > 0 ? (totalCost / _sessionCount) : 0,
      });

      await ref.read(_planSvcProvider).createPlan(
        {
          'clinic_id': widget.clinicId,
          'patient_id': _patientId,
          'doctor_id': doctorId,
          'title': _titleCtrl.text,
          'description': _descCtrl.text.isEmpty ? null : _descCtrl.text,
          'status': 'active',
          'total_cost': totalCost,
          'paid_amount': 0,
        },
        sessions,
      );
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
