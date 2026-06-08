import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/staff_provider.dart';
import '../../models/profile.dart';
import '../../models/staff_task.dart';

class StaffTasksScreen extends ConsumerStatefulWidget {
  const StaffTasksScreen({super.key});

  @override
  ConsumerState<StaffTasksScreen> createState() => _StaffTasksScreenState();
}

class _StaffTasksScreenState extends ConsumerState<StaffTasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const primaryColor = Color(0xFF006D63);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

  @override
  Widget build(BuildContext context) {
    if (_clinicId.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final args = (
      clinicId: _clinicId,
      assignedTo: _isAdmin ? null : _profileId,
      status: null
    );
    final tasksAsync = ref.watch(staffTasksProvider(args));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('إدارة المهام', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.add_task, color: primaryColor),
              onPressed: () => _showAddTaskSheet(context),
              tooltip: 'إضافة مهمة',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryColor,
          tabs: const [
            Tab(text: 'قيد الانتظار'),
            Tab(text: 'جارٍ العمل'),
            Tab(text: 'مكتملة'),
          ],
        ),
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text('خطأ: $e', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(staffTasksProvider(args)),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
        data: (tasks) {
          final pending = tasks.where((t) => t.status == 'pending').toList();
          final inProgress = tasks.where((t) => t.status == 'in_progress').toList();
          final completed = tasks.where((t) => t.status == 'completed').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTaskList(pending, args),
              _buildTaskList(inProgress, args),
              _buildTaskList(completed, args),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTaskList(List<StaffTask> tasks, dynamic args) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('لا توجد مهام في هذا القسم',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(staffTasksProvider(args)),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: tasks.length,
        itemBuilder: (context, i) => _buildTaskCard(tasks[i], args),
      ),
    );
  }

  Widget _buildTaskCard(StaffTask t, dynamic args) {
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    if (t.status == 'pending') {
      statusColor = Colors.orange;
      statusIcon = Icons.hourglass_empty;
      statusLabel = 'قيد الانتظار';
    } else if (t.status == 'in_progress') {
      statusColor = Colors.blue;
      statusIcon = Icons.sync;
      statusLabel = 'جارٍ العمل';
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusLabel = 'مكتملة';
    }

    final isOverdue = t.dueDate != null &&
        t.dueDate!.isBefore(DateTime.now()) &&
        t.status != 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOverdue ? Colors.red.shade200 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(statusLabel,
                        style: TextStyle(color: statusColor, fontSize: 12)),
                  ],
                ),
              ),
              if (_isAdmin)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (value) async {
                    if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('حذف المهمة'),
                          content: const Text('هل أنت متأكد من حذف هذه المهمة؟'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('إلغاء')),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white),
                              child: const Text('حذف'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref.read(staffServiceProvider).deleteTask(t.id);
                        ref.invalidate(staffTasksProvider(args));
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('حذف', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (t.description != null && t.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(t.description!,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (_isAdmin && t.assignedToName != null)
                _Chip(
                  icon: Icons.person,
                  label: t.assignedToName!,
                  color: primaryColor,
                ),
              _Chip(
                icon: Icons.calendar_today,
                label: DateFormat('dd MMM yyyy').format(t.createdAt),
                color: Colors.grey,
              ),
              if (t.dueDate != null)
                _Chip(
                  icon: isOverdue ? Icons.warning_amber : Icons.schedule,
                  label: 'موعد التسليم: ${DateFormat('dd MMM').format(t.dueDate!)}',
                  color: isOverdue ? Colors.red : Colors.orange,
                ),
            ],
          ),
          if (t.status != 'completed') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final newStatus =
                      t.status == 'pending' ? 'in_progress' : 'completed';
                  await ref
                      .read(staffServiceProvider)
                      .updateTaskStatus(t.id, newStatus);
                  ref.invalidate(staffTasksProvider(args));
                },
                icon: Icon(
                  t.status == 'pending' ? Icons.play_arrow : Icons.check,
                  size: 18,
                ),
                label: Text(
                  t.status == 'pending' ? 'ابدأ العمل' : 'إكمال المهمة',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.status == 'pending' ? Colors.blue : Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fade().slideY(begin: 0.1);
  }

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTaskSheet(
        clinicId: _clinicId,
        createdBy: _profileId,
        onSaved: () {
          final args = (
            clinicId: _clinicId,
            assignedTo: null,
            status: null,
          );
          ref.invalidate(staffTasksProvider(args));
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}

class _AddTaskSheet extends ConsumerStatefulWidget {
  final String clinicId;
  final String createdBy;
  final VoidCallback onSaved;

  const _AddTaskSheet({
    required this.clinicId,
    required this.createdBy,
    required this.onSaved,
  });

  @override
  ConsumerState<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<_AddTaskSheet> {
  static const primaryColor = Color(0xFF006D63);
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _selectedStaffId;
  DateTime? _dueDate;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffMembersProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('إضافة مهمة جديدة',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: 'عنوان المهمة *',
                hintText: 'أدخل عنوان المهمة...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16)),
                prefixIcon: const Icon(Icons.task_alt, color: primaryColor),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'العنوان مطلوب' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'التفاصيل (اختياري)',
                hintText: 'وصف المهمة...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16)),
                prefixIcon: const Icon(Icons.description_outlined,
                    color: primaryColor),
              ),
            ),
            const SizedBox(height: 16),
            staffAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('خطأ في تحميل الموظفين: $e'),
              data: (staff) => DropdownButtonFormField<String>(
                value: _selectedStaffId,
                decoration: InputDecoration(
                  labelText: 'تكليف إلى *',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16)),
                  prefixIcon: const Icon(Icons.person_outline,
                      color: primaryColor),
                ),
                items: staff.map((p) {
                  return DropdownMenuItem(
                    value: p.id,
                    child: Text(p.fullName),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedStaffId = v),
                validator: (v) => v == null ? 'يرجى اختيار موظف' : null,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  locale: const Locale('ar'),
                  helpText: 'اختر موعد التسليم',
                );
                if (date != null) setState(() => _dueDate = date);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: primaryColor),
                    const SizedBox(width: 12),
                    Text(
                      _dueDate == null
                          ? 'موعد التسليم (اختياري)'
                          : 'التسليم: ${DateFormat('dd MMM yyyy').format(_dueDate!)}',
                      style: TextStyle(
                        color: _dueDate == null ? Colors.grey : Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    if (_dueDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _dueDate = null),
                        child: const Icon(Icons.close, size: 18, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: const Text('حفظ المهمة',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(staffServiceProvider).createTask({
        'clinic_id': widget.clinicId,
        'assigned_to': _selectedStaffId,
        'created_by': widget.createdBy,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        'status': 'pending',
        'due_date': _dueDate?.toIso8601String(),
      });
      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إضافة المهمة بنجاح'),
            backgroundColor: Color(0xFF006D63),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
