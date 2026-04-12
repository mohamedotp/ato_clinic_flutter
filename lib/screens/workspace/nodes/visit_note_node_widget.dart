import 'package:flutter/material.dart';
import '../../../models/workspace_note.dart';
import 'base_node_wrapper.dart';

class VisitNoteNodeWidget extends StatelessWidget {
  final WorkspaceNote note;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(String title) onTitleChange;
  final Function(String colorHex) onColorChange;
  final Function(Map<String, dynamic> metadata) onMetadataChange;
  final Function(double x, double y) onPositionUpdate;
  final Function(String id, Offset localPosition)? onConnectStart;
  final VoidCallback? onToggleLock;
  final VoidCallback? onClearConnections;

  const VisitNoteNodeWidget({
    super.key,
    required this.note,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
    required this.onTitleChange,
    required this.onColorChange,
    required this.onMetadataChange,
    required this.onPositionUpdate,
    this.onConnectStart,
    this.onToggleLock,
    this.onClearConnections,
  });

  @override
  Widget build(BuildContext context) {
    final metadata = note.metadata ?? {};
    
    return BaseNodeWrapper(
      note: note,
      isSelected: isSelected,
      onTap: onTap,
      onDelete: onDelete,
      onTitleChange: onTitleChange,
      onColorChange: onColorChange,
      onPositionUpdate: onPositionUpdate,
      onConnectStart: onConnectStart,
      onToggleLock: onToggleLock,
      onClearConnections: onClearConnections,
      icon: Icons.assignment_outlined,
      child: Column(
        children: [
          _buildField('الشكوى:', 'complaint', metadata),
          const SizedBox(height: 8),
          _buildField('التشخيص:', 'diagnosis', metadata),
          const SizedBox(height: 8),
          _buildField('العلاج:', 'treatment', metadata),
        ],
      ),
    );
  }

  Widget _buildField(String label, String key, Map<String, dynamic> metadata) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: metadata[key] ?? '',
          maxLines: null,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
            border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue.withValues(alpha: 0.1))),
          ),
          onChanged: (val) {
            onMetadataChange({...metadata, key: val});
          },
        ),
      ],
    );
  }
}
