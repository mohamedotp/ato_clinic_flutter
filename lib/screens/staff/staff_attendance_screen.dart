import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/staff_provider.dart';
import '../../models/profile.dart';
import '../../models/staff_attendance.dart';

class StaffAttendanceScreen extends ConsumerStatefulWidget {
  const StaffAttendanceScreen({super.key});

  @override
  ConsumerState<StaffAttendanceScreen> createState() => _StaffAttendanceScreenState();
}

class _StaffAttendanceScreenState extends ConsumerState<StaffAttendanceScreen>
    with SingleTickerProviderStateMixin {
  static const primaryColor = Color(0xFF006D63);
  bool _isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _isAdmin ? 2 : 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _clinicId {
    final auth = ref.read(authProvider);
    return auth is AuthAuthenticated ? (auth.profile?.clinicId ?? '') : '';
  }

  String get _profileId {
    final auth = ref.read(authProvider);
    return auth is AuthAuthenticated ? (auth.profile?.id ?? '') : '';
  }

  bool get _isAdmin {
    final auth = ref.read(authProvider);
    if (auth is AuthAuthenticated) {
      return auth.profile?.role == UserRole.admin ||
          auth.profile?.role == UserRole.super_admin;
    }
    return false;
  }

  String _formatDuration(DateTime checkIn, DateTime? checkOut) {
    final end = checkOut ?? DateTime.now();
    final dur = end.difference(checkIn);
    final hours = dur.inHours;
    final mins = dur.inMinutes % 60;
    return '${hours}س ${mins}د';
  }

  @override
  Widget build(BuildContext context) {
    if (_clinicId.isEmpty || _profileId.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final args = (clinicId: _clinicId, profileId: _profileId);
    final todayAsync = ref.watch(todayAttendanceProvider(args));
    final historyArgs = (clinicId: _clinicId, profileId: _isAdmin ? null : _profileId);
    final historyAsync = ref.watch(attendanceHistoryProvider(historyArgs));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('الحضور والانصراف', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: _isAdmin
            ? TabBar(
                controller: _tabController,
                labelColor: primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: primaryColor,
                tabs: const [
                  Tab(text: 'حضوري'),
                  Tab(text: 'سجل الفريق'),
                ],
              )
            : null,
      ),
      body: _isAdmin
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildMyAttendance(todayAsync, historyArgs),
                _buildTeamOverview(historyAsync),
              ],
            )
          : _buildMyAttendance(todayAsync, historyArgs),
    );
  }

  Widget _buildMyAttendance(
    AsyncValue<StaffAttendance?> todayAsync,
    ({String clinicId, String? profileId}) historyArgs,
  ) {
    final historyAsync = ref.watch(attendanceHistoryProvider(
        (clinicId: _clinicId, profileId: _profileId)));

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: todayAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('خطأ: $e')),
              data: (attendance) {
                final isCheckedIn = attendance != null;
                final isCheckedOut = attendance?.checkOut != null;

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isCheckedOut
                              ? [Colors.grey.shade700, Colors.grey.shade900]
                              : isCheckedIn
                                  ? [const Color(0xFF006D63), const Color(0xFF004D40)]
                                  : [const Color(0xFF1976D2), const Color(0xFF0D47A1)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: (isCheckedOut
                                    ? Colors.grey
                                    : isCheckedIn
                                        ? primaryColor
                                        : Colors.blue)
                                .withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            isCheckedOut
                                ? Icons.home
                                : isCheckedIn
                                    ? Icons.work
                                    : Icons.fingerprint,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isCheckedOut
                                ? 'تم الانصراف اليوم'
                                : isCheckedIn
                                    ? 'أنت الآن في العمل'
                                    : 'لم يتم تسجيل الحضور',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                          if (isCheckedIn) ...[
                            const SizedBox(height: 8),
                            Text(
                              'وقت الحضور: ${DateFormat('hh:mm a').format(attendance.checkIn)}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            if (isCheckedOut)
                              Text(
                                'وقت الانصراف: ${DateFormat('hh:mm a').format(attendance.checkOut!)}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'مدة العمل: ${_formatDuration(attendance.checkIn, attendance.checkOut)}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          if (!isCheckedOut)
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => _toggleAttendance(
                                        isCheckedIn, attendance?.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      isCheckedIn ? Colors.redAccent : Colors.white,
                                  foregroundColor: isCheckedIn
                                      ? Colors.white
                                      : Colors.blue.shade800,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white)
                                    : Text(
                                        isCheckedIn
                                            ? 'تسجيل انصراف'
                                            : 'تسجيل حضور',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                              ),
                            ),
                        ],
                      ),
                    ).animate().fade().slideY(begin: -0.2),
                  ],
                );
              },
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text('سجل حضوري',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ),
        historyAsync.when(
          loading: () =>
              const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
          error: (e, _) =>
              SliverToBoxAdapter(child: Center(child: Text('خطأ: $e'))),
          data: (history) {
            if (history.isEmpty) {
              return const SliverToBoxAdapter(
                child: Center(
                    child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('لا يوجد سجل حضور'))),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildHistoryItem(history[index]),
                childCount: history.length,
              ),
            );
          },
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
      ],
    );
  }

  Widget _buildTeamOverview(AsyncValue<List<StaffAttendance>> historyAsync) {
    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (history) {
        // Group by employee - use profileId as key since we don't have name in model
        // We'll fetch staff members to get names
        return Consumer(builder: (context, ref, _) {
          final staffAsync = ref.watch(staffMembersProvider);
          return staffAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('خطأ: $e')),
            data: (staff) {
              final nameMap = {for (var s in staff) s.id: s.fullName};
              // Group by profileId
              final Map<String, List<StaffAttendance>> grouped = {};
              for (var h in history) {
                grouped.putIfAbsent(h.profileId, () => []).add(h);
              }

              if (grouped.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('لا يوجد سجل حضور للفريق',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(attendanceHistoryProvider),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: grouped.entries.map((entry) {
                    final name = nameMap[entry.key] ?? 'موظف';
                    final records = entry.value;
                    final todayRecord = records.firstWhere(
                      (r) {
                        final now = DateTime.now();
                        return r.checkIn.year == now.year &&
                            r.checkIn.month == now.month &&
                            r.checkIn.day == now.day;
                      },
                      orElse: () => records.first,
                    );
                    final isCheckedInToday = records.any((r) {
                      final now = DateTime.now();
                      return r.checkIn.year == now.year &&
                          r.checkIn.month == now.month &&
                          r.checkIn.day == now.day;
                    });

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: isCheckedInToday
                                ? primaryColor.withValues(alpha: 0.1)
                                : Colors.grey.shade100,
                            child: Icon(
                              isCheckedInToday ? Icons.person : Icons.person_off,
                              color: isCheckedInToday ? primaryColor : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 4),
                                Text(
                                  isCheckedInToday
                                      ? 'حضر اليوم - ${DateFormat('hh:mm a').format(todayRecord.checkIn)}'
                                      : 'لم يسجل حضور اليوم',
                                  style: TextStyle(
                                    color: isCheckedInToday
                                        ? Colors.green
                                        : Colors.red.shade300,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'إجمالي الأيام: ${records.length} يوم',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isCheckedInToday
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isCheckedInToday ? 'حاضر' : 'غائب',
                              style: TextStyle(
                                color: isCheckedInToday ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fade().slideX(begin: 0.1);
                  }).toList(),
                ),
              );
            },
          );
        });
      },
    );
  }

  Widget _buildHistoryItem(StaffAttendance h) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: h.checkOut != null
                  ? Colors.grey.shade100
                  : primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              h.checkOut != null ? Icons.check_circle : Icons.timelapse,
              color: h.checkOut != null ? Colors.grey : primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE، dd MMM yyyy', 'ar').format(h.checkIn),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'دخول: ${DateFormat('hh:mm a').format(h.checkIn)}' +
                      (h.checkOut != null
                          ? ' | خروج: ${DateFormat('hh:mm a').format(h.checkOut!)}'
                          : ' | لم يُسجَّل الانصراف'),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            _formatDuration(h.checkIn, h.checkOut),
            style: TextStyle(
              color: h.checkOut != null ? primaryColor : Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ).animate().fade().slideX(begin: 0.1);
  }

  Future<void> _toggleAttendance(bool isCheckedIn, String? attendanceId) async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(staffServiceProvider);
      if (isCheckedIn && attendanceId != null) {
        await service.checkOut(attendanceId);
      } else {
        await service.checkIn(_clinicId, _profileId);
      }
      ref.invalidate(todayAttendanceProvider);
      ref.invalidate(attendanceHistoryProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
