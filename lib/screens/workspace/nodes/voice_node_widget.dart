import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:async';

import '../../../models/workspace_note.dart';
import 'base_node_wrapper.dart';

class VoiceNodeWidget extends StatefulWidget {
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

  const VoiceNodeWidget({
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
  State<VoiceNodeWidget> createState() => _VoiceNodeWidgetState();
}

class _VoiceNodeWidgetState extends State<VoiceNodeWidget> {
  final _record = AudioRecorder();
  final _player = AudioPlayer();
  
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isUploading = false;
  int _duration = 0;
  Timer? _timer;
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
  }

  @override
  void dispose() {
    _record.dispose();
    _player.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _startRecording() async {
    try {
      if (await _record.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        _localPath = path;

        const config = RecordConfig();
        await _record.start(config, path: path);

        setState(() {
          _isRecording = true;
          _duration = 0;
        });

        _timer = Timer.periodic(const Duration(seconds: 1), (t) {
          setState(() => _duration++);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نحتاج صلاحية الميكروفون للتسجيل')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في التسجيل: $e')));
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _record.stop();
      _timer?.cancel();
      setState(() => _isRecording = false);

      if (path != null) {
        _uploadRecording(path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في إيقاف التسجيل: $e')));
    }
  }

  Future<void> _uploadRecording(String path) async {
    setState(() => _isUploading = true);
    try {
      final file = File(path);
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final storagePath = 'clinic-files/${widget.note.clinicId}/${widget.note.patientId}/$fileName';

      await Supabase.instance.client.storage.from('doctor-assets').upload(storagePath, file);
      final publicUrl = Supabase.instance.client.storage.from('doctor-assets').getPublicUrl(storagePath);

      widget.onMetadataChange({
        ...(widget.note.metadata ?? {}),
        'duration': _duration,
        'url': publicUrl,
      });
      
      // Update node content to store the URL
      // Since BaseNodeWrapper updates DB on metadata change, but we might want to update content too
      // We'll use a local helper to update both if needed, but for now metadata is fine.
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الرفع: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _togglePlayback() async {
    final url = widget.note.metadata?['url'] ?? widget.note.content;
    if (url == null || url.isEmpty) return;

    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play(UrlSource(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.note.metadata?['url'] ?? widget.note.content;
    final hasAudio = url != null && url.isNotEmpty;

    return BaseNodeWrapper(
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
      icon: Icons.mic_none_outlined,
      child: Center(
        child: _isUploading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isRecording) ...[
                    const Icon(Icons.mic, color: Colors.red, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      _formatTime(_duration),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _stopRecording,
                      icon: const Icon(Icons.stop),
                      label: const Text('إيقاف'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    ),
                  ] else if (hasAudio) ...[
                    GestureDetector(
                      onTap: _togglePlayback,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 32,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _formatTime(widget.note.metadata?['duration'] ?? 0),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _startRecording,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('إعادة تسجيل', style: TextStyle(fontSize: 11)),
                    ),
                  ] else ...[
                    IconButton(
                      icon: const Icon(Icons.mic, size: 48, color: Colors.blueAccent),
                      onPressed: _startRecording,
                    ),
                    const SizedBox(height: 8),
                    const Text('اضغط لبدء التسجيل', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ],
              ),
      ),
    );
  }
}
