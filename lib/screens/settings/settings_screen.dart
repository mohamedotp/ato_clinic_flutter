import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/clinic_provider.dart';
import '../../models/clinic.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final List<String> _days = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
  bool _isSaving = false;

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
    const primaryColor = Color(0xFF006D63);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('إعدادات العيادة', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: clinicAsync.when(
        data: (clinic) {
          if (clinic == null) return const Center(child: Text('لم يتم العثور على بيانات العيادة'));

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
                
                const Text(
                  'أوقات العمل اليومية',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                ),
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
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
                
                const Text(
                  'أيام العطلات الأسبوعية',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                ),
                const SizedBox(height: 16),
                
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _days.map((day) {
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
                      selectedColor: Colors.redAccent.withOpacity(0.1),
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
                  }).toList(),
                ).reversed.toList().cast<Widget>(), // RTL feel

                const SizedBox(height: 40),
                
                if (_isSaving)
                  const Center(child: CircularProgressIndicator())
                else
                  Container(
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
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
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
              time,
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
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.1)),
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
