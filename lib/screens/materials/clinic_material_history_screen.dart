import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/clinic_material.dart';
import '../../providers/materials_provider.dart';
import '../../providers/auth_provider.dart';

class ClinicMaterialHistoryScreen extends ConsumerStatefulWidget {
  const ClinicMaterialHistoryScreen({super.key});

  @override
  ConsumerState<ClinicMaterialHistoryScreen> createState() =>
      _ClinicMaterialHistoryScreenState();
}

class _ClinicMaterialHistoryScreenState
    extends ConsumerState<ClinicMaterialHistoryScreen>
    with SingleTickerProviderStateMixin {
  static const _primary = Color(0xFF006D63);
  String _filterType = 'all';
  String _searchQuery = '';
  late TabController _tabController;

  static const _tabs = [
    {'key': 'all', 'label': 'الكل'},
    {'key': 'restock', 'label': 'إضافة مخزون'},
    {'key': 'patient_use', 'label': 'صرف لمريض'},
    {'key': 'transfer_out', 'label': 'تحويل للخارج'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _filterType = _tabs[_tabController.index]['key']!);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final clinicId = auth is AuthAuthenticated ? auth.profile?.clinicId ?? '' : '';
    final historyState = ref.watch(clinicUsageProvider(clinicId));

    final filtered = historyState.usages.where((u) {
      final matchType = _filterType == 'all' || u.usageType == _filterType;
      final matchSearch = _searchQuery.isEmpty ||
          (u.materialName ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (u.patientName ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      return matchType && matchSearch;
    }).toList();

    // Summary stats
    final totalIn = historyState.usages
        .where((u) => u.usageType == 'restock' || u.usageType == 'transfer_in')
        .fold(0.0, (s, u) => s + u.quantityUsed);
    final totalOut = historyState.usages
        .where((u) => u.usageType != 'restock' && u.usageType != 'transfer_in')
        .fold(0.0, (s, u) => s + u.quantityUsed);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Column(
          children: [
            Text('سجل حركات المخزون',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text('العيادة كاملة',
                style: TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _primary),
            onPressed: () =>
                ref.read(clinicUsageProvider(clinicId).notifier).refresh(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: _primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _primary,
          indicatorWeight: 3,
          isScrollable: true,
          tabs: _tabs.map((t) => Tab(text: t['label'])).toList(),
        ),
      ),
      body: Column(
        children: [
          // Summary Stats Row
          _SummaryStatsRow(totalIn: totalIn, totalOut: totalOut,
              total: historyState.usages.length),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: const InputDecoration(
                  hintText: 'ابحث باسم الخامة أو المريض...',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Timeline List
          Expanded(
            child: historyState.isLoading
                ? const Center(child: CircularProgressIndicator(color: _primary))
                : historyState.error != null
                    ? _ErrorWidget(
                        error: historyState.error!,
                        onRetry: () => ref
                            .read(clinicUsageProvider(clinicId).notifier)
                            .refresh(),
                      )
                    : filtered.isEmpty
                        ? const _EmptyWidget()
                        : _ClinicHistoryTimeline(usages: filtered),
          ),
        ],
      ),
    );
  }
}

// ─── Summary Stats Row ────────────────────────────────────────────────────────
class _SummaryStatsRow extends StatelessWidget {
  final double totalIn;
  final double totalOut;
  final int total;
  const _SummaryStatsRow(
      {required this.totalIn, required this.totalOut, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _StatChip(
            label: 'إجمالي الحركات',
            value: total.toString(),
            icon: Icons.swap_horiz_rounded,
            color: Colors.blueGrey,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'وارد',
            value: totalIn % 1 == 0 ? totalIn.toInt().toString() : totalIn.toStringAsFixed(1),
            icon: Icons.add_circle_rounded,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'صادر',
            value: totalOut % 1 == 0 ? totalOut.toInt().toString() : totalOut.toStringAsFixed(1),
            icon: Icons.remove_circle_rounded,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatChip(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: color)),
                  Text(label,
                      style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Timeline ─────────────────────────────────────────────────────────────────
class _ClinicHistoryTimeline extends StatelessWidget {
  final List<MaterialUsage> usages;
  const _ClinicHistoryTimeline({required this.usages});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<MaterialUsage>> grouped = {};
    for (final u in usages) {
      final dateKey = DateFormat('yyyy-MM-dd').format(u.usedAt.toLocal());
      grouped.putIfAbsent(dateKey, () => []).add(u);
    }
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: sortedDates.length,
      itemBuilder: (ctx, i) {
        final dateStr = sortedDates[i];
        final items = grouped[dateStr]!;
        final date = DateTime.parse(dateStr);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));
        final d = DateTime(date.year, date.month, date.day);

        String dateLabel;
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006D63).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(dateLabel,
                        style: const TextStyle(
                            color: Color(0xFF006D63),
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Divider(color: Colors.grey.shade200)),
                  const SizedBox(width: 8),
                  Text('${items.length} حركة',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 11)),
                ],
              ),
            ),
            ...items.map((u) => _ClinicHistoryEntry(usage: u)),
          ],
        );
      },
    );
  }
}

