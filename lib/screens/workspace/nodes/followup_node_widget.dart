import 'package:flutter/material.dart';
import '../../../models/workspace_note.dart';
import 'base_node_wrapper.dart';

class FollowupNodeWidget extends StatelessWidget {
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

  const FollowupNodeWidget({
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
    final followupDate = metadata['followup_date'] ?? '';

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
      icon: Icons.calendar_today_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('تاريخ المتابعة القادم:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.tryParse(followupDate) ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) {
                onMetadataChange({...metadata, 'followup_date': date.toIso8601String().split('T')[0]});
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                   Icon(Icons.event, size: 16, color: Theme.of(context).primaryColor),
                   const SizedBox(width: 8),
                   Text(followupDate.isEmpty ? 'حدد التاريخ' : followupDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: note.content,
            maxLines: 3,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'تفاصيل المتابعة...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              fillColor: Colors.grey.withValues(alpha: 0.05),
              filled: true,
            ),
            onChanged: (val) {
               onMetadataChange({...metadata, 'details': val});
            },
          )
        ],
      ),
    );
  }
}
