import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/staff_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/profile.dart';

class UsersListScreen extends ConsumerWidget {
  const UsersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffMembersProvider);
    final authState = ref.watch(authProvider);
    
    final isAdmin = authState is AuthAuthenticated && 
        (authState.profile?.role == UserRole.admin || authState.profile?.role == UserRole.super_admin);
    
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
            final authState = ref.watch(authProvider);
            final isSuperAdmin = authState is AuthAuthenticated && authState.profile?.role == UserRole.super_admin;
            final hasClinic = authState is AuthAuthenticated && authState.profile?.clinicId != null;

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    !hasClinic && isSuperAdmin 
                        ? 'يرجى اختيار عيادة لعرض طاقم العمل' 
                        : 'لا يوجد أعضاء في الطاقم حالياً',
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
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
                    if (isAdmin) ...[
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => _AddStaffBottomSheet(member: member),
                          );
                        },
                      ),
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
                    ],
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
      floatingActionButton: isAdmin ? FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const _AddStaffBottomSheet(),
          );
        },
        backgroundColor: primaryColor,
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        label: const Text('إضافة عضو', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ) : null,
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

class _AddStaffBottomSheet extends ConsumerStatefulWidget {
  final Profile? member;
  const _AddStaffBottomSheet({this.member});

  @override
  ConsumerState<_AddStaffBottomSheet> createState() => _AddStaffBottomSheetState();
}

class _AddStaffBottomSheetState extends ConsumerState<_AddStaffBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late UserRole _selectedRole;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member?.fullName ?? '');
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _selectedRole = widget.member?.role ?? UserRole.doctor;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authState = ref.read(authProvider);
      if (authState is! AuthAuthenticated) return;
      
      final clinicId = authState.profile?.clinicId;
      if (clinicId == null) throw Exception('No clinic ID found');

      if (widget.member != null) {
        // Edit existing member
        final data = {
          'full_name': _nameController.text,
          'role': _selectedRole.name,
        };
        await ref.read(staffServiceProvider).updateStaffMember(widget.member!.id, data);
      } else {
        // Add new member
        final data = {
          'full_name': _nameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'role': _selectedRole.name,
          'clinic_id': clinicId,
        };
        await ref.read(staffServiceProvider).addStaffMember(data);
      }

      ref.invalidate(staffMembersProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.member != null ? 'تم تعديل البيانات بنجاح' : 'تمت إضافة العضو بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains('Exception:')) {
          errorMsg = errorMsg.replaceFirst('Exception: ', '');
        }
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('خطأ', style: TextStyle(color: Colors.red)),
            content: Text(errorMsg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.member != null;
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isEditing ? 'تعديل بيانات العضو' : 'إضافة عضو جديد للطاقم',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              _buildField('الاسم الكامل', _nameController, Icons.person_outline),
              if (!isEditing) ...[
                const SizedBox(height: 20),
                _buildField('البريد الإلكتروني', _emailController, Icons.email_outlined, TextInputType.emailAddress),
                const SizedBox(height: 20),
                _buildField('كلمة المرور المؤقتة', _passwordController, Icons.lock_outline, null, true),
              ],
              const SizedBox(height: 24),
              const Text('الدور الوظيفي', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _roleChip(UserRole.receptionist, 'سكرتارية'),
                  const SizedBox(width: 8),
                  _roleChip(UserRole.doctor, 'طبيب'),
                  const SizedBox(width: 8),
                  _roleChip(UserRole.admin, 'مدير'),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00302D),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isEditing ? 'حفظ التعديلات' : 'إضافة العضو الآن', 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleChip(UserRole role, String label) {
    final isSelected = _selectedRole == role;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedRole = role);
      },
      selectedColor: const Color(0xFF006D63).withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF006D63) : Colors.black54,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, [TextInputType? type, bool isPassword = false]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          textAlign: TextAlign.right,
          keyboardType: type,
          obscureText: isPassword,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
          validator: (val) => val == null || val.isEmpty ? 'هذا الحقل مطلوب' : null,
        ),
      ],
    );
  }
}

