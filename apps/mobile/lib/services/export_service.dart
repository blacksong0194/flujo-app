import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/finance_provider.dart';

const _kBg       = PdfColor.fromInt(0xFF0F1117);
const _kSurface  = PdfColor.fromInt(0xFF1A1D2E);
const _kSurface2 = PdfColor.fromInt(0xFF141726);
const _kBrand    = PdfColor.fromInt(0xFF6C63FF);
const _kGreen    = PdfColor.fromInt(0xFF4CAF82);
const _kRed      = PdfColor.fromInt(0xFFE05C5C);
const _kYellow   = PdfColor.fromInt(0xFFFFC857);
const _kTextMain = PdfColors.white;
const _kTextSub  = PdfColor.fromInt(0xFF8A8FAD);

pw.PageTheme _pageTheme() => pw.PageTheme(
  pageFormat: PdfPageFormat.a4,
  margin: const pw.EdgeInsets.all(28),
  theme: pw.ThemeData.withFont(),
  buildBackground: (ctx) => pw.Container(color: _kBg),
);

String _fmt(double v) =>
    '\$${v.abs().toStringAsFixed(2).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}';

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

pw.TextStyle _style({double size = 10, PdfColor color = _kTextMain, pw.FontWeight weight = pw.FontWeight.normal}) =>
    pw.TextStyle(fontSize: size, color: color, fontWeight: weight);

pw.Widget _divider() => pw.Container(
    height: 1, color: _kBrand, margin: const pw.EdgeInsets.symmetric(vertical: 6));

pw.Widget _kpiBox(String label, String value, PdfColor valueColor) => pw.Container(
  padding: const pw.EdgeInsets.all(10),
  decoration: pw.BoxDecoration(
    color: _kSurface,
    borderRadius: pw.BorderRadius.circular(8),
    border: pw.Border.all(color: _kBrand, width: 0.5),
  ),
  child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    pw.Text(label, style: _style(size: 8, color: _kTextSub)),
    pw.SizedBox(height: 4),
    pw.Text(value, style: _style(size: 13, color: valueColor, weight: pw.FontWeight.bold)),
  ]),
);

pw.Widget _pageHeader(String title, String subtitle) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('FLUJO', style: _style(size: 22, color: _kBrand, weight: pw.FontWeight.bold)),
        pw.Text('Finance OS', style: _style(size: 9, color: _kTextSub)),
      ]),
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
        pw.Text(title, style: _style(size: 16, weight: pw.FontWeight.bold)),
        pw.Text(subtitle, style: _style(size: 9, color: _kTextSub)),
      ]),
    ]),
    _divider(),
  ],
);

pw.Widget _tableHeader(List<String> cols, List<double> flex) => pw.Container(
  padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
  color: _kBrand,
  child: pw.Row(children: List.generate(cols.length, (i) =>
      pw.Expanded(flex: (flex[i] * 10).round(),
          child: pw.Text(cols[i], style: _style(size: 8, weight: pw.FontWeight.bold))))),
);

pw.Widget _tableRow(List<String> cells, List<double> flex,
    {bool odd = true, List<PdfColor?>? colors}) =>
    pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      color: odd ? _kSurface : _kSurface2,
      child: pw.Row(children: List.generate(cells.length, (i) =>
          pw.Expanded(flex: (flex[i] * 10).round(),
              child: pw.Text(cells[i],
                  style: _style(size: 8,
                      color: (colors != null && colors[i] != null)
                          ? colors[i]! : _kTextMain))))),
    );

