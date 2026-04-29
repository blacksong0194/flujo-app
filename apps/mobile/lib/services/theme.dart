
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- Colors -------------------------------------------------------------------
const kBg       = Color(0xFF0A0F1A);
const kSurface  = Color(0xFF111827);
const kSurface2 = Color(0xFF0D1420);
const kBorder   = Color(0xFF1E2A3A);
const kBrand    = Color(0xFF10B981);
const kRed      = Color(0xFFEF4444);
const kAmber    = Color(0xFFF59E0B);
const kBlue     = Color(0xFF3B82F6);
const kPurple   = Color(0xFF8B5CF6);
const kText     = Color(0xFFE2E8F0);
const kTextSub  = Color(0xFF94A3B8);
const kMuted    = Color(0xFF4A6B8A);

// --- Text styles --------------------------------------------------------------
const kHeading = TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kText, letterSpacing: -0.5);
const kTitle   = TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: kText);
const kBody    = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: kText);
const kCaption = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: kMuted, letterSpacing: 0.8);

// --- Formatters ---------------------------------------------------------------
final _dateFmt  = DateFormat('d MMM yyyy', 'es');
final _monthFmt = DateFormat('MMMM yyyy', 'es');

String fmtCurrency(double v) {
  final sign = v < 0 ? '-' : '';
  final abs = v.abs();
  final parts = abs.toStringAsFixed(2).split('.');
  final intPart = parts[0].replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  return '${sign}RD\$$intPart.${parts[1]}';
}
String fmtCompact(double v) => fmtCurrency(v);
String fmtDate(DateTime d)  => _dateFmt.format(d);
String fmtMonth(int y, int m) => _monthFmt.format(DateTime(y, m));
String fmtPercent(double v) => '${(v * 100).toStringAsFixed(1)}%';

// --- Card decoration SIN borde superior de color (uniforme) ------------------
BoxDecoration kCardDecoration({Color? borderTop}) => BoxDecoration(
  color: kSurface,
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: kBorder, width: 1),
);

// El acento de color en MetricCard se implementa via clipPath en FCard
Color typeColor(String type) => type == 'income' ? kBrand : kRed;
String typeSign(String type)  => type == 'income' ? '+' : '-';

const Map<String, String> accountTypeLabels = {
  'banco':       'Banco',
  'cooperativa': 'Cooperativa',
  'efectivo':    'Efectivo',
  'inversion':   'Inversion',
  'deuda':       'Deuda',
  'prestamo':    'Prestamo',
};

Color hexColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}
