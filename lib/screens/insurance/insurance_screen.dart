import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../services/insurance_service.dart';
import '../../models/insurance_company.dart';

final _insuranceSvcProvider2 = Provider((ref) => InsuranceService());

final _insuranceCompaniesProvider = FutureProvider.family<List<InsuranceCompany>, String>((ref, clinicId) {
  return ref.read(_insuranceSvcProvider2).getCompanies(clinicId);
});

class InsuranceScreen extends ConsumerWidget {
  const InsuranceScreen({super.key});

  static const primaryColor = Color(0xFF006D63);

  String _clinicId(WidgetRef ref) {
    final auth = ref.read(authProvider);
    return auth is AuthAuthenticated ? (auth.profile?.clinicId ?? '') : '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clinicId = _clinicId(ref);
    final companiesAsync = ref.watch(_insuranceCompaniesProvider(clinicId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('التأمين الطبي', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: primaryColor),
            onPressed: () => _showAddSheet(context, ref, clinicId),
          ),
        ],
      ),
      body: companiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (companies) {
          if (companies.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.health_and_safety_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('لا توجد شركات تأمين مضافة', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddSheet(context, ref, clinicId),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة شركة'),
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: companies.length,
            itemBuilder: (context, i) => _InsuranceCard(
              company: companies[i],
              onEdit: () => _showAddSheet(context, ref, clinicId, company: companies[i]),
              onDelete: () async {
                await ref.read(_insuranceSvcProvider2).deleteCompany(companies[i].id);
                ref.invalidate(_insuranceCompaniesProvider(clinicId));
              },
            ).animate().fade(delay: Duration(milliseconds: i * 50)).slideX(),
          );
        },
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref, String clinicId, {InsuranceCompany? company}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddInsuranceSheet(
        clinicId: clinicId,
        company: company,
        onSaved: () => ref.invalidate(_insuranceCompaniesProvider(clinicId)),
      ),
    );
  }
}

class _InsuranceCard extends StatelessWidget {
  final InsuranceCompany company;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _InsuranceCard({required this.company, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF006D63);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Row(
            children: [
              IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, color: primaryColor, size: 20)),
              IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20)),
            ],
          ),
          const Spacer(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(company.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (company.contactPhone != null) ...[
                      Text(company.contactPhone!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 8),
                      const Icon(Icons.phone, size: 14, color: Colors.grey),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text('${company.coveragePercentage.toStringAsFixed(0)}%',
                    style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 20)),
                const Text('تغطية', style: TextStyle(color: primaryColor, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddInsuranceSheet extends ConsumerStatefulWidget {
  final String clinicId;
  final InsuranceCompany? company;
  final VoidCallback onSaved;
  const _AddInsuranceSheet({required this.clinicId, this.company, required this.onSaved});

  @override
  ConsumerState<_AddInsuranceSheet> createState() => _AddInsuranceSheetState();
}

class _AddInsuranceSheetState extends ConsumerState<_AddInsuranceSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _notesCtrl;
  double _coverage = 80;
  bool _loading = false;
  static const primaryColor = Color(0xFF006D63);

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.company?.name ?? '');
    _phoneCtrl = TextEditingController(text: widget.company?.contactPhone ?? '');
    _emailCtrl = TextEditingController(text: widget.company?.contactEmail ?? '');
    _notesCtrl = TextEditingController(text: widget.company?.notes ?? '');
    _coverage = widget.company?.coveragePercentage ?? 80;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(widget.company == null ? 'إضافة شركة تأمين' : 'تعديل بيانات التأمين',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextFormField(controller: _nameCtrl, textAlign: TextAlign.right,
                decoration: InputDecoration(labelText: 'اسم شركة التأمين *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 12),
            // Coverage slider
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('نسبة التغطية: ${_coverage.toStringAsFixed(0)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Slider(
                  value: _coverage,
                  min: 0, max: 100,
                  divisions: 20,
                  activeColor: primaryColor,
                  label: '${_coverage.toStringAsFixed(0)}%',
                  onChanged: (v) => setState(() => _coverage = v),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(controller: _phoneCtrl, textAlign: TextAlign.right, keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: 'رقم الهاتف (اختياري)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 12),
            TextFormField(controller: _emailCtrl, textAlign: TextAlign.right, keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: 'البريد الإلكتروني (اختياري)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 12),
            TextFormField(controller: _notesCtrl, textAlign: TextAlign.right, maxLines: 2,
                decoration: InputDecoration(labelText: 'ملاحظات', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _loading || _nameCtrl.text.isEmpty ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('حفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final data = {
        'clinic_id': widget.clinicId,
        'name': _nameCtrl.text,
        'coverage_percentage': _coverage,
        'contact_phone': _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text,
        'contact_email': _emailCtrl.text.isEmpty ? null : _emailCtrl.text,
        'notes': _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
        'is_active': true,
      };
      if (widget.company != null) {
        await ref.read(_insuranceSvcProvider2).updateCompany(widget.company!.id, data);
      } else {
        await ref.read(_insuranceSvcProvider2).createCompany(data);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
