import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audit_service.dart';
import '../models/audit_log.dart';
import 'auth_provider.dart';

final auditServiceProvider = Provider((ref) => AuditService());

final auditLogsProvider = FutureProvider.autoDispose<List<AuditLog>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return [];
  
  final clinicId = authState.profile?.clinicId;
  if (clinicId == null || clinicId.isEmpty) return [];

  return ref.read(auditServiceProvider).getLogs(clinicId);
});
