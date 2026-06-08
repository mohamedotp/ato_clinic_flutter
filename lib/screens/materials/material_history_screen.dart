import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/clinic_material.dart';
import '../../providers/materials_provider.dart';

class MaterialHistoryScreen extends ConsumerWidget {
  final ClinicMaterial material;

  const MaterialHistoryScreen({super.key, required this.material});

  static const _primary = Color(0xFF006D63);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(materialHistoryProvider(material.id));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          children: [
            Text(material.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('سجل الحركات',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(materialHistoryProvider(material.id).notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Material Stats Header
          _MaterialStatsBar(material: material),

          // Timeline
          Expanded(
            child: historyState.isLoading
                ? const Center(child: CircularProgressIndicator(color: _primary))
                : historyState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                            const SizedBox(height: 12),
                            Text('خطأ في التحميل: ${historyState.error}',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.red.shade400)),
                            TextButton(
                              onPressed: () => ref.read(materialHistoryProvider(material.id).notifier).refresh(),
                              child: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      )
                    : historyState.usages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: _primary.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.history_rounded,
                                      size: 52, color: _primary),
                                ),
                                const SizedBox(height: 16),
                                const Text('لا توجد حركات مسجلة',
                                    style: TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text('لم يتم صرف أو إضافة هذه الخامة بعد',
                                    style: TextStyle(
                                        color: Colors.grey.shade500, fontSize: 13)),
                              ],
                            ),
                          )
                        : _HistoryTimeline(usages: historyState.usages),
          ),
        ],
      ),
    );
  }
}

// ─── Stats Bar ────────────────────────────────────────────────────────────────
class _MaterialStatsBar extends StatelessWidget {
  final ClinicMaterial material;
  const _MaterialStatsBar({required this.material});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          _StatBox(
            label: 'المخزون الحالي',
            value: '${material.stockQuantity % 1 == 0 ? material.stockQuantity.toInt() : material.stockQuantity}',
            unit: material.unit,
            icon: Icons.inventory_2_rounded,
            color: material.isLowStock ? Colors.orange : const Color(0xFF006D63),
          ),
          const SizedBox(width: 12),
          _StatBox(
            label: 'الوحدة',
            value: material.unit,
            unit: '',
            icon: Icons.straighten_rounded,
            color: Colors.blueGrey,
          ),
          const SizedBox(width: 12),
          _StatBox(
            label: 'التكلفة',
            value: material.costPerUnit.toStringAsFixed(1),
            unit: 'ج.م',
            icon: Icons.payments_outlined,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text('$value ${unit.isEmpty ? '' : unit}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color)),
            Text(label,
                style:
                    TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}

// ─── Timeline ─────────────────────────────────────────────────────────────────
class _HistoryTimeline extends StatelessWidget {
  final List<MaterialUsage> usages;
  const _HistoryTimeline({required this.usages});

  @override
  Widget build(BuildContext context) {
    // Group by date
    final Map<String, List<MaterialUsage>> grouped = {};
    for (final u in usages) {
      final dateKey = DateFormat('yyyy-MM-dd').format(u.usedAt.toLocal());
      grouped.putIfAbsent(dateKey, () => []).add(u);
    }

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: sortedDates.length,
      itemBuilder: (ctx, i) {
        final dateStr = sortedDates[i];
        final items = grouped[dateStr]!;
        final date = DateTime.parse(dateStr);

        String dateLabel;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));
        final d = DateTime(date.year, date.month, date.day);

        if (d == today) {
          dateLabel = 'اليوم';
        } else if (d == yesterday) {
          dateLabel = 'أمس';
        } else {
          dateLabel = DateFormat('d MMMM yyyy', 'ar').format(date);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006D63).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      dateLabel,
                      style: const TextStyle(
                          color: Color(0xFF006D63),
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Divider(color: Colors.grey.shade200)),
                ],
              ),
            ),
            ...items.map((u) => _HistoryEntry(usage: u)),
          ],
        );
      },
    );
  }
}

// ─── History Entry ────────────────────────────────────────────────────────────
class _HistoryEntry extends StatelessWidget {
  final MaterialUsage usage;
  const _HistoryEntry({required this.usage});

  @override
  Widget build(BuildContext context) {
    final config = _getTypeConfig(usage.usageType);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: config.color.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type icon circle
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: config.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(config.icon, color: config.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Type badge
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: config.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(config.label,
                            style: TextStyle(
                                color: config.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 11)),
                      ),
                      const Spacer(),
                      // Quantity
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: config.isPositive
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: config.isPositive
                                ? Colors.green.shade200
                                : Colors.red.shade200,
                          ),
                        ),
                        child: Text(
                          '${config.isPositive ? '+' : '-'}${usage.quantityUsed % 1 == 0 ? usage.quantityUsed.toInt() : usage.quantityUsed}',
                          style: TextStyle(
                            color: config.isPositive
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Patient info (if patient_use)
                  if (usage.patientName != null) ...[
                    _InfoRow(
                      icon: Icons.person_outline,
                      color: const Color(0xFF006D63),
                      label: 'المريض',
                      value: usage.patientName!,
                    ),
                    if (usage.patientPhone != null)
                      _InfoRow(
                        icon: Icons.phone_outlined,
                        color: Colors.blue,
                        label: 'الهاتف',
                        value: usage.patientPhone!,
                      ),
                  ],

                  // Who performed
                  if (usage.usedByName != null)
                    _InfoRow(
                      icon: Icons.medical_services_outlined,
                      color: Colors.purple,
                      label: 'بواسطة',
                      value: usage.usedByName!,
                    ),

                  // Notes
                  if (usage.notes != null && usage.notes!.isNotEmpty)
                    _InfoRow(
                      icon: Icons.notes_rounded,
                      color: Colors.orange,
                      label: 'ملاحظة',
                      value: usage.notes!,
                    ),

                  const SizedBox(height: 4),
                  // Time
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('hh:mm a').format(usage.usedAt.toLocal()),
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text('$label: ',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Type Configuration ───────────────────────────────────────────────────────
class _TypeConfig {
  final String label;
  final IconData icon;
  final Color color;
  final bool isPositive;

  const _TypeConfig({
    required this.label,
    required this.icon,
    required this.color,
    required this.isPositive,
  });
}

_TypeConfig _getTypeConfig(String type) {
  switch (type) {
    case 'restock':
      return const _TypeConfig(
        label: 'إضافة مخزون',
        icon: Icons.add_circle_rounded,
        color: Colors.green,
        isPositive: true,
      );
    case 'patient_use':
      return const _TypeConfig(
        label: 'صرف لمريض',
        icon: Icons.personal_injury_outlined,
        color: Color(0xFF006D63),
        isPositive: false,
      );
    case 'transfer_out':
      return const _TypeConfig(
        label: 'تحويل للخارج',
        icon: Icons.outbox_rounded,
        color: Colors.orange,
        isPositive: false,
      );
    case 'transfer_in':
      return const _TypeConfig(
        label: 'تحويل وارد',
        icon: Icons.move_to_inbox_rounded,
        color: Colors.blue,
        isPositive: true,
      );
    case 'adjustment':
      return const _TypeConfig(
        label: 'تسوية',
        icon: Icons.tune_rounded,
        color: Colors.purple,
        isPositive: false,
      );
    default:
      return const _TypeConfig(
        label: 'حركة',
        icon: Icons.swap_horiz_rounded,
        color: Colors.grey,
        isPositive: false,
      );
  }
}
