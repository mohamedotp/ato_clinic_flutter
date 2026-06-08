import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patients_provider.dart';
import '../../services/lab_service.dart';
import '../../models/lab_order.dart';

final _labSvcProvider = Provider((ref) => LabService());

final _labOrdersProvider = FutureProvider.family<List<LabOrder>, String>((ref, clinicId) {
  return ref.read(_labSvcProvider).getOrders(clinicId);
});

final _labTestsProvider = FutureProvider.family<List<LabTest>, String>((ref, clinicId) {
  return ref.read(_labSvcProvider).getTests(clinicId);
});

class LabOrdersScreen extends ConsumerWidget {
  const LabOrdersScreen({super.key});

  static const primaryColor = Color(0xFF006D63);

  String _clinicId(WidgetRef ref) {
    final auth = ref.read(authProvider);
    return auth is AuthAuthenticated ? (auth.profile?.clinicId ?? '') : '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clinicId = _clinicId(ref);
    final ordersAsync = ref.watch(_labOrdersProvider(clinicId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('طلبات التحاليل', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: primaryColor),
            onPressed: () => _showCreateOrderSheet(context, ref, clinicId),
          ),
        ],
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.science_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('لا توجد طلبات تحاليل', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateOrderSheet(context, ref, clinicId),
                    icon: const Icon(Icons.add),
                    label: const Text('إنشاء طلب'),
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_labOrdersProvider(clinicId)),
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: orders.length,
              itemBuilder: (context, i) => _LabOrderCard(
                order: orders[i],
                onTap: () => _showOrderDetails(context, ref, orders[i], clinicId),
              ).animate().fade(delay: Duration(milliseconds: i * 50)).slideY(begin: 0.1),
            ),
          );
        },
      ),
    );
  }

  void _showCreateOrderSheet(BuildContext context, WidgetRef ref, String clinicId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateOrderSheet(
        clinicId: clinicId,
        onSaved: () => ref.invalidate(_labOrdersProvider(clinicId)),
      ),
    );
  }

  void _showOrderDetails(BuildContext context, WidgetRef ref, LabOrder order, String clinicId) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _LabOrderDetailScreen(order: order, clinicId: clinicId,
        onUpdate: () => ref.invalidate(_labOrdersProvider(clinicId))),
    ));
  }
}

