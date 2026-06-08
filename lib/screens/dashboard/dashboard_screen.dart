import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/appointments_provider.dart';
import '../../providers/patients_provider.dart';
import '../../providers/visits_provider.dart';
import '../../models/appointment.dart';
import '../../models/profile.dart';
import '../../widgets/modals/add_edit_appointment_modal.dart';
import '../handoff/handoff_screen.dart';
import '../handoff/conversations_screen.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/connectivity_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/treasury_service.dart';

final _treasurySvcProvider = Provider((ref) => TreasuryService());
final _dashDailyRevenueProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, clinicId) {
  return ref.read(_treasurySvcProvider).getDailyRevenue(clinicId, 7);
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final appointmentsAsync = ref.watch(appointmentsProvider);
    final patientsAsync = ref.watch(patientsProvider);
    final visitsAsync = ref.watch(visitsProvider);
    
    // RBAC
    final profile = authState is AuthAuthenticated ? authState.profile : null;
    final isReceptionist = profile?.role == UserRole.receptionist;
    
    // Dynamic Stats
    final now = DateTime.now();
    bool isToday(DateTime date) => date.year == now.year && date.month == now.month && date.day == now.day;

    final visitsList = visitsAsync.valueOrNull ?? [];
    int todaysVisitsCount = 0;
    for (var v in visitsList) {
      final d = v.visitDate ?? v.createdAt;
      if (isToday(d)) todaysVisitsCount++;
    }

    // \u0627\u0644\u0625\u064a\u0631\u0627\u062f\u0627\u062a \u0645\u0646 \u0627\u0644\u062e\u0632\u064a\u0646\u0629 (appointments \u0645\u0643\u062a\u0645\u0644\u0629 + \u0632\u064a\u0627\u0631\u0627\u062a + \u0623\u064a \u0645\u0635\u062f\u0631 \u0622\u062e\u0631)
    final clinicId = profile?.clinicId ?? '';
    final chartData = ref.watch(_dashDailyRevenueProvider(clinicId));
    // Today's revenue = last entry in the chart data (today)
    double todaysRevenue = 0.0;
    chartData.whenData((data) {
      if (data.isNotEmpty) {
        final todayKey = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}';
        final todayEntry = data.where((d) => d['day'] == todayKey).toList();
        if (todayEntry.isNotEmpty) {
          todaysRevenue = (todayEntry.first['revenue'] as num).toDouble();
        }
      }
    });

    final appointmentsList = appointmentsAsync.valueOrNull ?? [];
    final todaysAppointments = appointmentsList.where((a) {
      final d = a.appointmentDate ?? a.scheduledAt ?? a.createdAt;
      return isToday(d);
    }).toList();
    
    // Theme Colors
    const primaryColor = Color(0xFF006D63); 
    const scaffoldBg = Color(0xFFF8FAF9);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Offline Banner
            Consumer(
              builder: (ctx, ref2, _) {
                final isOnline = ref2.watch(isOnlineProvider);
                if (isOnline) return const SizedBox.shrink();
                return Material(
                  color: Colors.transparent,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: Colors.orange.shade700,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'أنت الآن في وضع Offline — البيانات محفوظة محلياً وستُزامن تلقائياً',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ).animate().slideY(begin: -1, duration: 400.ms),
                );
              },
            ),
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              // 1. Custom Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white,
                      backgroundImage: (authState is AuthAuthenticated && authState.profile?.avatarUrl != null)
                          ? NetworkImage(authState.profile!.avatarUrl!)
                          : const AssetImage('assets/images/placeholder_doctor.png') as ImageProvider,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isReceptionist)
                          const Text(
                            'مرحباً دكتور',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        Text(
                          authState is AuthAuthenticated ? authState.profile?.fullName ?? '' : 'مرحباً',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (profile?.role == UserRole.super_admin) ...[
                      InkWell(
                        onTap: () {
                          ref.read(authProvider.notifier).exitClinicContext();
                          context.go('/super-admin');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.admin_panel_settings, color: Colors.red, size: 18),
                              SizedBox(width: 4),
                              Text(
                                'خروج للإدارة',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    // Notification Bell
                    Consumer(
                      builder: (context, ref, child) {
                        final unreadCount = ref.watch(unreadNotificationsCountProvider);
                        return Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_none, color: primaryColor, size: 28),
                              onPressed: () => context.push('/notifications'),
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                      const Text(
                        'عياداتي',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ).animate().fade(duration: 400.ms).slideY(begin: -0.2),

                // 2. Revenue Card (Hidden for Receptionist)
                if (!isReceptionist) ...[
                  _RevenueCard(revenue: todaysRevenue)
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .shimmer(duration: 2000.ms, color: Colors.white10)
                      .animate().fade(delay: 200.ms).scale(),
                  
                  const SizedBox(height: 10),
                  if (clinicId.isNotEmpty)
                    _RevenueChart(chartAsync: chartData)
                      .animate().fade(delay: 300.ms).slideX(),
                ],


              // 3. Quick Actions Grid
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Text(
                  'روابط سريعة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = (constraints.maxWidth - 16) / 2;
                    final cards = [
                      _QuickActionCard(
                        title: 'المرضى',
                        icon: Icons.people_outline,
                        color: const Color(0xFF00302D),
                        onTap: () => context.push('/patients'),
                      ),
                      _QuickActionCard(
                        title: 'المواعيد',
                        icon: Icons.calendar_month_outlined,
                        color: Colors.white,
                        textColor: Colors.black,
                        onTap: () => context.push('/appointments'),
                      ),
                      _QuickActionCard(
                        title: 'اضافة موعد',
                        icon: Icons.add_alarm_outlined,
                        color: const Color(0xFFF0FDF4),
                        textColor: const Color(0xFF166534),
                        onTap: () => AddEditAppointmentModal.show(context),
                      ),
                      if (!isReceptionist)
                        _QuickActionCard(
                          title: 'الخامات',
                          icon: Icons.inventory_2_outlined,
                          color: const Color(0xFFF5F3FF),
                          textColor: const Color(0xFF5B21B6),
                          onTap: () => context.push('/materials'),
                        ),
                      _QuickActionCard(
                        title: 'الخدمات',
                        icon: Icons.medical_information_outlined,
                        color: Colors.white,
                        textColor: Colors.black,
                        onTap: () => context.push('/services'),
                      ),
                      // ── Basic Modules ──
                      if (!isReceptionist)
                        _QuickActionCard(
                          title: 'المالية',
                          icon: Icons.account_balance_wallet_outlined,
                          color: const Color(0xFFFFF8E1),
                          textColor: const Color(0xFFF57F17),
                          onTap: () => context.push('/finance'),
                        ),
                      if (!isReceptionist)
                        _QuickActionCard(
                          title: 'التقارير',
                          icon: Icons.analytics_outlined,
                          color: const Color(0xFFEDE7F6),
                          textColor: const Color(0xFF512DA8),
                          onTap: () => context.push('/reports'),
                        ),
                      if (!isReceptionist)
                        _QuickActionCard(
                          title: 'خطط العلاج',
                          icon: Icons.assignment_outlined,
                          color: const Color(0xFFE8F5E9),
                          textColor: const Color(0xFF2E7D32),
                          onTap: () => context.push('/treatment-plans'),
                        ),
                      _QuickActionCard(
                        title: 'تحاليل',
                        icon: Icons.science_outlined,
                        color: const Color(0xFFE3F2FD),
                        textColor: const Color(0xFF1565C0),
                        onTap: () => context.push('/lab-orders'),
                      ),
                      if (!isReceptionist)
                        _QuickActionCard(
                          title: 'الإجراءات',
                          icon: Icons.list_alt_outlined,
                          color: const Color(0xFFF3E5F5),
                          textColor: const Color(0xFF6A1B9A),
                          onTap: () => context.push('/procedures'),
                        ),
                      if (!isReceptionist)
                        _QuickActionCard(
                          title: 'التأمين',
                          icon: Icons.health_and_safety_outlined,
                          color: const Color(0xFFE0F7FA),
                          textColor: const Color(0xFF00695C),
                          onTap: () => context.push('/insurance'),
                        ),
                      if (!isReceptionist)
                        _QuickActionCard(
                          title: 'نسب الأطباء',
                          icon: Icons.percent,
                          color: const Color(0xFFFCE4EC),
                          textColor: const Color(0xFFC62828),
                          onTap: () => context.push('/doctor-percentage'),
                        ),
                      // ── Staff Modules ──
                      _QuickActionCard(
                        title: 'الحضور',
                        icon: Icons.fingerprint,
                        color: const Color(0xFFFFF3E0),
                        textColor: const Color(0xFFE65100),
                        onTap: () => context.push('/staff/attendance'),
                      ),
                      _QuickActionCard(
                        title: 'المهام',
                        icon: Icons.task_alt,
                        color: const Color(0xFFE1F5FE),
                        textColor: const Color(0xFF0277BD),
                        onTap: () => context.push('/staff/tasks'),
                      ),
                      // الدعم الفني موقوف مؤقتاً
                      // _QuickActionCard(
                      //   title: 'التدريب والدعم',
                      //   icon: Icons.support_agent,
                      //   color: const Color(0xFFF1F8E9),
                      //   textColor: const Color(0xFF33691E),
                      //   onTap: () => context.push('/staff/training'),
                      // ),
                    ];
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: cards
                          .map((c) => SizedBox(width: cardWidth, child: c))
                          .toList()
                          .animate(interval: 50.ms)
                          .fade(duration: 300.ms)
                          .scale(begin: const Offset(0.9, 0.9)),
                    );
                  }
                ),
              ).animate().fade(delay: 300.ms),

              // Handoff Banner (for receptionist or admin - when there are pending handoffs)
              Consumer(builder: (ctx, ref2, _) {
                final handoffs = ref2.watch(handoffProvider);
                final pending = handoffs.valueOrNull
                        ?.where((h) => h.status == 'pending')
                        .length ??
                    0;
                if (pending == 0) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () => context.push('/handoff'),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.shade700,
                          Colors.orange.shade500
                        ],
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.support_agent,
                            color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$pending طلب تحويل ينتظر',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15),
                              ),
                              const Text(
                                'اضغط لإدارة طلبات التحويل',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_back_ios,
                            color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                );
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'إجمالي المرضى',
                        value: patientsAsync.when(data: (p) => p.length.toString(), loading: () => '...', error: (_, _) => '0'),
                        icon: Icons.people_alt_outlined,
                        color: const Color(0xFFE3F2FD),
                        iconColor: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SummaryCard(
                        title: 'زيارات اليوم',
                        value: visitsAsync.isLoading ? '...' : todaysVisitsCount.toString(),
                        icon: Icons.calendar_today_outlined,
                        color: const Color(0xFFE8F5E9),
                        iconColor: Colors.green,
                      ),
                    ),
                  ],
                ).animate().fade(delay: 400.ms).slideX(),
              ),

              // 5. Today's Appointments Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'مواعيد اليوم',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => context.push('/appointments'),
                      child: const Text('عرض الكل', style: TextStyle(color: primaryColor)),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: 220,
                child: appointmentsAsync.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : todaysAppointments.isEmpty
                        ? const Center(child: Text('لا يوجد مواعيد اليوم'))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(left: 20),
                            itemCount: todaysAppointments.length,
                            itemBuilder: (context, index) {
                              return _AppointmentListCard(appointment: todaysAppointments[index]);
                            },
                          ).animate().fade(duration: 500.ms),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Text(
                  'آخر النشاطات',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ...() {
                 final sortedAppointments = List<Appointment>.from(appointmentsList)
                    ..sort((a,b) => b.createdAt.compareTo(a.createdAt));
                 final recent = sortedAppointments.take(3).toList();
                 
                 if (recent.isEmpty) {
                   return [const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('لا توجد نشاطات حديثة')))];
                 }

                 return recent.map((app) {
                   final timeDiff = DateTime.now().difference(app.createdAt);
                   String timeText = 'منذ ${timeDiff.inMinutes} دقيقة';
                   if (timeDiff.inMinutes > 60) {
                     timeText = 'منذ ${timeDiff.inHours} ساعة';
                   }
                   if (timeDiff.inHours > 24) {
                     timeText = 'منذ ${timeDiff.inDays} يوم';
                   }

                   return _ActivityItem(
                     title: 'موعد ${app.statusLabel} : ${app.patient?.fullName ?? 'مريض'}',
                     time: timeText,
                     icon: Icons.calendar_month_outlined,
                     color: const Color(0xFFE3F2FD),
                     iconColor: const Color(0xFF2196F3),
                   ).animate().fade(delay: 600.ms).slideX(begin: 0.1);
                 }).toList();
              }(),
              const SizedBox(height: 100),
            ],
          ),
          ),
        ),
        ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/patients'),
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      bottomNavigationBar: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) context.push('/patients');
          if (index == 2) context.push('/appointments');
          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ConversationsScreen()),
            );
          }
          if (index == 4) context.push('/settings');
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'الرئيسية'),
          const BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'المرضى'),
          const BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'المواعيد'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'المحادثات',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'الإعدادات'),
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final double revenue;
  const _RevenueCard({required this.revenue});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF006D63), Color(0xFF004D40)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF006D63).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: -20,
            bottom: -20,
            child: Icon(
              Icons.account_balance_wallet,
              size: 150,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'إجمالي الإيرادات اليوم',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      revenue.toStringAsFixed(0),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'ج.م',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        '+ 12% من الأمس',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> chartAsync;
  const _RevenueChart({required this.chartAsync});

  @override
  Widget build(BuildContext context) {
    return chartAsync.when(
      data: (data) {
        if (data.isEmpty) return const SizedBox.shrink();
        
        // Find max value to scale chart
        double maxRev = 0;
        for (var item in data) {
          if ((item['revenue'] as num) > maxRev) {
            maxRev = (item['revenue'] as num).toDouble();
          }
        }
        if (maxRev == 0) maxRev = 1000;

        return Container(
          height: 200,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('إيرادات آخر 7 أيام', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value < 0 || value >= data.length) return const SizedBox();
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                data[value.toInt()]['day'] as String,
                                style: const TextStyle(color: Colors.grey, fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: data.asMap().entries.map((e) {
                          return FlSpot(e.key.toDouble(), (e.value['revenue'] as num).toDouble());
                        }).toList(),
                        isCurved: true,
                        color: const Color(0xFF006D63),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF006D63).withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                    minY: 0,
                    maxY: maxRev * 1.2,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => SizedBox(height: 200, child: Center(child: Text('خطأ: $e'))),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    this.textColor = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        border: color == Colors.white ? Border.all(color: Colors.grey[200]!) : null,
        boxShadow: [
          if (color != Colors.white)
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          splashColor: Colors.white.withValues(alpha: 0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color iconColor;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[50]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87),
              ),
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppointmentListCard extends StatelessWidget {
  final Appointment appointment; 
  const _AppointmentListCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16, bottom: 5),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage('assets/images/placeholder_doctor.png'), 
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  appointment.queueNumber != null ? 'رقم ${appointment.queueNumber}' : 'غير محدد',
                  style: const TextStyle(color: Color(0xFF006D63), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.patient?.fullName ?? 'بدون اسم',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  appointment.notes?.isNotEmpty == true ? appointment.notes! : 'مراجعة',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.more_horiz, color: Colors.grey),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.push('/workspace/${appointment.patientId}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006D63),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('بدء الكشف'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;
  final Color color;
  final Color iconColor;

  const _ActivityItem({
    required this.title,
    required this.time,
    required this.icon,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

