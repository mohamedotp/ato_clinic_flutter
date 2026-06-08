import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

import '../../../providers/workspace_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/workspace_note.dart';
import 'widgets/grid_painter.dart';
import 'widgets/connections_painter.dart';
import 'nodes/text_node_widget.dart';
import 'nodes/todo_node_widget.dart';
import 'nodes/image_node_widget.dart';
import 'nodes/visit_note_node_widget.dart';
import 'nodes/prescription_node_widget.dart';
import 'nodes/followup_node_widget.dart';
import 'nodes/alert_node_widget.dart';
import 'nodes/file_node_widget.dart';
import 'nodes/voice_node_widget.dart';
import 'nodes/material_usage_node_widget.dart';
import '../patients/patient_finance_tab.dart';

class WorkspaceScreen extends ConsumerStatefulWidget {
  final String patientId;

  const WorkspaceScreen({super.key, required this.patientId});

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  final TransformationController _transformationController = TransformationController();
  String? _selectedNoteId;
  String? _activeDragFromId;
  Offset? _activeDragToPoint;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Start at a more neutral position (around 400, 400 on the 3200x3200 canvas)
    _transformationController.value = Matrix4.identity()
      ..translate(-400.0, -400.0)
      ..scale(0.8);
  }

  Future<bool> _confirmDelete() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف العنصر'),
        content: const Text('هل أنت متأكد من رغبتك في حذف هذا العنصر؟ لا يمكن التراجع عن هذه الخطوة.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
  }

  void _handleAddNote(String type) {
    FocusScope.of(context).unfocus();
    
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;
    final clinicId = authState.profile?.clinicId;
    if (clinicId == null) return;

    final size = MediaQuery.of(context).size;
    final matrix = _transformationController.value;
    final scale = matrix.getMaxScaleOnAxis();
    final trans = matrix.getTranslation();
    
    final cx = (size.width / 2 - trans.x) / scale;
    final cy = (size.height / 2 - trans.y) / scale;

    ref.read(workspaceProvider(widget.patientId).notifier).addNote({
      'patient_id': widget.patientId,
      'clinic_id': clinicId,
      'title': _getDefaultTitle(type),
      'content': '',
      'type': type,
      'note_type': type,
      'position_x': cx - 144,
      'position_y': cy - 100,
      'width': 288.0,
      'height': type == 'prescription' ? 300.0 : 200.0,
      'color_custom': _getDefaultColor(type),
    });
  }

  String _getDefaultTitle(String type) {
    switch(type) {
      case 'visit': return 'زيارة طبية';
      case 'prescription': return 'روشتة علاجية';
      case 'alert': return 'تنبيه هامة';
      case 'todo': return 'قائمة مهام';
      case 'followup': return 'متابعة';
      case 'file': return 'ملف مرفق';
      case 'voice': return 'تسجيل صوتي';
      case 'materials': return 'صرف الخامات';
      default: return 'ملاحظة جديدة';
    }
  }

  String _getDefaultColor(String type) {
    switch(type) {
      case 'visit': return '#eff6ff';
      case 'prescription': return '#ecfdf5';
      case 'alert': return '#fef2f2';
      case 'file': return '#f3f4f6';
      case 'voice': return '#eef2ff';
      case 'materials': return '#f5f3ff';
      default: return '#ffffff';
    }
  }

  Future<void> _pickAndUploadImage() async {
    // Show choice dialog: Camera or Gallery
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text('اختر مصدر الصورة',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006D63).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF006D63).withValues(alpha: 0.2)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.camera_alt_rounded, size: 36, color: Color(0xFF006D63)),
                          SizedBox(height: 8),
                          Text('الكاميرا', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF006D63))),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.indigo.withValues(alpha: 0.2)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.photo_library_rounded, size: 36, color: Colors.indigo),
                          SizedBox(height: 8),
                          Text('الصور', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 80);
    if (image == null) return;

    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;
    final clinicId = authState.profile?.clinicId;
    if (clinicId == null) return;

    // Show loading indicator
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF006D63)),
                  SizedBox(height: 16),
                  Text('جاري رفع الصورة...'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    try {
      final file = File(image.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'clinic-files/$clinicId/${widget.patientId}/$fileName';
      
      await Supabase.instance.client.storage.from('clinic-files').upload(path, file);
      final publicUrl = Supabase.instance.client.storage.from('clinic-files').getPublicUrl(path);

      if (mounted) Navigator.of(context, rootNavigator: true).pop(); // close loading

      final size = MediaQuery.of(context).size;
      final matrix = _transformationController.value;
      final scale = matrix.getMaxScaleOnAxis();
      final trans = matrix.getTranslation();
      final cx = (size.width / 2 - trans.x) / scale;
      final cy = (size.height / 2 - trans.y) / scale;

      ref.read(workspaceProvider(widget.patientId).notifier).addNote({
        'patient_id': widget.patientId,
        'clinic_id': clinicId,
        'title': 'صورة مرفقة',
        'content': publicUrl,
        'type': 'image',
        'note_type': 'image',
        'position_x': cx - 144,
        'position_y': cy - 100,
        'width': 288,
        'height': 220,
      });
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop(); // close loading
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الرفع: $e')));
    }
  }

  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('إضافة عنصر جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 24),
            Wrap(
              spacing: 20,
              runSpacing: 24,
              alignment: WrapAlignment.center,
              children: [
                _ModalAction(icon: Icons.medical_services, label: 'زيارة', color: Colors.blue, onTap: () { context.pop(); _handleAddNote('visit'); }),
                _ModalAction(icon: Icons.medication_outlined, label: 'روشتة', color: Colors.teal, onTap: () { context.pop(); _handleAddNote('prescription'); }),
                _ModalAction(icon: Icons.text_snippet, label: 'ملاحظة', color: Colors.orange, onTap: () { context.pop(); _handleAddNote('note'); }),
                _ModalAction(icon: Icons.check_circle, label: 'مهام', color: Colors.green, onTap: () { context.pop(); _handleAddNote('todo'); }),
                _ModalAction(icon: Icons.event, label: 'متابعة', color: Colors.purple, onTap: () { context.pop(); _handleAddNote('followup'); }),
                _ModalAction(icon: Icons.mic, label: 'صوت', color: Colors.indigo, onTap: () { context.pop(); _handleAddNote('voice'); }),
                _ModalAction(icon: Icons.warning, label: 'تنبيه', color: Colors.red, onTap: () { context.pop(); _handleAddNote('alert'); }),
                _ModalAction(icon: Icons.image, label: 'صورة', color: Colors.indigo, onTap: () { context.pop(); _pickAndUploadImage(); }),
                _ModalAction(icon: Icons.attach_file, label: 'ملف', color: Colors.blueGrey, onTap: () { context.pop(); _handleAddNote('file'); }),
                _ModalAction(icon: Icons.inventory_2_rounded, label: 'خامات', color: const Color(0xFF7B3FBE), onTap: () { context.pop(); _handleAddNote('materials'); }),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _handleConnectEnd(PointerUpEvent event) {
    if (_activeDragFromId == null) return;
    
    final workspaceState = ref.read(workspaceProvider(widget.patientId));
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;
    final clinicId = authState.profile?.clinicId;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPoint = renderBox.globalToLocal(event.position);
    final matrix = _transformationController.value;
    final scale = matrix.getMaxScaleOnAxis();
    final trans = matrix.getTranslation();
    
    final canvasX = (localPoint.dx - trans.x) / scale;
    final canvasY = (localPoint.dy - trans.y) / scale;

    String? targetId;
    for (var note in workspaceState.notes) {
      if (note.id == _activeDragFromId) continue;
      final rect = Rect.fromLTWH(note.positionX, note.positionY, note.width, note.height);
      if (rect.contains(Offset(canvasX, canvasY))) {
        targetId = note.id;
        break;
      }
    }

    if (targetId != null && clinicId != null) {
      final exists = workspaceState.connections.any((c) => 
        (c.fromNoteId == _activeDragFromId && c.toNoteId == targetId) ||
        (c.fromNoteId == targetId && c.toNoteId == _activeDragFromId)
      );
      
      if (!exists) {
        ref.read(workspaceProvider(widget.patientId).notifier).addConnection(_activeDragFromId!, targetId, clinicId);
      }
    }

    setState(() {
      _activeDragFromId = null;
      _activeDragToPoint = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(workspaceProvider(widget.patientId), (previous, next) {
      if (previous?.isLoading == true && next.isLoading == false) {
        if (next.notes.isNotEmpty) {
          // Calculate bounding box of all notes
          double minX = double.infinity;
          double minY = double.infinity;
          double maxX = double.negativeInfinity;
          double maxY = double.negativeInfinity;

          for (var note in next.notes) {
            if (note.positionX < minX) minX = note.positionX;
            if (note.positionY < minY) minY = note.positionY;
            if (note.positionX + note.width > maxX) maxX = note.positionX + note.width;
            if (note.positionY + note.height > maxY) maxY = note.positionY + note.height;
          }

          if (minX != double.infinity) {
            final cx = (minX + maxX) / 2;
            final cy = (minY + maxY) / 2;
            final size = MediaQuery.sizeOf(context);
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              const scale = 0.8;
              _transformationController.value = Matrix4.identity()
                ..translate(size.width / 2 - cx * scale, size.height / 2 - cy * scale)
                ..scale(scale);
            });
          }
        } else {
          // Center the canvas if no notes
          final size = MediaQuery.sizeOf(context);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            const scale = 0.8;
            _transformationController.value = Matrix4.identity()
              ..translate(size.width / 2 - 1600 * scale, size.height / 2 - 1600 * scale)
              ..scale(scale);
          });
        }
      }
    });

    final workspaceState = ref.watch(workspaceProvider(widget.patientId));
    final notifier = ref.read(workspaceProvider(widget.patientId).notifier);

    final filteredNotes = workspaceState.notes.where((n) => 
      n.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      (n.content ?? '').toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Stack(
        children: [
          // Canvas Area
          Listener(
            onPointerMove: (event) {
              if (_activeDragFromId != null) {
                final RenderBox renderBox = context.findRenderObject() as RenderBox;
                final localPoint = renderBox.globalToLocal(event.position);
                final matrix = _transformationController.value;
                final scale = matrix.getMaxScaleOnAxis();
                final trans = matrix.getTranslation();
                
                setState(() {
                  _activeDragToPoint = Offset(
                    (localPoint.dx - trans.x) / scale,
                    (localPoint.dy - trans.y) / scale
                  );
                });
              }
            },
            onPointerUp: _handleConnectEnd,
            child: workspaceState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : workspaceState.error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text('خطأ في تحميل البيانات: ${workspaceState.error}', 
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed: () => ref.refresh(workspaceProvider(widget.patientId)),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  )
                : InteractiveViewer(
                  transformationController: _transformationController,
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(2000),
                  minScale: 0.1,
                  maxScale: 2.5,
                  panEnabled: true,
                  scaleEnabled: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      if (_selectedNoteId != null) {
                        setState(() => _selectedNoteId = null);
                      }
                    },
                    child: SizedBox(
                      width: 3200,
                      height: 3200,
                      child: Stack(
                      children: [
                        Positioned.fill(child: CustomPaint(painter: GridPainter())),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: ConnectionsPainter(
                              connections: workspaceState.connections,
                              notes: workspaceState.notes,
                              activeFromNoteId: _activeDragFromId,
                              activeToPoint: _activeDragToPoint,
                            ),
                          ),
                        ),
                        if (filteredNotes.isEmpty)
                          const Center(
                            child: Text(
                              'لا توجد ملاحظات حالياً.\nاضغط على زر + للإضافة.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ),
                        ...filteredNotes.map((note) => _buildNode(note, notifier)),
                      ],
                    ),
                  ),
                ),
              ), // Closes InteractiveViewer
          ), // Closes Listener

          // Search & Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16, bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.9),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                      ),
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: const InputDecoration(
                          hintText: 'ابحث في الملاحظات...',
                          prefixIcon: Icon(Icons.search, size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _HeaderAction(icon: Icons.center_focus_strong, onTap: () {
                    _transformationController.value = Matrix4.identity()..translate(-1000.0, -1000.0)..scale(0.8);
                  }),
                  const SizedBox(width: 8),
                  // زر الحسابات المالية
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => DraggableScrollableSheet(
                          initialChildSize: 0.75,
                          minChildSize: 0.5,
                          maxChildSize: 0.95,
                          builder: (_, ctrl) => Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFF8FAF9),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                            ),
                            child: Column(
                              children: [
                                const SizedBox(height: 12),
                                Container(
                                  width: 40, height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'الحسابات المالية',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: PatientFinanceTab(
                                    patientId: widget.patientId,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006D63).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF006D63).withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.account_balance_wallet_rounded,
                              size: 16, color: Color(0xFF006D63)),
                          SizedBox(width: 6),
                          Text(
                            'الحسابات',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF006D63),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 24,
            left: 24,
            child: Column(
              children: [
                _FabControl(icon: Icons.add, onTap: () {
                  final matrix = _transformationController.value.clone();
                  matrix.scale(1.2);
                  _transformationController.value = matrix;
                }),
                const SizedBox(height: 12),
                _FabControl(icon: Icons.remove, onTap: () {
                  final matrix = _transformationController.value.clone();
                  matrix.scale(0.8);
                  _transformationController.value = matrix;
                }),
              ],
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: _showAddMenu,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildNode(WorkspaceNote note, WorkspaceNotifier notifier) {
    final isSelected = _selectedNoteId == note.id;

    void onTap() => setState(() => _selectedNoteId = note.id);
    Future<void> onDelete() async {
      if (await _confirmDelete()) {
        notifier.deleteNote(note.id);
      }
    }
    Future<void> onTitleChange(String title) => notifier.updateNoteLocal(note.copyWith(title: title));
    Future<void> onColorChange(String colorHex) => notifier.updateNoteInDb(note.copyWith(colorCustom: colorHex));
    Future<void> onPositionUpdate(double x, double y) => notifier.updateNoteInDb(note.copyWith(positionX: x, positionY: y));
    Future<void> onContentChange(String content) => notifier.updateNoteLocal(note.copyWith(content: content));
    Future<void> onMetadataChange(Map<String, dynamic> metadata) => notifier.updateNoteInDb(note.copyWith(metadata: metadata));
    Future<void> onToggleLock() => notifier.updateNoteInDb(note.copyWith(isLocked: !note.isLocked));
    Future<void> onClearConnections() => notifier.clearConnectionsForNote(note.id);
    
    Null onConnectStart(String id, Offset localPoint) {
      if (!isSelected) return;
      setState(() {
        _activeDragFromId = id;
        _activeDragToPoint = localPoint;
      });
    }

    switch (note.type) {
      case 'visit': return VisitNoteNodeWidget(key: ValueKey(note.id), note: note, isSelected: isSelected, onTap: onTap, onDelete: onDelete, onTitleChange: onTitleChange, onColorChange: onColorChange, onMetadataChange: onMetadataChange, onPositionUpdate: onPositionUpdate, onConnectStart: onConnectStart, onToggleLock: onToggleLock, onClearConnections: onClearConnections);
      case 'prescription': return PrescriptionNodeWidget(key: ValueKey(note.id), note: note, isSelected: isSelected, onTap: onTap, onDelete: onDelete, onTitleChange: onTitleChange, onColorChange: onColorChange, onMetadataChange: onMetadataChange, onPositionUpdate: onPositionUpdate, onConnectStart: onConnectStart, onToggleLock: onToggleLock, onClearConnections: onClearConnections);
      case 'followup': return FollowupNodeWidget(key: ValueKey(note.id), note: note, isSelected: isSelected, onTap: onTap, onDelete: onDelete, onTitleChange: onTitleChange, onColorChange: onColorChange, onMetadataChange: onMetadataChange, onPositionUpdate: onPositionUpdate, onConnectStart: onConnectStart, onToggleLock: onToggleLock, onClearConnections: onClearConnections);
      case 'alert': return AlertNodeWidget(key: ValueKey(note.id), note: note, isSelected: isSelected, onTap: onTap, onDelete: onDelete, onTitleChange: onTitleChange, onColorChange: onColorChange, onContentChange: onContentChange, onPositionUpdate: onPositionUpdate, onConnectStart: onConnectStart, onToggleLock: onToggleLock, onClearConnections: onClearConnections);
      case 'todo': return TodoNodeWidget(key: ValueKey(note.id), note: note, isSelected: isSelected, onTap: onTap, onDelete: onDelete, onTitleChange: onTitleChange, onColorChange: onColorChange, onContentChange: onContentChange, onPositionUpdate: onPositionUpdate, onConnectStart: onConnectStart, onToggleLock: onToggleLock, onClearConnections: onClearConnections);
      case 'image': return ImageNodeWidget(key: ValueKey(note.id), note: note, isSelected: isSelected, onTap: onTap, onDelete: onDelete, onTitleChange: onTitleChange, onColorChange: onColorChange, onPositionUpdate: onPositionUpdate, onConnectStart: onConnectStart, onToggleLock: onToggleLock, onClearConnections: onClearConnections);
      case 'file': return FileNodeWidget(key: ValueKey(note.id), note: note, isSelected: isSelected, onTap: onTap, onDelete: onDelete, onTitleChange: onTitleChange, onColorChange: onColorChange, onPositionUpdate: onPositionUpdate, onConnectStart: onConnectStart, onToggleLock: onToggleLock, onClearConnections: onClearConnections);
      case 'voice': return VoiceNodeWidget(key: ValueKey(note.id), note: note, isSelected: isSelected, onTap: onTap, onDelete: onDelete, onTitleChange: onTitleChange, onColorChange: onColorChange, onMetadataChange: onMetadataChange, onPositionUpdate: onPositionUpdate, onConnectStart: onConnectStart, onToggleLock: onToggleLock, onClearConnections: onClearConnections);
      case 'materials': return MaterialUsageNodeWidget(key: ValueKey(note.id), note: note, isSelected: isSelected, onTap: onTap, onDelete: onDelete, onTitleChange: onTitleChange, onColorChange: onColorChange, onPositionUpdate: onPositionUpdate, onConnectStart: onConnectStart, onToggleLock: onToggleLock, onClearConnections: onClearConnections);
      default: return TextNodeWidget(key: ValueKey(note.id), note: note, isSelected: isSelected, onTap: onTap, onDelete: onDelete, onTitleChange: onTitleChange, onColorChange: onColorChange, onContentChange: onContentChange, onPositionUpdate: onPositionUpdate, onConnectStart: onConnectStart, onToggleLock: onToggleLock, onClearConnections: onClearConnections);
    }
  }
}

class _ModalAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ModalAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: Colors.black54),
      ),
    );
  }
}

class _FabControl extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _FabControl({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)]),
        child: Icon(icon, size: 20, color: Colors.black87),
      ),
    );
  }
}
