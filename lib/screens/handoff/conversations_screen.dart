import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/clinic_provider.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class Conversation {
  final String phone;
  final String patientName;
  final String? patientId;
  final DateTime lastMessageAt;
  final String lastMessage;
  final String? lastAiResponse;
  final int messageCount;
  final bool aiPaused;
  final String? instance;

  Conversation({
    required this.phone,
    required this.patientName,
    this.patientId,
    required this.lastMessageAt,
    required this.lastMessage,
    this.lastAiResponse,
    required this.messageCount,
    required this.aiPaused,
    this.instance,
  });

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        phone: j['phone'] ?? '',
        patientName: j['patient_name'] ?? 'زائر',
        patientId: j['patient_id'],
        lastMessageAt: DateTime.parse(j['last_message_at']),
        lastMessage: j['last_message'] ?? '',
        lastAiResponse: j['last_ai_response'],
        messageCount: j['message_count'] ?? 0,
        aiPaused: j['ai_paused'] ?? false,
        instance: j['instance'],
      );
}

class WaMessage {
  final String id;
  final String phone;
  final String msg;
  final String? aiResponse;
  final String status;
  final DateTime createdAt;
  final DateTime? processedAt;

  WaMessage({
    required this.id,
    required this.phone,
    required this.msg,
    this.aiResponse,
    required this.status,
    required this.createdAt,
    this.processedAt,
  });

  factory WaMessage.fromJson(Map<String, dynamic> j) => WaMessage(
        id: j['id'] ?? '',
        phone: j['phone'] ?? '',
        msg: j['msg'] ?? '',
        aiResponse: j['ai_response'],
        status: j['status'] ?? '',
        createdAt: DateTime.parse(j['created_at']),
        processedAt:
            j['processed_at'] != null ? DateTime.parse(j['processed_at']) : null,
      );
}

// ── Providers ─────────────────────────────────────────────────────────────────

final conversationsProvider =
    FutureProvider.autoDispose<List<Conversation>>((ref) async {
  final clinic = await ref.watch(clinicProvider.future);
  if (clinic == null) return [];

  final supabase = Supabase.instance.client;

  // جيب كل الرسائل الخاصة بالعيادة
  final rows = await supabase
      .from('ai_messages_queue')
      .select('phone, msg, ai_response, status, created_at, instance')
      .eq('instance', clinic.evolutionInstance)
      .order('created_at', ascending: false);

  // جمّعها حسب phone
  final Map<String, Map<String, dynamic>> grouped = {};
  for (final row in rows) {
    final phone = row['phone'] as String;
    if (!grouped.containsKey(phone)) {
      grouped[phone] = {
        'phone': phone,
        'last_message': row['msg'],
        'last_ai_response': row['ai_response'],
        'last_message_at': row['created_at'],
        'message_count': 1,
        'instance': row['instance'],
        'ai_paused': false,
        'patient_name': 'زائر',
        'patient_id': null,
      };
    } else {
      grouped[phone]!['message_count'] =
          (grouped[phone]!['message_count'] as int) + 1;
    }
  }

  if (grouped.isEmpty) return [];

  // جيب بيانات المرضى
  final phones = grouped.keys.toList();
  final patients = await supabase
      .from('patients')
      .select('id, phone, full_name')
      .eq('clinic_id', clinic.id)
      .inFilter('phone', phones);

  for (final p in patients) {
    final phone = p['phone'] as String;
    if (grouped.containsKey(phone)) {
      grouped[phone]!['patient_name'] = p['full_name'];
      grouped[phone]!['patient_id'] = p['id'];
    }
  }

  // جيب حالة الـ handoff لكل phone
  final handoffs = await supabase
      .from('handoff_requests')
      .select('phone, ai_paused, status')
      .eq('clinic_id', clinic.id)
      .neq('status', 'resolved')
      .eq('ai_paused', true);

  for (final h in handoffs) {
    final phone = h['phone'] as String;
    if (grouped.containsKey(phone)) {
      grouped[phone]!['ai_paused'] = true;
    }
  }

  return grouped.values.map((m) => Conversation.fromJson(m)).toList()
    ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
});