// ─── History Entry ─────────────────────────────────────────────────────────────
class _ClinicHistoryEntry extends StatelessWidget {
  final MaterialUsage usage;
  const _ClinicHistoryEntry({required this.usage});

  @override
  Widget build(BuildContext context) {
    final config = _getTypeConfig(usage.usageType);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: config.color.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // timeline line + icon
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: config.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(config.icon, color: config.color, size: 18),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Material name
                      Expanded(
                        child: Text(
                          usage.materialName ?? 'خامة',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Quantity badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: config.isPositive
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: config.isPositive
                                ? Colors.green.shade200
                                : Colors.red.shade200,
                          ),
                        ),
                        child: Text(
                          '${config.isPositive ? '+' : '-'}${usage.quantityUsed % 1 == 0 ? usage.quantityUsed.toInt() : usage.quantityUsed} ${usage.materialUnit ?? ''}',
                          style: TextStyle(
                            color: config.isPositive
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Type badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: config.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(config.label,
                            style: TextStyle(
                                color: config.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 10)),
                      ),
                      if (usage.usedByName != null) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.person_outline,
                            size: 11, color: Colors.grey.shade400),
                        const SizedBox(width: 2),
                        Text(usage.usedByName!,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ],
                  ),
                  if (usage.patientName != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.personal_injury_outlined,
                            size: 12, color: const Color(0xFF006D63)),
                        const SizedBox(width: 4),
                        Text('المريض: ${usage.patientName}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF006D63),
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                  if (usage.notes != null && usage.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.notes_rounded,
                            size: 12, color: Colors.orange.shade400),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(usage.notes!,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 11, color: Colors.grey.shade300),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('hh:mm a').format(usage.usedAt.toLocal()),
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade400),
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

// ─── Empty Widget ─────────────────────────────────────────────────────────────
class _EmptyWidget extends StatelessWidget {
  const _EmptyWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF006D63).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_rounded,
                size: 56, color: Color(0xFF006D63)),
          ),
          const SizedBox(height: 20),
          const Text('لا توجد حركات مسجلة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('لم يتم تسجيل أي حركات مخزون حتى الآن',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorWidget({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text('خطأ: $error', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}

// ─── Type Config ─────────────────────────────────────────────────────────────
class _TypeConfig {
  final String label;
  final IconData icon;
  final Color color;
  final bool isPositive;
  const _TypeConfig(
      {required this.label,
      required this.icon,
      required this.color,
      required this.isPositive});
}

_TypeConfig _getTypeConfig(String type) {
  switch (type) {
    case 'restock':
      return const _TypeConfig(
          label: 'إضافة مخزون',
          icon: Icons.add_circle_rounded,
          color: Colors.green,
          isPositive: true);
    case 'patient_use':
      return const _TypeConfig(
          label: 'صرف لمريض',
          icon: Icons.personal_injury_outlined,
          color: Color(0xFF006D63),
          isPositive: false);
    case 'transfer_out':
      return const _TypeConfig(
          label: 'تحويل للخارج',
          icon: Icons.outbox_rounded,
          color: Colors.orange,
          isPositive: false);
    case 'transfer_in':
      return const _TypeConfig(
          label: 'تحويل وارد',
          icon: Icons.move_to_inbox_rounded,
          color: Colors.blue,
          isPositive: true);
    case 'adjustment':
      return const _TypeConfig(
          label: 'تسوية',
          icon: Icons.tune_rounded,
          color: Colors.purple,
          isPositive: false);
    default:
      return const _TypeConfig(
          label: 'حركة',
          icon: Icons.swap_horiz_rounded,
          color: Colors.grey,
          isPositive: false);
  }
}
