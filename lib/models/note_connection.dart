class NoteConnection {
  final String id;
  final String fromNoteId;
  final String toNoteId;
  final String patientId;
  final String clinicId;
  final DateTime? createdAt;

  NoteConnection({
    required this.id,
    required this.fromNoteId,
    required this.toNoteId,
    required this.patientId,
    required this.clinicId,
    this.createdAt,
  });

  factory NoteConnection.fromJson(Map<String, dynamic> json) {
    return NoteConnection(
      id: json['id'],
      fromNoteId: json['from_note_id'],
      toNoteId: json['to_note_id'],
      patientId: json['patient_id'],
      clinicId: json['clinic_id'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from_note_id': fromNoteId,
      'to_note_id': toNoteId,
      'patient_id': patientId,
      'clinic_id': clinicId,
    };
  }
}
