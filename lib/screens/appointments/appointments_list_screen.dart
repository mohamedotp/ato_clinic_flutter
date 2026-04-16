import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../models/appointment.dart';
import '../../providers/appointments_provider.dart';
import '../../widgets/modals/add_edit_appointment_modal.dart';
import '../visits/visits_list_screen.dart';

class AppointmentsListScreen extends ConsumerStatefulWidget {
  const AppointmentsListScreen({super.key});

  @override
  ConsumerState<AppointmentsListScreen> createState() => _AppointmentsListScreenState();
}

enum ViewMode { month, day }

class _AppointmentsListScreenState extends ConsumerState<AppointmentsListScreen> {
  DateTime _currentDate = DateTime.now();
  DateTime _selectedDayForView = DateTime.now();
  ViewMode _viewMode = ViewMode.month;

  static const primaryColor = Color(0xFF0D9488);
  static const secondaryColor = Color(0xFF00302D);
  static const scaffoldBg = Color(0xFFF8FAF9);

  List<DateTime> _calculateCalendarDays(DateTime monthDate) {
    final monthStart = DateTime(monthDate.year, monthDate.month, 1);
    final monthEnd = DateTime(monthDate.year, monthDate.month + 1, 0);
    
    // Saturday is 6 in Dart (same as weekStartsOn: 6 in date-fns)
    // We want the start of the week containing monthStart, where week starts on Saturday
    // Calculation: (weekday - 6) % 7
    int daysToSubtract = (monthStart.weekday - 6) % 7;
    if (daysToSubtract < 0) daysToSubtract += 7;

    final startDate = monthStart.subtract(Duration(days: daysToSubtract));
    
    // Calculate end date (end of week containing monthEnd)
    // If Sat: weekday is 6. daysToAdd should be 6.
    // If Fri: weekday is 5. daysToAdd should be 0.
    // Calculation: (5 - weekday) % 7
    int daysToAdd = (5 - monthEnd.weekday) % 7;
    if (daysToAdd < 0) daysToAdd += 7;
    
    final endDate = monthEnd.add(Duration(days: daysToAdd));
    
    final days = <DateTime>[];
    for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
      days.add(startDate.add(Duration(days: i)));
    }
    return days;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isToday(DateTime date) {
    return _isSameDay(date, DateTime.now());
  }

