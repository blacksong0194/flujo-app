import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

enum ExportPeriod { currentMonth, last3Months }

class ExportService {
  static Future<void> exportExcel({
    required List<Transaction> transactions,
    required List<Account> accounts,
    required List<Budget> budgets,
    required List<Goal> goals,
    required List<PendingItem> pendingItems,
    required ExportPeriod period,
    required int selectedYear,
    required int selectedMonth,
  }) async {
    final now = DateTime.now();
    final filtered = _filterByPeriod(transactions, period, selectedYear, selectedMonth);

    final excel = Excel.createExcel();

    // -- Hoja 1: Resumen ----------------------------------------------
    final summary = excel['Resumen'];
    excel.setDefaultSheet('Resumen');

    _writeHeader(summary, 0, ['FLUJO Finance OS — Reporte Financiero']);
    _writeHeader(summary, 1, [_periodLabel(period, selectedYear, selectedMonth)]);
    _writeHeader(summary, 2, ['Generado: ${DateFormat('dd MMM yyyy', 'es').format(now)}']);
    summary.appendRow([TextCellValue('')]);

    _writeHeader(summary, 4, ['RESUMEN GENERAL']);
    summary.appendRow([]);

    final ingresos = filtered.where((t) => t.type == 'income').fold(0.0, (s, t) => s + t.amount);
    final egresos  = filtered.where((t) => t.type == 'expense').fold(0.0, (s, t) => s + t.amount);
    final ahorrado = (ingresos - egresos).clamp(0.0, double.infinity);
    final tasaAhorro = ingresos > 0 ? (ahorrado / ingresos * 100) : 0.0;
    final liquidez = accounts.where((a) => a.type != 'deuda' && a.type != 'prestamo').fold(0.0, (s, a) => s + a.balance);
    final deuda    = accounts.where((a) => a.type == 'deuda' || a.type == 'prestamo').fold(0.0, (s, a) => s + a.balance.abs());

    _writeRow(summary, ['Ingresos del periodo',  'RD\$${_fmt(ingresos)}']);
    _writeRow(summary, ['Egresos del periodo',   'RD\$${_fmt(egresos)}']);
    _writeRow(summary, ['Ahorrado',              'RD\$${_fmt(ahorrado)}']);
    _writeRow(summary, ['Tasa de ahorro',        '${tasaAhorro.toStringAsFixed(1)}%']);
    _writeRow(summary, ['Balance liquido',       'RD\$${_fmt(liquidez)}']);
    _writeRow(summary, ['Total deuda',           'RD\$${_fmt(deuda)}']);
    _writeRow(summary, ['Patrimonio neto',       'RD\$${_fmt(liquidez - deuda)}']);

    // -- Hoja 2: Movimientos ------------------------------------------
    final txSheet = excel['Movimientos'];
    _writeBoldRow(txSheet, ['Fecha', 'Descripcion', 'Categoria', 'Cuenta', 'Tipo', 'Monto (RD\$)']);
    for (final t in filtered) {
      txSheet.appendRow([
        TextCellValue(DateFormat('dd/MM/yyyy').format(t.transactionDate)),
        TextCellValue(t.detail),
        TextCellValue(t.category?.name ?? ''),
        TextCellValue(t.account?.name ?? ''),
        TextCellValue(t.type == 'income' ? 'Ingreso' : 'Egreso'),
        DoubleCellValue(t.type == 'income' ? t.amount : -t.amount),
      ]);
    }

    // -- Hoja 3: Cuentas ----------------------------------------------
    final accSheet = excel['Cuentas'];
    _writeBoldRow(accSheet, ['Nombre', 'Tipo', 'Balance (RD\$)', 'Estado']);
    for (final a in accounts) {
      accSheet.appendRow([
        TextCellValue(a.name),
        TextCellValue(a.type),
        DoubleCellValue(a.balance),
        TextCellValue(a.isActive ? 'Activa' : 'Inactiva'),
      ]);
    }

    // -- Hoja 4: Presupuestos -----------------------------------------
    final budSheet = excel['Presupuestos'];
    _writeBoldRow(budSheet, ['Categoria', 'Limite (RD\$)', 'Periodo', 'Alerta en %']);
    for (final b in budgets) {
      budSheet.appendRow([
        TextCellValue(b.category?.name ?? ''),
        DoubleCellValue(b.amount),
        TextCellValue(b.period),
        IntCellValue(b.alertAtPercent),
      ]);
    }

    // -- Hoja 5: Metas ------------------------------------------------
    final goalSheet = excel['Metas'];
    _writeBoldRow(goalSheet, ['Nombre', 'Meta (RD\$)', 'Ahorrado (RD\$)', 'Progreso %', 'Fecha limite']);
    for (final g in goals) {
      goalSheet.appendRow([
        TextCellValue(g.name),
        DoubleCellValue(g.targetAmount),
        DoubleCellValue(g.currentAmount),
        DoubleCellValue(g.progressPercent),
        TextCellValue(g.targetDate != null ? DateFormat('dd/MM/yyyy').format(g.targetDate!) : '—'),
      ]);
    }

    // -- Hoja 6: Por cobrar -------------------------------------------
    final pendSheet = excel['Por cobrar'];
    _writeBoldRow(pendSheet, ['Deudor', 'Descripcion', 'Monto (RD\$)', 'Vence', 'Estado']);
    for (final p in pendingItems) {
      pendSheet.appendRow([
        TextCellValue(p.debtorName),
        TextCellValue(p.description),
        DoubleCellValue(p.amount),
        TextCellValue(DateFormat('dd/MM/yyyy').format(p.dueDate)),
        TextCellValue(p.status == 'collected' ? 'Cobrado' : p.status == 'overdue' ? 'Vencido' : 'Pendiente'),
      ]);
    }

    // -- Guardar y compartir ------------------------------------------
    final bytes = excel.encode();
    if (bytes == null) throw Exception('Error al generar Excel');

    final dir  = await getTemporaryDirectory();
    final name = 'FLUJO_Reporte_${DateFormat('yyyy_MM').format(now)}.xlsx';
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
      subject: 'Reporte FLUJO Finance OS',
      text: 'Reporte financiero — ${_periodLabel(period, selectedYear, selectedMonth)}',
    );
  }

  static List<Transaction> _filterByPeriod(
    List<Transaction> txs, ExportPeriod period, int year, int month) {
    final now = DateTime.now();
    if (period == ExportPeriod.currentMonth) {
      return txs.where((t) =>
        t.transactionDate.year == year &&
        t.transactionDate.month == month).toList();
    } else {
      final from = DateTime(now.year, now.month - 2, 1);
      return txs.where((t) => t.transactionDate.isAfter(from.subtract(const Duration(days: 1)))).toList();
    }
  }

  static String _periodLabel(ExportPeriod period, int year, int month) {
    if (period == ExportPeriod.currentMonth) {
      return DateFormat('MMMM yyyy', 'es').format(DateTime(year, month));
    }
    return 'Ultimos 3 meses';
  }

  static String _fmt(double v) => NumberFormat('#,##0.00').format(v);

  static void _writeHeader(Sheet sheet, int row, List<String> values) {
    while (sheet.maxRows <= row) sheet.appendRow([TextCellValue('')]);
    for (int i = 0; i < values.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
        .value = TextCellValue(values[i]);
    }
  }

  static void _writeRow(Sheet sheet, List<String> values) {
    sheet.appendRow(values.map((v) => TextCellValue(v)).toList());
  }

  static void _writeBoldRow(Sheet sheet, List<String> values) {
    sheet.appendRow(values.map((v) => TextCellValue(v)).toList());
  }
}
