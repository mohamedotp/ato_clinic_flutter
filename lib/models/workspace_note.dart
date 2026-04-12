class WorkspaceNote {
  final String id;
  final String patientId;
  final String clinicId;
  final String title;
  final String? content;
  final String type; // 'note', 'todo', 'image', etc.
  final String? noteType;
  final double positionX;
  final double positionY;
  final double width;
  final double height;
  final String? color;
  final String? colorCustom;
  final bool isLocked;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WorkspaceNote({
    required this.id,
    required this.patientId,
    required this.clinicId,
    required this.title,
    this.content,
    required this.type,
    this.noteType,
    required this.positionX,
    required this.positionY,
    required this.width,
    required this.height,
    this.color,
    this.colorCustom,
    this.isLocked = false,
    this.metadata,
    this.createdAt,
    this.updatedAt,
  });

  factory WorkspaceNote.fromJson(Map<String, dynamic> json) {
    return WorkspaceNote(
      id: json['id'],
      patientId: json['patient_id'],
      clinicId: json['clinic_id'],
      title: json['title'] ?? 'ملاحظة',
      content: json['content'],
      type: json['type'] ?? 'note',
      noteType: json['note_type'],
      positionX: (json['position_x'] as num?)?.toDouble() ?? 50.0,
      positionY: (json['position_y'] as num?)?.toDouble() ?? 50.0,
      width: (json['width'] as num?)?.toDouble() ?? 288.0,
      height: (json['height'] as num?)?.toDouble() ?? 200.0,
      color: json['color'],
      colorCustom: json['color_custom'],
      isLocked: json['is_locked'] == true,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'clinic_id': clinicId,
      'title': title,
      'content': content,
      'type': type,
      'note_type': noteType,
      'position_x': positionX,
      'position_y': positionY,
      'width': width,
      'height': height,
      'color': color,
      'color_custom': colorCustom,
      'is_locked': isLocked,
      'metadata': metadata,
    };
  }

  WorkspaceNote copyWith({
    String? title,
    String? content,
    double? positionX,
    double? positionY,
    double? width,
    double? height,
    String? color,
    String? colorCustom,
    bool? isLocked,
    Map<String, dynamic>? metadata,
  }) {
    return WorkspaceNote(
      id: id,
      patientId: patientId,
      clinicId: clinicId,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type,
      noteType: noteType,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      width: width ?? this.width,
      height: height ?? this.height,
      color: color ?? this.color,
      colorCustom: colorCustom ?? this.colorCustom,
      isLocked: isLocked ?? this.isLocked,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
