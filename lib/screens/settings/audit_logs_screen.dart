import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../providers/audit_provider.dart';
import '../../models/audit_log.dart';

class AuditLogsScreen extends ConsumerWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(auditLogsProvider);
    const primaryColor = Color(0xFF006D63);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('سجل العمليات والرقابة والأمن', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(auditLogsProvider),
          ),
        ],
      ),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد عمليات مسجلة في النظام حالياً',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return _AuditLogCard(log: log);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: primaryColor)),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text('خطأ في تحميل سجل العمليات: $err', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
          ),
        ),
      ),
    );
  }
}

class _AuditLogCard extends StatefulWidget {
  final AuditLog log;
  const _AuditLogCard({required this.log});

  @override
  State<_AuditLogCard> createState() => _AuditLogCardState();
}

class _AuditLogCardState extends State<_AuditLogCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    final formattedTime = DateFormat('yyyy/MM/dd - hh:mm a').format(log.createdAt.toLocal());
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Row(
              children: [
                Text(
                  formattedTime,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                _ActionBadge(action: log.action),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 8),
                Text(
                  log.description,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      log.userFullName ?? 'موظف مجهول',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                  ],
                ),
              ],
            ),
            leading: log.oldValues != null || log.newValues != null
                ? IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: const Color(0xFF006D63),
                    ),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                  )
                : const SizedBox(width: 48),
          ),
          if (_isExpanded && (log.oldValues != null || log.newValues != null))
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'تفاصيل التغيير:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  if (log.oldValues != null) ...[
                    const Text('القيم السابقة:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                    const SizedBox(height: 4),
                    _buildJsonWidget(log.oldValues!),
                    const SizedBox(height: 12),
                  ],
                  if (log.newValues != null) ...[
                    const Text('القيم الجديدة:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 4),
                    _buildJsonWidget(log.newValues!),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildJsonWidget(Map<String, dynamic> json) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: json.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Text(
                '${entry.key}: ${entry.value}',
                style: const TextStyle(
                  color: Colors.lightGreenAccent,
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ActionBadge extends StatelessWidget {
  final String action;
  const _ActionBadge({required this.action});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    String label = action;

    if (action.contains('create') || action.contains('add')) {
      color = Colors.green;
      label = 'إضافة جديد';
    } else if (action.contains('update') || action.contains('edit')) {
      color = Colors.blue;
      label = 'تعديل';
    } else if (action.contains('delete') || action.contains('remove')) {
      color = Colors.red;
      label = 'حذف';
    } else if (action.contains('login') || action.contains('auth')) {
      color = Colors.orange;
      label = 'أمان';
    } else if (action.contains('close') || action.contains('closure')) {
      color = Colors.purple;
      label = 'تسوية مالية';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}
