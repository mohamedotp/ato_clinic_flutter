import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';

class AppNotification {
  final String id;
  final String clinicId;
  final String title;
  final String message;
  final String? type;
  final String? targetRole;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.clinicId,
    required this.title,
    required this.message,
    this.type,
    this.targetRole,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      clinicId: json['clinic_id'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      targetRole: json['target_role'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return Stream.value([]);
  
  final clinicId = authState.profile?.clinicId;
  final role = authState.profile?.role?.name;
  
  if (clinicId == null) return Stream.value([]);

  return Supabase.instance.client
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('clinic_id', clinicId)
      .order('created_at', ascending: false)
      .map((data) {
        return data.map((json) => AppNotification.fromJson(json)).where((n) {
          // Filter by target role if present
          if (n.targetRole != null && n.targetRole != role) return false;
          return true;
        }).toList();
      });
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  return notificationsAsync.maybeWhen(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

final notificationServiceProvider = Provider((ref) => NotificationService());

class NotificationService {
  final _client = Supabase.instance.client;

  Future<void> markAsRead(String id) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', id);
  }
  
  Future<void> markAllAsRead(String clinicId, String role) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('clinic_id', clinicId)
        .eq('is_read', false)
        .or('target_role.is.null,target_role.eq.$role');
  }

  Future<void> deleteNotification(String id) async {
    await _client.from('notifications').delete().eq('id', id);
  }
}
