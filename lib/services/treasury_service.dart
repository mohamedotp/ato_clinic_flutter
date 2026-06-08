import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/treasury_transaction.dart';

class TreasuryService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<TreasuryTransaction>> getTransactions(String clinicId, {
    String? type,
    DateTime? from,
    DateTime? to,
  }) async {
    var query = _client
        .from('treasury_transactions')
        .select()
        .eq('clinic_id', clinicId);

    if (type != null) query = query.eq('type', type);
    if (from != null) query = query.gte('transaction_date', from.toIso8601String());
    if (to != null) query = query.lte('transaction_date', to.toIso8601String());

    final data = await query.order('transaction_date', ascending: false);
    return (data as List).map((e) => TreasuryTransaction.fromJson(e)).toList();
  }

  Future<TreasuryTransaction> addTransaction(Map<String, dynamic> data) async {
    final res = await _client.from('treasury_transactions').insert(data).select().single();
    return TreasuryTransaction.fromJson(res);
  }

  Future<void> updateTransaction(String id, Map<String, dynamic> data) async {
    await _client.from('treasury_transactions').update(data).eq('id', id);
  }

  Future<void> deleteTransaction(String id) async {
    await _client.from('treasury_transactions').delete().eq('id', id);
  }

  Future<Map<String, double>> getSummary(String clinicId, {DateTime? from, DateTime? to}) async {
    final transactions = await getTransactions(clinicId, from: from, to: to);
    double income = 0, expense = 0;
    for (final t in transactions) {
      if (t.isIncome) income += t.amount;
      else expense += t.amount;
    }
    return {'income': income, 'expense': expense, 'net': income - expense};
  }

  Future<List<Map<String, dynamic>>> getCategories(String clinicId) async {
    final data = await _client
        .from('finance_categories')
        .select()
        .eq('clinic_id', clinicId)
        .eq('is_active', true)
        .order('name');
    return List<Map<String, dynamic>>.from(data);
  }

  /// Revenue per day for the last N days — for charts
  Future<List<Map<String, dynamic>>> getDailyRevenue(String clinicId, int days) async {
    final from = DateTime.now().subtract(Duration(days: days));
    final transactions = await getTransactions(clinicId, from: from);
    final Map<String, double> byDay = {};
    for (final t in transactions) {
      if (!t.isIncome) continue;
      final d = t.transactionDate;
      final key = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
      byDay[key] = (byDay[key] ?? 0) + t.amount;
    }
    final sorted = byDay.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return sorted.map((e) => {'day': e.key, 'revenue': e.value}).toList();
  }

  /// Doctor-wise revenue breakdown
  Future<List<Map<String, dynamic>>> getDoctorRevenue(String clinicId) async {
    final data = await _client
        .from('visits')
        .select('doctor_id, cost, profiles!doctor_id(full_name)')
        .eq('clinic_id', clinicId)
        .eq('status', 'completed');

    final Map<String, Map<String, dynamic>> doctorMap = {};
    for (final row in data as List) {
      final doctorId = row['doctor_id'] as String? ?? 'unknown';
      final doctorName = row['profiles']?['full_name'] ?? 'غير محدد';
      final cost = (row['cost'] as num?)?.toDouble() ?? 0;
      if (!doctorMap.containsKey(doctorId)) {
        doctorMap[doctorId] = {'id': doctorId, 'name': doctorName, 'revenue': 0.0, 'visits': 0};
      }
      doctorMap[doctorId]!['revenue'] = (doctorMap[doctorId]!['revenue'] as double) + cost;
      doctorMap[doctorId]!['visits'] = (doctorMap[doctorId]!['visits'] as int) + 1;
    }
    return doctorMap.values.toList()..sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));
  }
}
