import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    await ref.read(authProvider.notifier).signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            // 1. Premium Background Gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0F172A), // Dark slate
                    Color(0xFF1E293B), // Slate 800
                    Color(0xFF0F172A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            
            // 2. Animated Background Blobs
            Positioned(
              top: -100,
              left: -50, // Adjusted for RTL visual balance
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .moveY(begin: 0, end: 50, duration: 4.seconds, curve: Curves.easeInOut)
               .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2)),
            ),
            Positioned(
              bottom: -50,
              right: -50, // Adjusted for RTL visual balance
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .moveX(begin: 0, end: 40, duration: 5.seconds, curve: Curves.easeInOut)
               .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
            ),
  
            // 3. Main Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Branding Logo
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.2),
                              blurRadius: 40,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: const Icon(
                              Icons.medical_services_rounded,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ).animate()
                       .fadeIn(duration: 800.ms)
                       .scale(delay: 200.ms, curve: Curves.elasticOut),
  
                      const SizedBox(height: 32),
                      
                      const Text(
                        'Ato Clinic',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        'مستقبلك الطبي الرقمي يبدأ من هنا',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ).animate().fadeIn(delay: 600.ms),
  
                      const SizedBox(height: 48),
  
                      // 4. Glassmorphism Login Card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(color: Colors.white.withOpacity(0.15)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start, // Start is Right in RTL
                              children: [
                                const Text(
                                  'تسجيل الدخول',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'أهلاً بك مجدداً في نظام العيادة الذكي',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.6),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                
                                // Error Message
                                if (authState is AuthError)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 24),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            (authState).message,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ).animate().shake(),
                                
                                // Email Field
                                _buildInputField(
                                  controller: _emailController,
                                  label: 'البريد الإلكتروني',
                                  hint: 'example@clinic.com',
                                  icon: Icons.alternate_email_rounded,
                                ).animate().fadeIn(delay: 800.ms).moveX(begin: -30, end: 0),
                                
                                const SizedBox(height: 24),
                                
                                // Password Field
                                _buildInputField(
                                  controller: _passwordController,
                                  label: 'كلمة المرور',
                                  hint: '••••••••',
                                  icon: Icons.lock_outline_rounded,
                                  isPassword: true,
                                  obscureText: _obscurePassword,
                                  onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                                ).animate().fadeIn(delay: 1000.ms).moveX(begin: -30, end: 0),
                                
                                const SizedBox(height: 40),
                                
                                // Login Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 60,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.accent,
                                          AppColors.accent.withBlue(150),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.accent.withOpacity(0.3),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 3,
                                              ),
                                            )
                                          : const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.login_rounded, color: Colors.white),
                                                SizedBox(width: 12),
                                                Text(
                                                  'دخول للنظام',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ).animate().fadeIn(delay: 1200.ms).scale(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 48),
  
                      // Bottom Features
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _FeatureItem(icon: Icons.security_rounded, label: 'آمن تماماً'),
                          _FeatureItem(icon: Icons.cloud_off_rounded, label: 'بدون انترنت'),
                          _FeatureItem(icon: Icons.support_agent_rounded, label: 'دعم فني'),
                        ],
                      ).animate().fadeIn(delay: 1400.ms),
                      
                      const SizedBox(height: 40),
                      Text(
                        'ATO CLINIC SYSTEM © 2024',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ).animate().fadeIn(delay: 1600.ms),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Right in RTL
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: obscureText,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl, // Set to RTL as requested
          onTap: () {
            // Force cursor to the end of the text when tapped
            if (controller.text.isNotEmpty) {
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: controller.text.length),
              );
            }
          },
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            prefixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    onPressed: onTogglePassword,
                    splashRadius: 24,
                  )
                : Icon(icon, color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.accent.withOpacity(0.5), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Icon(icon, color: AppColors.accent, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
