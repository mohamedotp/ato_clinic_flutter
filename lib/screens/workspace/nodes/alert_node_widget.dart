import 'package:flutter/material.dart';
import '../../../models/workspace_note.dart';
import 'base_node_wrapper.dart';

class AlertNodeWidget extends StatefulWidget {
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

  const AlertNodeWidget({
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
  State<AlertNodeWidget> createState() => _AlertNodeWidgetState();
}

class _AlertNodeWidgetState extends State<AlertNodeWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: BaseNodeWrapper(
        note: widget.note,
        isSelected: widget.isSelected,
        onTap: widget.onTap,
        onDelete: widget.onDelete,
        onTitleChange: widget.onTitleChange,
        onColorChange: widget.onColorChange,
        onPositionUpdate: widget.onPositionUpdate,
        onConnectStart: widget.onConnectStart,
        onToggleLock: widget.onToggleLock,
        onClearConnections: widget.onClearConnections,
        icon: Icons.warning_amber_rounded,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red[50]!.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[200]!, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.red.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 2),
            ],
          ),
          child: TextFormField(
            initialValue: widget.note.content,
            maxLines: null,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'تنبيه هام جداً...',
              hintStyle: TextStyle(color: Colors.redAccent.withValues(alpha: 0.5)),
            ),
            onChanged: widget.onContentChange,
          ),
        ),
      ),
    );
  }
}
