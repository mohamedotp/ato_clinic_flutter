import 'package:flutter/material.dart';
import '../../../models/workspace_note.dart';
import 'base_node_wrapper.dart';

class TextNodeWidget extends StatelessWidget {
  final WorkspaceNote note;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(String title) onTitleChange;
  final Function(String colorHex) onColorChange;
  final Function(String content) onContentChange;
  final Function(double x, double y) onPositionUpdate;
  final Function(String id, Offset localPosition)? onConnectStart;
  final VoidCallback? onToggleLock;
  final VoidCallback? onClearConnections;

  const TextNodeWidget({
    super.key,
    required this.note,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
    required this.onTitleChange,
    required this.onColorChange,
    required this.onContentChange,
    required this.onPositionUpdate,
    this.onConnectStart,
    this.onToggleLock,
    this.onClearConnections,
  });

  @override
  Widget build(BuildContext context) {
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
      icon: Icons.text_snippet_outlined,
      child: TextFormField(
        initialValue: note.content,
        maxLines: null,
        style: const TextStyle(fontSize: 13),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'اكتب ملاحظاتك هنا...',
        ),
        onChanged: onContentChange,
      ),
    );
  }
}
