import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../providers/internal_chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/staff_provider.dart';
class InternalChatTab extends ConsumerStatefulWidget {
  const InternalChatTab({super.key});

  @override
  ConsumerState<InternalChatTab> createState() => _InternalChatTabState();
}

class _InternalChatTabState extends ConsumerState<InternalChatTab> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _selectedReceiverId;

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;
    final clinicId = authState.profile?.clinicId;
    final senderId = authState.profile?.id;

    if (clinicId == null || senderId == null) return;

    _messageController.clear();
    
    try {
      await ref.read(internalChatServiceProvider).sendMessage(
        clinicId, 
        senderId, 
        text,
        receiverId: _selectedReceiverId,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(internalMessagesProvider);
    final authState = ref.watch(authProvider);
    final currentUserId = authState is AuthAuthenticated ? authState.profile?.id : null;
    const primary = Color(0xFF006D63);

    final staffAsync = ref.watch(staffMembersProvider);

    return Column(
      children: [
        // Staff Horizontal List
        Container(
          height: 105,
          color: Colors.white,
          child: staffAsync.when(
            data: (staffList) {
              final others = staffList.where((s) => s.id != currentUserId).toList();
              return ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _buildStaffAvatar(
                    name: 'شات العيادة',
                    icon: Icons.groups,
                    isSelected: _selectedReceiverId == null,
                    onTap: () => setState(() => _selectedReceiverId = null),
                  ),
                  const SizedBox(width: 12),
                  ...others.map((staff) => Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: _buildStaffAvatar(
                      name: staff.fullName.split(' ').first,
                      icon: Icons.person,
                      isSelected: _selectedReceiverId == staff.id,
                      onTap: () => setState(() => _selectedReceiverId = staff.id),
                    ),
                  )),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
        Divider(height: 1, color: Colors.grey.shade200),
        
        Expanded(
          child: messagesAsync.when(
            data: (allMessages) {
              // Filter messages based on selection
              final messages = allMessages.where((m) {
                if (_selectedReceiverId == null) {
                  // Group chat
                  return m.receiverId == null;
                } else {
                  // 1-on-1 chat
                  return (m.senderId == currentUserId && m.receiverId == _selectedReceiverId) ||
                         (m.senderId == _selectedReceiverId && m.receiverId == currentUserId);
                }
              }).toList();

              if (messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _selectedReceiverId == null ? Icons.forum_outlined : Icons.person_outline, 
                          size: 60, color: primary
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _selectedReceiverId == null ? 'شات العيادة المجمع' : 'محادثة خاصة', 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 8),
                      const Text('ابدأ المحادثة الآن', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }
              
              // Use a post frame callback to scroll to bottom when new messages arrive
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                }
              });

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg.senderId == currentUserId;
                  final isDoctor = msg.senderRole == 'doctor';
                  final senderName = msg.senderName ?? 'مجهول';

                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMe ? primary : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                          bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: isMe ? null : Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMe && _selectedReceiverId == null) // Show name only in group chat
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isDoctor ? Icons.medical_services : Icons.person,
                                    size: 12,
                                    color: isDoctor ? primary : Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    senderName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isDoctor ? primary : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Text(
                            msg.content,
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: isMe ? Alignment.bottomLeft : Alignment.bottomRight,
                            child: Text(
                              DateFormat('hh:mm a').format(msg.createdAt.toLocal()),
                              style: TextStyle(
                                fontSize: 10,
                                color: isMe ? Colors.white70 : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: primary)),
            error: (e, _) => Center(child: Text('خطأ: $e')),
          ),
        ),
        // Input Area
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  onPressed: _sendMessage,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: _selectedReceiverId == null ? 'اكتب رسالة للطاقم...' : 'اكتب رسالة خاصة...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStaffAvatar({
    required String name,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const primary = Color(0xFF006D63);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? primary : Colors.grey.shade100,
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: primary.withOpacity(0.3), width: 4) : null,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? primary : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
