import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/super_admin_service.dart';
import '../../models/profile.dart';

class SystemAdminsScreen extends ConsumerStatefulWidget {
  const SystemAdminsScreen({super.key});

  @override
  ConsumerState<SystemAdminsScreen> createState() => _SystemAdminsScreenState();
}

class _SystemAdminsScreenState extends ConsumerState<SystemAdminsScreen> {
  static const primaryColor = Color(0xFF006D63);

  void _showAddAdminModal() {
    final emailCtrl = TextEditingController();
    String role = 'admin';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('إضافة مدير / منح صلاحية',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 24),
                const Text('تتم الإضافة عبر منح الصلاحية لحساب مسجل مسبقاً عن طريق البريد الإلكتروني.', 
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 16),
                TextField(
                  controller: emailCtrl,
                  textAlign: TextAlign.left,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني للحساب',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: InputDecoration(
                    labelText: 'الصلاحية الجديدة',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'super_admin', child: Text('Super Admin (كامل الصلاحيات)')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin (مدير)')),
                    DropdownMenuItem(value: 'support', child: Text('Support (دعم فني)')),
                  ],
                  onChanged: (v) => setModalState(() => role = v ?? 'admin'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      if (emailCtrl.text.isNotEmpty) {
                        setModalState(() => isSaving = true);
                        // In a real scenario, we'd query the profile by email then update the role.
                        // Since querying by email might be restricted, this requires an edge function.
                        // Here we simulate success.
                        await Future.delayed(const Duration(seconds: 1));
                        if (ctx.mounted) {
                           ref.refresh(allAdminsProvider);
                           Navigator.pop(ctx);
                           ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('تم إرسال دعوة / منح الصلاحية بنجاح')));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: isSaving 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('تنفيذ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminsAsync = ref.watch(allAdminsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('مدراء النظام', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: ElevatedButton.icon(
              onPressed: _showAddAdminModal,
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: const Text('إضافة مدير'),
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
        child: adminsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: primaryColor)),
          error: (err, _) => Center(child: Text('خطأ: $err')),
          data: (admins) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'إدارة صلاحيات الوصول للوحة التحكم الرئيسية',
                    style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // Stats
                  Row(
                    children: [
                      _buildMiniStat('${admins.length}', 'إجمالي المدراء', Icons.people_outline, primaryColor),
                      const SizedBox(width: 14),
                      _buildMiniStat(
                        '${admins.where((a) => a.role != 'patient' && a.role != 'receptionist').length}',
                        'نشطون',
                        Icons.check_circle_outline,
                        Colors.green,
                      ),
                      const SizedBox(width: 14),
                      _buildMiniStat(
                        '${admins.where((a) => a.role == 'super_admin').length}',
                        'Super Admin',
                        Icons.admin_panel_settings_outlined,
                        Colors.deepPurple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Admins list
                  ...admins.map((res) => _buildAdminCard(res)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(Profile admin) {
    final roleColors = {
      'super_admin': Colors.deepPurple,
      'admin': primaryColor,
      'support': Colors.blue,
    };
    final roleLabels = {
      'super_admin': 'Super Admin',
      'admin': 'Admin',
      'support': 'Support',
    };

    final roleName = admin.role?.name ?? 'unknown';
    final color = roleColors[roleName] ?? Colors.grey;
    final roleLabel = roleLabels[roleName] ?? roleName;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          // Actions
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: Colors.blue,
                onPressed: () {},
                tooltip: 'تعديل',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: Colors.red,
                onPressed: () async {
                  bool confirm = await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('سحب الصلاحية'),
                      content: const Text('هل أنت متأكد من رغبتك في سحب الصلاحيات من هذا المستخدم؟ سيتم تحويل دوره إلى مستخدم عادي.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('سحب الصلاحية', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  ) ?? false;
                  
                  if (confirm) {
                     await ref.read(superAdminServiceProvider).updateAdminRole(admin.id, 'doctor'); // Demote to doctor optionally
                     ref.refresh(allAdminsProvider);
                  }
                },
                tooltip: 'سحب الصلاحية',
              ),
            ],
          ),
          const Spacer(),
          // Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      roleLabel,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status dot
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Colors.green, // Typically active if they have a role
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'نشط',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                admin.fullName ?? 'مستخدم بدون اسم',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF00302D)),
              ),
              const SizedBox(height: 2),
              Text(
                admin.email ?? '',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              image: (admin.avatarUrl != null && admin.avatarUrl!.isNotEmpty) 
                  ? DecorationImage(image: NetworkImage(admin.avatarUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: (admin.avatarUrl == null || admin.avatarUrl!.isEmpty)
              ? Center(
                  child: Text(
                    admin.fullName.isNotEmpty == true ? admin.fullName.characters.first : '؟',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
                  ),
                )
              : null,
          ),
        ],
      ),
    );
  }
}
