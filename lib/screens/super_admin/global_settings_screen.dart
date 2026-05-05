import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/super_admin_service.dart';

class GlobalSettingsScreen extends ConsumerStatefulWidget {
  const GlobalSettingsScreen({super.key});

  @override
  ConsumerState<GlobalSettingsScreen> createState() => _GlobalSettingsScreenState();
}

class _GlobalSettingsScreenState extends ConsumerState<GlobalSettingsScreen> {
  final _appNameController = TextEditingController();
  final _supportEmailController = TextEditingController();
  bool _maintenanceMode = false;
  int _selectedTab = 0;
  bool _isSaving = false;
  bool _initialized = false;

  static const primaryColor = Color(0xFF006D63);

  final _tabs = [
    {'id': 'general', 'label': 'عام', 'icon': Icons.language},
    {'id': 'security', 'label': 'الأمان', 'icon': Icons.shield_outlined},
    {'id': 'database', 'label': 'البيانات والنسخ', 'icon': Icons.storage_outlined},
    {'id': 'notifications', 'label': 'الإشعارات الكلية', 'icon': Icons.notifications_outlined},
  ];

  @override
  void dispose() {
    _appNameController.dispose();
    _supportEmailController.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final service = ref.read(superAdminServiceProvider);
      
      await service.saveGlobalSettings('app_name', {'value': _appNameController.text});
      await service.saveGlobalSettings('support_email', {'value': _supportEmailController.text});
      await service.saveGlobalSettings('maintenance_mode', {'value': _maintenanceMode});

      ref.refresh(globalSettingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الإعدادات بنجاح'),
            backgroundColor: primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(globalSettingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('إعدادات النظام العامة', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            // Side tab list
            Container(
              width: 200,
              margin: const EdgeInsets.all(16),
              child: Column(
                children: List.generate(_tabs.length, (i) {
                  final tab = _tabs[i];
                  final isActive = _selectedTab == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTab = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isActive ? primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive ? primaryColor : Colors.grey.shade200,
                        ),
                        boxShadow: isActive
                            ? [BoxShadow(color: primaryColor.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))]
                            : [],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            tab['icon'] as IconData,
                            size: 20,
                            color: isActive ? Colors.white : Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            tab['label'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isActive ? Colors.white : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Content panel
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: settingsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: primaryColor)),
                  error: (err, _) => Center(child: Text('خطأ: $err')),
                  data: (settings) {
                    if (!_initialized) {
                      final appNameObj = settings['app_name'];
                      final emailObj = settings['support_email'];
                      final maintObj = settings['maintenance_mode'];

                      _appNameController.text = (appNameObj != null && appNameObj is Map && appNameObj['value'] != null) ? appNameObj['value'].toString() : 'Clinic Link Assist';
                      _supportEmailController.text = (emailObj != null && emailObj is Map && emailObj['value'] != null) ? emailObj['value'].toString() : 'support@cliniclink.com';
                      _maintenanceMode = (maintObj != null && maintObj is Map && maintObj['value'] != null) ? (maintObj['value'] == true || maintObj['value'] == 'true') : false;
                      _initialized = true;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'الإعدادات العامة',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF00302D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Divider(),
                        const SizedBox(height: 20),
                        Expanded(
                          child: ListView(
                            children: [
                              _buildLabel('اسم النظام (SaaS App Name)'),
                              const SizedBox(height: 8),
                              _buildTextField(_appNameController),
                              const SizedBox(height: 20),
                              _buildLabel('البريد الإلكتروني للدعم (Support Email)'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _supportEmailController,
                                textAlign: TextAlign.left,
                                textDirection: TextDirection.ltr,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 20),
                              _buildLabel('وضع الصيانة (Maintenance Mode)'),
                              const SizedBox(height: 4),
                              const Text(
                                'إيقاف النظام لجميع العيادات لإجراء صيانة عاجلة',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () => setState(() => _maintenanceMode = !_maintenanceMode),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _maintenanceMode ? Colors.red.shade50 : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _maintenanceMode ? Colors.red.shade200 : Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Switch(
                                        value: _maintenanceMode,
                                        onChanged: (v) => setState(() => _maintenanceMode = v),
                                        activeThumbColor: Colors.red,
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _maintenanceMode ? 'وضع الصيانة مفعل' : 'تفعيل وضع الصيانة',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: _maintenanceMode ? Colors.red[700] : Colors.grey[700],
                                            ),
                                          ),
                                          if (_maintenanceMode)
                                            const Text(
                                              'النظام متوقف حالياً عن جميع العيادات',
                                              style: TextStyle(fontSize: 11, color: Colors.red),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveSettings,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: _isSaving
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('حفظ التغييرات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF00302D)),
    );
  }

  Widget _buildTextField(TextEditingController controller) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
  }
}
