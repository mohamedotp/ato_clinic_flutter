import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';

class InternalMessage {
  final String id;
  final String clinicId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final String? receiverId;
  final String? senderName;
  final String? senderRole;

  InternalMessage({
    required this.id,
    required this.clinicId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.receiverId,
    this.senderName,
    this.senderRole,
  });

  factory InternalMessage.fromJson(Map<String, dynamic> json) {
    return InternalMessage(
      id: json['id'],
      clinicId: json['clinic_id'],
      senderId: json['sender_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      receiverId: json['receiver_id'],
      senderName: json['profiles']?['full_name'],
      senderRole: json['profiles']?['role'],
    );
  }
}

final internalMessagesProvider = StreamProvider<List<InternalMessage>>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return Stream.value([]);
  
  final clinicId = authState.profile?.clinicId;
  if (clinicId == null) return Stream.value([]);

  return Supabase.instance.client
      .from('internal_messages')
      .stream(primaryKey: ['id'])
      .eq('clinic_id', clinicId)
      .order('created_at', ascending: true)
      .asyncMap((data) async {
        // We need to fetch the sender profiles manually since stream doesn't support joins natively
        final senderIds = data.map((e) => e['sender_id'] as String).toSet().toList();
        
        Map<String, dynamic> profilesMap = {};
        if (senderIds.isNotEmpty) {
          final profilesResponse = await Supabase.instance.client
              .from('profiles')
              .select('id, full_name, role')
              .inFilter('id', senderIds);
          
          for (var p in profilesResponse) {
            profilesMap[p['id']] = p;
          }
        }
        
        return data.map((json) {
          final sender = profilesMap[json['sender_id']];
          if (sender != null) {
            json['profiles'] = sender;
          }
          return InternalMessage.fromJson(json);
        }).toList();
      });
});

final internalChatServiceProvider = Provider((ref) => InternalChatService());

class InternalChatService {
  final _client = Supabase.instance.client;

  Future<void> sendMessage(String clinicId, String senderId, String content, {String? receiverId}) async {
    await _client.from('internal_messages').insert({
      'clinic_id': clinicId,
      'sender_id': senderId,
      'content': content,
      if (receiverId != null) 'receiver_id': receiverId,
    });
  }
}
