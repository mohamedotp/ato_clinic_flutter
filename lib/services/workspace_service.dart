import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workspace_note.dart';
import '../models/note_connection.dart';

class WorkspaceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<WorkspaceNote>> getNotes(String patientId) async {
    final response = await _supabase
        .from('patient_notes')
        .select('*')
        .eq('patient_id', patientId)
        .order('created_at', ascending: true);

    return (response as List).map((json) => WorkspaceNote.fromJson(json)).toList();
  }

  Future<List<NoteConnection>> getConnections(String patientId) async {
    final response = await _supabase
        .from('note_connections')
        .select('*')
        .eq('patient_id', patientId);

    return (response as List).map((json) => NoteConnection.fromJson(json)).toList();
  }

  Future<WorkspaceNote> addNote(Map<String, dynamic> data) async {
    final response = await _supabase.from('patient_notes').insert(data).select().single();
    return WorkspaceNote.fromJson(response);
  }

  Future<void> updateNote(String id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    await _supabase.from('patient_notes').update(data).eq('id', id);
  }

  Future<void> deleteNote(String id) async {
    await _supabase.from('patient_notes').delete().eq('id', id);
  }

  Future<NoteConnection> addConnection(Map<String, dynamic> data) async {
    final response = await _supabase.from('note_connections').insert(data).select().single();
    return NoteConnection.fromJson(response);
  }

  Future<void> deleteConnection(String id) async {
    await _supabase.from('note_connections').delete().eq('id', id);
  }
}
