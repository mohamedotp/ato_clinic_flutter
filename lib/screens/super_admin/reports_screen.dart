import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/super_admin_service.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  static const primaryColor = Color(0xFF006D63);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clinicsAsync = ref.watch(allClinicsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('تقارير النظام', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_outlined, size: 16),
              label: const Text('تصدير'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: const BorderSide(color: primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: clinicsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: primaryColor)),
          error: (err, _) => Center(child: Text('خطأ: $err')),
          data: (clinics) {
            final totalClinics = clinics.length;
            double estimatedRevenue = 0;

            for (var clinic in clinics) {
              if (clinic.isActive) {
                // Mock revenue calc
                estimatedRevenue += clinic.plan == 'pro' ? 1.5 : 0.5; // in thousands
              }
            }

            final stats = [
              {'title': 'إجمالي العيادات', 'value': '$totalClinics', 'icon': Icons.people_outline, 'color': Colors.blue},
              {'title': 'موعد منجز عبر النظام', 'value': 'قريباً', 'icon': Icons.calendar_today_outlined, 'color': Colors.green},
              {'title': 'إجمالي الإيرادات كتقرير', 'value': '${estimatedRevenue.toStringAsFixed(1)}k', 'icon': Icons.trending_up, 'color': primaryColor},
              {'title': 'معدل النمو الشهري', 'value': '+14%', 'icon': Icons.bar_chart, 'color': Colors.purple},
            ];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'نظرة شاملة على أداء نظام إدارة العيادات',
                    style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // Stats grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.3,
                    ),
                    itemCount: stats.length,
                    itemBuilder: (context, i) {
                      final s = stats[i];
                      final color = s['color'] as Color;
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(s['icon'] as IconData, color: color, size: 24),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              s['value'] as String,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF00302D),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s['title'] as String,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Chart placeholder
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'الرسوم البيانية للإيرادات',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF00302D)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'تحليل نمو الدخل الشهري (يناير - أغسطس)',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 24),
                        // Bar chart visual
                        SizedBox(
                          height: 160,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [40.0, 60.0, 35.0, 75.0, 85.0, 65.0, 50.0, 40.0].asMap().entries.map((entry) {
                              final months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس'];
                              final isHighlight = entry.key == 4;
                              return Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0, end: entry.value / 100),
                                      duration: Duration(milliseconds: 600 + entry.key * 100),
                                      builder: (context, value, _) {
                                        return Container(
                                          height: 130 * value,
                                          margin: const EdgeInsets.symmetric(horizontal: 3),
                                          decoration: BoxDecoration(
                                            color: isHighlight
                                                ? primaryColor.withOpacity(0.7)
                                                : primaryColor.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      months[entry.key],
                                      style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
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
}
