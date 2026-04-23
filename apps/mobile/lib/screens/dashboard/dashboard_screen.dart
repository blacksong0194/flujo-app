import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/finance_provider.dart';
import '../../services/theme.dart';
import '../../widgets/common/widgets.dart';
import '../../models/models.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Dashboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          Text(fmtMonth(state.selectedYear, state.selectedMonth),
            style: const TextStyle(fontSize: 12, color: kMuted)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: kBrand),
            onPressed: () => _showAddTransactionSheet(context, ref),
          ),
        ],
      ),
      body: state.isLoading
        ? const LoadingPlaceholder()
        : RefreshIndicator(
            color: kBrand,
            backgroundColor: kSurface,
            onRefresh: () => ref.read(financeProvider.notifier).fetchAll(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                // Period navigation
                _PeriodNav(state: state, ref: ref),
                const SizedBox(height: 16),

                // Alerts
                if (state.totalDebt > 0 && state.totalLiquid > 0)
                  if (state.totalDebt / (state.totalLiquid + state.totalDebt) > 0.85)
                    AlertBannerWidget(
                      title: 'Ratio de endeudamiento crítico',
                      message: 'Tu deuda representa más del 85% de tus activos',
                      color: kRed,
                    ),

                // KPI grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    MetricCard(
                      label: 'Balance líquido',
                      value: fmtCompact(state.totalLiquid),
                      accent: state.totalLiquid >= 0 ? kBrand : kRed,
                      icon: Icons.account_balance_wallet_rounded,
                    ),
                    MetricCard(
                      label: 'Ingresos del mes',
                      value: fmtCompact(state.summary.ingresos),
                      subtitle: '${(state.summary.tasaAhorro * 100).toStringAsFixed(0)}% ahorro',
                      accent: kBrand,
                      icon: Icons.trending_up_rounded,
                    ),
                    MetricCard(
                      label: 'Egresos del mes',
                      value: fmtCompact(state.summary.egresos),
                      subtitle: 'Ahorrado: ${fmtCompact(state.summary.ahorrado)}',
                      accent: kRed,
                      icon: Icons.trending_down_rounded,
                    ),
                    MetricCard(
                      label: 'Patrimonio neto',
                      value: fmtCompact(state.netWorth),
                      subtitle: 'Deuda: ${fmtCompact(state.totalDebt)}',
                      accent: state.netWorth >= 0 ? kBlue : kRed,
                      icon: Icons.pie_chart_outline_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Distribution card
                FCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Activos vs. Deudas', style: kTitle),
                      const SizedBox(height: 14),
                      _SimpleBar('Activos líquidos', state.totalLiquid, state.totalLiquid + state.totalDebt, kBrand),
                      const SizedBox(height: 8),
                      _SimpleBar('Total deudas', state.totalDebt, state.totalLiquid + state.totalDebt, kRed),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Patrimonio neto', style: TextStyle(color: kTextSub, fontSize: 13)),
                          Text(fmtCurrency(state.netWorth),
                            style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700,
                              color: state.netWorth >= 0 ? kBrand : kRed,
                            )),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Recent transactions
                const SectionHeader(title: 'Movimientos recientes'),
                FCard(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: state.transactions.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('Sin movimientos', style: TextStyle(color: kMuted))),
                      )
                    : Column(
                        children: state.transactions.take(6)
                          .map((t) => _TxRow(t))
                          .toList(),
                      ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => context.go('/transactions'),
                  child: const Center(
                    child: Text('Ver todos los movimientos →',
                      style: TextStyle(color: kBrand, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class _PeriodNav extends StatelessWidget {
  final FinanceState state;
  final WidgetRef ref;
  const _PeriodNav({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: kSurface, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: kTextSub, size: 22),
            onPressed: () {
              final notifier = ref.read(financeProvider.notifier);
              if (state.selectedMonth == 1) notifier.setPeriod(state.selectedYear - 1, 12);
              else notifier.setPeriod(state.selectedYear, state.selectedMonth - 1);
            },
          ),
          Text(
            fmtMonth(state.selectedYear, state.selectedMonth),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kText),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, color: kTextSub, size: 22),
            onPressed: () {
              final now = DateTime.now();
              if (state.selectedYear == now.year && state.selectedMonth == now.month) return;
              final notifier = ref.read(financeProvider.notifier);
              if (state.selectedMonth == 12) notifier.setPeriod(state.selectedYear + 1, 1);
              else notifier.setPeriod(state.selectedYear, state.selectedMonth + 1);
            },
          ),
        ],
      ),
    );
  }
}

