import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

class StaffTrainingScreen extends StatelessWidget {
  const StaffTrainingScreen({super.key});

  static const primaryColor = Color(0xFF006D63);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('التدريب والدعم الفني', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Training Section
            const Text('أكاديمية اوتو كلينيك', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('فيديوهات وشروحات لكيفية استخدام النظام', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            _buildVideoCard(
              title: 'كيفية استخدام شاشة الطبيب (Workspace)',
              duration: '5:20',
              imageUrl: 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=500&q=80',
              onTap: () {},
            ),
            const SizedBox(height: 16),
            _buildVideoCard(
              title: 'تسجيل المرضى وإدارة المواعيد',
              duration: '3:45',
              imageUrl: 'https://images.unsplash.com/photo-1551076805-e18690c5e561?w=500&q=80',
              onTap: () {},
            ),
            const SizedBox(height: 16),
            _buildVideoCard(
              title: 'إدارة الخزينة والمالية للعيادة',
              duration: '4:10',
              imageUrl: 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=500&q=80',
              onTap: () {},
            ),

            const SizedBox(height: 40),

            // Support Section
            const Text('مدير الحساب والدعم الفني', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('متاحون لخدمتك على مدار الساعة', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00302D), Color(0xFF006D63)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.support_agent, size: 30, color: primaryColor),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('م. أحمد صبحي', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('مدير الحساب المخصص لعيادتك', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => launchUrl(Uri.parse('tel:+201000000000')),
                          icon: const Icon(Icons.call),
                          label: const Text('اتصال مباشر'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => launchUrl(Uri.parse('https://wa.me/201000000000')),
                          icon: const Icon(Icons.chat),
                          label: const Text('واتساب الدعم'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fade().slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard({required String title, required String duration, required String imageUrl, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
              child: Image.network(imageUrl, width: 100, height: 100, fit: BoxFit.cover),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.play_circle_outline, size: 16, color: primaryColor),
                        const SizedBox(width: 4),
                        Text(duration, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ).animate().fade().slideX(begin: -0.1),
    );
  }
}
