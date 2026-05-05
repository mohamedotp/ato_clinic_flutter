import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/super_admin_service.dart';

class ServiceActivationScreen extends ConsumerStatefulWidget {
  const ServiceActivationScreen({super.key});

  @override
  ConsumerState<ServiceActivationScreen> createState() => _ServiceActivationScreenState();
}

class _ServiceActivationScreenState extends ConsumerState<ServiceActivationScreen> {
  static const primaryColor = Color(0xFF006D63);
  static const darkBg = Color(0xFF00302D);

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(smartServicesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('تفعيل الخدمات الذكية', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.settings, size: 18),
              label: const Text('الربط التقني'),
              style: ElevatedButton.styleFrom(
                backgroundColor: darkBg,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'تحكم في تفعيل الميزات المتقدمة وتطبيقات الذكاء الاصطناعي لشبكة العيادات بالكامل.',
                style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Services grid
              servicesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: primaryColor)),
                error: (err, _) => Center(child: Text('خطأ: $err')),
                data: (services) {
                  if (services.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Center(
                        child: Text(
                          'لا توجد خدمات ذكية مسجلة في قاعدة البيانات.\nيمكنك إضافتها من خلال قاعدة البيانات مباشرة.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: services.length,
                    itemBuilder: (context, i) => _buildServiceCard(services[i]),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Global stats banner
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: darkBg,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('٩٩.٩٪', 'وقت التشغيل (Uptime)', const Color(0xFF75E6DA)),
                        _buildStatItem('٤٨ ألف', 'طلب API / اليوم', Colors.white),
                        _buildStatItem('٣٢٤', 'تنبيهات أمنية محجوبة', const Color(0xFFF06E4A)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withOpacity(0.2)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('تحميل شهادة الأمان', style: TextStyle(fontSize: 12)),
                          ),
                          const Text(
                            'جميع الميزات محمية بتشفير من طرف إلى طرف ومعايير HIPAA',
                            style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color valueColor) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: valueColor)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold)),
      ],
    );
  }

  IconData _getIcon(String? iconName) {
    if (iconName == null) return Icons.smart_toy_outlined;
    if (iconName.contains('storage')) return Icons.storage_outlined;
    if (iconName.contains('bolt')) return Icons.bolt_outlined;
    if (iconName.contains('psychology')) return Icons.psychology_outlined;
    return Icons.smart_toy_outlined;
  }

  Color _getColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.green;
    try {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return Colors.green;
    }
  }

  Widget _buildServiceCard(Map<String, dynamic> s) {
    final isActive = (s['status'] ?? false) as bool;
    final color = _getColor(s['color_hex']?.toString());
    final icon = _getIcon(s['icon_name']?.toString());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isActive ? Colors.green.shade100 : Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isActive ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isActive ? 'مفعل' : 'متوقف',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.green[700] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'مفعل لدى ${s['active_count'] ?? 0}',
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            s['name']?.toString() ?? '',
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF00302D)),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              s['description']?.toString() ?? '',
              textAlign: TextAlign.right,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Colors.grey[500], height: 1.5),
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () async {
                  try {
                    await ref.read(superAdminServiceProvider).toggleSmartService(s['id'], !isActive);
                    ref.refresh(smartServicesProvider);
                  } catch(e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.red.shade500 : Colors.green.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'تعطيل' : 'تفعيل',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'إعدادات',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
