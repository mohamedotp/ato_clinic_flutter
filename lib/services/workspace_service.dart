import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workspace_note.dart';
import '../models/note_connection.dart';
import '../core/services/local_storage_service.dart';
import '../core/services/sync_service.dart';
import 'dart:math';

class WorkspaceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _generateTempId() {
    final random = Random();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    // Set version 4
    values[6] = (values[6] & 0x0f) | 0x40;
    // Set variant
    values[8] = (values[8] & 0x3f) | 0x80;
    
    final hex = values.map((val) => val.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  Future<List<WorkspaceNote>> getNotes(String patientId) async {
    try {
      final response = await _supabase
          .from('patient_notes')
          .select('*')
          .eq('patient_id', patientId)
          .order('created_at', ascending: true);

      final jsonList = response as List;
      await LocalStorageService.savePatientNotes(patientId, jsonList);
      return jsonList.map((json) => WorkspaceNote.fromJson(json)).toList();
    } catch (e) {
      final cachedJson = LocalStorageService.getPatientNotes(patientId);
      if (cachedJson != null) {
        return cachedJson.map((json) => WorkspaceNote.fromJson(json)).toList();
      }
      return [];
    }
  }

  Future<List<NoteConnection>> getConnections(String patientId) async {
    try {
      final response = await _supabase
          .from('note_connections')
          .select('*')
          .eq('patient_id', patientId);

      final jsonList = response as List;
      await LocalStorageService.savePatientConnections(patientId, jsonList);
      return jsonList.map((json) => NoteConnection.fromJson(json)).toList();
    } catch (e) {
      final cachedJson = LocalStorageService.getPatientConnections(patientId);
      if (cachedJson != null) {
        return cachedJson.map((json) => NoteConnection.fromJson(json)).toList();
      }
      return [];
    }
  }

  Future<WorkspaceNote> addNote(Map<String, dynamic> data) async {
    try {
      final response = await _supabase.from('patient_notes').insert(data).select().single();
      
      final patientId = data['patient_id'];
      final cached = LocalStorageService.getPatientNotes(patientId) ?? [];
      cached.add(response);
      await LocalStorageService.savePatientNotes(patientId, cached);

      return WorkspaceNote.fromJson(response);
    } catch (e) {
      final tempId = _generateTempId();
      data['id'] = tempId;
      data['created_at'] = DateTime.now().toIso8601String();
      await SyncService.enqueueMutation('patient_notes', 'INSERT', data);

      final patientId = data['patient_id'];
      final cached = LocalStorageService.getPatientNotes(patientId) ?? [];
      cached.add(data);
      await LocalStorageService.savePatientNotes(patientId, cached);

      return WorkspaceNote.fromJson(data);
    }
  }

  Future<void> updateNote(String id, Map<String, dynamic> data) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();
      await _supabase.from('patient_notes').update(data).eq('id', id);
      _updateCachedNote(id, data);
    } catch (e) {
      await SyncService.enqueueMutation('patient_notes', 'UPDATE', data, matchField: 'id', matchValue: id);
      _updateCachedNote(id, data);
    }
  }

  void _updateCachedNote(String id, Map<String, dynamic> data) {
    final box = LocalStorageService.workspaceBox;
    for (var key in box.keys) {
      if (key.toString().startsWith('notes_')) {
        final patientId = key.toString().replaceFirst('notes_', '');
        final cached = LocalStorageService.getPatientNotes(patientId);
        if (cached != null) {
          bool updated = false;
          final updatedList = cached.map((item) {
            if (item['id'] == id) {
              updated = true;
              return {...item, ...data};
            }
            return item;
          }).toList();
          if (updated) {
            LocalStorageService.savePatientNotes(patientId, updatedList);
            break;
          }
        }
      }
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      await _supabase.from('patient_notes').delete().eq('id', id);
      _deleteCachedNote(id);
    } catch (e) {
      await SyncService.enqueueMutation('patient_notes', 'DELETE', {}, matchField: 'id', matchValue: id);
      _deleteCachedNote(id);
    }
  }

  void _deleteCachedNote(String id) {
    final box = LocalStorageService.workspaceBox;
    for (var key in box.keys) {
      if (key.toString().startsWith('notes_')) {
        final patientId = key.toString().replaceFirst('notes_', '');
        final cached = LocalStorageService.getPatientNotes(patientId);
        if (cached != null) {
          final originalLength = cached.length;
          final updatedList = cached.where((item) => item['id'] != id).toList();
          if (updatedList.length < originalLength) {
            LocalStorageService.savePatientNotes(patientId, updatedList);
            break;
          }
        }
      }
    }
  }

  Future<NoteConnection> addConnection(Map<String, dynamic> data) async {
    try {
      final response = await _supabase.from('note_connections').insert(data).select().single();
      
      final patientId = data['patient_id'];
      final cached = LocalStorageService.getPatientConnections(patientId) ?? [];
      cached.add(response);
      await LocalStorageService.savePatientConnections(patientId, cached);

      return NoteConnection.fromJson(response);
    } catch (e) {
      final tempId = _generateTempId();
      data['id'] = tempId;
      data['created_at'] = DateTime.now().toIso8601String();
      await SyncService.enqueueMutation('note_connections', 'INSERT', data);

      final patientId = data['patient_id'];
      final cached = LocalStorageService.getPatientConnections(patientId) ?? [];
      cached.add(data);
      await LocalStorageService.savePatientConnections(patientId, cached);

      return NoteConnection.fromJson(data);
    }
  }

  Future<void> deleteConnection(String id) async {
    try {
      await _supabase.from('note_connections').delete().eq('id', id);
      _deleteCachedConnection(id);
    } catch (e) {
      await SyncService.enqueueMutation('note_connections', 'DELETE', {}, matchField: 'id', matchValue: id);
      _deleteCachedConnection(id);
    }
  }

  void _deleteCachedConnection(String id) {
    final box = LocalStorageService.workspaceBox;
    for (var key in box.keys) {
      if (key.toString().startsWith('connections_')) {
        final patientId = key.toString().replaceFirst('connections_', '');
        final cached = LocalStorageService.getPatientConnections(patientId);
        if (cached != null) {
          final originalLength = cached.length;
          final updatedList = cached.where((item) => item['id'] != id).toList();
          if (updatedList.length < originalLength) {
            LocalStorageService.savePatientConnections(patientId, updatedList);
            break;
          }
        }
      }
    }
  }
}
