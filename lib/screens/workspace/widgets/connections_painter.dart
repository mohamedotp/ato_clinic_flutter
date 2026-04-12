import 'dart:math';
import 'package:flutter/material.dart';
import '../../../models/workspace_note.dart';
import '../../../models/note_connection.dart';

class ConnectionsPainter extends CustomPainter {
  final List<NoteConnection> connections;
  final List<WorkspaceNote> notes;
  final WorkspaceNote? draggedNode; // If a node is being actively dragged, we use its new coordinates
  
  // For active drag connection
  final String? activeFromNoteId;
  final Offset? activeToPoint;

  ConnectionsPainter({
    required this.connections,
    required this.notes,
    this.draggedNode,
    this.activeFromNoteId,
    this.activeToPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.fill;

    final activePaint = Paint()
      ..color = const Color(0xFF6D67E4).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
      // In Flutter drawing dashed line requires PathMetric or a custom method, keeping it solid for simplicity, or we can just draw solid.

    final activeDotPaint = Paint()
      ..color = const Color(0xFF6D67E4)
      ..style = PaintingStyle.fill;

    // Draw saved connections
    for (var conn in connections) {
      final fromNote = _getNote(conn.fromNoteId);
      final toNote = _getNote(conn.toNoteId);

      if (fromNote == null || toNote == null) continue;

      _drawN8nConnection(canvas, fromNote, toNote, paint, dotPaint);
    }

    // Draw active dragging connection
    if (activeFromNoteId != null && activeToPoint != null) {
      final fromNote = _getNote(activeFromNoteId!);
      if (fromNote != null) {
        // Output port is usually on the left (RTL canvas means right visually but let's stick to standard math)
        // Since RTL in Flutter can be tricky with absolute positioning, we assume absolute X, Y are physical and we just connect them.
        
        final fromRect = Rect.fromLTWH(fromNote.positionX, fromNote.positionY, fromNote.width, fromNote.height);
        // Assuming output is on the right of the 'from' note
        final startPoint = Offset(fromRect.right, fromRect.center.dy);
        
        _drawCurve(canvas, startPoint, activeToPoint!, activePaint, activeDotPaint);
      }
    }
  }

  WorkspaceNote? _getNote(String id) {
    if (draggedNode != null && draggedNode!.id == id) {
      return draggedNode;
    }
    try {
      return notes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  void _drawN8nConnection(Canvas canvas, WorkspaceNote fromNote, WorkspaceNote toNote, Paint linePaint, Paint dotPaint) {
    final fromRect = Rect.fromLTWH(fromNote.positionX, fromNote.positionY, fromNote.width, fromNote.height);
    final toRect = Rect.fromLTWH(toNote.positionX, toNote.positionY, toNote.width, toNote.height);

    // Simplest approach mirroring the React code's logic:
    // Finding closest points among the 4 edges.
    
    final fromPts = [
      _PointDir(Offset(fromRect.center.dx, fromRect.top), 'up'),
      _PointDir(Offset(fromRect.center.dx, fromRect.bottom), 'down'),
      _PointDir(Offset(fromRect.left, fromRect.center.dy), 'left'),
      _PointDir(Offset(fromRect.right, fromRect.center.dy), 'right'),
    ];

    final toPts = [
      _PointDir(Offset(toRect.center.dx, toRect.top), 'up'),
      _PointDir(Offset(toRect.center.dx, toRect.bottom), 'down'),
      _PointDir(Offset(toRect.left, toRect.center.dy), 'left'),
      _PointDir(Offset(toRect.right, toRect.center.dy), 'right'),
    ];

    _PointDir bestFrom = fromPts[1];
    _PointDir bestTo = toPts[0];
    double minDist = double.infinity;

    for (var fp in fromPts) {
      for (var tp in toPts) {
        final d = (tp.offset - fp.offset).distance;
        if (d < minDist) {
          minDist = d;
          bestFrom = fp;
          bestTo = tp;
        }
      }
    }

    final p1 = bestFrom.offset;
    final p2 = bestTo.offset;
    
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;

    final horizontalStrength = max(dx.abs() * 0.45, 60.0);
    final verticalStrength = max(dy.abs() * 0.45, 60.0);

    Offset cp1 = p1;
    Offset cp2 = p2;

    if (bestFrom.dir == 'right') cp1 += Offset(horizontalStrength, 0);
    else if (bestFrom.dir == 'left') cp1 -= Offset(horizontalStrength, 0);
    else if (bestFrom.dir == 'down') cp1 += Offset(0, verticalStrength);
    else if (bestFrom.dir == 'up') cp1 -= Offset(0, verticalStrength);

    if (bestTo.dir == 'right') cp2 -= Offset(horizontalStrength, 0);
    else if (bestTo.dir == 'left') cp2 += Offset(horizontalStrength, 0);
    else if (bestTo.dir == 'down') cp2 -= Offset(0, verticalStrength);
    else if (bestTo.dir == 'up') cp2 += Offset(0, verticalStrength);

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);

    canvas.drawPath(path, linePaint);
    canvas.drawCircle(p1, 4, dotPaint);
    canvas.drawCircle(p2, 4, dotPaint);
  }

  void _drawCurve(Canvas canvas, Offset p1, Offset p2, Paint linePaint, Paint dotPaint) {
    final dx = p2.dx - p1.dx;
    final strength = max(dx.abs() * 0.45, 80.0);
    
    final cp1 = p1 + Offset(strength, 0);
    final cp2 = p2 - Offset(strength, 0);

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);

    canvas.drawPath(path, linePaint);
    canvas.drawCircle(p1, 5, dotPaint..color = dotPaint.color.withValues(alpha: 0.8));
    canvas.drawCircle(p2, 5, dotPaint..color = dotPaint.color.withValues(alpha: 0.4));
  }

  @override
  bool shouldRepaint(covariant ConnectionsPainter oldDelegate) {
    return true; // Simply return true for now to handle all drags smoothly
  }
}

class _PointDir {
  final Offset offset;
  final String dir;
  _PointDir(this.offset, this.dir);
}
