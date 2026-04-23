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
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        FCard(child: Column(children: [
          _SettingTile(Icons.person_outline_rounded, 'Moneda principal', 'Peso Dominicano (DOP)'),
          const Divider(),
          _SettingTile(Icons.access_time_rounded, 'Zona horaria', 'America/Santo_Domingo'),
          const Divider(),
          _SettingTile(Icons.calendar_month_rounded, 'Inicio del período', '1 de cada mes'),
          const Divider(),
          _SettingTile(Icons.cloud_sync_rounded, 'Sincronización', 'Activa — Supabase'),
        ])),
        const SizedBox(height: 16),
        FCard(child: Column(children: [
          _ActionTile(Icons.download_rounded, 'Exportar datos', kBlue, () {}),
          const Divider(),
          _ActionTile(Icons.table_chart_rounded, 'Exportar Excel', kBrand, () {}),
        ])),
        const SizedBox(height: 16),
        FCard(child: _ActionTile(Icons.logout_rounded, 'Cerrar sesión', kRed, () async {
          await Supabase.instance.client.auth.signOut();
        })),
        const SizedBox(height: 24),
        const Center(child: Text('FLUJO Finance OS v1.0.0', style: TextStyle(color: kMuted, fontSize: 12))),
      ]),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _SettingTile(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(children: [
      Icon(icon, color: kMuted, size: 18),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: kText))),
      Text(value, style: const TextStyle(fontSize: 12, color: kMuted)),
    ]),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile(this.icon, this.label, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500)),
        const Spacer(),
        Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.5), size: 18),
      ]),
    ),
  );
}