Future<void> exportToPdf(BuildContext context, FinanceState state, {int months = 1}) async {
  final now = DateTime.now();
  final cutoff = DateTime(now.year, now.month - (months - 1), 1);

  final txns = state.transactions
      .where((t) => t.transactionDate.isAfter(cutoff.subtract(const Duration(days: 1))))
      .toList()
    ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

  final income  = txns.where((t) => t.type == 'income').fold(0.0, (s, t) => s + t.amount);
  final expense = txns.where((t) => t.type == 'expense').fold(0.0, (s, t) => s + t.amount);
  final balance = income - expense;
  final periodLabel = months == 1
      ? '${_monthName(now.month)} ${now.year}'
      : 'Últimos 3 meses';

  final doc = pw.Document();

  // ── Página 1: Movimientos ────────────────────────────────────────────────
  doc.addPage(pw.MultiPage(
    pageTheme: _pageTheme(),
    build: (ctx) => [
      _pageHeader('Reporte Financiero', periodLabel),
      pw.SizedBox(height: 12),
      pw.Row(children: [
        pw.Expanded(child: _kpiBox('Ingresos',    _fmt(income),     _kGreen)),
        pw.SizedBox(width: 8),
        pw.Expanded(child: _kpiBox('Egresos',     _fmt(expense),    _kRed)),
        pw.SizedBox(width: 8),
        pw.Expanded(child: _kpiBox('Balance',     _fmt(balance),    balance >= 0 ? _kGreen : _kRed)),
        pw.SizedBox(width: 8),
        pw.Expanded(child: _kpiBox('Movimientos', '${txns.length}', _kBrand)),
      ]),
      pw.SizedBox(height: 20),
      pw.Text('Movimientos', style: _style(size: 13, weight: pw.FontWeight.bold)),
      pw.SizedBox(height: 6),
      _tableHeader(['Fecha', 'Detalle', 'Categoría', 'Tipo', 'Monto'], [1.2, 2.5, 1.8, 1.0, 1.5]),
      ...List.generate(txns.length, (i) {
        final t = txns[i];
        final isIncome = t.type == 'income';
        return _tableRow(
          [_fmtDate(t.transactionDate), t.detail, t.category?.name ?? '—',
           isIncome ? 'Ingreso' : 'Egreso', _fmt(t.amount)],
          [1.2, 2.5, 1.8, 1.0, 1.5],
          odd: i.isOdd,
          colors: [null, null, null, isIncome ? _kGreen : _kRed, isIncome ? _kGreen : _kRed],
        );
      }),
    ],
  ));

  // ── Página 2: Presupuestos ───────────────────────────────────────────────
  if (state.budgets.isNotEmpty) {
    doc.addPage(pw.MultiPage(
      pageTheme: _pageTheme(),
      build: (ctx) => [
        _pageHeader('Presupuestos', periodLabel),
        pw.SizedBox(height: 12),
        _tableHeader(['Categoría', 'Límite', 'Período', 'Alerta %'], [2.5, 2.0, 2.0, 1.5]),
        ...List.generate(state.budgets.length, (i) {
          final b = state.budgets[i];
          return _tableRow(
            [b.category?.name ?? '—', _fmt(b.amount), b.period, '${b.alertAtPercent}%'],
            [2.5, 2.0, 2.0, 1.5],
            odd: i.isOdd,
          );
        }),
      ],
    ));
  }

  // ── Página 3: Por cobrar ─────────────────────────────────────────────────
  if (state.pendingItems.isNotEmpty) {
    final totalPending = state.pendingItems
        .where((p) => p.status != 'collected')
        .fold(0.0, (s, p) => s + p.amount);
    doc.addPage(pw.MultiPage(
      pageTheme: _pageTheme(),
      build: (ctx) => [
        _pageHeader('Por Cobrar / Pendientes', periodLabel),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          pw.Expanded(child: _kpiBox('Total pendiente', _fmt(totalPending), _kYellow)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _kpiBox('Cantidad', '${state.pendingItems.length}', _kBrand)),
        ]),
        pw.SizedBox(height: 16),
        _tableHeader(['Deudor', 'Detalle', 'Monto', 'Vence', 'Estado'], [2.0, 2.0, 1.5, 1.5, 1.5]),
        ...List.generate(state.pendingItems.length, (i) {
          final p = state.pendingItems[i];
          final vencido = p.dueDate.isBefore(now);
          final statusColor = p.status == 'collected' ? _kGreen : vencido ? _kRed : _kYellow;
          final statusLabel = p.status == 'collected' ? 'Cobrado' : vencido ? 'Vencido' : 'Pendiente';
          return _tableRow(
            [p.debtorName, p.description, _fmt(p.amount), _fmtDate(p.dueDate), statusLabel],
            [2.0, 2.0, 1.5, 1.5, 1.5],
            odd: i.isOdd,
            colors: [null, null, _kGreen, null, statusColor],
          );
        }),
      ],
    ));
  }

  // ── Página 4: Cuentas ────────────────────────────────────────────────────
  if (state.accounts.isNotEmpty) {
    final totalBalance = state.accounts.fold(0.0, (s, a) => s + a.balance);
    doc.addPage(pw.MultiPage(
      pageTheme: _pageTheme(),
      build: (ctx) => [
        _pageHeader('Cuentas', periodLabel),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          pw.Expanded(child: _kpiBox('Balance total', _fmt(totalBalance), totalBalance >= 0 ? _kGreen : _kRed)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _kpiBox('Cuentas', '${state.accounts.length}', _kBrand)),
        ]),
        pw.SizedBox(height: 16),
        _tableHeader(['Nombre', 'Tipo', 'Color', 'Balance'], [2.5, 2.0, 1.5, 2.0]),
        ...List.generate(state.accounts.length, (i) {
          final a = state.accounts[i];
          return _tableRow(
            [a.name, a.type, a.color, _fmt(a.balance)],
            [2.5, 2.0, 1.5, 2.0],
            odd: i.isOdd,
            colors: [null, null, null, a.balance >= 0 ? _kGreen : _kRed],
          );
        }),
      ],
    ));
  }

  await Printing.layoutPdf(
    onLayout: (_) async => doc.save(),
    name: 'flujo_reporte_${now.year}${now.month.toString().padLeft(2, '0')}.pdf',
  );
}

String _monthName(int m) => const [
  '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
][m];