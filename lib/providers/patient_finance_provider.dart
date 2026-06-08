import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Patient Financial Summary Model ─────────────────────────────────────────
class PatientFinancialSummary {
  final double totalCharged;  // مجموع تكاليف الزيارات
  final double totalPaid;     // مجموع المدفوعات المسجلة
  final double balance;       // الرصيد = المطلوب - المدفوع

  const PatientFinancialSummary({
    required this.totalCharged,
    required this.totalPaid,
    required this.balance,
  });

  /// هل عليه مديونية؟
  bool get hasDebt => balance > 0.5;

  /// هل حسابه خالص أو له رصيد دائن؟
  bool get isClear => balance <= 0.5;
}

// ─── Patient Transaction Model ────────────────────────────────────────────────
class PatientTransaction {
  final String id;
  final String type; // 'charge' | 'payment'
  final double amount;
  final String description;
  final DateTime date;
  final String? paymentMethod;

  const PatientTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    this.paymentMethod,
  });

  bool get isCharge => type == 'charge';
  bool get isPayment => type == 'payment';
}

// ─── State ────────────────────────────────────────────────────────────────────
class PatientFinanceState {
  final PatientFinancialSummary? summary;
  final List<PatientTransaction> transactions;
  final bool isLoading;
  final String? error;

  const PatientFinanceState({
    this.summary,
    this.transactions = const [],
    this.isLoading = false,
    this.error,
  });

  PatientFinanceState copyWith({
    PatientFinancialSummary? summary,
    List<PatientTransaction>? transactions,
    bool? isLoading,
    String? error,
  }) {
    return PatientFinanceState(
      summary: summary ?? this.summary,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────
class PatientFinanceNotifier extends StateNotifier<PatientFinanceState> {
  final SupabaseClient _client = Supabase.instance.client;
  final String patientId;

  PatientFinanceNotifier(this.patientId) : super(const PatientFinanceState()) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 1) جلب تكاليف الزيارات المكتملة
      final visitsRes = await _client
          .from('visits')
          .select('id, cost, visit_date, diagnosis, status')
          .eq('patient_id', patientId)
          .eq('status', 'completed');

      // 2) جلب المدفوعات المرتبطة بهذا المريض في الخزينة
      final paymentsRes = await _client
          .from('treasury_transactions')
          .select('id, amount, description, transaction_date, payment_method, type')
          .eq('reference_id', patientId)
          .eq('type', 'income');

      final List<PatientTransaction> txList = [];
      double totalCharged = 0;
      double totalPaid = 0;

      // تحميل الزيارات كـ "مطلوبات"
      for (final v in visitsRes as List) {
        final cost = (v['cost'] as num?)?.toDouble() ?? 0;
        totalCharged += cost;
        if (cost > 0) {
          txList.add(PatientTransaction(
            id: v['id'],
            type: 'charge',
            amount: cost,
            description: v['diagnosis'] != null && (v['diagnosis'] as String).isNotEmpty
                ? 'زيارة: ${v['diagnosis']}'
                : 'زيارة طبية',
            date: v['visit_date'] != null
                ? DateTime.parse(v['visit_date'])
                : DateTime.now(),
          ));
        }
      }

      // تحميل المدفوعات
      for (final p in paymentsRes as List) {
        final amount = (p['amount'] as num?)?.toDouble() ?? 0;
        totalPaid += amount;
        txList.add(PatientTransaction(
          id: p['id'],
          type: 'payment',
          amount: amount,
          description: p['description'] ?? 'دفعة سداد',
          date: DateTime.parse(p['transaction_date']),
          paymentMethod: p['payment_method'],
        ));
      }

      // ترتيب تنازلي حسب التاريخ
      txList.sort((a, b) => b.date.compareTo(a.date));

      final balance = totalCharged - totalPaid;

      state = state.copyWith(
        summary: PatientFinancialSummary(
          totalCharged: totalCharged,
          totalPaid: totalPaid,
          balance: balance,
        ),
        transactions: txList,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _load();

  /// تسجيل دفعة سداد يدوية للمريض
  Future<void> recordPayment({
    required String clinicId,
    required double amount,
    required String paymentMethod,
    String? notes,
  }) async {
    try {
      await _client.from('treasury_transactions').insert({
        'clinic_id': clinicId,
        'type': 'income',
        'amount': amount,
        'category': 'زيارات مرضى',
        'description': notes ?? 'دفعة سداد من مريض',
        'payment_method': paymentMethod,
        'reference_id': patientId,
        'reference_type': 'patient',
        'transaction_date': DateTime.now().toIso8601String(),
      });
      await _load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────
final patientFinanceProvider =
    StateNotifierProvider.family<PatientFinanceNotifier, PatientFinanceState, String>(
  (ref, patientId) => PatientFinanceNotifier(patientId),
);
