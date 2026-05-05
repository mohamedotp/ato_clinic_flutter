import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/clinic_provider.dart';
import '../../models/clinic.dart';
import '../../models/profile.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final List<String> _days = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
  bool _isSaving = false;
  late TextEditingController _clinicNameController;
  late TextEditingController _userNameController;

  @override
  void initState() {
    super.initState();
    _clinicNameController = TextEditingController();
    _userNameController = TextEditingController();
  }

  @override
  void dispose() {
    _clinicNameController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  Future<void> _updateSettings(Clinic currentClinic, Map<String, dynamic> updates) async {
    setState(() => _isSaving = true);
    try {
      await ref.read(clinicServiceProvider).updateClinic(currentClinic.id, updates);
      ref.invalidate(clinicProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الإعدادات بنجاح')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الحفظ: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _updateProfile(String name) async {
    setState(() => _isSaving = true);
    try {
      await ref.read(authProvider.notifier).updateProfile({'full_name': name});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الملف الشخصي')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل التحديث: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _selectTime(BuildContext context, String initialTime, Function(String) onSelected) async {
    final parts = initialTime.split(':');
    final time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    
    final picked = await showTimePicker(
      context: context,
      initialTime: time,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF006D63),
            colorScheme: const ColorScheme.light(primary: Color(0xFF006D63)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      onSelected(formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinicAsync = ref.watch(clinicProvider);
    final authState = ref.watch(authProvider);
    const primaryColor = Color(0xFF006D63);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('الإعدادات العامة', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
      body: clinicAsync.when(
        data: (clinic) {
          if (clinic == null) return const Center(child: Text('لم يتم العثور على بيانات العيادة'));
          
          if (_clinicNameController.text.isEmpty) {
            _clinicNameController.text = clinic.name;
          }
          
          if (authState is AuthAuthenticated && _userNameController.text.isEmpty) {
            _userNameController.text = authState.profile?.fullName ?? '';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Quick Navigation Cards
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        title: 'إدارة الطاقم',
                        icon: Icons.people_outline,
                        color: Colors.indigo,
                        onTap: () => context.push('/settings/users'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ActionCard(
                        title: 'الخدمات الطبية',
                        icon: Icons.medical_services_outlined,
                        color: Colors.teal,
                        onTap: () => context.push('/services'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                _buildSectionHeader('معلومات المركز الطبي'),
                _buildTextField(
                  controller: _clinicNameController,
                  label: 'اسم المركز',
                  onSubmitted: (val) => _updateSettings(clinic, {'name': val}),
                ),
                
                const SizedBox(height: 24),

                // Live Status Section
                _buildSectionHeader('الحالة المباشرة للعيادة'),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: clinic.isOpen ? const Color(0xFFE6F3F1) : Colors.red[50],
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: clinic.isOpen ? const Color(0xFF006D63).withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Switch.adaptive(
                        value: clinic.isOpen,
                        activeThumbColor: const Color(0xFF006D63),
                        activeTrackColor: const Color(0xFF006D63).withValues(alpha: 0.5),
                        onChanged: (val) => _updateSettings(clinic, {'is_open': val}),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            clinic.isOpen ? 'العيادة مفتوحة حالياً' : 'العيادة مغلقة حالياً',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: clinic.isOpen ? const Color(0xFF006D63) : Colors.red,
                            ),
                          ),
                          const Text(
                            'عند الإغلاق، سيتم إخبار المرضى بأن العيادة مغلقة',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        clinic.isOpen ? Icons.check_circle : Icons.do_not_disturb_on,
                        color: clinic.isOpen ? const Color(0xFF006D63) : Colors.red,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // WhatsApp Booking Toggle
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: clinic.whatsappBookingEnabled
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: clinic.whatsappBookingEnabled
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Switch.adaptive(
                        value: clinic.whatsappBookingEnabled,
                        activeThumbColor: Colors.green[700],
                        activeTrackColor: Colors.green.withValues(alpha: 0.4),
                        inactiveThumbColor: Colors.orange[700],
                        inactiveTrackColor: Colors.orange.withValues(alpha: 0.3),
                        onChanged: (val) => _updateSettings(
                            clinic, {'whatsapp_booking_enabled': val}),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            clinic.whatsappBookingEnabled
                                ? 'الحجز عبر واتساب مفعّل'
                                : 'الحجز عند الوصول فقط',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: clinic.whatsappBookingEnabled
                                  ? Colors.green[700]
                                  : Colors.orange[800],
                            ),
                          ),
                          Text(
                            clinic.whatsappBookingEnabled
                                ? ' يقبل الحجز من واتساب'
                                : ' يطلب الحضور للعيادة',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        clinic.whatsappBookingEnabled
                            ? Icons.chat
                            : Icons.location_on_outlined,
                        color: clinic.whatsappBookingEnabled
                            ? Colors.green[700]
                            : Colors.orange[700],
                        size: 28,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Doctor Availability Section
                _buildSectionHeader('تواجد الأطباء الآن'),
                ref.watch(clinicDoctorsProvider).when(
                  data: (doctors) {
                    if (doctors.isEmpty) {
                      return const Center(child: Text('لا يوجد أطباء مسجلين حالياً', style: TextStyle(color: Colors.grey)));
                    }
                    return Column(
                      children: doctors.map((doc) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5)],
                        ),
                        child: Row(
                          children: [
                            Switch.adaptive(
                              value: doc['is_available'] ?? false,
                              activeThumbColor: const Color(0xFF006D63),
                              activeTrackColor: const Color(0xFF006D63).withValues(alpha: 0.5),
                              onChanged: (val) async {
                                try {
                                  await ref.read(clinicServiceProvider).updateDoctorAvailability(doc['id'] as String, val);
                                  ref.invalidate(clinicDoctorsProvider);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                                  }
                                }
                              },
                            ),
                            const Spacer(),
                            Text(
                              doc['full_name'] ?? 'طبيب',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 12),
                            const CircleAvatar(
                              radius: 15,
                              backgroundColor: Color(0xFFF0F4F3),
                              child: Icon(Icons.person, size: 18, color: Color(0xFF006D63)),
                            ),
                          ],
                        ),
                      )).toList(),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (err, stack) => const Text('فشل تحميل قائمة الأطباء'),
                ),
                
                const SizedBox(height: 32),
                
                _buildSectionHeader('الملف الشخصي'),
                _buildTextField(
                  controller: _userNameController,
                  label: 'اسم الطبيب المسئول',
                  onSubmitted: (val) => _updateProfile(val),
                ),
                
                const SizedBox(height: 32),
                
                _buildSectionHeader('أوقات العمل اليومية'),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      _buildTimeTile(
                        context,
                        'وقت الفتح',
                        clinic.openTime,
                        Icons.login,
                        (newTime) => _updateSettings(clinic, {'open_time': newTime}),
                      ),
                      const Divider(height: 32),
                      _buildTimeTile(
                        context,
                        'وقت الإغلاق',
                        clinic.closeTime,
                        Icons.logout,
                        (newTime) => _updateSettings(clinic, {'close_time': newTime}),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                _buildSectionHeader('أيام العطلات الأسبوعية'),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: clinic.holidays.isNotEmpty || _days.isNotEmpty 
                    ? _days.map((day) {
                        final isHoliday = clinic.holidays.contains(day);
                        return FilterChip(
                          label: Text(day),
                          selected: isHoliday,
                          onSelected: (selected) {
                            final newHolidays = List<String>.from(clinic.holidays);
                            if (selected) {
                              newHolidays.add(day);
                            } else {
                              newHolidays.remove(day);
                            }
                            _updateSettings(clinic, {'holidays': newHolidays});
                          },
                          selectedColor: Colors.redAccent.withValues(alpha: 0.1),
                          checkmarkColor: Colors.redAccent,
                          labelStyle: TextStyle(
                            color: isHoliday ? Colors.redAccent : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: isHoliday ? Colors.redAccent : Colors.grey[200]!),
                          ),
                        );
                      }).toList()
                    : [],
                ),

                const SizedBox(height: 40),
                
                const SizedBox(height: 40),
                
                // Exit Clinic Context (For Super Admins)
                if (authState is AuthAuthenticated && authState.profile?.role == UserRole.super_admin)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ref.read(authProvider.notifier).exitClinicContext();
                          context.go('/super-admin');
                        },
                        icon: const Icon(Icons.admin_panel_settings, color: primaryColor),
                        label: const Text('العودة للإدارة العامة', 
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: primaryColor, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('تسجيل الخروج', textAlign: TextAlign.right),
                          content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج الآن؟', textAlign: TextAlign.right),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true), 
                              child: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await ref.read(authProvider.notifier).signOut();
                      }
                    },
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text('تسجيل الخروج', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF006D63)),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required Function(String) onSubmitted}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 5)],
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          suffixIcon: const Icon(Icons.edit, size: 18, color: Colors.grey),
        ),
        onSubmitted: onSubmitted,
      ),
    );
  }

  // ignore: unused_element
  Widget _buildAIInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber[100]!),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'هذه الإعدادات تستخدم بواسطة مساعد العيادة الذكي للرد على استفسارات المرضى حول المواعيد المتاحة.',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime12Hour(String time24) {
    if (time24.isEmpty) return '';
    final parts = time24.split(':');
    if (parts.length < 2) return time24;
    int hour = int.tryParse(parts[0]) ?? 0;
    int minute = int.tryParse(parts[1]) ?? 0;
    String amPm = hour >= 12 ? 'مساءً' : 'صباحاً';
    int hour12 = hour % 12;
    if (hour12 == 0) hour12 = 12;
    return '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $amPm';
  }

  Widget _buildTimeTile(BuildContext context, String label, String time, IconData icon, Function(String) onUpdate) {
    return InkWell(
      onTap: () => _selectTime(context, time, onUpdate),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.arrow_back_ios, size: 14, color: Colors.grey),
            const Spacer(),
            Text(
              _formatTime12Hour(time),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF00302D)),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Icon(icon, size: 18, color: const Color(0xFF006D63)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
