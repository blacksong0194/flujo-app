import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
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

// ─── Text styles ──────────────────────────────────────────────────────────────
const kHeading = TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kText, letterSpacing: -0.5);
const kTitle   = TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: kText);
const kBody    = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: kText);
const kCaption = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: kMuted, letterSpacing: 0.8);

// ─── Formatters ───────────────────────────────────────────────────────────────
final _currencyFmt = NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$', decimalDigits: 0);
final _compactFmt  = NumberFormat.compactCurrency(locale: 'es_DO', symbol: 'RD\$', decimalDigits: 1);
final _dateFmt     = DateFormat('d MMM yyyy', 'es');
final _monthFmt    = DateFormat('MMMM yyyy', 'es');

String fmtCurrency(double v) => _currencyFmt.format(v);
String fmtCompact(double v) {
  if (v.abs() >= 1000000) return 'RD\$${(v / 1000000).toStringAsFixed(1)}M';
  if (v.abs() >= 1000)    return 'RD\$${(v / 1000).toStringAsFixed(0)}K';
  return 'RD\$${v.toStringAsFixed(0)}';
}
String fmtDate(DateTime d)  => _dateFmt.format(d);
String fmtMonth(int y, int m) => _monthFmt.format(DateTime(y, m));
String fmtPercent(double v) => '${(v * 100).toStringAsFixed(1)}%';

// ─── Common widgets helpers ───────────────────────────────────────────────────
BoxDecoration kCardDecoration({Color? borderTop}) => BoxDecoration(
  color: kSurface,
  borderRadius: BorderRadius.circular(14),
  border: Border(
    top: borderTop != null
      ? BorderSide(color: borderTop, width: 3)
      : const BorderSide(color: kBorder),
    left:   const BorderSide(color: kBorder),
    right:  const BorderSide(color: kBorder),
    bottom: const BorderSide(color: kBorder),
  ),
);

Color typeColor(String type) => type == 'income' ? kBrand : kRed;
String typeSign(String type)  => type == 'income' ? '+' : '-';

const Map<String, String> accountTypeLabels = {
  'banco':        'Banco',
  'cooperativa':  'Cooperativa',
  'efectivo':     'Efectivo',
  'inversion':    'Inversión',
  'deuda':        'Deuda',
  'prestamo':     'Préstamo',
};

Color hexColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}
