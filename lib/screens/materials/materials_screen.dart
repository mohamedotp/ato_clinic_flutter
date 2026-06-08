import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/materials_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/clinic_material.dart';
import 'material_history_screen.dart';
import 'clinic_material_history_screen.dart';

class MaterialsScreen extends ConsumerStatefulWidget {
  const MaterialsScreen({super.key});

  @override
  ConsumerState<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends ConsumerState<MaterialsScreen> {
  String _search = '';
  String _filterCategory = 'الكل';
  static const _primary = Color(0xFF006D63);

  static const _categories = [
    'الكل', 'عام', 'تعقيم', 'حشوات', 'أدوات', 'خيوط', 'أدوية', 'أسنان', 'تجميل'
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final clinicId = authState is AuthAuthenticated
        ? authState.profile?.clinicId ?? ''
        : '';
    final userId = authState is AuthAuthenticated
        ? authState.user.id
        : '';
    final state = ref.watch(materialsProvider(clinicId));
    final notifier = ref.read(materialsProvider(clinicId).notifier);

    final filtered = state.materials.where((m) {
      final matchSearch = m.name.toLowerCase().contains(_search.toLowerCase()) ||
          (m.description ?? '').toLowerCase().contains(_search.toLowerCase());
      final matchCat = _filterCategory == 'الكل' || m.category == _filterCategory;
      return matchSearch && matchCat;
    }).toList();

    final lowStock = state.materials.where((m) => m.isLowStock).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('إدارة الخامات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'سجل الحركات العام',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ClinicMaterialHistoryScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => notifier.refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats bar
          if (lowStock > 0)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text('$lowStock خامة وصلت للحد الأدنى',
                    style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),

          // Search + Category filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: const InputDecoration(
                      hintText: 'ابحث عن خامة...',
                      prefixIcon: Icon(Icons.search, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final cat = _categories[i];
                      final selected = _filterCategory == cat;
                      return GestureDetector(
                        onTap: () => setState(() => _filterCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected ? _primary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: selected ? _primary : Colors.grey.shade300),
                          ),
                          child: Text(cat,
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            )),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // List
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(color: _primary))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('لا توجد خامات', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                            const SizedBox(height: 8),
                            Text('اضغط + لإضافة خامة جديدة', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) => _MaterialCard(
                          material: filtered[i],
                          onEdit: () => _showAddEditDialog(context, clinicId, notifier, material: filtered[i]),
                          onDelete: () => _confirmDelete(context, notifier, filtered[i]),
                          onRestock: () => _showRestockDialog(context, notifier, filtered[i], userId),
                          onIssue: () => _showIssueDialog(context, notifier, filtered[i], userId),
                          onHistory: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MaterialHistoryScreen(material: filtered[i]),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(context, clinicId, notifier),
        backgroundColor: _primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة خامة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, MaterialsNotifier notifier, ClinicMaterial m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الخامة'),
        content: Text('هل تريد حذف "${m.name}"؟ سيتم حذف سجل الصرف المرتبط به أيضاً.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await notifier.deleteMaterial(m.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف الخامة'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _showRestockDialog(BuildContext context, MaterialsNotifier notifier, ClinicMaterial m, String userId) async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('إضافة مخزون - ${m.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('المخزون الحالي: ${m.stockQuantity} ${m.unit}',
              style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'الكمية المضافة',
                suffixText: m.unit,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006D63)),
            onPressed: () async {
              final qty = double.tryParse(ctrl.text);
              if (qty != null && qty > 0) {
                Navigator.pop(context);
                await notifier.restockMaterial(m.id, qty, userId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم إضافة $qty ${m.unit} للمخزون')),
                  );
                }
              }
            },
            child: const Text('إضافة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showIssueDialog(BuildContext context, MaterialsNotifier notifier, ClinicMaterial m, String userId) async {
    final qtyCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('صرف أو تحويل - ${m.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('المخزون الحالي: ${m.stockQuantity} ${m.unit}',
              style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: qtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'الكمية المنصرفة',
                suffixText: m.unit,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'السبب / الملاحظات',
                hintText: 'مثال: تحويل إلى عيادة أخرى',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006D63)),
            onPressed: () async {
              final qty = double.tryParse(qtyCtrl.text);
              if (qty != null && qty > 0) {
                if (qty > m.stockQuantity) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('الكمية أكبر من المخزون المتاح!'), backgroundColor: Colors.red),
                  );
                  return;
                }
                Navigator.pop(context);
                await notifier.issueMaterial(m.id, qty, userId, notesCtrl.text);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم صرف $qty ${m.unit}')),
                  );
                }
              }
            },
            child: const Text('صرف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, String clinicId, MaterialsNotifier notifier, {ClinicMaterial? material}) {
    showDialog(
      context: context,
      builder: (_) => _AddEditMaterialDialog(
        clinicId: clinicId,
        material: material,
        onSave: (data) async {
          if (material != null) {
            await notifier.updateMaterial(material.id, data);
          } else {
            await notifier.addMaterial(data);
          }
        },
      ),
    );
  }
}

// ─── Material Card ────────────────────────────────────────────────────────────
class _MaterialCard extends StatelessWidget {
  final ClinicMaterial material;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRestock;
  final VoidCallback onIssue;
  final VoidCallback onHistory;

