import 'package:flutter/material.dart';
import '../../../models/workspace_note.dart';
import 'base_node_wrapper.dart';

class FileNodeWidget extends StatelessWidget {
  final WorkspaceNote note;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(String title) onTitleChange;
  final Function(String colorHex) onColorChange;
  final Function(double x, double y) onPositionUpdate;
  final Function(String id, Offset localPosition)? onConnectStart;
  final VoidCallback? onToggleLock;
  final VoidCallback? onClearConnections;

  const FileNodeWidget({
    super.key,
    required this.note,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
    required this.onTitleChange,
    required this.onColorChange,
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
      icon: Icons.attach_file_outlined,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description, size: 40, color: Colors.blueGrey),
            const SizedBox(height: 8),
            Text(
              note.content != null && note.content!.isNotEmpty 
                  ? note.content!.split('/').last 
                  : 'مستند مرفق',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (note.content != null && note.content!.isNotEmpty)
              TextButton(
                onPressed: () {
                  // Link opening logic
                },
                child: const Text('فتح الملف', style: TextStyle(fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }
}
