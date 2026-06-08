import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/treasury_service.dart';
import '../../models/treasury_transaction.dart';
import '../../providers/patients_provider.dart';

final _treasuryServiceProvider = Provider((ref) => TreasuryService());

final _transactionsProvider = FutureProvider.family<List<TreasuryTransaction>,
    ({String clinicId, DateTime? from, DateTime? to})>((ref, args) {
  return ref
      .read(_treasuryServiceProvider)
      .getTransactions(args.clinicId, from: args.from, to: args.to);
});

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const primaryColor = Color(0xFF006D63);

  // Date range filter
  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _from, end: _to),
      locale: const Locale('ar'),
      helpText: 'اختر الفترة الزمنية',
      saveText: 'تأكيد',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: primaryColor),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      setState(() {
        _from = range.start;
        _to = range.end.add(const Duration(hours: 23, minutes: 59));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinicId = _clinicId;
    if (clinicId.isEmpty) {
      return const Scaffold(body: Center(child: Text('غير مصرح')));
    }

    final args = (clinicId: clinicId, from: _from, to: _to);
    final transAsync = ref.watch(_transactionsProvider(args));
    final patientsAsync = ref.watch(patientsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('التقارير والتحليلات',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          GestureDetector(
            onTap: _pickDateRange,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range, color: primaryColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${DateFormat('dd/MM').format(_from)} - ${DateFormat('dd/MM').format(_to)}',
                    style: const TextStyle(
                        color: primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryColor,
          isScrollable: true,
          tabs: const [
            Tab(text: 'تقارير سريعة'),
            Tab(text: 'قائمة الدخل'),
            Tab(text: 'المصروفات'),
            Tab(text: 'الإحالات'),
            Tab(text: 'التوقعات'),
          ],
        ),
      ),
      body: transAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text('خطأ في تحميل البيانات: $e'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(_transactionsProvider(args)),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
        data: (transactions) {
          final income = transactions
              .where((t) => t.isIncome)
              .fold(0.0, (s, t) => s + t.amount);
          final expense = transactions
              .where((t) => t.isExpense)
              .fold(0.0, (s, t) => s + t.amount);
          final net = income - expense;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildQuickReports(transactions, income, expense, net),
              _buildIncomeStatement(transactions, income, expense, net),
              _buildExpenseAnalysis(transactions),
              _buildMarketingAnalysis(patientsAsync),
              _buildForecasting(transactions, income, expense),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuickReports(List<TreasuryTransaction> txs, double income,
      double expense, double net) {
    // Daily revenue map for bar chart
    final Map<String, double> byDay = {};
    for (var t in txs) {
      if (!t.isIncome) continue;
      final key = DateFormat('dd/MM').format(t.transactionDate);
      byDay[key] = (byDay[key] ?? 0) + t.amount;
    }
    final days = byDay.entries.toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Row
        Row(
          children: [
            _SummaryCard(
                title: 'الإيرادات',
                value: '${income.toStringAsFixed(0)} ج',
                icon: Icons.arrow_downward,
                color: Colors.green.withValues(alpha: 0.1),
                iconColor: Colors.green),
            const SizedBox(width: 8),
            _SummaryCard(
                title: 'المصروفات',
                value: '${expense.toStringAsFixed(0)} ج',
                icon: Icons.arrow_upward,
                color: Colors.red.withValues(alpha: 0.1),
                iconColor: Colors.red),
            const SizedBox(width: 8),
            _SummaryCard(
                title: 'الصافي',
                value: '${net.toStringAsFixed(0)} ج',
                icon: Icons.account_balance_wallet,
                color: net >= 0
                    ? primaryColor.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                iconColor: net >= 0 ? primaryColor : Colors.red),
          ].map((c) => Expanded(child: c)).toList(),
        ).animate().fade().slideY(),
        const SizedBox(height: 20),
        if (days.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('الإيرادات اليومية',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                AspectRatio(
                  aspectRatio: 1.6,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i < 0 || i >= days.length) {
                                return const SizedBox();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(days[i].key,
                                    style: const TextStyle(
                                        fontSize: 9, color: Colors.grey)),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: days.asMap().entries.map((e) {
                        return BarChartGroupData(x: e.key, barRods: [
                          BarChartRodData(
                            toY: e.value.value,
                            color: primaryColor,
                            width: 14,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                          )
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fade().slideY(),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('نسبة الإيرادات / المصروفات',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (income + expense > 0)
                AspectRatio(
                  aspectRatio: 1.6,
                  child: PieChart(PieChartData(
                    sections: [
                      PieChartSectionData(
                          value: income,
                          title: 'إيرادات\n${income.toStringAsFixed(0)} ج',
                          color: Colors.green,
                          radius: 60,
                          titleStyle: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      PieChartSectionData(
                          value: expense,
                          title: 'مصروفات\n${expense.toStringAsFixed(0)} ج',
                          color: Colors.red,
                          radius: 60,
                          titleStyle: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ],
                    centerSpaceRadius: 40,
                  )),
                )
              else
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('لا توجد بيانات في هذه الفترة',
                            style: TextStyle(color: Colors.grey)))),
            ],
          ),
        ).animate().fade(),
      ],
    );
  }

  Widget _buildIncomeStatement(List<TreasuryTransaction> txs, double income,
      double expense, double net) {
    final incomeItems = txs.where((t) => t.isIncome).toList();
    // Group income by category
    final Map<String, double> incomeByCategory = {};
    for (var t in incomeItems) {
      incomeByCategory[t.category] =
          (incomeByCategory[t.category] ?? 0) + t.amount;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('قائمة الدخل (P&L)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                '${DateFormat('dd MMM').format(_from)} - ${DateFormat('dd MMM yyyy').format(_to)}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Divider(),
              // Income breakdown
              ...incomeByCategory.entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 8, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(e.key.isEmpty ? 'إيرادات أخرى' : e.key)),
                        Text('${e.value.toStringAsFixed(2)} ج.م',
                            style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                  )),
              const Divider(),
              _plRow('إجمالي الإيرادات', income, Colors.green, bold: true),
              _plRow('إجمالي المصروفات', expense, Colors.red, bold: true),
              const Divider(thickness: 2),
              _plRow('صافي الربح / الخسارة', net,
                  net >= 0 ? Colors.green : Colors.red,
                  bold: true),
            ],
          ),
        ).animate().fade().scale(),
      ],
    );
  }

  Widget _plRow(String label, double value, Color color,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontWeight:
                          bold ? FontWeight.bold : FontWeight.normal))),
          Text('${value.toStringAsFixed(2)} ج.م',
              style: TextStyle(
                  color: color,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildExpenseAnalysis(List<TreasuryTransaction> txs) {
    final expenses = txs.where((t) => t.isExpense).toList();
    if (expenses.isEmpty) {
      return const Center(
          child: Text('لا توجد مصروفات في هذه الفترة',
              style: TextStyle(color: Colors.grey)));
    }
    final Map<String, double> categories = {};
    for (var e in expenses) {
      categories[e.category.isEmpty ? 'أخرى' : e.category] =
          (categories[e.category.isEmpty ? 'أخرى' : e.category] ?? 0) +
              e.amount;
    }
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.blue,
      Colors.teal
    ];
    final sorted = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = expenses.fold(0.0, (s, t) => s + t.amount);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('المصروفات حسب الفئة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              AspectRatio(
                aspectRatio: 1.4,
                child: PieChart(PieChartData(
                  sections: sorted.asMap().entries.map((e) {
                    final pct = (e.value.value / total * 100).toStringAsFixed(0);
                    return PieChartSectionData(
                      value: e.value.value,
                      title: '$pct%',
                      color: colors[e.key % colors.length],
                      radius: 60,
                      titleStyle: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    );
                  }).toList(),
                )),
              ),
              const SizedBox(height: 16),
              ...sorted.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                              color: colors[e.key % colors.length],
                              shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(e.value.key)),
                        Text('${e.value.value.toStringAsFixed(2)} ج.م',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Text(
                          '${(e.value.value / total * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                              color: colors[e.key % colors.length],
                              fontSize: 12),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ).animate().fade(),
      ],
    );
  }

  Widget _buildMarketingAnalysis(AsyncValue patientsAsync) {
    return patientsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (patients) {
        final List pts = patients as List;
        final Map<String, int> sources = {};
        for (var p in pts) {
          final src = (p.referralSource as String?) ?? 'غير محدد';
          sources[src] = (sources[src] ?? 0) + 1;
        }
        final total = pts.length;
        final sorted = sources.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final colors = [
          primaryColor,
          Colors.blue,
          Colors.orange,
          Colors.purple,
          Colors.teal
        ];

        if (sorted.isEmpty) {
          return const Center(
              child: Text('لا توجد بيانات إحالة',
                  style: TextStyle(color: Colors.grey)));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('مصادر المرضى والإحالات',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('إجمالي $total مريض',
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 16),
                  ...sorted.asMap().entries.map((e) {
                    final pct = total > 0 ? e.value.value / total : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.people_alt,
                                  color: colors[e.key % colors.length],
                                  size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(e.value.key)),
                              Text('${e.value.value} مريض',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Text(
                                  '${(pct * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                      color: colors[e.key % colors.length],
                                      fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: pct,
                            color: colors[e.key % colors.length],
                            backgroundColor:
                                colors[e.key % colors.length].withValues(alpha: 0.1),
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ).animate().fade().slideX(),
          ],
        );
      },
    );
  }

  Widget _buildForecasting(
      List<TreasuryTransaction> txs, double income, double expense) {
    // Real calculation based on selected period
    final days = _to.difference(_from).inDays.clamp(1, 365);
    final dailyIncome = income / days;
    final dailyExpense = expense / days;
    final projectedIncome30 = dailyIncome * 30;
    final projectedExpense30 = dailyExpense * 30;
    final projectedNet30 = projectedIncome30 - projectedExpense30;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF006D63), Color(0xFF004D40)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Icon(Icons.trending_up, color: Colors.white, size: 48),
              const SizedBox(height: 12),
              const Text('التوقعات للـ 30 يوم القادمة',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 4),
              Text('بناءً على متوسط الـ $days يوم الماضية',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ForecastStat(
                      label: 'إيرادات متوقعة',
                      value: '${projectedIncome30.toStringAsFixed(0)} ج',
                      color: Colors.greenAccent),
                  _ForecastStat(
                      label: 'مصروفات متوقعة',
                      value: '${projectedExpense30.toStringAsFixed(0)} ج',
                      color: Colors.redAccent),
                  _ForecastStat(
                      label: 'صافي متوقع',
                      value: '${projectedNet30.toStringAsFixed(0)} ج',
                      color: projectedNet30 >= 0
                          ? Colors.yellowAccent
                          : Colors.redAccent),
                ],
              ),
            ],
          ),
        ).animate().fade().scale(),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('المؤشرات اليومية',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _KpiRow(
                  label: 'متوسط الإيراد اليومي',
                  value: '${dailyIncome.toStringAsFixed(0)} ج/يوم',
                  icon: Icons.show_chart,
                  color: Colors.green),
              _KpiRow(
                  label: 'متوسط المصروف اليومي',
                  value: '${dailyExpense.toStringAsFixed(0)} ج/يوم',
                  icon: Icons.trending_down,
                  color: Colors.red),
              _KpiRow(
                  label: 'هامش الربح',
                  value: income > 0
                      ? '${((income - expense) / income * 100).toStringAsFixed(1)}%'
                      : '—',
                  icon: Icons.percent,
                  color: primaryColor),
            ],
          ),
        ).animate().fade().slideY(),
      ],
    );
  }
}

class _ForecastStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ForecastStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
            textAlign: TextAlign.center),
      ],
    );
  }
}

class _KpiRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _KpiRow(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(value,
              style:
                  TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color iconColor;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 5,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: iconColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
