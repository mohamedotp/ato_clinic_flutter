import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/super_admin_service.dart';

class SupportTicketsScreen extends ConsumerStatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  ConsumerState<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends ConsumerState<SupportTicketsScreen> {
  static const primaryColor = Color(0xFF006D63);
  String _selectedStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(allTicketsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('الدعم الفني', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ticketsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: primaryColor)),
          error: (err, _) => Center(child: Text('خطأ: $err')),
          data: (tickets) {
            final openCount = tickets.where((t) => t['status'] == 'open').length;
            final processingCount = tickets.where((t) => t['status'] == 'processing').length;
            final closedCount = tickets.where((t) => t['status'] == 'closed').length;

            final filteredTickets = (_selectedStatus == 'all')
                ? tickets
                : tickets.where((t) => t['status'] == _selectedStatus).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'إدارة تذاكر الدعم واستفسارات العيادات',
                    style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // Stats cards
                  Row(
                    children: [
                      _buildStatCard('تذاكر مفتوحة', openCount.toString(), Colors.red),
                      const SizedBox(width: 14),
                      _buildStatCard('قيد المعالجة', processingCount.toString(), Colors.amber),
                      const SizedBox(width: 14),
                      _buildStatCard('تذاكر مغلقة', closedCount.toString(), Colors.green),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Filter tabs
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Row(
                      children: [
                        _buildFilterTab('all', 'الكل'),
                        _buildFilterTab('open', 'مفتوحة'),
                        _buildFilterTab('processing', 'قيد المعالجة'),
                        _buildFilterTab('closed', 'مغلقة'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tickets list
                  if (filteredTickets.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.support_agent_outlined, size: 48, color: Color(0xFFCCCCCC)),
                          ),
                          const SizedBox(height: 16),
                          const Text('لا يوجد تذاكر جديدة مطابقة',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF00302D))),
                          const SizedBox(height: 6),
                          Text('ستظهر هنا التذاكر المرفوعة من العيادات.',
                              style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  else
                    ...filteredTickets.map((t) => _buildTicketCard(t)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.06), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String status, String label) {
    final isActive = _selectedStatus == status;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedStatus = status),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : Colors.grey[500],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> t) {
    final status = (t['status'] ?? 'open') as String;
    final priority = (t['priority'] ?? 'medium') as String;

    final statusConfig = {
      'open': {'label': 'مفتوحة', 'color': Colors.red},
      'processing': {'label': 'قيد المعالجة', 'color': Colors.amber[700]!},
      'closed': {'label': 'مغلقة', 'color': Colors.green},
    };

    final priorityConfig = {
      'high': {'label': 'عالي', 'color': Colors.red},
      'medium': {'label': 'متوسط', 'color': Colors.orange},
      'low': {'label': 'منخفض', 'color': Colors.green},
    };

    final sc = statusConfig[status] ?? statusConfig['open']!;
    final pc = priorityConfig[priority] ?? priorityConfig['medium']!;

    final ticketNumber = t['ticket_number']?.toString() ?? '#TK-${t['id'].toString().substring(0, 4)}';
    final dateStr = t['created_at'] != null 
        ? DateTime.parse(t['created_at']).toLocal().toString().split('.')[0]
        : 'غير معروف';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (sc['color'] as Color).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(sc['label'] as String,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: sc['color'] as Color)),
                  ),
                  const SizedBox(width: 8),
                  // Priority
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (pc['color'] as Color).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('أولوية ${pc['label']}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: pc['color'] as Color)),
                  ),
                ],
              ),
              // ID + Date
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(ticketNumber,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: primaryColor)),
                  Text(dateStr,
                      style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(t['subject']?.toString() ?? 'بدون عنوان',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF00302D))),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (status != 'closed')
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('فتح التذكرة ←', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                )
              else
                const SizedBox(),
              Row(
                children: [
                  const Icon(Icons.local_hospital_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(t['clinic_name']?.toString() ?? 'عيادة غير محددة',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
