import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/finance_provider.dart';
import '../../services/theme.dart';
import '../../widgets/common/widgets.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeProvider);
    final txs = state.transactions.where((t) =>
      t.transactionDate.year == state.selectedYear &&
      t.transactionDate.month == state.selectedMonth).toList();

    final spentMap = <String, double>{};
    for (final t in txs.where((t) => t.type == 'expense')) {
      spentMap[t.categoryId] = (spentMap[t.categoryId] ?? 0) + t.amount;
    }

    final totalBudget = state.budgets.fold(0.0, (s, b) => s + b.amount);
    final totalSpent  = state.budgets.fold(0.0, (s, b) => s + (spentMap[b.categoryId] ?? 0));
    final totalLeft   = totalBudget - totalSpent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presupuesto mensual'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: kBrand),
            onPressed: () => _showAddBudgetSheet(context, ref, state),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Expanded(child: _KpiCard(label: 'Presupuestado', value: fmtCompact(totalBudget), color: kBlue)),
            const SizedBox(width: 10),
            Expanded(child: _KpiCard(label: 'Gastado', value: fmtCompact(totalSpent), color: kRed)),
            const SizedBox(width: 10),
            Expanded(child: _KpiCard(label: 'Disponible', value: fmtCompact(totalLeft), color: kBrand)),
          ]),
          const SizedBox(height: 20),
          if (state.budgets.isEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.pie_chart_outline_rounded, color: kMuted, size: 48),
                const SizedBox(height: 12),
                const Text('Sin presupuestos configurados',
                  style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('Define limites de gasto por categoria',
                  style: TextStyle(color: kMuted, fontSize: 13), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _showAddBudgetSheet(context, ref, state),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Crear primer presupuesto'),
                ),
              ]),
            ))
          else
            ...state.budgets.map((b) {
              final spent = spentMap[b.categoryId] ?? 0;
              final pct   = b.amount > 0 ? (spent / b.amount * 100) : 0.0;
              final color = pct >= 100 ? kRed : pct >= 80 ? kAmber : kBrand;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(b.category?.name ?? 'Sin nombre',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kText)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                        child: Text(pct >= 100 ? 'Excedido' : pct >= 80 ? 'Atencion' : 'Normal',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color))),
                    ]),
                    const SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Gastado: ${fmtCompact(spent)}', style: const TextStyle(fontSize: 12, color: kMuted)),
                      Text('Limite: ${fmtCompact(b.amount)}', style: const TextStyle(fontSize: 12, color: kMuted)),
                    ]),
                    const SizedBox(height: 6),
                    FProgressBar(percent: pct.toDouble()),
                    const SizedBox(height: 4),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('${pct.toStringAsFixed(0)}% utilizado',
                        style: const TextStyle(fontSize: 11, color: kMuted)),
                      Text(b.amount - spent >= 0
                        ? '${fmtCompact(b.amount - spent)} restante'
                        : '${fmtCompact((b.amount - spent).abs())} excedido',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                    ]),
                  ]),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _KpiCard({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: kSurface, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kBorder)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(),
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: kMuted, letterSpacing: 0.5),
        maxLines: 2, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 6),
      Text(value,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color),
        overflow: TextOverflow.ellipsis),
    ]),
  );
}

void _showAddBudgetSheet(BuildContext context, WidgetRef ref, state) {
  showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: kSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _AddBudgetSheet(
      ref: ref,
      categories: state.categories.where((c) => c.movementType == 2).toList()),
  );
}

class _AddBudgetSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final List categories;
  const _AddBudgetSheet({required this.ref, required this.categories});
  @override
  ConsumerState<_AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends ConsumerState<_AddBudgetSheet> {
  final _amountCtrl = TextEditingController();
  String? _categoryId;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 4,
          decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(4)))),
        const SizedBox(height: 16),
        const Text('Nuevo presupuesto', style: kTitle),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _categoryId,
          dropdownColor: kSurface,
          style: const TextStyle(color: kText, fontSize: 13),
          decoration: const InputDecoration(labelText: 'Categoria'),
          items: widget.categories.map<DropdownMenuItem<String>>((c) =>
            DropdownMenuItem(value: c.id, child: Text('${c.icon} ${c.name}'))).toList(),
          onChanged: (v) => setState(() => _categoryId = v),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: kText, fontSize: 16),
          decoration: const InputDecoration(labelText: 'Limite mensual (RD\$)', prefixText: 'RD\$ '),
        ),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Crear presupuesto'),
          )),
      ]),
    );
  }

  Future<void> _submit() async {
    if (_categoryId == null || _amountCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos'), backgroundColor: kRed));
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(financeProvider.notifier).addBudget({
        'category_id':      _categoryId,
        'amount':           double.parse(_amountCtrl.text),
        'period':           'monthly',
        'alert_at_percent': 80,
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
