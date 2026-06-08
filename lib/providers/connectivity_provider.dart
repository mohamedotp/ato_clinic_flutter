import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/services/sync_service.dart';

final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  
  // Initial check
  final initialStatus = await connectivity.checkConnectivity();
  final initialIsOnline = !initialStatus.contains(ConnectivityResult.none);
  yield initialIsOnline;
  
  // Listen to changes
  await for (final status in connectivity.onConnectivityChanged) {
    final isOnline = !status.contains(ConnectivityResult.none);
    yield isOnline;
    
    // When coming back online, trigger sync of pending mutations
    if (isOnline) {
      SyncService.syncPendingMutations();
    }
  }
});

// A synchronous state provider that we can use to easily check online status
// outside of stream builders if needed, kept in sync with the stream.
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).value ?? true; // Default to true if loading
});
