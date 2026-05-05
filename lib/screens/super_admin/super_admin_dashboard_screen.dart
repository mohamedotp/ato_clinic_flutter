import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ato_clinic_flutter/providers/auth_provider.dart';
import '../../services/super_admin_service.dart';

class SuperAdminDashboardScreen extends ConsumerWidget {
  const SuperAdminDashboardScreen({super.key});

  static const primaryColor = Color(0xFF006D63);
  static const darkBg = Color(0xFF00302D);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profile = authState is AuthAuthenticated ? authState.profile : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('لوحة تحكم النظام الشاملة',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'تسجيل الخروج',
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            _buildHeaderCard(context, profile?.fullName ?? 'سوبر أدمن'),
            const SizedBox(height: 24),

            // KPI cards
            _buildKPICards(ref),
            const SizedBox(height: 28),

            // Title
            const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: Text(
                'لوحات الإدارة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: darkBg,
                ),
              ),
            ),

            // Nav rows — two columns
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.25,
              children: [
                _buildNavCard(
                  context,
                  icon: Icons.local_hospital_outlined,
                  title: 'إدارة العيادات',
                  subtitle: 'تعديل الاشتراكات وتفعيل الحسابات',
                  route: '/super-admin/clinics',
                  color: primaryColor,
                ),
                _buildNavCard(
                  context,
                  icon: Icons.verified_outlined,
                  title: 'الاشتراكات',
                  subtitle: 'الفواتير ومدفوعات العيادات',
                  route: '/super-admin/subscriptions',
                  color: Colors.blue,
                ),
                _buildNavCard(
                  context,
                  icon: Icons.bar_chart_outlined,
                  title: 'تقارير النظام',
                  subtitle: 'نظرة شاملة على الأداء',
                  route: '/super-admin/reports',
                  color: Colors.purple,
                ),
                _buildNavCard(
                  context,
                  icon: Icons.store_outlined,
                  title: 'إدارة المتاجر',
                  subtitle: 'المخزون والمبيعات المباشرة',
                  route: '/super-admin/stores',
                  color: Colors.orange,
                ),
                _buildNavCard(
                  context,
                  icon: Icons.smart_toy_outlined,
                  title: 'تفعيل الخدمات',
                  subtitle: 'الذكاء الاصطناعي والبيانات',
                  route: '/super-admin/services',
                  color: Colors.teal,
                ),
                _buildNavCard(
                  context,
                  icon: Icons.support_agent_outlined,
                  title: 'الدعم الفني',
                  subtitle: 'تذاكر الدعم والاستفسارات',
                  route: '/super-admin/support',
                  color: Colors.red,
                ),
                _buildNavCard(
                  context,
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'مدراء النظام',
                  subtitle: 'إدارة صلاحيات الوصول',
                  route: '/super-admin/admins',
                  color: Colors.deepPurple,
                ),
                _buildNavCard(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'إعدادات النظام',
                  subtitle: 'الإعدادات العامة للـ SaaS',
                  route: '/super-admin/settings',
                  color: Colors.blueGrey,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Enter clinic banner
            _buildClinicSelectorBanner(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, String name) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [darkBg, primaryColor],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: darkBg.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'مرحباً بك مجدداً',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICards(WidgetRef ref) {
    final clinicsAsync = ref.watch(allClinicsProvider);
    final ticketsAsync = ref.watch(allTicketsProvider);

    int totalClinics = 0;
    int activeClinics = 0;
    int openTickets = 0;

    if (clinicsAsync.hasValue && clinicsAsync.value != null) {
      totalClinics = clinicsAsync.value!.length;
      activeClinics = clinicsAsync.value!.where((c) => c.isActive).length;
    }

    if (ticketsAsync.hasValue && ticketsAsync.value != null) {
      openTickets = ticketsAsync.value!.where((t) => t['status'] != 'closed').length;
    }

    final kpis = [
      {'title': 'إجمالي العيادات', 'value': '$totalClinics', 'icon': Icons.local_hospital_outlined, 'trend': '+12%', 'color': primaryColor},
      {'title': 'العيادات النشطة', 'value': '$activeClinics', 'icon': Icons.verified_outlined, 'trend': '+5%', 'color': Colors.blue},
      {'title': 'تذاكر مفتوحة', 'value': '$openTickets', 'icon': Icons.support_agent_outlined, 'trend': '', 'color': Colors.orange},
      {'title': 'حالة النظام', 'value': 'مستقر', 'icon': Icons.health_and_safety_outlined, 'trend': '100%', 'color': Colors.green},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.25,
      ),
      itemCount: kpis.length,
      itemBuilder: (context, i) {
        final k = kpis[i];
        final color = k['color'] as Color;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.06), blurRadius: 12),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(k['icon'] as IconData, color: color, size: 20),
                  ),
                  if ((k['trend'] as String).isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        k['trend'] as String,
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    )
                  else
                    const SizedBox(),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    k['value'] as String,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF00302D)),
                  ),
                  Text(
                    k['title'] as String,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFCCCCCC)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF00302D),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicSelectorBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/super-admin/select-clinic'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: darkBg,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'دخول عيادة بعينها',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'تصفح وادخل أي عيادة مسجلة في النظام',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('اختر عيادة',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
