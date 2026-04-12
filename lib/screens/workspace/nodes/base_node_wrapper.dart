import 'package:flutter/material.dart';
import '../../../models/workspace_note.dart';

class BaseNodeWrapper extends StatefulWidget {
  final WorkspaceNote note;
  final Widget child;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(String title) onTitleChange;
  final Function(String colorHex) onColorChange;
  final Function(double x, double y) onPositionUpdate;
  final Function(String id, Offset localPosition)? onConnectStart;
  final Function(String targetId)? onConnectEnd;
  final VoidCallback? onToggleLock;
  final VoidCallback? onClearConnections;
  
  // Custom builder for content
  const BaseNodeWrapper({
    super.key,
    required this.note,
    required this.child,
    this.icon,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
    required this.onTitleChange,
    required this.onColorChange,
    required this.onPositionUpdate,
    this.onConnectStart,
    this.onConnectEnd,
    this.onToggleLock,
    this.onClearConnections,
  });

  @override
  State<BaseNodeWrapper> createState() => _BaseNodeWrapperState();
}

class _BaseNodeWrapperState extends State<BaseNodeWrapper> {
  late double _currentX;
  late double _currentY;
  bool _showColorPicker = false;

  final List<String> _colors = [
    '#ffffff', '#fef2f2', '#fff7ed', '#fefce8', '#f0fdf4', '#ecfeff',
    '#eff6ff', '#f5f3ff', '#fdf4ff', '#ffe4e6', '#dbeafe', '#fef08a'
  ];

  @override
  void initState() {
    super.initState();
    _currentX = widget.note.positionX;
    _currentY = widget.note.positionY;
  }

  @override
  void didUpdateWidget(covariant BaseNodeWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.positionX != widget.note.positionX || 
        oldWidget.note.positionY != widget.note.positionY) {
      _currentX = widget.note.positionX;
      _currentY = widget.note.positionY;
    }
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.note.colorCustom != null 
        ? _hexToColor(widget.note.colorCustom!) 
        : Colors.white;

    return Positioned(
      left: _currentX,
      top: _currentY,
      width: widget.note.width,
      height: widget.note.height,
      child: GestureDetector(
        onTap: () {
          widget.onTap();
          if (_showColorPicker) setState(() => _showColorPicker = false);
        },
        onPanUpdate: widget.note.isLocked ? null : (details) {
          if (!widget.isSelected) widget.onTap();
          setState(() {
            _currentX += details.delta.dx;
            _currentY += details.delta.dy;
          });
        },
        onPanEnd: widget.note.isLocked ? null : (details) {
          widget.onPositionUpdate(_currentX, _currentY);
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: widget.isSelected ? Theme.of(context).primaryColor : Colors.black.withValues(alpha: 0.05),
                  width: widget.isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.isSelected 
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: widget.isSelected ? 20 : 10,
                    spreadRadius: widget.isSelected ? 2 : 0,
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
                    ),
                    child: Row(
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, size: 16, color: Colors.black38),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: TextFormField(
                            initialValue: widget.note.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                            ),
                            onChanged: (val) => widget.onTitleChange(val),
                          ),
                        ),
                        
                        // Tools (Color & Menu)
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _showColorPicker = !_showColorPicker),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.palette_outlined, size: 14, color: Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 4),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 16, color: Colors.black38),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 150),
                              onSelected: (val) {
                                if (val == 'delete') widget.onDelete();
                                if (val == 'lock') widget.onToggleLock?.call();
                                if (val == 'clear_conn') widget.onClearConnections?.call();
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'lock',
                                  child: Row(
                                    children: [
                                      Icon(widget.note.isLocked ? Icons.lock_open : Icons.lock, size: 18),
                                      const SizedBox(width: 8),
                                      Text(widget.note.isLocked ? 'إلغاء القفل' : 'قفل النود'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'clear_conn',
                                  child: Row(
                                    children: [
                                      Icon(Icons.link_off, size: 18),
                                      const SizedBox(width: 8),
                                      Text('مسح الروابط'),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 18, color: Colors.red),
                                      const SizedBox(width: 8),
                                      Text('حذف', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),

                  // Content Body
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: widget.child,
                    ),
                  ),
                ],
              ),
            ),

            // Color Picker Dropdown Mode
            if (_showColorPicker)
              Positioned(
                top: 48,
                right: 16,
                width: 120,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
                    ],
                  ),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _colors.map((c) {
                      return GestureDetector(
                        onTap: () {
                          widget.onColorChange(c);
                          setState(() => _showColorPicker = false);
                        },
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _hexToColor(c),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: widget.note.colorCustom == c ? Theme.of(context).primaryColor : Colors.black12,
                              width: widget.note.colorCustom == c ? 2 : 1,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

             // Output connection port
            if (widget.isSelected)
              Positioned(
                right: -8, // Right edge outside
                top: widget.note.height / 2 - 8,
                child: GestureDetector(
                  onPanStart: (details) {
                    final localPos = Offset(widget.note.positionX + widget.note.width, widget.note.positionY + widget.note.height / 2);
                    widget.onConnectStart?.call(widget.note.id, localPos);
                  },
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
