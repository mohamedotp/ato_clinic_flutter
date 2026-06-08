import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/workspace_note.dart';
import '../../../models/clinic_material.dart';
import '../../../providers/materials_provider.dart';
import '../../../providers/auth_provider.dart';
import 'base_node_wrapper.dart';

class MaterialUsageNodeWidget extends ConsumerStatefulWidget {
  final WorkspaceNote note;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(String title) onTitleChange;
  final Function(String colorHex) onColorChange;
  final Function(double x, double y) onPositionUpdate;
  final Function(String id, Offset localPosition)? onConnectStart;
  final VoidCallback? onToggleLock;
  final VoidCallback? onClearConnections;

  const MaterialUsageNodeWidget({
    super.key,
    required this.note,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
    required this.onTitleChange,
    required this.onColorChange,
    required this.onPositionUpdate,
    this.onConnectStart,
    this.onToggleLock,
    this.onClearConnections,
  });

  @override
  ConsumerState<MaterialUsageNodeWidget> createState() => _MaterialUsageNodeState();
}

class _MaterialUsageNodeState extends ConsumerState<MaterialUsageNodeWidget> {
  static const _primary = Color(0xFF7B3FBE);

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final clinicId = widget.note.clinicId;
    final matState = ref.watch(materialsProvider(clinicId));
    final usageState = ref.watch(patientUsageProvider(widget.note.patientId));

    return BaseNodeWrapper(
      note: widget.note,
      isSelected: widget.isSelected,
      onTap: widget.onTap,
      onDelete: widget.onDelete,
      onTitleChange: widget.onTitleChange,
      onColorChange: widget.onColorChange,
      onPositionUpdate: widget.onPositionUpdate,
      onConnectStart: widget.onConnectStart,
      onToggleLock: widget.onToggleLock,
      onClearConnections: widget.onClearConnections,
      icon: Icons.medical_services_rounded,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add usage button
            if (!widget.note.isLocked)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary.withValues(alpha: 0.1),
                    foregroundColor: _primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('صرف خامة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: () => _showAddUsageSheet(
                    context,
                    clinicId,
                    matState.materials,
                    matState.isLoading,
                    authState,
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // Usage list
            Expanded(
              child: usageState.isLoading
                  ? const Center(child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ))
                  : usageState.usages.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 32, color: Colors.grey.shade300),
                                const SizedBox(height: 6),
                                Text('لا يوجد صرف مسجل',
                                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            children: usageState.usages.take(8).map((u) => _UsageRow(
                              usage: u,
                              onDelete: widget.note.isLocked ? null : () async {
                                await ref.read(patientUsageProvider(widget.note.patientId).notifier)
                                    .deleteUsage(u.id);
                                ref.read(materialsProvider(clinicId).notifier).refresh();
                              },
                            )).toList(),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddUsageSheet(
    BuildContext context,
    String clinicId,
    List<ClinicMaterial> materials,
    bool isLoading,
    dynamic authState,
  ) async {
    ClinicMaterial? selectedMat;
    final qtyCtrl = TextEditingController(text: '1');
    final notesCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('صرف خامة على المريض',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 16),

                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (materials.isEmpty) ...[
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: Colors.purple.shade200),
                        const SizedBox(height: 12),
                        const Text(
                          'لا توجد خامات مسجلة',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'لم يتم تسجيل أي خامات في هذه العيادة بعد. يرجى إضافة بعض الخامات من شاشة إدارة الخامات أولاً لتتمكن من صرفها هنا.',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  DropdownButtonFormField<ClinicMaterial>(
                    value: selectedMat,
                    onChanged: (v) => setSheet(() => selectedMat = v),
                    decoration: InputDecoration(
                      labelText: 'اختر الخامة',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: materials.map((m) => DropdownMenuItem(
                      value: m,
                      child: Row(
                        children: [
                          Expanded(child: Text(m.name, style: const TextStyle(fontSize: 14))),
                          Text('${m.stockQuantity} ${m.unit}',
                            style: TextStyle(
                              color: m.isLowStock ? Colors.orange : Colors.grey,
                              fontSize: 11,
                            )),
                        ],
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'الكمية',
                      suffixText: selectedMat?.unit ?? '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: notesCtrl,
                    decoration: InputDecoration(
                      labelText: 'ملاحظات (اختياري)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        if (selectedMat == null) return;
                        final qty = double.tryParse(qtyCtrl.text) ?? 1;
                        if (qty <= 0) return;
                        if (qty > selectedMat!.stockQuantity) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('المتاح فقط ${selectedMat!.stockQuantity} ${selectedMat!.unit}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        Navigator.pop(sheetCtx);
                        try {
                          final userId = authState is AuthAuthenticated ? authState.profile?.id : null;
                          await ref.read(patientUsageProvider(widget.note.patientId).notifier).addUsage({
                            'clinic_id': clinicId,
                            'patient_id': widget.note.patientId,
                            'material_id': selectedMat!.id,
                            'quantity_used': qty,
                            'notes': notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                            'used_by': userId,
                            'used_at': DateTime.now().toIso8601String(),
                          });
                          ref.read(materialsProvider(clinicId).notifier).refresh();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ تم صرف $qty ${selectedMat!.unit} من ${selectedMat!.name}'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      child: const Text('تأكيد الصرف',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Usage Row ────────────────────────────────────────────────────────────────
class _UsageRow extends StatelessWidget {
  final MaterialUsage usage;
  final VoidCallback? onDelete;
  const _UsageRow({required this.usage, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF7B3FBE).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF7B3FBE).withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(Icons.fiber_manual_record, size: 8, color: Colors.purple.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${usage.materialName ?? 'خامة'} — ${usage.quantityUsed % 1 == 0 ? usage.quantityUsed.toInt() : usage.quantityUsed} ${usage.materialUnit ?? ''}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
                if (usage.notes?.isNotEmpty == true)
                  Text(usage.notes!, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                Text(
                  '${usage.usedAt.day}/${usage.usedAt.month}/${usage.usedAt.year} ${usage.usedAt.hour}:${usage.usedAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                ),
              ],
            ),
          ),
          if (onDelete != null)
            GestureDetector(
              onTap: onDelete,
              child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
            ),
        ],
      ),
    );
  }
}
