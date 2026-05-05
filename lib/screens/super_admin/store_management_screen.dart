import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/super_admin_service.dart';

class StoreManagementScreen extends ConsumerStatefulWidget {
  const StoreManagementScreen({super.key});

  @override
  ConsumerState<StoreManagementScreen> createState() => _StoreManagementScreenState();
}

class _StoreManagementScreenState extends ConsumerState<StoreManagementScreen> {
  static const primaryColor = Color(0xFF006D63);
  String _activeFilter = 'الكل';
  final _searchController = TextEditingController();

  final _filters = ['الكل', 'متجر', 'صيدلية', 'مستودع'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateStoreModal() {
    final nameCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    String newType = 'متجر';
    String newStatus = 'active';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('إضافة كيان جديد', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(
                controller: nameCtrl,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  labelText: 'اسم المتجر/الصيدلية',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationCtrl,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  labelText: 'الفرع/الموقع',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: newType,
                decoration: InputDecoration(
                  labelText: 'النوع',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                items: const [
                  DropdownMenuItem(value: 'متجر', child: Text('متجر', textAlign: TextAlign.right)),
                  DropdownMenuItem(value: 'صيدلية', child: Text('صيدلية', textAlign: TextAlign.right)),
                  DropdownMenuItem(value: 'مستودع', child: Text('مستودع', textAlign: TextAlign.right)),
                ],
                onChanged: (v) => setState(() => newType = v ?? 'متجر'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: newStatus,
                decoration: InputDecoration(
                  labelText: 'الحالة',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('نشط', textAlign: TextAlign.right)),
                  DropdownMenuItem(value: 'inactive', child: Text('متوقف', textAlign: TextAlign.right)),
                ],
                onChanged: (v) => setState(() => newStatus = v ?? 'active'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    setState(() => isSaving = true);
                    try {
                      await ref.read(superAdminServiceProvider).createStore({
                        'name': nameCtrl.text.trim(),
                        'location': locationCtrl.text.trim(),
                        'type': newType,
                        'status': newStatus,
                        'sales': 0,
                      });
                      ref.refresh(allStoresProvider);
                      if (ctx.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                    } finally {
                      setState(() => isSaving = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: isSaving 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('حفظ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storesAsync = ref.watch(allStoresProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('إدارة المتاجر والمستودعات', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: ElevatedButton.icon(
              onPressed: _showCreateStoreModal,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('إنشاء متجر'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: storesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: primaryColor)),
          error: (err, _) => Center(child: Text('خطأ في جلب البيانات: $err')),
          data: (stores) {
            final filteredStores = stores.where((s) {
              final matchFilter = _activeFilter == 'الكل' || s['type'] == _activeFilter;
              final matchSearch = s['name'].toString().contains(_searchController.text);
              return matchFilter && matchSearch;
            }).toList();

            final totalSales = stores.fold<double>(0, (sum, item) => sum + (double.tryParse(item['sales']?.toString() ?? '0') ?? 0));

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'تحكم مركزي في المخزون، المبيعات المباشرة، وتخصيص المتاجر لكل عيادة.',
                    style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // Stats row
                  Row(
                    children: [
                      _buildStatCard('إجمالي المنافذ', '${stores.length}', Icons.grid_view_outlined, Colors.grey),
                      const SizedBox(width: 14),
                      _buildStatCard('إجمالي المبيعات', totalSales.toStringAsFixed(0), Icons.trending_up, primaryColor),
                      const SizedBox(width: 14),
                      _buildStatCard('معدل دوران المخزون', '٨٥٪', Icons.inventory_2_outlined, Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Search and filters
                  Row(
                    children: [
                      // Filters
                      Wrap(
                        spacing: 8,
                        children: _filters.map((f) {
                          final isActive = _activeFilter == f;
                          return GestureDetector(
                            onTap: () => setState(() => _activeFilter = f),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isActive ? primaryColor : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isActive ? primaryColor : Colors.grey.shade200),
                              ),
                              child: Text(
                                f,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? Colors.white : Colors.grey[600],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const Spacer(),
                      // Search
                      SizedBox(
                        width: 220,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(
                            hintText: 'البحث في المتاجر...',
                            hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                            prefixIcon: const Icon(Icons.search, size: 20),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stores list
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      children: [
                        // Title header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey,
                                  side: BorderSide(color: Colors.grey.shade200),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('تصدير التقرير', style: TextStyle(fontSize: 12)),
                              ),
                              const Text(
                                'قائمة الكيانات التجارية',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF00302D)),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        ...filteredStores.isEmpty
                            ? [
                                Padding(
                                  padding: const EdgeInsets.all(40),
                                  child: Center(
                                    child: Text('لا يوجد نتائج مطابقة', style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold)),
                                  ),
                                )
                              ]
                            : filteredStores.map((s) => _buildStoreRow(s)).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF00302D))),
                const SizedBox(height: 2),
                Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreRow(Map<String, dynamic> s) {
    final isActive = s['status'] == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade50)),
      ),
      child: Row(
        children: [
          // Actions
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[600],
              side: BorderSide(color: Colors.grey.shade200),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            child: const Text('إدارة المخزون'),
          ),
          const SizedBox(width: 12),
          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isActive ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isActive ? Colors.green.shade100 : Colors.red.shade100),
            ),
            child: Text(
              isActive ? 'نشط' : 'متوقف',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.green[700] : Colors.red[700],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Sales
          Text(s['sales']?.toString() ?? '0', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
          const SizedBox(width: 12),
          // Type
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(s['type']?.toString() ?? '', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[700])),
          ),
          const SizedBox(width: 12),
          // Location
          Text(s['location']?.toString() ?? '', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          const Spacer(),
          // Name with icon
          Row(
            children: [
              Text(
                s['name']?.toString() ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF00302D)),
              ),
              const SizedBox(width: 10),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.store_outlined, size: 20, color: Color(0xFF006D63)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
