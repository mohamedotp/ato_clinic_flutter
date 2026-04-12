import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/staff_provider.dart';
import '../../models/profile.dart';

class UsersListScreen extends ConsumerWidget {
  const UsersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffMembersProvider);
    const primaryColor = Color(0xFF006D63);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('إدارة طاقم العمل', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: staffAsync.when(
        data: (staff) {
          if (staff.isEmpty) {
            return const Center(child: Text('لا يوجد أعضاء في الطاقم حالياً'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: staff.length,
            itemBuilder: (context, index) {
              final member = staff[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('إزالة العضو'),
                            content: Text('هل أنت متأكد من إزالة ${member.fullName} من طاقم العيادة؟'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('إزالة', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await ref.read(staffServiceProvider).removeStaffMember(member.id);
                          ref.invalidate(staffMembersProvider);
                        }
                      },
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          member.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getRoleColor(member.role).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getRoleName(member.role),
                            style: TextStyle(
                              color: _getRoleColor(member.role),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
                      child: member.avatarUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ميزة دعوة الأعضاء ستكون متاحة قريباً')),
          );
        },
        backgroundColor: primaryColor,
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        label: const Text('إضافة عضو', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  String _getRoleName(UserRole? role) {
    switch (role) {
      case UserRole.admin: return 'مدير النظام';
      case UserRole.doctor: return 'طبيب';
      case UserRole.receptionist: return 'سكرتارية';
      case UserRole.super_admin: return 'مدير عام';
      default: return 'عضو';
    }
  }

  Color _getRoleColor(UserRole? role) {
    switch (role) {
      case UserRole.admin: return Colors.orange;
      case UserRole.doctor: return const Color(0xFF006D63);
      case UserRole.receptionist: return Colors.blue;
      case UserRole.super_admin: return Colors.purple;
      default: return Colors.grey;
    }
  }
}
