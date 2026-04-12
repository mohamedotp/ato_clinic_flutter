import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workspace_note.dart';
import '../models/note_connection.dart';
import '../services/workspace_service.dart';

final workspaceServiceProvider = Provider((ref) => WorkspaceService());

// We use a StateNotifier to maintain the active state of notes and connections for a specific patient.
class WorkspaceState {
  final List<WorkspaceNote> notes;
  final List<NoteConnection> connections;
  final bool isLoading;
  final String? error;

  WorkspaceState({
    this.notes = const [],
    this.connections = const [],
    this.isLoading = false,
    this.error,
  });

  WorkspaceState copyWith({
    List<WorkspaceNote>? notes,
    List<NoteConnection>? connections,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return WorkspaceState(
      notes: notes ?? this.notes,
      connections: connections ?? this.connections,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class WorkspaceNotifier extends StateNotifier<WorkspaceState> {
  final WorkspaceService _service;
  final String patientId;

  WorkspaceNotifier(this._service, this.patientId) : super(WorkspaceState(isLoading: true)) {
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final notes = await _service.getNotes(patientId);
      final connections = await _service.getConnections(patientId);
      
      state = state.copyWith(
        notes: notes,
        connections: connections,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addNote(Map<String, dynamic> data) async {
    try {
      final newNote = await _service.addNote(data);
      state = state.copyWith(notes: [...state.notes, newNote]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateNoteLocal(WorkspaceNote updatedNote) async {
    // Update locally immediately for smooth UI
    final updatedNotes = state.notes.map((n) {
      return n.id == updatedNote.id ? updatedNote : n;
    }).toList();
    
    state = state.copyWith(notes: updatedNotes);
  }

  Future<void> updateNoteInDb(WorkspaceNote updatedNote) async {
    try {
      await updateNoteLocal(updatedNote); // Make sure local is updated
      
      await _service.updateNote(updatedNote.id, {
        'title': updatedNote.title,
        'content': updatedNote.content,
        'position_x': updatedNote.positionX,
        'position_y': updatedNote.positionY,
        'width': updatedNote.width,
        'height': updatedNote.height,
        'color_custom': updatedNote.colorCustom,
        'is_locked': updatedNote.isLocked,
        'metadata': updatedNote.metadata,
      });
    } catch (e) {
      state = state.copyWith(error: e.toString());
      // Ideally revert local change on failure, but passing for now
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      // Remove locally first
      state = state.copyWith(
        notes: state.notes.where((n) => n.id != id).toList(),
        connections: state.connections.where((c) => c.fromNoteId != id && c.toNoteId != id).toList(),
      );
      
      await _service.deleteNote(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      await _loadData(); // Reload to restore if failed
    }
  }

  Future<void> addConnection(String fromId, String toId, String clinicId) async {
    try {
      final newConn = await _service.addConnection({
        'from_note_id': fromId,
        'to_note_id': toId,
        'patient_id': patientId,
        'clinic_id': clinicId,
      });
      state = state.copyWith(connections: [...state.connections, newConn]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteConnection(String id) async {
    try {
      state = state.copyWith(
        connections: state.connections.where((c) => c.id != id).toList(),
      );
      await _service.deleteConnection(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      await _loadData(); // Reload if failed
    }
  }

  Future<void> clearConnectionsForNote(String noteId) async {
    try {
      final toDelete = state.connections.where((c) => c.fromNoteId == noteId || c.toNoteId == noteId).toList();
      
      state = state.copyWith(
        connections: state.connections.where((c) => c.fromNoteId != noteId && c.toNoteId != noteId).toList(),
      );

      for (var conn in toDelete) {
        await _service.deleteConnection(conn.id);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      await _loadData();
    }
  }
}

// Family provider to scope it per patient
final workspaceProvider = StateNotifierProvider.family<WorkspaceNotifier, WorkspaceState, String>((ref, patientId) {
  final service = ref.watch(workspaceServiceProvider);
  return WorkspaceNotifier(service, patientId);
});