class _SimpleBar extends StatelessWidget {
  final String label;
  final double value;
  final double total;
  final Color color;
  const _SimpleBar(this.label, this.value, this.total, this.color);

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (value / total).clamp(0.0, 1.0) : 0.0;
    return Row(
      children: [
        SizedBox(width: 130, child: Text(label, style: const TextStyle(color: kMuted, fontSize: 12))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct, minHeight: 8,
              backgroundColor: kBorder,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(fmtCompact(value), style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

class _TxRow extends StatelessWidget {
  final Transaction tx;
  const _TxRow(this.tx);

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == 'income';
    final color = isIncome ? kBrand : kRed;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: color, size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tx.detail, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kText),
                overflow: TextOverflow.ellipsis),
              Text('${tx.category?.name ?? ''} · ${tx.account?.name ?? ''}',
                style: const TextStyle(fontSize: 11, color: kMuted)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${isIncome ? '+' : '-'}${fmtCompact(tx.amount)}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            Text(fmtDate(tx.transactionDate),
              style: const TextStyle(fontSize: 10, color: kMuted)),
          ]),
        ],
      ),
    );
  }
}

// ─── Add Transaction Bottom Sheet ─────────────────────────────────────────────
void _showAddTransactionSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: kSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _AddTransactionSheet(ref: ref),
  );
}

class _AddTransactionSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _AddTransactionSheet({required this.ref});
  @override
  ConsumerState<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<_AddTransactionSheet> {
  String _type = 'income';
  final _detailCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String? _categoryId;
  String? _accountId;
  DateTime _date = DateTime.now();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financeProvider);
    final cats = state.categories.where((c) =>
      _type == 'income' ? c.movementType == 1 : c.movementType == 2).toList();
    final accounts = state.accounts.where((a) => a.isActive).toList();
    final accent = _type == 'income' ? kBrand : kRed;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 16),
          const Text('Nuevo movimiento', style: kTitle),
          const SizedBox(height: 16),

          // Type tabs
          Row(children: ['income', 'expense'].map((t) => Expanded(
            child: GestureDetector(
              onTap: () => setState(() { _type = t; _categoryId = null; }),
              child: Container(
                margin: EdgeInsets.only(right: t == 'income' ? 6 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _type == t ? (t == 'income' ? kBrand : kRed) : kBorder),
                  color: _type == t ? (t == 'income' ? kBrand : kRed).withOpacity(0.1) : Colors.transparent,
                ),
                child: Center(child: Text(
                  t == 'income' ? '↑ Ingreso' : '↓ Egreso',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: _type == t ? (t == 'income' ? kBrand : kRed) : kMuted),
                )),
              ),
            ),
          )).toList()),
          const SizedBox(height: 14),

          // Amount
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(labelText: 'Monto (RD\$)', prefixText: 'RD\$ '),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _detailCtrl,
            style: const TextStyle(color: kText),
            decoration: const InputDecoration(labelText: 'Descripción'),
          ),
          const SizedBox(height: 12),

          // Category dropdown
          DropdownButtonFormField<String>(
            value: _categoryId,
            dropdownColor: kSurface,
            style: const TextStyle(color: kText, fontSize: 13),
            decoration: const InputDecoration(labelText: 'Categoría'),
            items: cats.map((c) => DropdownMenuItem(
              value: c.id,
              child: Text('${c.icon} ${c.name}'),
            )).toList(),
            onChanged: (v) => setState(() => _categoryId = v),
          ),
          const SizedBox(height: 12),

          // Account dropdown
          DropdownButtonFormField<String>(
            value: _accountId,
            dropdownColor: kSurface,
            style: const TextStyle(color: kText, fontSize: 13),
            decoration: const InputDecoration(labelText: 'Cuenta / Almacén'),
            items: accounts.map((a) => DropdownMenuItem(
              value: a.id,
              child: Text(a.name),
            )).toList(),
            onChanged: (v) => setState(() => _accountId = v),
          ),
          const SizedBox(height: 20),

          // Submit
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              onPressed: _loading ? null : _submit,
              child: _loading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Registrar movimiento'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_amountCtrl.text.isEmpty || _categoryId == null || _accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos'), backgroundColor: kRed));
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(financeProvider.notifier).addTransaction({
        'account_id':       _accountId,
        'category_id':      _categoryId,
        'amount':           double.parse(_amountCtrl.text),
        'detail':           _detailCtrl.text,
        'transaction_date': _date.toIso8601String().split('T')[0],
        'type':             _type,
        'is_recurring':     false,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: kRed));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
