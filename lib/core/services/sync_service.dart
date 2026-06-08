import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SyncService {
  static const String _syncQueueBox = 'syncQueueBox';

  static Future<void> init() async {
    await Hive.openBox(_syncQueueBox);
  }

  static Box get syncBox => Hive.box(_syncQueueBox);

  /// Add a mutation to the queue to be executed later when online
  static Future<void> enqueueMutation(
    String table,
    String action,
    Map<String, dynamic> payload, {
    String? matchField,
    dynamic matchValue,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final item = {
      'id': timestamp,
      'table': table,
      'action': action, // 'INSERT', 'UPDATE', 'DELETE'
      'payload': payload,
      'matchField': matchField,
      'matchValue': matchValue,
    };
    await syncBox.put(timestamp, jsonEncode(item));
  }

  /// Sync all pending mutations with Supabase
  static Future<void> syncPendingMutations() async {
    if (syncBox.isEmpty) return;
    
    final client = Supabase.instance.client;
    final keys = syncBox.keys.toList();
    
    for (final key in keys) {
      try {
        final data = jsonDecode(syncBox.get(key));
        final String table = data['table'];
        final String action = data['action'];
        final Map<String, dynamic> payload = data['payload'];
        
        if (action == 'INSERT') {
          await client.from(table).insert(payload);
        } else if (action == 'UPDATE') {
          await client.from(table).update(payload).eq(data['matchField'], data['matchValue']);
        } else if (action == 'DELETE') {
          await client.from(table).delete().eq(data['matchField'], data['matchValue']);
        }
        
        // Remove from queue after successful sync
        await syncBox.delete(key);
      } catch (e) {
        // If there's an error, we leave it in the queue to try again later
        print('Error syncing mutation $key: $e');
      }
    }
  }
}
