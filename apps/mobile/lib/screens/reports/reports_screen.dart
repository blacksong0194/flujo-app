// reports_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/finance_provider.dart';
import '../../services/theme.dart';
import '../../widgets/common/widgets.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeProvider);
    final summary = state.summary;

    // Category totals for the period
    final spentMap = <String, double>{};
    final spentNames = <String, String>{};
    final spentColors = <String, String>{};
    for (final t in state.transactions.where((t) =>
      t.type == 'expense' &&
      t.transactionDate.year == state.selectedYear &&
      t.transactionDate.month == state.selectedMonth)) {
      spentMap[t.categoryId]   = (spentMap[t.categoryId]   ?? 0) + t.amount;
      spentNames[t.categoryId] = t.category?.name ?? t.categoryId;
      spentColors[t.categoryId]= t.category?.color ?? '#ef4444';
    }
    final sorted = spentMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // KPI row
        GridView.count(crossAxisCount: 2, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.7,
          children: [
            MetricCard(label: 'Ingresos', value: fmtCompact(summary.ingresos), accent: kBrand, icon: Icons.trending_up_rounded),
            MetricCard(label: 'Egresos',  value: fmtCompact(summary.egresos),  accent: kRed,   icon: Icons.trending_down_rounded),
            MetricCard(label: 'Ahorrado', value: fmtCompact(summary.ahorrado), accent: kBlue,  icon: Icons.savings_rounded),
            MetricCard(label: 'Tasa ahorro', value: fmtPercent(summary.tasaAhorro), accent: kAmber, icon: Icons.percent_rounded),
          ]),
        const SizedBox(height: 20),

        // Expense breakdown
        const SectionHeader(title: 'Egresos por categoría'),
        FCard(
          child: sorted.isEmpty
            ? const Padding(padding: EdgeInsets.all(20),
                child: Center(child: Text('Sin egresos en este período', style: TextStyle(color: kMuted))))
            : Column(
                children: sorted.take(8).map((entry) {
                  final pct = summary.egresos > 0 ? entry.value / summary.egresos : 0.0;
                  final color = hexColor(spentColors[entry.key] ?? '#ef4444');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(spentNames[entry.key] ?? '', style: const TextStyle(fontSize: 13, color: kText)),
                        Text(fmtCompact(entry.value), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        Expanded(child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(value: pct, minHeight: 5,
                            backgroundColor: kBorder,
                            valueColor: AlwaysStoppedAnimation(color)))),
                        const SizedBox(width: 8),
                        Text('${(pct * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 10, color: kMuted)),
                      ]),
                    ]),
                  );
                }).toList(),
              ),
        ),
        const SizedBox(height: 20),

        // Indicators
        const SectionHeader(title: 'Indicadores financieros'),
        FCard(
          child: Column(children: [
            _IndicatorRow('Ratio ingreso/egreso',
              summary.egresos > 0 ? '${(summary.ingresos / summary.egresos).toStringAsFixed(2)}x' : '—',
              'Meta: >1.2x',
              summary.ingresos / (summary.egresos > 0 ? summary.egresos : 1) >= 1.2 ? kBrand : kAmber),
            const Divider(),
            _IndicatorRow('Gasto sobre ingresos',
              summary.ingresos > 0 ? '${(summary.egresos / summary.ingresos * 100).toStringAsFixed(1)}%' : '—',
              summary.ingresos > 0 && summary.egresos / summary.ingresos < 0.8 ? 'Nivel saludable' : 'Alto — revisar',
              summary.ingresos > 0 && summary.egresos / summary.ingresos < 0.8 ? kBrand : kRed),
            const Divider(),
            _IndicatorRow('Transacciones del mes',
              state.transactions.where((t) =>
                t.transactionDate.year == state.selectedYear &&
                t.transactionDate.month == state.selectedMonth).length.toString(),
              'Total del período', kBlue),
          ]),
        ),
      ]),
    );
  }
}

class _IndicatorRow extends StatelessWidget {
  final String label, value, note;
  final Color color;
  const _IndicatorRow(this.label, this.value, this.note, this.color);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 13, color: kText)),
        Text(note, style: const TextStyle(fontSize: 11, color: kMuted)),
      ])),
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

// settings_screen.dart
