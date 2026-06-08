import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shift_closure.dart';

class ShiftService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<double> getExpectedCash(String clinicId, String staffId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final response = await _client
          .from('treasury_transactions')
          .select()
          .eq('clinic_id', clinicId)
          .eq('created_by', staffId)
          .eq('payment_method', 'cash')
          .gte('transaction_date', startOfDay.toIso8601String())
          .lte('transaction_date', endOfDay.toIso8601String());

      final jsonList = response as List;
      double total = 0.0;
      for (var json in jsonList) {
        final type = json['type'] as String;
        final amount = (json['amount'] as num).toDouble();
        if (type == 'income') {
          total += amount;
        } else if (type == 'expense') {
          total -= amount;
        }
      }
      return total;
    } catch (e) {
      print('=== Expected Cash Calculation Error: $e ===');
      return 0.0;
    }
  }

  Future<void> closeShift({
    required String clinicId,
    required String staffId,
    required double expectedCash,
    required double actualCash,
    String? notes,
  }) async {
    final difference = actualCash - expectedCash;
    await _client.from('shift_closures').insert({
      'clinic_id': clinicId,
      'staff_id': staffId,
      'expected_cash': expectedCash,
      'actual_cash': actualCash,
      'difference': difference,
      'notes': notes,
      'closed_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<ShiftClosure>> getClosures(String clinicId) async {
    try {
      final response = await _client
          .from('shift_closures')
          .select('*, profiles(full_name)')
          .eq('clinic_id', clinicId)
          .order('created_at', ascending: false);

      final jsonList = response as List;
      return jsonList.map((json) => ShiftClosure.fromJson(json)).toList();
    } catch (e) {
      print('=== Shift Closures Fetch Error: $e ===');
      return [];
    }
  }
}
