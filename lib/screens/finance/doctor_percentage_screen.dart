import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/treasury_service.dart';
import '../../services/insurance_service.dart';
import '../../providers/staff_provider.dart';

final _treasurySvcProvider = Provider((ref) => TreasuryService());
final _insuranceSvcProvider = Provider((ref) => InsuranceService());

final _doctorRevenueProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, clinicId) {
  return ref.read(_treasurySvcProvider).getDoctorRevenue(clinicId);
});

final _doctorPercentagesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, clinicId) {
  return ref.read(_insuranceSvcProvider).getAllDoctorPercentages(clinicId);
});

class DoctorPercentageScreen extends ConsumerStatefulWidget {
  const DoctorPercentageScreen({super.key});

  @override
  ConsumerState<DoctorPercentageScreen> createState() => _DoctorPercentageScreenState();
}

class _DoctorPercentageScreenState extends ConsumerState<DoctorPercentageScreen> {
  static const primaryColor = Color(0xFF006D63);

  String get _clinicId {
    final auth = ref.read(authProvider);
    return auth is AuthAuthenticated ? (auth.profile?.clinicId ?? '') : '';
  }

  @override
  Widget build(BuildContext context) {
    final revenueAsync = ref.watch(_doctorRevenueProvider(_clinicId));
    final percentagesAsync = ref.watch(_doctorPercentagesProvider(_clinicId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('نسب الأطباء', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Revenue Pie Chart
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('توزيع الإيرادات بين الأطباء', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 20),
                  revenueAsync.when(
                    data: (doctors) {
                      if (doctors.isEmpty) return const Center(child: Text('لا توجد بيانات', style: TextStyle(color: Colors.grey)));
                      final totalRevenue = doctors.fold(0.0, (s, d) => s + (d['revenue'] as double));
                      final colors = [primaryColor, Colors.blue, Colors.orange, Colors.purple, Colors.teal, Colors.red];
                      return Column(
                        children: [
                          SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                sections: doctors.asMap().entries.map((e) {
                                  final pct = totalRevenue > 0 ? (e.value['revenue'] as double) / totalRevenue * 100 : 0;
                                  return PieChartSectionData(
                                    value: (e.value['revenue'] as double),
                                    title: '${pct.toStringAsFixed(0)}%',
                                    color: colors[e.key % colors.length],
                                    radius: 80,
                                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  );
                                }).toList(),
                                centerSpaceRadius: 40,
                                sectionsSpace: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...doctors.asMap().entries.map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[e.key % colors.length], shape: BoxShape.circle)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(e.value['name'], style: const TextStyle(fontWeight: FontWeight.w500))),
                                Text('${(e.value['revenue'] as double).toStringAsFixed(0)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                                const SizedBox(width: 8),
                                Text('(${e.value['visits']} زيارة)', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          )).toList(),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('خطأ: $e'),
                  ),
                ],
              ),
            ).animate().fade().scale(begin: const Offset(0.95, 0.95)),

            const SizedBox(height: 20),

            // Doctor Percentages Settings
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('إعدادات النسب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton.icon(
                  onPressed: () => _showSetPercentageSheet(context),
                  icon: const Icon(Icons.edit, size: 16, color: primaryColor),
                  label: const Text('تعديل', style: TextStyle(color: primaryColor)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            percentagesAsync.when(
              data: (percentages) {
                if (percentages.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: const Center(child: Text('لم يتم تحديد نسب بعد', style: TextStyle(color: Colors.grey))),
                  );
                }
                return Column(
                  children: percentages.map((p) => _DoctorPercentageTile(data: p)).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('خطأ: $e'),
            ),

            const SizedBox(height: 20),

            // Doctor Net Earnings
            revenueAsync.when(
              data: (doctors) {
                final percentages = percentagesAsync.valueOrNull ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('صافي أرباح الأطباء', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    ...doctors.map((d) {
                      final pctData = percentages.where((p) => p['doctor_id'] == d['id']).firstOrNull;
                      final pct = (pctData?['percentage'] as num?)?.toDouble() ?? 50;
                      final revenue = d['revenue'] as double;
                      final netEarning = revenue * pct / 100;
                      return _EarningCard(
                        name: d['name'] as String,
                        revenue: revenue,
                        percentage: pct,
                        netEarning: netEarning,
                        visits: d['visits'] as int,
                      ).animate().fade().slideX();
                    }),
                  ],
                );
              },
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetPercentageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SetPercentageSheet(
        clinicId: _clinicId,
        onSaved: () {
          ref.invalidate(_doctorPercentagesProvider(_clinicId));
          ref.invalidate(_doctorRevenueProvider(_clinicId));
        },
      ),
    );
  }
}

class _DoctorPercentageTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DoctorPercentageTile({required this.data});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF006D63);
    final name = data['profiles']?['full_name'] ?? 'الطبيب';
    final pct = (data['percentage'] as num).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Text('$pct%', style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('نسبة من ${data['calculation_base'] == 'revenue' ? 'الإيراد' : 'الربح'}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningCard extends StatelessWidget {
  final String name;
  final double revenue;
  final double percentage;
  final double netEarning;
  final int visits;
  const _EarningCard({required this.name, required this.revenue, required this.percentage, required this.netEarning, required this.visits});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF006D63);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor.withValues(alpha: 0.05), Colors.white],
          begin: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${netEarning.toStringAsFixed(0)} ج.م', style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 20)),
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('إيراد: ${revenue.toStringAsFixed(0)} ج.م × $percentage%',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text('$visits زيارة', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation(primaryColor),
            minHeight: 4,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

class _SetPercentageSheet extends ConsumerStatefulWidget {
  final String clinicId;
  final VoidCallback onSaved;
  const _SetPercentageSheet({required this.clinicId, required this.onSaved});

  @override
  ConsumerState<_SetPercentageSheet> createState() => _SetPercentageSheetState();
}

class _SetPercentageSheetState extends ConsumerState<_SetPercentageSheet> {
  final _pctCtrl = TextEditingController(text: '50');
  String? _selectedDoctorId;
  String _base = 'revenue';
  bool _loading = false;
  static const primaryColor = Color(0xFF006D63);

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffMembersProvider);
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
            const Text('تحديد نسبة الطبيب', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            staffAsync.when(
              data: (staff) => DropdownButtonFormField<String>(
                value: _selectedDoctorId,
                hint: const Text('اختر الطبيب'),
                decoration: InputDecoration(labelText: 'الطبيب', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: staff.map((s) =>
                    DropdownMenuItem(value: s.id, child: Text(s.fullName))).toList(),
                onChanged: (v) => setState(() => _selectedDoctorId = v),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('خطأ'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pctCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              decoration: InputDecoration(labelText: 'النسبة %', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _base,
              decoration: InputDecoration(labelText: 'أساس الحساب', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: const [
                DropdownMenuItem(value: 'revenue', child: Text('من الإيراد الكلي')),
                DropdownMenuItem(value: 'profit', child: Text('من الربح الصافي')),
              ],
              onChanged: (v) => setState(() => _base = v!),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading || _selectedDoctorId == null ? null : _save,
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
    final pct = double.tryParse(_pctCtrl.text);
    if (pct == null || _selectedDoctorId == null) return;
    setState(() => _loading = true);
    try {
      await ref.read(_insuranceSvcProvider).setDoctorPercentage(widget.clinicId, _selectedDoctorId!, pct, _base);
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
