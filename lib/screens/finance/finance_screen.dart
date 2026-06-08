import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../services/treasury_service.dart';
import '../../models/treasury_transaction.dart';
import '../../providers/shift_provider.dart';
import '../../providers/audit_provider.dart';

final _treasuryServiceProvider = Provider((ref) => TreasuryService());

final _transactionsProvider = FutureProvider.family<List<TreasuryTransaction>, String>((ref, clinicId) {
  return ref.read(_treasuryServiceProvider).getTransactions(clinicId);
});

final _dailyRevenueProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, clinicId) {
  return ref.read(_treasuryServiceProvider).getDailyRevenue(clinicId, 7);
});

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const primaryColor = Color(0xFF006D63);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _clinicId {
    final auth = ref.read(authProvider);
    return auth is AuthAuthenticated ? (auth.profile?.clinicId ?? '') : '';
  }

  @override
  Widget build(BuildContext context) {
    final transAsync = ref.watch(_transactionsProvider(_clinicId));
    final chartAsync = ref.watch(_dailyRevenueProvider(_clinicId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('المالية والخزينة', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: primaryColor),
            onPressed: () => _showAddTransactionSheet(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryColor,
          tabs: const [
            Tab(text: 'الملخص'),
            Tab(text: 'الإيرادات'),
            Tab(text: 'المصروفات'),
            Tab(text: 'تسوية الخزينة'),
          ],
        ),
      ),
      body: transAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (transactions) {
          final income = transactions.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
          final expense = transactions.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount);
          final net = income - expense;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildSummaryTab(income, expense, net, transactions, chartAsync),
              _buildTransactionList(transactions.where((t) => t.isIncome).toList(), isIncome: true),
              _buildTransactionList(transactions.where((t) => t.isExpense).toList(), isIncome: false),
              _buildShiftClosureTab(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryTab(double income, double expense, double net,
      List<TreasuryTransaction> transactions, AsyncValue<List<Map<String, dynamic>>> chartAsync) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(_transactionsProvider(_clinicId)),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Net Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: net >= 0
                      ? [const Color(0xFF006D63), const Color(0xFF004D40)]
                      : [Colors.red.shade700, Colors.red.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (net >= 0 ? primaryColor : Colors.red).withValues(alpha: 0.3),
                    blurRadius: 20, offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('صافي الرصيد', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    '${net.toStringAsFixed(0)} ج.م',
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _MiniStat(label: 'إيرادات', value: income, color: Colors.greenAccent),
                      const SizedBox(width: 16),
                      _MiniStat(label: 'مصروفات', value: expense, color: Colors.redAccent),
                    ],
                  ),
                ],
              ),
            ).animate().fade().slideY(begin: -0.2),

            const SizedBox(height: 20),

            // Revenue Chart
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('الإيرادات (آخر 7 أيام)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 160,
                    child: chartAsync.when(
                      data: (chartData) {
                        if (chartData.isEmpty) {
                          return const Center(child: Text('لا توجد بيانات', style: TextStyle(color: Colors.grey)));
                        }
                        return BarChart(
                          BarChartData(
                            barGroups: chartData.asMap().entries.map((e) {
                              return BarChartGroupData(x: e.key, barRods: [
                                BarChartRodData(
                                  toY: (e.value['amount'] as double),
                                  color: primaryColor,
                                  width: 16,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ]);
                            }).toList(),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() >= chartData.length) return const SizedBox();
                                    final date = chartData[value.toInt()]['date'] as String;
                                    final parts = date.split('-');
                                    return Text('${parts[2]}/${parts[1]}', style: const TextStyle(fontSize: 9));
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                          ),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => const SizedBox(),
                    ),
                  ),
                ],
              ),
            ).animate().fade(delay: 200.ms),

            const SizedBox(height: 20),

            // Recent Transactions
            const Align(
              alignment: Alignment.centerRight,
              child: Text('آخر المعاملات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 12),
            ...transactions.take(5).map((t) => _TransactionCard(
              transaction: t,
              onDelete: () async {
                await ref.read(_treasuryServiceProvider).deleteTransaction(t.id);
                ref.invalidate(_transactionsProvider(_clinicId));
              },
            ).animate().fade().slideX()).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(List<TreasuryTransaction> list, {required bool isIncome}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isIncome ? Icons.trending_up : Icons.trending_down, size: 64,
                color: (isIncome ? Colors.green : Colors.red).withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('لا توجد ${isIncome ? "إيرادات" : "مصروفات"} مسجلة',
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(_transactionsProvider(_clinicId)),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: list.length,
        itemBuilder: (context, i) => _TransactionCard(
          transaction: list[i],
          onDelete: () async {
            await ref.read(_treasuryServiceProvider).deleteTransaction(list[i].id);
            ref.invalidate(_transactionsProvider(_clinicId));
          },
        ).animate().fade().slideX(begin: 0.1),
      ),
    );
  }

  void _showAddTransactionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTransactionSheet(
        clinicId: _clinicId,
        onSaved: () => ref.invalidate(_transactionsProvider(_clinicId)),
      ),
    );
  }

  Widget _buildShiftClosureTab() {
    return _ShiftClosureTab(clinicId: _clinicId);
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
            Text('${value.toStringAsFixed(0)} ج.م', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final TreasuryTransaction transaction;
  final VoidCallback onDelete;

  const _TransactionCard({required this.transaction, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.isIncome;
    final color = isIncome ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
          ),
          const Spacer(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(transaction.category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                if (transaction.description != null)
                  Text(transaction.description!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(transaction.paymentMethodLabel, style: TextStyle(color: color, fontSize: 10)),
                    ),
                    const SizedBox(width: 8),
                    Text(DateFormat('dd/MM/yyyy').format(transaction.transactionDate), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 18),
                Text('${transaction.amount.toStringAsFixed(0)}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTransactionSheet extends ConsumerStatefulWidget {
  final String clinicId;
  final VoidCallback onSaved;

  const _AddTransactionSheet({required this.clinicId, required this.onSaved});

  @override
  ConsumerState<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<_AddTransactionSheet> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'income';
  String _paymentMethod = 'cash';
  String _category = 'إيرادات أخرى';
  bool _loading = false;

  static const primaryColor = Color(0xFF006D63);

  final _incomeCategories = ['زيارات مرضى', 'تأمين طبي', 'مبيعات منتجات', 'إيرادات أخرى'];
  final _expenseCategories = ['رواتب وأجور', 'إيجار وخدمات', 'مستلزمات طبية', 'صيانة', 'مصاريف تشغيلية'];

  List<String> get _categories => _type == 'income' ? _incomeCategories : _expenseCategories;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('إضافة معاملة مالية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // Type toggle
            Row(
              children: [
                Expanded(child: _TypeBtn(label: 'مصروف', icon: Icons.arrow_upward, selected: _type == 'expense', color: Colors.red,
                    onTap: () => setState(() { _type = 'expense'; _category = _expenseCategories.first; }))),
                const SizedBox(width: 12),
                Expanded(child: _TypeBtn(label: 'إيراد', icon: Icons.arrow_downward, selected: _type == 'income', color: Colors.green,
                    onTap: () => setState(() { _type = 'income'; _category = _incomeCategories.first; }))),
              ],
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<String>(
              value: _category,
              decoration: InputDecoration(labelText: 'الفئة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),

            // Amount
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              decoration: InputDecoration(labelText: 'المبلغ (ج.م)', prefixIcon: const Icon(Icons.payments_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 12),

            // Payment Method
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: InputDecoration(labelText: 'طريقة الدفع', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('نقدي')),
                DropdownMenuItem(value: 'card', child: Text('بطاقة')),
                DropdownMenuItem(value: 'transfer', child: Text('تحويل')),
                DropdownMenuItem(value: 'insurance', child: Text('تأمين')),
              ],
              onChanged: (v) => setState(() => _paymentMethod = v!),
            ),
            const SizedBox(height: 12),

            // Description
            TextFormField(
              controller: _descCtrl,
              textAlign: TextAlign.right,
              decoration: InputDecoration(labelText: 'ملاحظات (اختياري)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('حفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;
    setState(() => _loading = true);
    try {
      await ref.read(_treasuryServiceProvider).addTransaction({
        'clinic_id': widget.clinicId,
        'type': _type,
        'amount': amount,
        'category': _category,
        'description': _descCtrl.text.isEmpty ? null : _descCtrl.text,
        'payment_method': _paymentMethod,
        'transaction_date': DateTime.now().toIso8601String(),
      });
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeBtn({required this.label, required this.icon, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : Colors.transparent, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? color : Colors.grey, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: selected ? color : Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _ShiftClosureTab extends ConsumerStatefulWidget {
  final String clinicId;
  const _ShiftClosureTab({required this.clinicId});

  @override
  ConsumerState<_ShiftClosureTab> createState() => _ShiftClosureTabState();
}

class _ShiftClosureTabState extends ConsumerState<_ShiftClosureTab> {
  final _actualCashCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _actualCashCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitClosure(double expected) async {
    final actual = double.tryParse(_actualCashCtrl.text) ?? 0.0;
    final diff = actual - expected;

    setState(() => _isSubmitting = true);
    try {
      final authState = ref.read(authProvider);
      if (authState is! AuthAuthenticated) return;
      
      final staffId = authState.profile?.id ?? '';
      final staffName = authState.profile?.fullName ?? '';

      // 1. Submit Shift Closure
      await ref.read(shiftServiceProvider).closeShift(
        clinicId: widget.clinicId,
        staffId: staffId,
        expectedCash: expected,
        actualCash: actual,
        notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
      );

      // 2. Log Security/Audit Event
      String diffMsg = diff == 0 
          ? 'بدون فروقات مالية (مطابق)' 
          : (diff < 0 ? 'بعجز مالي بقيمة ${diff.abs()} ج.م' : 'بزيادة مالية بقيمة $diff ج.م');
          
      await ref.read(auditServiceProvider).logEvent(
        clinicId: widget.clinicId,
        userId: staffId,
        action: 'shift_closure',
        tableName: 'shift_closures',
        description: 'قام موظف الاستقبال $staffName بإغلاق وتسوية الوردية المالية اليوم $diffMsg',
        newValues: {
          'expected_cash': expected,
          'actual_cash': actual,
          'difference': diff,
          'notes': _notesCtrl.text,
        },
      );

      // 3. Reset and Invalidate
      _actualCashCtrl.clear();
      _notesCtrl.clear();
      ref.invalidate(expectedCashProvider);
      ref.invalidate(shiftClosuresProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل إغلاق الخزينة والوردية بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في إغلاق الوردية: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expectedAsync = ref.watch(expectedCashProvider);
    final closuresAsync = ref.watch(shiftClosuresProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Expected Cash Panel
          expectedAsync.when(
            data: (expected) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'الرصيد النقدي المتوقع بالدرج اليوم',
                      style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${expected.toStringAsFixed(2)} ج.م',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF006D63)),
                    ),
                    const Divider(height: 30),
                    
                    // Form fields
                    const Text('الرصيد الفعلي الموجود بالدرج حالياً', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _actualCashCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        suffixText: 'ج.م',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    
                    // Real-time Variance Checker
                    if (_actualCashCtrl.text.isNotEmpty) ...[
                      () {
                        final actual = double.tryParse(_actualCashCtrl.text) ?? 0.0;
                        final variance = actual - expected;
                        Color varColor = Colors.green;
                        String varLabel = 'رصيد مطابق تماماً (ممتاز)';
                        IconData varIcon = Icons.check_circle;

                        if (variance < 0) {
                          varColor = Colors.red;
                          varLabel = 'عجز مالي بقيمة ${variance.abs().toStringAsFixed(2)} ج.م';
                          varIcon = Icons.warning_amber_rounded;
                        } else if (variance > 0) {
                          varColor = Colors.blue;
                          varLabel = 'زيادة مالية بقيمة ${variance.toStringAsFixed(2)} ج.م';
                          varIcon = Icons.info_outline;
                        }

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: varColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: varColor.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(varLabel, style: TextStyle(color: varColor, fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(width: 8),
                              Icon(varIcon, color: varColor, size: 18),
                            ],
                          ),
                        );
                      }(),
                      const SizedBox(height: 16),
                    ],

                    const Text('ملاحظات التسوية (اختياري)', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesCtrl,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'اكتب سبباً للعجز أو أي ملاحظات أخرى...',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : () => _submitClosure(expected),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00302D),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('تسجيل إغلاق الخزينة والوردية الآن', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('خطأ: $e')),
          ),

          const SizedBox(height: 32),
          const Text('سجل تسويات وإغلاقات الخزينة السابقة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          closuresAsync.when(
            data: (closures) {
              if (closures.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text('لا توجد تسويات سابقة مسجلة', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: closures.length,
                itemBuilder: (context, index) {
                  final closure = closures[index];
                  final formattedDate = DateFormat('yyyy/MM/dd - hh:mm a').format(closure.closedAt.toLocal());
                  
                  Color diffColor = Colors.green;
                  String diffLabel = 'رصيد مطابق';
                  if (closure.difference < 0) {
                    diffColor = Colors.red;
                    diffLabel = 'عجز: ${closure.difference.abs().toStringAsFixed(0)} ج.م';
                  } else if (closure.difference > 0) {
                    diffColor = Colors.blue;
                    diffLabel = 'زيادة: ${closure.difference.toStringAsFixed(0)} ج.م';
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.01),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Text(
                              formattedDate,
                              style: TextStyle(color: Colors.grey[400], fontSize: 11),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: diffColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                diffLabel,
                                style: TextStyle(color: diffColor, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'تسوية الموظف: ${closure.staffFullName ?? "موظف"}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('الرصيد الفعلي: ${closure.actualCash.toStringAsFixed(0)} ج.م', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(width: 12),
                            Text('الرصيد المتوقع: ${closure.expectedCash.toStringAsFixed(0)} ج.م', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        if (closure.notes != null && closure.notes!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('ملاحظة: ${closure.notes}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.blueGrey)),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('خطأ: $e')),
          ),
        ],
      ),
    );
  }
}
