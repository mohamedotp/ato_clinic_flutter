import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/clinic_provider.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class HandoffRequest {
  final String id;
  final String clinicId;
  final String phone;
  final String patientName;
  final String status; // pending | handling | resolved
  final bool aiPaused;
  final DateTime requestedAt;
  final DateTime? resolvedAt;
  final String? notes;

  HandoffRequest({
    required this.id,
    required this.clinicId,
    required this.phone,
    required this.patientName,
    required this.status,
    required this.aiPaused,
    required this.requestedAt,
    this.resolvedAt,
    this.notes,
  });

  factory HandoffRequest.fromJson(Map<String, dynamic> j) => HandoffRequest(
        id: j['id'] ?? '',
        clinicId: j['clinic_id'] ?? '',
        phone: j['phone'] ?? '',
        patientName: j['patient_name'] ?? 'زائر',
        status: j['status'] ?? 'pending',
        aiPaused: j['ai_paused'] ?? true,
        requestedAt: DateTime.parse(j['requested_at']),
        resolvedAt:
            j['resolved_at'] != null ? DateTime.parse(j['resolved_at']) : null,
        notes: j['notes'],
      );
}

// ── Provider ──────────────────────────────────────────────────────────────────

final handoffProvider =
    StreamProvider.autoDispose<List<HandoffRequest>>((ref) {
  final clinicAsync = ref.watch(clinicProvider);
  final clinic = clinicAsync.valueOrNull;
  if (clinic == null) return Stream.value([]);

  final supabase = Supabase.instance.client;

  // Real-time stream using Supabase Realtime
  return supabase
      .from('handoff_requests')
      .stream(primaryKey: ['id'])
      .eq('clinic_id', clinic.id)
      .order('requested_at', ascending: false)
      .map((rows) => rows
          .where((r) => r['status'] != 'resolved')
          .map((r) => HandoffRequest.fromJson(r))
          .toList());
});

// ── Screen ────────────────────────────────────────────────────────────────────

class HandoffScreen extends ConsumerStatefulWidget {
  const HandoffScreen({super.key});

  @override
  ConsumerState<HandoffScreen> createState() => _HandoffScreenState();
}

class _HandoffScreenState extends ConsumerState<HandoffScreen> {
  final _supabase = Supabase.instance.client;
  bool _showResolved = false;

  Future<void> _updateHandoff(String id, Map<String, dynamic> data) async {
    try {
      await _supabase.from('handoff_requests').update(data).eq('id', id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  Future<void> _toggleAI(HandoffRequest req) async {
    await _updateHandoff(req.id, {'ai_paused': !req.aiPaused});
  }

  Future<void> _markHandling(HandoffRequest req) async {
    await _updateHandoff(req.id, {'status': 'handling'});
  }

  Future<void> _markResolved(HandoffRequest req) async {
    await _updateHandoff(req.id, {
      'status': 'resolved',
      'ai_paused': false,
      'resolved_at': DateTime.now().toIso8601String(),
    });
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'منذ ${diff.inSeconds} ث';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    return 'منذ ${diff.inDays} يوم';
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF006D63);
    final handoffAsync = ref.watch(handoffProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('مركز التحويل للموظف',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => setState(() => _showResolved = !_showResolved),
            child: Text(
              _showResolved ? 'إخفاء المحلولة' : 'عرض المحلولة',
              style: const TextStyle(color: primary, fontSize: 12),
            ),
          ),
        ],
      ),
      body: handoffAsync.when(
        data: (list) {
          final filtered = _showResolved
              ? list
              : list.where((r) => r.status != 'resolved').toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F3F1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline,
                        size: 56, color: primary),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'لا يوجد طلبات تحويل حالياً',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'سيظهر هنا أي مريض يطلب التكلم مع موظف',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) => _HandoffCard(
              request: filtered[i],
              timeAgo: _timeAgo(filtered[i].requestedAt),
              onToggleAI: () => _toggleAI(filtered[i]),
              onHandling: () => _markHandling(filtered[i]),
              onResolved: () => _markResolved(filtered[i]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
      ),
    );
  }
}

// ── Card Widget ───────────────────────────────────────────────────────────────

class _HandoffCard extends StatelessWidget {
  final HandoffRequest request;
  final String timeAgo;
  final VoidCallback onToggleAI;
  final VoidCallback onHandling;
  final VoidCallback onResolved;

  const _HandoffCard({
    required this.request,
    required this.timeAgo,
    required this.onToggleAI,
    required this.onHandling,
    required this.onResolved,
  });

  Color get _statusColor {
    switch (request.status) {
      case 'pending':
        return Colors.orange;
      case 'handling':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String get _statusLabel {
    switch (request.status) {
      case 'pending':
        return 'ينتظر';
      case 'handling':
        return 'جاري التعامل';
      case 'resolved':
        return 'تم الحل';
      default:
        return request.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isResolved = request.status == 'resolved';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isResolved
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.orange.withValues(alpha: 0.3),
          width: isResolved ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isResolved
                  ? Colors.green.withValues(alpha: 0.05)
                  : Colors.orange.withValues(alpha: 0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                            color: _statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _statusLabel,
                        style: TextStyle(
                            color: _statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // AI Paused indicator
                if (request.aiPaused)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pause_circle_filled,
                            size: 12, color: Colors.red),
                        SizedBox(width: 4),
                        Text('AI موقف',
                            style:
                                TextStyle(color: Colors.red, fontSize: 11)),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                Text(timeAgo,
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF006D63), Color(0xFF004D40)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          request.patientName.isNotEmpty
                              ? request.patientName[0]
                              : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.patientName,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.phone_outlined,
                                  size: 13, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                request.phone,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (!isResolved) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // ── Action Buttons ───────────────────────────
                  Row(
                    children: [
                      // Toggle AI
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onToggleAI,
                          icon: Icon(
                            request.aiPaused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            size: 16,
                          ),
                          label: Text(
                            request.aiPaused ? 'شغّل AI' : 'وقّف AI',
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: request.aiPaused
                                ? Colors.green
                                : Colors.orange,
                            side: BorderSide(
                                color: request.aiPaused
                                    ? Colors.green
                                    : Colors.orange),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Handling
                      if (request.status == 'pending')
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onHandling,
                            icon: const Icon(Icons.support_agent, size: 16),
                            label: const Text('بدأت أتكلم',
                                style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue,
                              side: const BorderSide(color: Colors.blue),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),

                      const SizedBox(width: 8),

                      // Resolved
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onResolved,
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('تم الحل',
                              style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006D63),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
