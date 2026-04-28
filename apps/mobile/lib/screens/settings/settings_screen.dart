import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/theme.dart';
import '../../services/export_service.dart';
import '../../widgets/common/widgets.dart';
import '../../providers/finance_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const SectionHeader(title: 'Preferencias'),
        FCard(child: Column(children: [
          _SettingTile(Icons.attach_money_rounded, 'Moneda principal', 'Peso Dominicano (DOP)'),
          const Divider(),
          _SettingTile(Icons.access_time_rounded, 'Zona horaria', 'America/Santo_Domingo'),
          const Divider(),
          _SettingTile(Icons.calendar_month_rounded, 'Inicio del periodo', '1 de cada mes'),
          const Divider(),
          _SettingTile(Icons.cloud_done_rounded, 'Sincronizacion', 'Activa - Supabase'),
        ])),
        const SizedBox(height: 16),

        const SectionHeader(title: 'Exportar datos'),
        FCard(child: Column(children: [
          _ActionTile(Icons.table_chart_rounded, 'Exportar como Excel', kBrand, () =>
            _showExportDialog(context, ref, state)),
        ])),
        const SizedBox(height: 16),

        const SectionHeader(title: 'Cuenta'),
        FCard(child: Column(children: [
          _ActionTile(Icons.open_in_new_rounded, 'Gestionar en la web', kMuted, () async {
            final url = Uri.parse('https://flujo-app-web.vercel.app');
            if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
          }),
          const Divider(),
          _ActionTile(Icons.logout_rounded, 'Cerrar sesion', kRed, () async {
            await Supabase.instance.client.auth.signOut();
            if (context.mounted) context.go('/auth/login');
          }),
        ])),
        const SizedBox(height: 32),
        const Center(child: Column(children: [
          Text('FLUJO Finance OS', style: TextStyle(color: kMuted, fontSize: 12, fontWeight: FontWeight.w600)),
          SizedBox(height: 2),
          Text('Version 1.0.0', style: TextStyle(color: kMuted, fontSize: 11)),
        ])),
      ]),
    );
  }
}

void _showExportDialog(BuildContext context, WidgetRef ref, state) {
  showModalBottomSheet(
    context: context,
    backgroundColor: kSurface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _ExportSheet(ref: ref, state: state),
  );
}

class _ExportSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final dynamic state;
  const _ExportSheet({required this.ref, required this.state});
  @override
  ConsumerState<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends ConsumerState<_ExportSheet> {
  ExportPeriod _period = ExportPeriod.currentMonth;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 4,
          decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(4)))),
        const SizedBox(height: 20),
        const Text('Exportar reporte Excel', style: kTitle),
        const SizedBox(height: 6),
        const Text('El reporte incluye movimientos, cuentas, presupuestos, metas y cobros pendientes.',
          style: TextStyle(color: kMuted, fontSize: 12)),
        const SizedBox(height: 20),
        const Text('PERIODO', style: TextStyle(color: kMuted, fontSize: 10, letterSpacing: .8, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        _PeriodOption(
          label: 'Mes actual',
          subtitle: 'Solo los movimientos del mes seleccionado',
          selected: _period == ExportPeriod.currentMonth,
          onTap: () => setState(() => _period = ExportPeriod.currentMonth),
        ),
        const SizedBox(height: 8),
        _PeriodOption(
          label: 'Ultimos 3 meses',
          subtitle: 'Movimientos de los ultimos 3 meses',
          selected: _period == ExportPeriod.last3Months,
          onTap: () => setState(() => _period = ExportPeriod.last3Months),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: kBrand, padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: _loading ? null : _export,
            icon: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.download_rounded, size: 18),
            label: Text(_loading ? 'Generando...' : 'Generar y compartir Excel'),
          ),
        ),
      ]),
    );
  }

  Future<void> _export() async {
    setState(() => _loading = true);
    try {
      final state = ref.read(financeProvider);
      await ExportService.exportExcel(
        transactions: state.transactions,
        accounts:     state.accounts,
        budgets:      state.budgets,
        goals:        state.goals,
        pendingItems: state.pendingItems,
        period:       _period,
        selectedYear:  state.selectedYear,
        selectedMonth: state.selectedMonth,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: kRed));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _PeriodOption extends StatelessWidget {
  final String label, subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _PeriodOption({required this.label, required this.subtitle, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: selected ? kBrand : kBorder, width: selected ? 1.5 : 1),
        color: selected ? kBrand.withOpacity(0.06) : Colors.transparent,
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? kBrand : kText)),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: kMuted)),
        ])),
        if (selected) const Icon(Icons.check_circle_rounded, color: kBrand, size: 18),
      ]),
    ),
  );
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
        Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500))),
        Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.5), size: 18),
      ]),
    ),
  );
}
