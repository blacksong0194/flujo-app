// budgets_screen.dart
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

    return Scaffold(
      appBar: AppBar(title: const Text('Presupuesto')),
      body: state.budgets.isEmpty
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.pie_chart_outline_rounded, color: kMuted, size: 48),
            const SizedBox(height: 12),
            const Text('Sin presupuestos', style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Configura límites de gasto por categoría', style: TextStyle(color: kMuted)),
          ]))
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemCount: state.budgets.length,
            itemBuilder: (ctx, i) {
              final b = state.budgets[i];
              final spent = spentMap[b.categoryId] ?? 0;
              final pct = b.amount > 0 ? (spent / b.amount * 100) : 0.0;
              final color = pct >= 100 ? kRed : pct >= 80 ? kAmber : kBrand;
              return FCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(b.category?.name ?? 'Sin nombre',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kText)),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20)),
                      child: Text(pct >= 100 ? 'Excedido' : pct >= 80 ? 'Atención' : 'Normal',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color))),
                  ]),
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Gastado: ${fmtCompact(spent)}', style: const TextStyle(fontSize: 12, color: kMuted)),
                    Text('Límite: ${fmtCompact(b.amount)}', style: const TextStyle(fontSize: 12, color: kMuted)),
                  ]),
                  const SizedBox(height: 6),
                  FProgressBar(percent: pct.toDouble()),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('${pct.toStringAsFixed(0)}% utilizado', style: const TextStyle(fontSize: 11, color: kMuted)),
                    Text(b.amount - spent >= 0 ? '${fmtCompact(b.amount - spent)} restante' : '${fmtCompact((b.amount - spent).abs())} excedido',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                  ]),
                ]),
              );
            },
          ),
    );
  }
}