class _LabOrderCard extends StatelessWidget {
  final LabOrder order;
  final VoidCallback onTap;
  const _LabOrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF006D63);
    final statusColors = {
      'pending': Colors.orange, 'in_progress': Colors.blue,
      'completed': Colors.green, 'cancelled': Colors.red,
    };
    final color = statusColors[order.status] ?? Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.science_outlined, color: primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(order.patientName ?? 'مريض', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('${order.items.length} تحليل • ${order.completedCount} مكتمل',
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(DateFormat('dd/MM/yyyy').format(order.orderDate), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(order.statusLabel, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Text('${order.totalCost.toStringAsFixed(0)} ج.م',
                    style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LabOrderDetailScreen extends ConsumerStatefulWidget {
  final LabOrder order;
  final String clinicId;
  final VoidCallback onUpdate;
  const _LabOrderDetailScreen({required this.order, required this.clinicId, required this.onUpdate});

  @override
  ConsumerState<_LabOrderDetailScreen> createState() => _LabOrderDetailScreenState();
}

class _LabOrderDetailScreenState extends ConsumerState<_LabOrderDetailScreen> {
  late LabOrder _order;
  static const primaryColor = Color(0xFF006D63);

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: Text(_order.patientName ?? 'طلب تحليل', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          if (_order.status != 'completed')
            TextButton(
              onPressed: _markCompleted,
              child: const Text('اكتمل', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Order info card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _InfoRow(label: 'المريض', value: _order.patientName ?? '-'),
                _InfoRow(label: 'الطبيب', value: _order.doctorName ?? '-'),
                _InfoRow(label: 'التاريخ', value: DateFormat('dd/MM/yyyy').format(_order.orderDate)),
                _InfoRow(label: 'الحالة', value: _order.statusLabel),
                _InfoRow(label: 'التكلفة', value: '${_order.totalCost.toStringAsFixed(0)} ج.م'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('التحاليل المطلوبة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ..._order.items.map((item) => _LabItemCard(
            item: item,
            onEnterResult: () => _showResultSheet(item),
          ).animate().fade()),
        ],
      ),
    );
  }

  void _showResultSheet(LabOrderItem item) {
    final ctrl = TextEditingController(text: item.resultValue);
    final notesCtrl = TextEditingController(text: item.notes);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('نتيجة: ${item.testName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(controller: ctrl, textAlign: TextAlign.right,
                  decoration: InputDecoration(labelText: 'القيمة', hintText: item.normalRange ?? '', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextFormField(controller: notesCtrl, textAlign: TextAlign.right,
                  decoration: InputDecoration(labelText: 'ملاحظات', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref.read(_labSvcProvider).updateItemResult(item.id, ctrl.text, notesCtrl.text.isEmpty ? null : notesCtrl.text);
                    widget.onUpdate();
                    final updated = await ref.read(_labSvcProvider).getOrderById(_order.id);
                    setState(() => _order = updated);
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                  child: const Text('حفظ النتيجة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markCompleted() async {
    await ref.read(_labSvcProvider).updateOrderStatus(_order.id, 'completed');
    widget.onUpdate();
    if (mounted) Navigator.pop(context);
  }
}

class _LabItemCard extends StatelessWidget {
  final LabOrderItem item;
  final VoidCallback onEnterResult;
  const _LabItemCard({required this.item, required this.onEnterResult});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF006D63);
    final isCompleted = item.status == 'completed';
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
              onTap: onEnterResult,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(8)),
                child: const Text('إدخال', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            )
          else
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(item.testName, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (item.resultValue != null) ...[
                Text('النتيجة: ${item.resultValue}${item.unit != null ? ' ${item.unit}' : ''}',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                if (item.normalRange != null)
                  Text('المعدل الطبيعي: ${item.normalRange}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
              Text('${item.testPrice.toStringAsFixed(0)} ج.م', style: const TextStyle(color: primaryColor, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _CreateOrderSheet extends ConsumerStatefulWidget {
  final String clinicId;
  final VoidCallback onSaved;
  const _CreateOrderSheet({required this.clinicId, required this.onSaved});

  @override
  ConsumerState<_CreateOrderSheet> createState() => _CreateOrderSheetState();
}

class _CreateOrderSheetState extends ConsumerState<_CreateOrderSheet> {
  String? _patientId;
  final List<LabTest> _selectedTests = [];
  bool _loading = false;
  static const primaryColor = Color(0xFF006D63);

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(patientsProvider);
    final testsAsync = ref.watch(_labTestsProvider(widget.clinicId));

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('طلب تحاليل جديد', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            const Text('اختر التحاليل:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: testsAsync.when(
                data: (tests) => ListView(
                  children: tests.map((t) {
                    final isSelected = _selectedTests.any((s) => s.id == t.id);
                    return CheckboxListTile(
                      value: isSelected,
                      title: Text(t.name),
                      subtitle: Text('${t.price.toStringAsFixed(0)} ج.م'),
                      activeColor: primaryColor,
                      onChanged: (v) => setState(() {
                        if (v == true) _selectedTests.add(t);
                        else _selectedTests.removeWhere((s) => s.id == t.id);
                      }),
                    );
                  }).toList(),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('خطأ: $e'),
              ),
            ),
            if (_selectedTests.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('الإجمالي: ${_selectedTests.fold(0.0, (s, t) => s + t.price).toStringAsFixed(0)} ج.م',
                        style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${_selectedTests.length} تحليل', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading || _patientId == null || _selectedTests.isEmpty ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('إرسال الطلب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
      final total = _selectedTests.fold(0.0, (s, t) => s + t.price);
      final authState = ref.read(authProvider);
      final doctorId = authState is AuthAuthenticated ? authState.profile?.id : null;

      await ref.read(_labSvcProvider).createOrder(
        {
          'clinic_id': widget.clinicId,
          'patient_id': _patientId,
          'doctor_id': doctorId,
          'order_date': DateTime.now().toIso8601String(),
          'status': 'pending',
          'total_cost': total,
        },
        _selectedTests.map((t) => {
          'test_id': t.id,
          'test_name': t.name,
          'test_price': t.price,
          'normal_range': t.normalRange,
          'unit': t.unit,
        }).toList(),
      );
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
