import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/patient_finance_provider.dart';
import '../../providers/auth_provider.dart';

class PatientFinanceTab extends ConsumerStatefulWidget {
  final String patientId;
  const PatientFinanceTab({super.key, required this.patientId});

  @override
  ConsumerState<PatientFinanceTab> createState() => _PatientFinanceTabState();
}

class _PatientFinanceTabState extends ConsumerState<PatientFinanceTab> {
  static const _primary = Color(0xFF006D63);

  @override
  Widget build(BuildContext context) {
    final financeState = ref.watch(patientFinanceProvider(widget.patientId));
    final auth = ref.watch(authProvider);
    final clinicId = auth is AuthAuthenticated ? auth.profile?.clinicId ?? '' : '';

    if (financeState.isLoading && financeState.summary == null) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }

    final summary = financeState.summary;

    return RefreshIndicator(
      color: _primary,
      onRefresh: () =>
          ref.read(patientFinanceProvider(widget.patientId).notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // ─── Balance Card ──────────────────────────────────────────────────
          if (summary != null) ...[
            _BalanceCard(summary: summary),
            const SizedBox(height: 20),
          ],

          // ─── Quick Pay Button ──────────────────────────────────────────────
          if (summary != null && summary.hasDebt)
            _QuickPayButton(
              patientId: widget.patientId,
              clinicId: clinicId,
              remaining: summary.balance,
            ),

          if (summary != null && summary.hasDebt) const SizedBox(height: 20),

          // ─── Transaction History ───────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded,
                  color: _primary, size: 18),
              const SizedBox(width: 8),
              const Text('سجل المعاملات المالية',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              if (financeState.isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _primary),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (financeState.error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('خطأ: ${financeState.error}',
                  style: TextStyle(color: Colors.red.shade700)),
            )
          else if (financeState.transactions.isEmpty)
            const _EmptyTransactions()
          else
            ...financeState.transactions
                .map((t) => _TransactionTile(transaction: t)),
        ],
      ),
    );
  }
}

// ─── Balance Card ─────────────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final PatientFinancialSummary summary;
  const _BalanceCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final isDebt = summary.hasDebt;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDebt
              ? [Colors.red.shade700, Colors.red.shade900]
              : [const Color(0xFF006D63), const Color(0xFF004D44)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isDebt ? Colors.red : const Color(0xFF006D63))
                .withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDebt ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isDebt ? 'يوجد رصيد مستحق' : 'الحساب خالص',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${summary.balance.abs().toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'ج.م',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isDebt ? 'متبقي على المريض' : 'لا توجد مديونية',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Row(
            children: [
              _FinanceStat(
                label: 'إجمالي التكاليف',
                value: '${summary.totalCharged.toStringAsFixed(0)} ج.م',
                icon: Icons.medical_services_outlined,
              ),
              Expanded(child: Container()),
              _FinanceStat(
                label: 'إجمالي المدفوع',
                value: '${summary.totalPaid.toStringAsFixed(0)} ج.م',
                icon: Icons.payments_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinanceStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _FinanceStat(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white60, size: 14),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(color: Colors.white60, fontSize: 10)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      ],
    );
  }
}

// ─── Quick Pay Button ─────────────────────────────────────────────────────────
class _QuickPayButton extends ConsumerStatefulWidget {
  final String patientId;
  final String clinicId;
  final double remaining;
  const _QuickPayButton({
    required this.patientId,
    required this.clinicId,
    required this.remaining,
  });

  @override
  ConsumerState<_QuickPayButton> createState() => _QuickPayButtonState();
}

class _QuickPayButtonState extends ConsumerState<_QuickPayButton> {
  bool _loading = false;
  final _amountCtrl = TextEditingController();
  String _method = 'cash';

  @override
  void initState() {
    super.initState();
    _amountCtrl.text = widget.remaining.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(patientFinanceProvider(widget.patientId).notifier)
          .recordPayment(
            clinicId: widget.clinicId,
            amount: amount,
            paymentMethod: _method,
            notes: 'سداد جزئي/كلي',
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showPayDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل دفعة سداد',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: StatefulBuilder(
          builder: (ctx, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'المبلغ المدفوع (ج.م)',
                  prefixIcon: Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Payment method
              Wrap(
                spacing: 8,
                children: [
                  for (final m in [
                    ('cash', 'كاش', Icons.money),
                    ('card', 'بطاقة', Icons.credit_card),
                    ('bank_transfer', 'تحويل', Icons.account_balance),
                  ])
                    ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(m.$3, size: 14),
                          const SizedBox(width: 4),
                          Text(m.$2),
                        ],
                      ),
                      selected: _method == m.$1,
                      selectedColor:
                          const Color(0xFF006D63).withValues(alpha: 0.15),
                      onSelected: (v) {
                        if (v) setDialogState(() => _method = m.$1);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006D63),
              foregroundColor: Colors.white,
            ),
            onPressed: _loading ? null : _pay,
            icon: _loading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_rounded),
            label: const Text('تأكيد السداد'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF006D63),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.payments_rounded),
        label: Text(
          'تسجيل دفعة سداد (${widget.remaining.toStringAsFixed(0)} ج.م)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: _showPayDialog,
      ),
    );
  }
}

// ─── Transaction Tile ─────────────────────────────────────────────────────────
class _TransactionTile extends StatelessWidget {
  final PatientTransaction transaction;
  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isPayment = transaction.isPayment;
    final color = isPayment ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isPayment ? Icons.payments_rounded : Icons.medical_services_outlined,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          transaction.description,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: Text(
          DateFormat('d MMM yyyy', 'ar').format(transaction.date.toLocal()),
          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isPayment ? '+' : '-'}${transaction.amount.toStringAsFixed(0)} ج.م',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (transaction.paymentMethod != null)
              Text(
                _methodLabel(transaction.paymentMethod!),
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
              ),
          ],
        ),
      ),
    );
  }

  String _methodLabel(String method) {
    switch (method) {
      case 'cash':
        return '💵 كاش';
      case 'card':
        return '💳 بطاقة';
      case 'bank_transfer':
        return '🏦 تحويل';
      default:
        return method;
    }
  }
}

// ─── Empty Transactions ───────────────────────────────────────────────────────
class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('لا توجد معاملات مالية',
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('ستظهر هنا الزيارات والمدفوعات بعد تسجيلها',
                style:
                    TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
