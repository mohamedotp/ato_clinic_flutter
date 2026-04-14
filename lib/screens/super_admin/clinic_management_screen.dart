import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/super_admin_service.dart';
import '../../models/clinic.dart';

class ClinicManagementScreen extends ConsumerWidget {
  const ClinicManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clinicsAsync = ref.watch(allClinicsProvider);
    const primaryColor = Color(0xFF006D63);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('إدارة العيادات', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: clinicsAsync.when(
        data: (clinics) => _buildClinicsList(context, ref, clinics, primaryColor),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('خطأ: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showClinicModal(context, ref),
        backgroundColor: primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildClinicsList(BuildContext context, WidgetRef ref, List<Clinic> clinics, Color primary) {
    if (clinics.isEmpty) {
      return const Center(child: Text('لا توجد عيادات مسجلة حالياً', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: clinics.length,
      itemBuilder: (context, index) {
        final clinic = clinics[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                          onPressed: () => _showClinicModal(context, ref, clinic: clinic),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                          onPressed: () => _confirmDelete(context, ref, clinic.id),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Text(
                        clinic.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                _infoRow('المعرف', clinic.id.substring(0, 8).toUpperCase()),
                _infoRow('الخطة', clinic.plan == 'pro' ? 'Pro (سنوي)' : 'Starter (شهري)'),
                _infoRow('حالة النظام', clinic.isActive ? 'نشط' : 'متوقف', color: clinic.isActive ? Colors.green : Colors.red),
                if (clinic.subscriptionEndsAt != null)
                  _infoRow('تاريخ الانتهاء', _formatDate(clinic.subscriptionEndsAt!)),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _infoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 8),
          Text('$label:', style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  void _showClinicModal(BuildContext context, WidgetRef ref, {Clinic? clinic}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ClinicFormModal(clinic: clinic),
    ).then((_) => ref.refresh(allClinicsProvider));
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف العيادة', textAlign: TextAlign.right),
        content: const Text('هل أنت متأكد من رغبتك في حذف هذه العيادة نهائياً؟', textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(superAdminServiceProvider).deleteClinic(id);
                ref.refresh(allClinicsProvider);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الحذف: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

class _ClinicFormModal extends ConsumerStatefulWidget {
  final Clinic? clinic;
  const _ClinicFormModal({this.clinic});

  @override
  ConsumerState<_ClinicFormModal> createState() => _ClinicFormModalState();
}

class _ClinicFormModalState extends ConsumerState<_ClinicFormModal> {
  final _nameController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _evolutionController = TextEditingController();
  
  String _plan = 'starter';
  bool _isActive = true;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.clinic != null) {
      _nameController.text = widget.clinic!.name;
      _whatsappController.text = widget.clinic!.whatsappNumber;
      _evolutionController.text = widget.clinic!.evolutionInstance;
      _plan = widget.clinic!.plan;
      _isActive = widget.clinic!.isActive;
      _endDate = widget.clinic!.subscriptionEndsAt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(widget.clinic == null ? 'إضافة عيادة جديدة' : 'تعديل العيادة', 
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                TextField(
                  controller: _nameController,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    labelText: 'اسم العيادة',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _plan,
                  decoration: InputDecoration(
                    labelText: 'باقة الاشتراك',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'starter', child: Text('Starter (شهري)')),
                    DropdownMenuItem(value: 'pro', child: Text('Pro (سنوي)')),
                  ],
                  onChanged: (val) => setState(() => _plan = val ?? 'starter'),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('تاريخ الانتهاء', textAlign: TextAlign.right),
                  subtitle: Text(
                     _endDate != null 
                        ? '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}'
                        : 'لم يحدد',
                     textAlign: TextAlign.right,
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  tileColor: Colors.grey[50],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[300]!)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) setState(() => _endDate = date);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _whatsappController,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    labelText: 'رقم الواتساب (للربط)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _evolutionController,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    labelText: 'Instance Evolution',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('حالة تفعيل العيادة', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold)),
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveClinic,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006D63),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(widget.clinic == null ? 'حفظ وإضافة' : 'تحديث البيانات', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _saveClinic() async {
    if (_nameController.text.trim().isEmpty) return;
    
    setState(() => _isLoading = true);
    
    final payload = {
      'name': _nameController.text.trim(),
      'plan': _plan,
      'is_active': _isActive,
      'subscription_ends_at': _endDate?.toIso8601String(),
      'whatsapp_number': _whatsappController.text.trim(),
      'evolution_instance': _evolutionController.text.trim(),
    };

    try {
      final service = ref.read(superAdminServiceProvider);
      if (widget.clinic != null) {
        await service.updateClinic(widget.clinic!.id, payload);
      } else {
        payload['welcome_msg'] = 'مرحباً بك في عيادتنا';
        payload['holidays'] = [];
        await service.createClinic(payload);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
