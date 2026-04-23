import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../services/theme.dart';
import '../../widgets/common/widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const SectionHeader(title: 'Preferencias'),
        FCard(child: Column(children: [
          _SettingTile(Icons.attach_money_rounded, 'Moneda principal', 'Peso Dominicano (DOP)'),
          const Divider(),
          _SettingTile(Icons.access_time_rounded, 'Zona horaria', 'America/Santo_Domingo'),
          const Divider(),
          _SettingTile(Icons.calendar_month_rounded, 'Inicio del período', '1 de cada mes'),
          const Divider(),
          _SettingTile(Icons.cloud_done_rounded, 'Sincronización', 'Activa — Supabase'),
        ])),
        const SizedBox(height: 16),

        const SectionHeader(title: 'Datos'),
        FCard(child: Column(children: [
          _ActionTile(Icons.download_rounded, 'Exportar todos mis datos', kBlue,
            () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Próximamente disponible')))),
          const Divider(),
          _ActionTile(Icons.table_chart_rounded, 'Exportar como Excel', kBrand,
            () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Próximamente disponible')))),
        ])),
        const SizedBox(height: 16),

        const SectionHeader(title: 'Cuenta'),
        FCard(child: Column(children: [
          _ActionTile(Icons.open_in_new_rounded, 'Gestionar en la web', kMuted,
            () {}),
          const Divider(),
          _ActionTile(Icons.logout_rounded, 'Cerrar sesión', kRed, () async {
            await Supabase.instance.client.auth.signOut();
            if (context.mounted) context.go('/auth/login');
          }),
        ])),
        const SizedBox(height: 32),
        const Center(
          child: Column(children: [
            Text('FLUJO Finance OS', style: TextStyle(color: kMuted, fontSize: 12, fontWeight: FontWeight.w600)),
            SizedBox(height: 2),
            Text('Versión 1.0.0', style: TextStyle(color: kMuted, fontSize: 11)),
          ]),
        ),
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
        Expanded(child: Text(label,
          style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500))),
        Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.5), size: 18),
      ]),
    ),
  );
}