final chatMessagesProvider = FutureProvider.autoDispose
    .family<List<WaMessage>, String>((ref, phone) async {
  final supabase = Supabase.instance.client;
  final rows = await supabase
      .from('ai_messages_queue')
      .select()
      .eq('phone', phone)
      .order('created_at', ascending: true);
  return rows.map((r) => WaMessage.fromJson(r)).toList();
});

// ── Conversations List Screen ──────────────────────────────────────────────────

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    return 'منذ ${diff.inDays} يوم';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const primary = Color(0xFF006D63);
    final convAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        title: const Text(
          'محادثات الواتساب',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(conversationsProvider),
          ),
        ],
      ),
      body: convAsync.when(
        data: (convs) {
          if (convs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chat_bubble_outline_rounded,
                        size: 60, color: primary),
                  ),
                  const SizedBox(height: 20),
                  const Text('لا توجد محادثات بعد',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 8),
                  const Text('سيظهر هنا كل من تواصل عبر الواتساب',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: primary,
            onRefresh: () async => ref.invalidate(conversationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: convs.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade200, indent: 80),
              itemBuilder: (ctx, i) {
                final c = convs[i];
                return _ConvTile(
                  conv: c,
                  timeAgo: _timeAgo(c.lastMessageAt),
                  onTap: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => ChatDetailScreen(conversation: c),
                    ),
                  ).then((_) => ref.invalidate(conversationsProvider)),
                );
              },
            ),
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF006D63))),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('خطأ في تحميل المحادثات\n$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(conversationsProvider),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Conversation Tile ─────────────────────────────────────────────────────────

class _ConvTile extends StatelessWidget {
  final Conversation conv;
  final String timeAgo;
  final VoidCallback onTap;

  const _ConvTile(
      {required this.conv, required this.timeAgo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF006D63);
    final isVisitor = conv.patientName == 'زائر' ||
        conv.patientName.startsWith('Visitor-');
    final displayName =
        isVisitor ? conv.phone : conv.patientName;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      conv.aiPaused ? Colors.orange.shade100 : const Color(0xFFE0F2F1),
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: conv.aiPaused ? Colors.orange : primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
                if (conv.aiPaused)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.pause_circle_filled,
                          size: 16, color: Colors.orange),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(timeAgo,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    conv.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 13),
                  ),
                  if (conv.aiPaused) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pause_rounded,
                              size: 11, color: Colors.orange),
                          SizedBox(width: 3),
                          Text('AI موقف - بانتظار ردك',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.orange)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Message count badge
            if (conv.messageCount > 1) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${conv.messageCount}',
                  style: const TextStyle(
                      color: primary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Chat Detail Screen ────────────────────────────────────────────────────────

class ChatDetailScreen extends ConsumerStatefulWidget {
  final Conversation conversation;
  const ChatDetailScreen({super.key, required this.conversation});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _supabase = Supabase.instance.client;
  bool _aiPaused = false;

  @override
  void initState() {
    super.initState();
    _aiPaused = widget.conversation.aiPaused;
  }

  Future<void> _toggleAI() async {
    try {
      if (_aiPaused) {
        // شغّل الـ AI: resolve كل الـ handoff requests النشطة
        await _supabase
            .from('handoff_requests')
            .update({
              'status': 'resolved',
              'ai_paused': false,
              'resolved_at': DateTime.now().toIso8601String(),
            })
            .eq('phone', widget.conversation.phone)
            .eq('ai_paused', true)
            .neq('status', 'resolved');
      } else {
        // وقّف الـ AI: عمل handoff request جديد
        final clinic = await ref.read(clinicProvider.future);
        if (clinic == null) return;

        await _supabase.from('handoff_requests').insert({
          'clinic_id': clinic.id,
          'phone': widget.conversation.phone,
          'patient_name': widget.conversation.patientName,
          'status': 'handling',
          'ai_paused': true,
        });
      }
      setState(() => _aiPaused = !_aiPaused);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_aiPaused ? '⏸ AI موقف' : '▶ AI شغال تاني'),
            backgroundColor: _aiPaused ? Colors.orange : const Color(0xFF006D63),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
      }
    }
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF006D63);
    final msgsAsync =
        ref.watch(chatMessagesProvider(widget.conversation.phone));
    final isVisitor = widget.conversation.patientName == 'زائر' ||
        widget.conversation.patientName.startsWith('Visitor-');
    final displayName =
        isVisitor ? widget.conversation.phone : widget.conversation.patientName;

    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 40,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text(
                displayName[0].toUpperCase(),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  Text(widget.conversation.phone,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // AI Toggle Button
          GestureDetector(
            onTap: _toggleAI,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _aiPaused
                    ? Colors.orange.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _aiPaused ? Colors.orange : Colors.white54,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _aiPaused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    size: 16,
                    color: _aiPaused ? Colors.orange : Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _aiPaused ? 'شغّل AI' : 'وقّف AI',
                    style: TextStyle(
                      fontSize: 12,
                      color: _aiPaused ? Colors.orange : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // AI Status Banner
          if (_aiPaused)
            Container(
              color: Colors.orange.shade100,
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.pause_circle_filled,
                      size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'الـ AI موقف - أنت المسؤول عن الرد دلوقتي',
                      style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  TextButton(
                    onPressed: _toggleAI,
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(60, 24)),
                    child: const Text('شغّله',
                        style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // Messages List
          Expanded(
            child: msgsAsync.when(
              data: (msgs) {
                if (msgs.isEmpty) {
                  return const Center(
                      child: Text('لا توجد رسائل',
                          style: TextStyle(color: Colors.grey)));
                }
                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: msgs.length,
                  itemBuilder: (ctx, i) {
                    final m = msgs[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Patient message (right side in Arabic)
                        _MessageBubble(
                          text: m.msg,
                          time: _formatTime(m.createdAt),
                          isAI: false,
                          status: m.status,
                        ),
                        // AI response (left side)
                        if (m.aiResponse != null && m.aiResponse!.isNotEmpty)
                          _MessageBubble(
                            text: m.aiResponse!,
                            time: m.processedAt != null
                                ? _formatTime(m.processedAt!)
                                : '',
                            isAI: true,
                            status: m.status,
                          ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: Color(0xFF006D63))),
              error: (e, _) => Center(child: Text('خطأ: $e')),
            ),
          ),

          // Phone Copy Bar
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.conversation.phone,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded,
                      size: 20, color: Colors.grey),
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: widget.conversation.phone));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('تم نسخ الرقم'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 1)),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message Bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool isAI;
  final String status;

  const _MessageBubble({
    required this.text,
    required this.time,
    required this.isAI,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF006D63);

    return Align(
      alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isAI ? Colors.white : primary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                isAI ? const Radius.circular(4) : const Radius.circular(16),
            bottomRight:
                isAI ? const Radius.circular(16) : const Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isAI ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            if (isAI)
              const Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.smart_toy_outlined,
                        size: 11, color: Color(0xFF006D63)),
                    SizedBox(width: 3),
                    Text('AI',
                        style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF006D63),
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            Text(
              text,
              style: TextStyle(
                color: isAI ? Colors.black87 : Colors.white,
                fontSize: 14,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (time.isNotEmpty)
                  Text(
                    time,
                    style: TextStyle(
                      color: isAI ? Colors.grey : Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                if (!isAI) ...[
                  const SizedBox(width: 4),
                  Icon(
                    status == 'completed'
                        ? Icons.done_all_rounded
                        : Icons.done_rounded,
                    size: 12,
                    color: status == 'completed'
                        ? Colors.lightBlueAccent
                        : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
