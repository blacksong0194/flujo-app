import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/finance_provider.dart';
import '../../services/export_service.dart';

class ExportModal extends StatefulWidget {
  const ExportModal({super.key});
  @override
  State<ExportModal> createState() => _ExportModalState();
}

class _ExportModalState extends State<ExportModal> {
  int _months = 1;
  bool _loading = false;

  static const _kBrand  = Color(0xFF6C63FF);
  static const _kBg     = Color(0xFF0F1117);
  static const _kCard   = Color(0xFF1A1D2E);
  static const _kBorder = Color(0xFF2A2D3E);
  static const _kSub    = Color(0xFF8A8FAD);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: _kBorder, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        const Row(children: [
          Icon(Icons.picture_as_pdf_rounded, color: _kBrand, size: 22),
          SizedBox(width: 10),
          Text('Exportar Reporte PDF', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 6),
        const Text('Genera un reporte con diseño dark mode y elige el periodo.',
            style: TextStyle(color: _kSub, fontSize: 13)),
        const SizedBox(height: 24),
        const Align(alignment: Alignment.centerLeft,
            child: Text('Período', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
        const SizedBox(height: 10),
        Row(children: [
          _periodChip(1, 'Mes actual'),
          const SizedBox(width: 10),
          _periodChip(3, 'Últimos 3 meses'),
        ]),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBorder)),
          child: Column(children: [
            _row(Icons.swap_horiz_rounded, 'Movimientos', 'Todos los ingresos y egresos'),
            _row(Icons.pie_chart_rounded, 'Presupuestos', 'Límites y % de uso'),
            _row(Icons.access_time_rounded, 'Por cobrar', 'Pendientes y vencidos'),
            _row(Icons.account_balance_wallet_rounded, 'Cuentas', 'Saldos por cuenta', last: true),
          ]),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: _loading ? null : _export,
            style: ElevatedButton.styleFrom(
                backgroundColor: _kBrand,
                disabledBackgroundColor: _kBrand.withOpacity(0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: _loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.download_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Generar PDF', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ]),
          ),
        ),
      ]),
    );
  }

  Widget _periodChip(int months, String label) {
    final sel = _months == months;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _months = months),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? _kBrand.withOpacity(0.15) : _kCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? _kBrand : _kBorder, width: sel ? 1.5 : 1),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: sel ? _kBrand : _kSub,
              fontWeight: sel ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String title, String subtitle, {bool last = false}) =>
      Column(children: [
        Row(children: [
          Icon(icon, color: _kBrand, size: 18), const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            Text(subtitle, style: const TextStyle(color: _kSub, fontSize: 11)),
          ]),
        ]),
        if (!last) ...[const SizedBox(height: 8), const Divider(color: Color(0xFF2A2D3E), height: 1), const SizedBox(height: 8)],
      ]);

  Future<void> _export() async {
    setState(() => _loading = true);
    try {
      final state = context.read<FinanceProvider>().state;
      await exportToPdf(context, state, months: _months);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFE05C5C)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

void showExportModal(BuildContext context) => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => const ExportModal());