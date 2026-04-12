import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/workspace_note.dart';
import 'base_node_wrapper.dart';

class ImageNodeWidget extends StatelessWidget {
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

  const ImageNodeWidget({
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
      icon: Icons.image_outlined,
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withValues(alpha: 0.05),
              ),
              clipBehavior: Clip.antiAlias,
              child: note.content != null && note.content!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: note.content!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                    )
                  : const Center(child: Icon(Icons.image, color: Colors.grey, size: 48)),
            ),
          ),
          if (note.content == null || note.content!.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text('جاري رفع الصورة...', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ),
        ],
      ),
    );
  }
}