  const _MaterialCard({
    required this.material,
    required this.onEdit,
    required this.onDelete,
    required this.onRestock,
    required this.onIssue,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    final isLow = material.isLowStock;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLow ? Colors.orange.shade200 : Colors.grey.shade100,
          width: isLow ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF006D63).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF006D63), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(material.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      if (material.description?.isNotEmpty == true)
                        Text(material.description!,
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                    if (v == 'restock') onRestock();
                    if (v == 'issue') onIssue();
                    if (v == 'history') onHistory();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'history', child: Row(children: [Icon(Icons.history_rounded, size: 18), SizedBox(width: 8), Text('تتبع الخامة')])),
                    const PopupMenuItem(value: 'restock', child: Row(children: [Icon(Icons.add_circle_outline, size: 18), SizedBox(width: 8), Text('إضافة مخزون')])),
                    const PopupMenuItem(value: 'issue', child: Row(children: [Icon(Icons.outbox_rounded, size: 18), SizedBox(width: 8), Text('صرف / تحويل')])),
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('تعديل')])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('حذف', style: TextStyle(color: Colors.red))])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _StockBadge(quantity: material.stockQuantity, unit: material.unit, isLow: isLow),
                const SizedBox(width: 8),
                _InfoChip(label: material.category, icon: Icons.category_outlined),
                const Spacer(),
                if (material.costPerUnit > 0)
                  Text('${material.costPerUnit.toStringAsFixed(2)} ج.م / ${material.unit}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final double quantity;
  final String unit;
  final bool isLow;

  const _StockBadge({required this.quantity, required this.unit, required this.isLow});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isLow ? Colors.orange.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isLow ? Colors.orange.shade200 : Colors.green.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isLow ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            size: 13, color: isLow ? Colors.orange.shade700 : Colors.green.shade700),
          const SizedBox(width: 4),
          Text('${quantity % 1 == 0 ? quantity.toInt() : quantity} $unit',
            style: TextStyle(
              color: isLow ? Colors.orange.shade700 : Colors.green.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            )),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
        ],
      ),
    );
  }
}

// ─── Add/Edit Dialog ─────────────────────────────────────────────────────────
class _AddEditMaterialDialog extends StatefulWidget {
  final String clinicId;
  final ClinicMaterial? material;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _AddEditMaterialDialog({
    required this.clinicId,
    this.material,
    required this.onSave,
  });

  @override
  State<_AddEditMaterialDialog> createState() => _AddEditMaterialDialogState();
}

class _AddEditMaterialDialogState extends State<_AddEditMaterialDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _unit;
  late final TextEditingController _stock;
  late final TextEditingController _minAlert;
  late final TextEditingController _cost;
  String _category = 'عام';
  bool _isSaving = false;

  static const _units = ['قطعة', 'علبة', 'كرتون', 'مل', 'غم', 'لتر', 'أنبوبة', 'رول', 'قفاز'];
  static const _cats = ['عام', 'تعقيم', 'حشوات', 'أدوات', 'خيوط', 'أدوية', 'أسنان', 'تجميل'];

  @override
  void initState() {
    super.initState();
    final m = widget.material;
    _name = TextEditingController(text: m?.name ?? '');
    _desc = TextEditingController(text: m?.description ?? '');
    _unit = TextEditingController(text: m?.unit ?? 'قطعة');
    _stock = TextEditingController(text: m != null ? '${m.stockQuantity}' : '0');
    _minAlert = TextEditingController(text: m != null ? '${m.minStockAlert ?? 5}' : '5');
    _cost = TextEditingController(text: m != null ? '${m.costPerUnit}' : '0');
    _category = m?.category ?? 'عام';
  }

  @override
  void dispose() {
    _name.dispose(); _desc.dispose(); _unit.dispose();
    _stock.dispose(); _minAlert.dispose(); _cost.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.material != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006D63).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF006D63)),
                  ),
                  const SizedBox(width: 12),
                  Text(isEdit ? 'تعديل الخامة' : 'إضافة خامة جديدة',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 20),
              _field(_name, 'اسم الخامة *', validator: (v) => v!.isEmpty ? 'مطلوب' : null),
              const SizedBox(height: 12),
              _field(_desc, 'وصف اختياري'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _dropdownField('وحدة القياس', _units, _unit.text, (v) => setState(() => _unit.text = v!))),
                const SizedBox(width: 12),
                Expanded(child: _dropdownField('التصنيف', _cats, _category, (v) => setState(() => _category = v!))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _field(_stock, 'الكمية الحالية', keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _field(_minAlert, 'حد التنبيه الأدنى', keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 12),
              _field(_cost, 'التكلفة / الوحدة (ج.م)', keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006D63),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : Text(isEdit ? 'حفظ التعديلات' : 'إضافة الخامة',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _dropdownField(String label, List<String> items, String value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : items.first,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final data = {
        'clinic_id': widget.clinicId,
        'name': _name.text.trim(),
        'description': _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        'unit': _unit.text,
        'stock_quantity': double.tryParse(_stock.text) ?? 0,
        'min_stock_alert': double.tryParse(_minAlert.text) ?? 5,
        'cost_per_unit': double.tryParse(_cost.text) ?? 0,
        'category': _category,
        'is_active': true,
      };
      await widget.onSave(data);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
