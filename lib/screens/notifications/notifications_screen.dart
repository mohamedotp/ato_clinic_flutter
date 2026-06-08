import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/notifications_provider.dart';
import '../../providers/auth_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final authState = ref.read(authProvider);
    final clinicId = authState is AuthAuthenticated ? authState.profile?.clinicId : null;
    final role = authState is AuthAuthenticated ? authState.profile?.role?.name : null;
    const primaryColor = Color(0xFF006D63);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('الإشعارات', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          if (clinicId != null && role != null)
            TextButton.icon(
              onPressed: () {
                ref.read(notificationServiceProvider).markAllAsRead(clinicId, role);
              },
              icon: const Icon(Icons.done_all, color: primaryColor, size: 18),
              label: const Text('تحديد الكل كمقروء', style: TextStyle(color: primaryColor, fontSize: 12)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('لا توجد إشعارات جديدة', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];
              final isWhatsapp = n.type == 'whatsapp_booking';

              return Dismissible(
                key: Key(n.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  ref.read(notificationServiceProvider).deleteNotification(n.id);
                },
                child: GestureDetector(
                  onTap: () {
                    if (!n.isRead) {
                      ref.read(notificationServiceProvider).markAsRead(n.id);
                    }
                    // Optionally, navigate based on type
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: n.isRead ? Colors.white : primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: n.isRead ? Colors.black.withValues(alpha: 0.05) : primaryColor.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        if (!n.isRead)
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isWhatsapp ? Colors.green.withValues(alpha: 0.1) : primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isWhatsapp ? Icons.wechat : Icons.notifications,
                            color: isWhatsapp ? Colors.green : primaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      n.title,
                                      style: TextStyle(
                                        fontWeight: n.isRead ? FontWeight.bold : FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    timeago.format(n.createdAt, locale: 'ar'),
                                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                n.message,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
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
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
      ),
    );
  }
}
