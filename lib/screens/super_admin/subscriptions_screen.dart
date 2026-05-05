import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/super_admin_service.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  static const primaryColor = Color(0xFF006D63);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clinicsAsync = ref.watch(allClinicsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('الاشتراكات والفواتير', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: clinicsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: primaryColor)),
          error: (err, _) => Center(child: Text('خطأ: $err')),
          data: (clinics) {
            int activeSubs = 0;
            int overdueSubs = 0;
            double estimatedRevenue = 0;

            final now = DateTime.now();

            for (var clinic in clinics) {
              if (clinic.isActive) {
                activeSubs++;
                // Assuming starter is 500/mo, pro is 1500/mo
                estimatedRevenue += clinic.plan == 'pro' ? 1500.0 : 500.0;
              }
              if (clinic.subscriptionEndsAt != null && clinic.subscriptionEndsAt!.isBefore(now)) {
                overdueSubs++;
              }
            }

            final stats = [
              {'label': 'اشتراكات نشطة', 'value': '$activeSubs', 'icon': Icons.check_circle_outline, 'color': Colors.green},
              {'label': 'إيرادات محتملة', 'value': 'EGP ${estimatedRevenue.toStringAsFixed(0)}', 'icon': Icons.trending_up, 'color': Colors.blue},
              {'label': 'اشتراكات متأخرة', 'value': '$overdueSubs', 'icon': Icons.credit_card_outlined, 'color': Colors.orange},
            ];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Header
                  const Text(
                    'تتبع مدفوعات العيادات وإدارة باقات الاشتراك',
                    style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // Stats cards
                  Row(
                    children: List.generate(stats.length, (i) {
                      final s = stats[i];
                      final color = [Colors.green, Colors.blue, Colors.orange][i];
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: i == 0 ? 0 : 12),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.grey.shade100),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.06),
                                blurRadius: 12,
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(s['icon'] as IconData, color: color, size: 26),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                s['value'] as String,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF00302D)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                s['label'] as String,
                                style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Invoices section - mock/coming soon
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.credit_card_outlined, size: 48, color: Color(0xFFCCCCCC)),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'قائمة الفواتير',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF00302D)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'لا توجد فواتير مسجلة حالياً.',
                          style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.download_outlined, size: 18),
                          label: const Text('تصدير تقرير الاشتراكات'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: const BorderSide(color: primaryColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