  String _formatTime12h(String? timeStr) {
    if (timeStr == null || !timeStr.contains(':')) return '--:--';
    try {
      final parts = timeStr.trim().split(' ');
      final timeParts = parts[0].split(':');
      int h = int.parse(timeParts[0]);
      int m = int.parse(timeParts[1]);
      
      String period = 'ص';
      if (parts.length > 1) {
        period = parts[1] == 'PM' || parts[1] == 'م' ? 'م' : 'ص';
      } else {
        if (h >= 12) {
          period = 'م';
          if (h > 12) h -= 12;
        } else if (h == 0) {
          h = 12;
        }
      }
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return timeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(appointmentsProvider);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: appointmentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (data) => LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 1000;
              final isMobile = constraints.maxWidth < 700;
              
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 24, 
                  vertical: isMobile ? 16 : 32
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isMobile),
                    const SizedBox(height: 32),
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildCalendarView(data)),
                          const SizedBox(width: 32),
                          Expanded(flex: 1, child: _buildSidebar(data)),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildCalendarView(data),
                          const SizedBox(height: 32),
                          _buildSidebar(data),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 8),
              const Text(
                'تقويم المواعيد والجدولة',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: secondaryColor),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActionBtn(
                  icon: Icons.add,
                  label: 'جدولة موعد',
                  onPressed: () => AddEditAppointmentModal.show(context),
                  color: secondaryColor,
                  textColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionBtn(
                  icon: Icons.add_task,
                  label: 'زيارة جديدة',
                  onPressed: () => AddEditVisitModal.show(context),
                  color: primaryColor,
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMonthNav(),
          if (_viewMode == ViewMode.day) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => setState(() => _viewMode = ViewMode.month),
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('العودة للتقويم الشهري', style: TextStyle(fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
            ),
          ]
        ],
      );
    }

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 24),
          onPressed: () => context.pop(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Changed to start for better alignment with back button
            children: [
              const Text(
                'تقويم المواعيد والجدولة',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: secondaryColor),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionBtn(
                  icon: Icons.add,
                  label: 'جدولة موعد جديد',
                  onPressed: () => AddEditAppointmentModal.show(context),
                  color: secondaryColor,
                  textColor: Colors.white,
                ),
                const SizedBox(width: 12),
                _buildActionBtn(
                  icon: Icons.add_task,
                  label: 'تسجيل زيارة',
                  onPressed: () => AddEditVisitModal.show(context),
                  color: primaryColor,
                  textColor: Colors.white,
                ),
                const SizedBox(width: 12),
                _buildMonthNav(),
              ],
            ),
            if (_viewMode == ViewMode.day) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => setState(() => _viewMode = ViewMode.month),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('العودة للتقويم الشهري', style: TextStyle(fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
              ),
            ]
          ],
        ),
      ],
    );
  }

  Widget _buildMonthNav() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() {
              if (_viewMode == ViewMode.month) {
                _currentDate = DateTime(_currentDate.year, _currentDate.month - 1);
              } else {
                _selectedDayForView = _selectedDayForView.subtract(const Duration(days: 1));
              }
            }),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.calendar_today, size: 16, color: primaryColor),
          const SizedBox(width: 8),
          Text(
            _viewMode == ViewMode.month
                ? DateFormat('MMMM yyyy', 'ar').format(_currentDate)
                : DateFormat('dd MMMM yyyy', 'ar').format(_selectedDayForView),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() {
              if (_viewMode == ViewMode.month) {
                _currentDate = DateTime(_currentDate.year, _currentDate.month + 1);
              } else {
                _selectedDayForView = _selectedDayForView.add(const Duration(days: 1));
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({required IconData icon, required String label, required VoidCallback onPressed, Color? color, Color? textColor}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 48), // Override global infinite width theme
        backgroundColor: color ?? Colors.white,
        foregroundColor: textColor ?? secondaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
    );
  }

  Widget _buildCalendarView(List<Appointment> data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      clipBehavior: Clip.antiAlias,
      child: _viewMode == ViewMode.month ? _buildMonthGrid(data) : _buildDayDetail(data),
    );
  }

  Widget _buildMonthGrid(List<Appointment> data) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isSmall = screenWidth < 600;
    
    final days = _calculateCalendarDays(_currentDate);
    final dayNames = isSmall 
        ? ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'] // Short Arabic days
        : ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];

    return Column(
      children: [
        Container(
          color: const Color(0xFFF9FAFB),
          padding: EdgeInsets.symmetric(vertical: isSmall ? 8 : 16),
          child: Row(
            children: dayNames
                .map((name) => Expanded(
                      child: Center(
                        child: Text(
                          name, 
                          style: TextStyle(
                            fontWeight: FontWeight.w900, 
                            fontSize: isSmall ? 11 : 13, 
                            color: secondaryColor
                          )
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: isSmall ? 0.65 : 0.8,
          ),
          itemCount: days.length,
          itemBuilder: (context, index) {
            final day = days[index];
            final isSelectedMonth = day.month == _currentDate.month;
            final dayAppointments = data.where((a) => _isSameDay(a.appointmentDate ?? a.createdAt, day)).toList();
            final isToday = _isToday(day);

            return InkWell(
              onTap: isSelectedMonth
                  ? () => setState(() {
                        _selectedDayForView = day;
                        _viewMode = ViewMode.day;
                      })
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFF3F4F6).withValues(alpha: 0.5)),
                  color: isToday ? primaryColor.withValues(alpha: 0.05) : null,
                ),
                padding: EdgeInsets.all(isSmall ? 4 : 8),
                child: Opacity(
                  opacity: isSelectedMonth ? 1.0 : 0.2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            day.day.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: isToday ? (isSmall ? 14 : 18) : (isSmall ? 10 : 12),
                              color: isToday ? primaryColor : Colors.grey[400],
                            ),
                          ),
                          if (isSelectedMonth)
                            IconButton(
                              icon: const Icon(Icons.add, size: 14),
                              onPressed: () => AddEditAppointmentModal.show(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              color: primaryColor,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            children: dayAppointments.take(3).map((a) {
                              final statusColor = _getStatusColor(a.status);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  a.patient?.fullName ?? 'مريض',
                                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: statusColor),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      if (dayAppointments.length > 3)
                        Text('+${dayAppointments.length - 3} مواعيد',
                            style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDayDetail(List<Appointment> data) {
    final dayAppointments = data.where((a) => _isSameDay(a.appointmentDate ?? a.createdAt, _selectedDayForView)).toList();
    dayAppointments.sort((a,b) => (a.appointmentTime ?? '').compareTo(b.appointmentTime ?? ''));

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text('مواعيد اليوم', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  Text('إجمالي ${dayAppointments.length} مواعيد مسجلة', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
              _buildActionBtn(
                icon: Icons.add,
                label: 'إضافة موعد لهذا اليوم',
                onPressed: () => AddEditAppointmentModal.show(context),
                color: primaryColor,
                textColor: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (dayAppointments.isEmpty)
             const Center(
              child: Padding(
                padding: EdgeInsets.all(64),
                child: Text('لا يوجد مواعيد مسجلة لهذا اليوم', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dayAppointments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final a = dayAppointments[index];
                return _buildAppointmentListItem(a);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAppointmentListItem(Appointment a) {
    final statusColor = _getStatusColor(a.status);
    return InkWell(
      onTap: () => AddEditAppointmentModal.show(context, appointment: a),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Row(
          children: [
            Column(
              children: [
                _buildActionBtnSmall(
                  icon: a.status == AppointmentStatus.confirmed ? Icons.check_circle : Icons.check_circle_outline,
                  color: a.status == AppointmentStatus.confirmed ? Colors.green : Colors.white,
                  iconColor: a.status == AppointmentStatus.confirmed ? Colors.white : Colors.grey,
                  onTap: () => _toggleStatus(a),
                ),
                const SizedBox(height: 8),
                _buildActionBtnSmall(
                  icon: Icons.delete_outline,
                  color: Colors.white,
                  iconColor: Colors.red,
                  onTap: () => _deleteAppointment(a.id),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () => context.push('/workspace/${a.patientId}'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Row(
                            children: [
                              Text('ملف المريض', style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.w900)),
                              SizedBox(width: 4),
                              Icon(Icons.person_pin, size: 14, color: primaryColor),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(a.patient?.fullName ?? 'بدون اسم', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(a.statusLabel, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(width: 8),
                      Text(a.patient?.phone ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Center(
                child: Text(
                  _formatTime12h(a.appointmentTime),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: primaryColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtnSmall({required IconData icon, required Color color, required Color iconColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: color == Colors.white ? Border.all(color: Colors.grey[200]!) : null,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
    );
  }

  Widget _buildSidebar(List<Appointment> data) {
    return Column(
      children: [
        _buildSidebarCard(
          title: 'مواعيد يوم ${DateFormat('dd MMM', 'ar').format(_selectedDayForView)}',
          child: _buildDaySummaryList(data),
        ),
        const SizedBox(height: 24),
        _buildSidebarCard(
          title: 'مواعيد قريبة',
          badge: 'خلال 3 أيام',
          child: _buildUpcomingList(data),
        ),
        const SizedBox(height: 24),
        _buildSidebarCard(
          title: 'إحصائيات الشهر',
          child: _buildMonthStats(data),
        ),
      ],
    );
  }

  Widget _buildSidebarCard({required String title, String? badge, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(badge, style: const TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.w900)),
                ),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDaySummaryList(List<Appointment> data) {
    final list = data.where((a) => _isSameDay(a.appointmentDate ?? a.createdAt, _selectedDayForView)).toList();
    if (list.isEmpty) return const Text('لا يوجد مواعيد', style: TextStyle(color: Colors.grey, fontSize: 12));
    
    return Column(
      children: list.map((a) => _buildSimpleItem(a)).toList(),
    );
  }

  Widget _buildUpcomingList(List<Appointment> data) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final limit = today.add(const Duration(days: 4));

    final list = data.where((a) {
      final d = a.appointmentDate ?? a.createdAt;
      return d.isAfter(today) && d.isBefore(limit);
    }).toList();
    list.sort((a,b) => (a.appointmentDate ?? a.createdAt).compareTo(b.appointmentDate ?? b.createdAt));

    if (list.isEmpty) return const Text('لا يوجد مواعيد قريبة', style: TextStyle(color: Colors.grey, fontSize: 12));
    
    return Column(
      children: list.map((a) => _buildSimpleItem(a, showDate: true)).toList(),
    );
  }

  Widget _buildSimpleItem(Appointment a, {bool showDate = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: a.status == AppointmentStatus.confirmed ? Colors.green : Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(a.patient?.fullName ?? 'مريض', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text(
                  '${showDate ? DateFormat('dd MMM', 'ar').format(a.appointmentDate ?? a.createdAt) + ' · ' : ''}${_formatTime12h(a.appointmentTime)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthStats(List<Appointment> data) {
    final total = data.length;
    final confirmed = data.where((a) => a.status == AppointmentStatus.confirmed).length;
    
    return Row(
      children: [
        Expanded(child: _buildStatItem('الإجمالي', total.toString(), secondaryColor)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatItem('المؤكدة', confirmed.toString(), Colors.green)),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed: return Colors.green;
      case AppointmentStatus.cancelled: return Colors.red;
      case AppointmentStatus.completed: return Colors.blue;
      case AppointmentStatus.no_show: return Colors.orange;
      case AppointmentStatus.scheduled: return Colors.blueGrey;
    }
  }

  Future<void> _toggleStatus(Appointment a) async {
    final nextStatus = a.status == AppointmentStatus.confirmed ? AppointmentStatus.scheduled : AppointmentStatus.confirmed;
    await ref.read(appointmentService).updateAppointment(a.id, {'status': nextStatus.name});
    ref.invalidate(appointmentsProvider);
  }

  Future<void> _deleteAppointment(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الموعد'),
        content: const Text('هل أنت متأكد من حذف هذا الموعد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(appointmentService).deleteAppointment(id);
      ref.invalidate(appointmentsProvider);
    }
  }
}
