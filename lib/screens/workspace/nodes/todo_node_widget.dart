import 'package:flutter/material.dart';
import '../../../models/workspace_note.dart';
import 'base_node_wrapper.dart';

class TodoNodeWidget extends StatelessWidget {
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

  const TodoNodeWidget({
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
    final lines = (note.content ?? '').split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) lines.add('[ ] ');

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
      icon: Icons.check_circle_outline,
      child: ListView.builder(
        itemCount: lines.length + 1,
        itemBuilder: (context, index) {
          if (index == lines.length) {
            return TextButton.icon(
              onPressed: () {
                final newContent = '${note.content}\n[ ] ';
                onContentChange(newContent);
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('إضافة مهمة', style: TextStyle(fontSize: 11)),
            );
          }

          final line = lines[index];
          final isChecked = line.startsWith('[x]');
          final text = line.replaceFirst(RegExp(r'\[.\]\s*'), '');

          return Row(
            children: [
              Checkbox(
                value: isChecked,
                visualDensity: VisualDensity.compact,
                onChanged: (val) {
                  final newLines = List<String>.from(lines);
                  newLines[index] = val! ? '[x] $text' : '[ ] $text';
                  onContentChange(newLines.join('\n'));
                },
              ),
              Expanded(
                child: TextFormField(
                  initialValue: text,
                  style: TextStyle(
                    fontSize: 13,
                    decoration: isChecked ? TextDecoration.lineThrough : null,
                    color: isChecked ? Colors.grey : Colors.black,
                  ),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                  onChanged: (val) {
                    final newLines = List<String>.from(lines);
                    newLines[index] = isChecked ? '[x] $val' : '[ ] $val';
                    onContentChange(newLines.join('\n'));
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 14, color: Colors.grey),
                onPressed: () {
                  final newLines = List<String>.from(lines);
                  newLines.removeAt(index);
                  onContentChange(newLines.join('\n'));
                },
              )
            ],
          );
        },
      ),
    );
  }
}
