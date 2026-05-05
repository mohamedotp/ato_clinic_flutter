import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/super_admin_service.dart';
import '../../models/clinic.dart';

class ClinicSelectorScreen extends ConsumerStatefulWidget {
  const ClinicSelectorScreen({super.key});

  @override
  ConsumerState<ClinicSelectorScreen> createState() => _ClinicSelectorScreenState();
}

class _ClinicSelectorScreenState extends ConsumerState<ClinicSelectorScreen> {
  static const primaryColor = Color(0xFF006D63);
  static const darkBg = Color(0xFF00302D);
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final clinicsAsync = ref.watch(allClinicsProvider);
    final authState = ref.watch(authProvider);
    final profile = authState is AuthAuthenticated ? authState.profile : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            children: [
              // Navbar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logout button
                    IconButton(
                      icon: const Icon(Icons.logout_outlined, color: Colors.grey),
                      tooltip: 'تسجيل الخروج',
                      onPressed: () => ref.read(authProvider.notifier).signOut(),
                    ),
                    // Profile info
                    if (profile != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            profile.fullName ?? 'سوبر أدمن',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF00302D)),
                          ),
                          Text(
                            profile.email ?? '',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    // Logo
                    Row(
                      children: [
                        const Text(
                          'عياداتي',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF00302D)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                  child: Column(
                    children: [
                      // Header text
                      const Text(
                        'أهلاً بك في بوابة الإدارة',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: darkBg,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'يرجى اختيار العيادة التي ترغب في تسجيل الدخول إليها حالياً للتحكم في كافة العمليات والبيانات.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.bold, height: 1.6),
                      ),
                      const SizedBox(height: 28),

                      // Search field
                      TextField(
                        onChanged: (v) => setState(() => _search = v),
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          hintText: 'بحث عن عيادة...',
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                          prefixIcon: const Icon(Icons.search, size: 20),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Clinics list
                      clinicsAsync.when(
                        loading: () => Column(
                          children: List.generate(
                            3,
                            (i) => Container(
                              height: 180,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                          ),
                        ),
                        error: (e, _) => Center(
                          child: Text('فشل في تحميل العيادات: $e', style: const TextStyle(color: Colors.red)),
                        ),
                        data: (clinics) {
                          final filtered = clinics
                              .where((c) => c.name.toLowerCase().contains(_search.toLowerCase()))
                              .toList();

                          if (filtered.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.local_hospital_outlined, size: 48, color: Color(0xFFCCCCCC)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'لا توجد عيادات مفعلة حالياً',
                                    style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Column(
                            children: filtered.map((clinic) => _buildClinicCard(clinic)).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClinicCard(Clinic clinic) {
    final isActive = clinic.isActive;

    return GestureDetector(
      onTap: () {
        ref.read(authProvider.notifier).selectClinic(clinic.id);
        context.go('/');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Status
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isActive ? 'نشطة' : 'متوقفة',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.green[700] : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('• آخر نشاط: اليوم',
                        style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                  ],
                ),
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: const Icon(Icons.local_hospital_outlined, color: primaryColor, size: 28),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Name & info
            Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    clinic.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: darkBg,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          clinic.plan == 'pro' ? 'Pro' : 'Starter',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'المركز الرئيسي',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 10),
            // Enter button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Avatar group placeholder
                Row(
                  children: List.generate(3, (i) {
                    return Transform.translate(
                      offset: Offset(-(i * 10.0), 0),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + i),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                // Enter button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: darkBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: darkBg.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_ios_new, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'دخول العيادة',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
