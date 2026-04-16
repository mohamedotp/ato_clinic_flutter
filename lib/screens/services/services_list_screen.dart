import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/services_provider.dart';
import '../../models/medical_service.dart';
import '../../providers/auth_provider.dart';

class ServicesListScreen extends ConsumerWidget {
  const ServicesListScreen({super.key});

  void _showAddEditDialog(BuildContext context, WidgetRef ref, [MedicalService? service]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEditServiceBottomSheet(service: service),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(filteredServicesProvider);
    final activeFilter = ref.watch(serviceCategoryFilterProvider);
    const primaryColor = Color(0xFF00302D);
    
    final filters = ['صب الأسنان', 'المختبر والتحاليل', 'الأشعة والتصوير', 'الاستشارات العامة', 'الكل'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('إدارة الخدمات', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              children: filters.reversed.map((f) {
                final isSelected = activeFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: isSelected,
                    onSelected: (val) => ref.read(serviceCategoryFilterProvider.notifier).state = f,
                    selectedColor: primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Services Grid
          Expanded(
            child: servicesAsync.when(
              data: (services) {
                if (services.isEmpty) {
                  return const Center(child: Text('لا توجد خدمات حالياً'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return _ServiceCard(
                      service: service,
                      onEdit: () => _showAddEditDialog(context, ref, service),
                      onDelete: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('حذف الخدمة'),
                            content: const Text('هل أنت متأكد من حذف هذه الخدمة؟'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await ref.read(medicalServiceService).deleteService(service.id);
                          ref.invalidate(servicesProvider);
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('خطأ: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context, ref),
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final MedicalService service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ServiceCard({required this.service, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Image / Icon
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: service.image != null && service.image!.startsWith('http')
                  ? Image.network(service.image!, fit: BoxFit.cover)
                  : const Center(child: Icon(Icons.medical_services_outlined, color: Colors.grey, size: 40)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  service.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '${service.price}ج.م',
                  style: const TextStyle(color: Color(0xFF006D63), fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.blueGrey)),
                        IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent)),
                      ],
                    ),
                    Text(
                      '${service.duration} د',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddEditServiceBottomSheet extends ConsumerStatefulWidget {
  final MedicalService? service;
  const _AddEditServiceBottomSheet({this.service});

  @override
  ConsumerState<_AddEditServiceBottomSheet> createState() => _AddEditServiceBottomSheetState();
}

class _AddEditServiceBottomSheetState extends ConsumerState<_AddEditServiceBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _durationController;
  late TextEditingController _descController;
  late String _category;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service?.name);
    _priceController = TextEditingController(text: widget.service?.price.toString());
    _durationController = TextEditingController(text: widget.service?.duration);
    _descController = TextEditingController(text: widget.service?.description);
    _category = widget.service?.category ?? 'الكل';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authState = ref.read(authProvider);
      if (authState is! AuthAuthenticated) return;
      
      final clinicId = authState.profile?.id;

      final data = {
        'name': _nameController.text,
        'price': double.parse(_priceController.text),
        'duration': _durationController.text,
        'description': _descController.text,
        'category': _category,
        'clinic_id': clinicId, // Placeholder
        'is_active': true,
      };

      if (widget.service != null) {
        await ref.read(medicalServiceService).updateService(widget.service!.id, data);
      } else {
        await ref.read(medicalServiceService).addService(data);
      }

      ref.invalidate(servicesProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 24, right: 24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Text(widget.service != null ? 'تعديل الخدمة' : 'إضافة خدمة جديدة', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              _buildField('اسم الخدمة', _nameController, Icons.medical_services_outlined),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildField('المدة (د)', _durationController, Icons.timer_outlined, TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField('السعر (ج.م)', _priceController, Icons.money, TextInputType.number)),
                ],
              ),
              const SizedBox(height: 20),
              _buildField('الوصف', _descController, Icons.description_outlined, TextInputType.multiline),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00302D), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('حفظ الخدمة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, [TextInputType? type]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          textAlign: TextAlign.right,
          keyboardType: type,
          maxLines: type == TextInputType.multiline ? 3 : 1,
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
