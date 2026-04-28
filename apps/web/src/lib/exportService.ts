// apps/web/src/lib/exportService.ts
// Exportación de reportes financieros — Excel diseñado con ExcelJS + JSON

import type { Transaction, Account, Budget, Goal } from "@/types";
import type { PendingPayment } from "@/types/pending";
import { format } from "date-fns";
import { es } from "date-fns/locale";

export type ExportPeriod = "currentMonth" | "last3Months";

function fmt(n: number) {
  return new Intl.NumberFormat("es-DO", { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(n);
}

function periodLabel(period: ExportPeriod, year: number, month: number): string {
  if (period === "currentMonth") return format(new Date(year, month - 1, 1), "MMMM yyyy", { locale: es });
  return "Últimos 3 meses";
}

function filterByPeriod(txs: Transaction[], period: ExportPeriod, year: number, month: number): Transaction[] {
  if (period === "currentMonth") {
    return txs.filter((t) =>
      new Date(t.transaction_date).getFullYear() === year &&
      new Date(t.transaction_date).getMonth() + 1 === month
    );
  }
  const now  = new Date();
  const from = new Date(now.getFullYear(), now.getMonth() - 2, 1);
  return txs.filter((t) => new Date(t.transaction_date) >= from);
}

const C = {
  brand:     "FF10B981", brandLight: "FF0D9268", blue: "FF3B82F6",
  red:       "FFEF4444", amber:      "FFF59E0B",
  bg:        "FF0F1923", surface:    "FF131E2B", surface2: "FF1A2535",
  border:    "FF1E2A3A", text:       "FFE2E8F0", muted:    "FF4A6B8A",
  white:     "FFFFFFFF", headerBg:   "FF0D9268", titleBg:  "FF0A7A58",
  sectionBg: "FF162030", altRow:     "FF111820",
};

const FONT_BASE    = { name: "Calibri", size: 11, color: { argb: C.text } };
const FONT_BOLD    = { ...FONT_BASE, bold: true };
const FONT_TITLE   = { name: "Calibri", size: 16, bold: true, color: { argb: C.brand } };
const FONT_SUBTITLE = { name: "Calibri", size: 11, color: { argb: C.muted } };
const FONT_SECTION = { name: "Calibri", size: 10, bold: true, color: { argb: C.brand } };
const FONT_HEADER  = { name: "Calibri", size: 10, bold: true, color: { argb: C.white } };

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function styleCell(cell: any, opts: { font?: object; bgColor?: string; bold?: boolean; align?: "left"|"center"|"right"; border?: boolean }) {
  if (opts.font)    cell.font      = opts.font;
  if (opts.bold)    cell.font      = { ...(cell.font ?? FONT_BASE), bold: true };
  if (opts.bgColor) cell.fill      = { type: "pattern", pattern: "solid", fgColor: { argb: opts.bgColor } };
  if (opts.align)   cell.alignment = { horizontal: opts.align, vertical: "middle" };
  if (opts.border)  cell.border    = {
    top: { style: "thin", color: { argb: C.border } }, left: { style: "thin", color: { argb: C.border } },
    bottom: { style: "thin", color: { argb: C.border } }, right: { style: "thin", color: { argb: C.border } },
  };
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function headerRow(sheet: any, rowNum: number, values: string[], bgColor = C.headerBg) {
  const row = sheet.getRow(rowNum);
  row.height = 26;
  values.forEach((v, i) => {
    const cell = row.getCell(i + 1);
    cell.value = v;
    styleCell(cell, { font: FONT_HEADER, bgColor, align: "center", border: true });
  });
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function kpiRow(sheet: any, rowNum: number, label: string, value: string, valueColor = C.brand) {
  const row = sheet.getRow(rowNum);
  row.height = 22;
  const cLabel = row.getCell(1); const cValue = row.getCell(2);
  cLabel.value = label; cValue.value = value;
  styleCell(cLabel, { font: FONT_BASE,  bgColor: C.surface2, align: "left",  border: true });
  styleCell(cValue, { font: { ...FONT_BOLD, color: { argb: valueColor } }, bgColor: C.surface, align: "right", border: true });
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function sectionTitle(sheet: any, rowNum: number, title: string, cols: number) {
  const row = sheet.getRow(rowNum); row.height = 24;
  const cell = row.getCell(1); cell.value = title;
  sheet.mergeCells(rowNum, 1, rowNum, cols);
  styleCell(cell, { font: FONT_SECTION, bgColor: C.sectionBg, align: "left", border: true });
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function sheetTitle(sheet: any, text: string, cols: number) {
  sheet.mergeCells(`A1:${String.fromCharCode(64 + cols)}1`);
  const cell = sheet.getCell("A1");
  cell.value = text;
  cell.font  = FONT_TITLE;
  cell.fill  = { type: "pattern", pattern: "solid", fgColor: { argb: C.bg } };
  cell.alignment = { horizontal: "left", vertical: "middle" };
  sheet.getRow(1).height = 32;
}

export async function exportExcel(params: {
  transactions: Transaction[]; accounts: Account[]; budgets: Budget[];
  goals: Goal[]; pendingItems: PendingPayment[];
  period: ExportPeriod; selectedYear: number; selectedMonth: number;
}) {
  const { transactions, accounts, budgets, goals, pendingItems, period, selectedYear, selectedMonth } = params;
  const ExcelJS    = (await import("exceljs")).default;
  const wb         = new ExcelJS.Workbook();
  wb.creator       = "FLUJO Finance OS";
  wb.created       = new Date();

  const filtered   = filterByPeriod(transactions, period, selectedYear, selectedMonth);
  const ingresos   = filtered.filter((t) => t.type === "income").reduce((s, t) => s + t.amount, 0);
  const egresos    = filtered.filter((t) => t.type === "expense").reduce((s, t) => s + t.amount, 0);
  const ahorrado   = Math.max(ingresos - egresos, 0);
  const tasaAhorro = ingresos > 0 ? (ahorrado / ingresos) * 100 : 0;
  const liquidez   = accounts.filter((a) => a.type !== "deuda" && a.type !== "prestamo").reduce((s, a) => s + a.balance, 0);
  const deuda      = accounts.filter((a) => a.type === "deuda" || a.type === "prestamo").reduce((s, a) => s + Math.abs(a.balance), 0);
  const label      = periodLabel(period, selectedYear, selectedMonth);

  // ── Hoja 1: Resumen ──────────────────────────────────────────────────────────
  const ws1 = wb.addWorksheet("Resumen");
  ws1.views = [{ showGridLines: false }];
  ws1.columns = [{ width: 34 }, { width: 22 }, { width: 22 }, { width: 18 }];

  ws1.mergeCells("A1:D1");
  const t1 = ws1.getCell("A1");
  t1.value = "FLUJO Finance OS — Reporte Financiero";
  t1.font  = FONT_TITLE;
  t1.fill  = { type: "pattern", pattern: "solid", fgColor: { argb: C.bg } };
  t1.alignment = { horizontal: "left", vertical: "middle" };
  ws1.getRow(1).height = 36;

  ws1.mergeCells("A2:D2");
  const sub = ws1.getCell("A2");
  sub.value = `Período: ${label}   ·   Generado: ${format(new Date(), "dd MMM yyyy", { locale: es })}`;
  sub.font  = FONT_SUBTITLE;
  sub.fill  = { type: "pattern", pattern: "solid", fgColor: { argb: C.bg } };
  sub.alignment = { horizontal: "left", vertical: "middle" };
  ws1.getRow(2).height = 20;
  ws1.getRow(3).height = 8;

  sectionTitle(ws1, 4, "  RESUMEN DEL PERÍODO", 2);
  headerRow(ws1, 5, ["Concepto", "Monto (RD$)"], C.brandLight);
  kpiRow(ws1, 6, "Ingresos del período",  `RD$ ${fmt(ingresos)}`,  C.brand);
  kpiRow(ws1, 7, "Egresos del período",   `RD$ ${fmt(egresos)}`,   C.red);
  kpiRow(ws1, 8, "Ahorrado",              `RD$ ${fmt(ahorrado)}`,  C.brand);
  kpiRow(ws1, 9, "Tasa de ahorro",        `${tasaAhorro.toFixed(1)}%`, tasaAhorro >= 20 ? C.brand : tasaAhorro >= 10 ? C.amber : C.red);
  ws1.getRow(10).height = 8;

  sectionTitle(ws1, 11, "  SITUACIÓN PATRIMONIAL", 2);
  headerRow(ws1, 12, ["Concepto", "Monto (RD$)"], C.brandLight);
  kpiRow(ws1, 13, "Balance líquido",  `RD$ ${fmt(liquidez)}`,        C.brand);
  kpiRow(ws1, 14, "Total deuda",      `RD$ ${fmt(deuda)}`,           C.red);
  kpiRow(ws1, 15, "Patrimonio neto",  `RD$ ${fmt(liquidez - deuda)}`, liquidez > deuda ? C.brand : C.red);
  ws1.getRow(16).height = 8;

  if (goals.length > 0) {
    sectionTitle(ws1, 17, "  METAS DE AHORRO", 4);
    headerRow(ws1, 18, ["Meta", "Objetivo (RD$)", "Ahorrado (RD$)", "Progreso %"], C.brandLight);
    goals.forEach((g, i) => {
      const pct   = g.target_amount > 0 ? (g.current_amount / g.target_amount) * 100 : 0;
      const row   = ws1.getRow(19 + i); row.height = 22;
      const bg    = i % 2 === 0 ? C.surface2 : C.altRow;
      const color = pct >= 80 ? C.brand : pct >= 40 ? C.amber : C.muted;
      const cells = [g.name, `RD$ ${fmt(g.target_amount)}`, `RD$ ${fmt(g.current_amount)}`, `${pct.toFixed(1)}%`];
      cells.forEach((v, ci) => {
        const cell = row.getCell(ci + 1); cell.value = v;
        styleCell(cell, { font: ci === 3 ? { ...FONT_BOLD, color: { argb: color } } : ci === 2 ? { ...FONT_BASE, color: { argb: C.brand } } : FONT_BASE, bgColor: bg, align: ci === 0 ? "left" : ci === 3 ? "center" : "right", border: true });
      });
    });
  }

  // ── Hoja 2: Movimientos ──────────────────────────────────────────────────────
  const ws2 = wb.addWorksheet("Movimientos");
  ws2.views = [{ showGridLines: false }];
  ws2.columns = [{ width: 14 }, { width: 38 }, { width: 22 }, { width: 22 }, { width: 14 }, { width: 18 }];
  sheetTitle(ws2, `Movimientos — ${label}`, 6);
  headerRow(ws2, 2, ["Fecha", "Descripción", "Categoría", "Cuenta", "Tipo", "Monto (RD$)"]);

  filtered.forEach((t, i) => {
    const isInc = t.type === "income";
    const row   = ws2.getRow(3 + i); row.height = 20;
    const bg    = i % 2 === 0 ? C.surface2 : C.altRow;
    [
      format(new Date(t.transaction_date), "dd/MM/yyyy"),
      t.detail,
      (t.category as { name: string } | undefined)?.name ?? "",
      (t.account  as { name: string } | undefined)?.name ?? "",
      isInc ? "Ingreso" : t.type === "expense" ? "Egreso" : "Transferencia",
      `${isInc ? "+" : "-"}RD$ ${fmt(t.amount)}`,
    ].forEach((v, ci) => {
      const cell = row.getCell(ci + 1); cell.value = v;
      styleCell(cell, { font: ci === 5 ? { ...FONT_BOLD, color: { argb: isInc ? C.brand : C.red } } : FONT_BASE, bgColor: bg, align: ci === 0 || ci === 4 ? "center" : ci === 5 ? "right" : "left", border: true });
    });
  });

  // Fila totales
  const tr = ws2.getRow(3 + filtered.length); tr.height = 24;
  ws2.mergeCells(3 + filtered.length, 1, 3 + filtered.length, 4);
  const tl = tr.getCell(1); tl.value = `Total: ${filtered.length} movimientos`;
  styleCell(tl, { font: FONT_BOLD, bgColor: C.sectionBg, align: "right", border: true });
  const ti = tr.getCell(5); ti.value = `+RD$ ${fmt(ingresos)}`;
  styleCell(ti, { font: { ...FONT_BOLD, color: { argb: C.brand } }, bgColor: C.sectionBg, align: "center", border: true });
  const te = tr.getCell(6); te.value = `-RD$ ${fmt(egresos)}`;
  styleCell(te, { font: { ...FONT_BOLD, color: { argb: C.red } }, bgColor: C.sectionBg, align: "right", border: true });

  // ── Hoja 3: Cuentas ──────────────────────────────────────────────────────────
  const ws3 = wb.addWorksheet("Cuentas");
  ws3.views = [{ showGridLines: false }];
  ws3.columns = [{ width: 30 }, { width: 18 }, { width: 20 }, { width: 12 }];
  sheetTitle(ws3, "Cuentas y Balances", 4);
  headerRow(ws3, 2, ["Nombre", "Tipo", "Balance (RD$)", "Estado"]);
  accounts.forEach((a, i) => {
    const row = ws3.getRow(3 + i); row.height = 22;
    const bg  = i % 2 === 0 ? C.surface2 : C.altRow;
    const isDebt = a.type === "deuda" || a.type === "prestamo";
    const balColor = isDebt ? C.red : a.balance >= 0 ? C.brand : C.amber;
    [a.name, a.type, `RD$ ${fmt(a.balance)}`, a.is_active ? "Activa" : "Inactiva"].forEach((v, ci) => {
      const cell = row.getCell(ci + 1); cell.value = v;
      styleCell(cell, { font: ci === 2 ? { ...FONT_BOLD, color: { argb: balColor } } : FONT_BASE, bgColor: bg, align: ci === 2 ? "right" : ci === 3 ? "center" : "left", border: true });
    });
  });

  // ── Hoja 4: Presupuestos ─────────────────────────────────────────────────────
  const ws4 = wb.addWorksheet("Presupuestos");
  ws4.views = [{ showGridLines: false }];
  ws4.columns = [{ width: 28 }, { width: 20 }, { width: 16 }, { width: 16 }];
  sheetTitle(ws4, "Presupuestos Mensuales", 4);
  headerRow(ws4, 2, ["Categoría", "Límite (RD$)", "Período", "Alerta en %"]);
  budgets.forEach((b, i) => {
    const row = ws4.getRow(3 + i); row.height = 22;
    const bg  = i % 2 === 0 ? C.surface2 : C.altRow;
    const cat = (b.category as { name: string } | undefined)?.name ?? "";
    [cat, `RD$ ${fmt(b.amount)}`, b.period, `${b.alert_at_percent}%`].forEach((v, ci) => {
      const cell = row.getCell(ci + 1); cell.value = v;
      styleCell(cell, { font: ci === 1 ? { ...FONT_BOLD, color: { argb: C.brand } } : FONT_BASE, bgColor: bg, align: ci >= 1 ? "right" : "left", border: true });
    });
  });

  // ── Hoja 5: Por cobrar ───────────────────────────────────────────────────────
  const ws5 = wb.addWorksheet("Por cobrar");
  ws5.views = [{ showGridLines: false }];
  ws5.columns = [{ width: 26 }, { width: 34 }, { width: 18 }, { width: 14 }, { width: 14 }];
  sheetTitle(ws5, "Cobros Pendientes", 5);
  headerRow(ws5, 2, ["Deudor", "Descripción", "Monto (RD$)", "Vence", "Estado"]);
  const nowD = new Date();
  pendingItems.forEach((p, i) => {
    const row = ws5.getRow(3 + i); row.height = 22;
    const bg  = i % 2 === 0 ? C.surface2 : C.altRow;
    const isC = p.status === "collected";
    const isO = !isC && new Date(p.due_date) < nowD;
    const sLabel = isC ? "Cobrado" : isO ? "Vencido" : "Pendiente";
    const sColor = isC ? C.brand : isO ? C.red : C.amber;
    [p.debtor_name, p.description, `RD$ ${fmt(p.amount)}`, format(new Date(p.due_date), "dd/MM/yyyy"), sLabel].forEach((v, ci) => {
      const cell = row.getCell(ci + 1); cell.value = v;
      styleCell(cell, { font: ci === 2 ? { ...FONT_BOLD, color: { argb: C.brand } } : ci === 4 ? { ...FONT_BOLD, color: { argb: sColor } } : FONT_BASE, bgColor: bg, align: ci === 2 ? "right" : ci >= 3 ? "center" : "left", border: true });
    });
  });

  // ── Descargar ────────────────────────────────────────────────────────────────
  const buffer = await wb.xlsx.writeBuffer();
  const blob   = new Blob([buffer], { type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" });
  const url    = URL.createObjectURL(blob);
  const a      = document.createElement("a");
  a.href       = url;
  a.download   = `FLUJO_Reporte_${format(new Date(), "yyyy_MM_dd")}.xlsx`;
  a.click();
  URL.revokeObjectURL(url);
}

// ─── Export JSON ──────────────────────────────────────────────────────────────
export async function exportJSON(params: {
  transactions: Transaction[]; accounts: Account[]; budgets: Budget[];
  goals: Goal[]; pendingItems: PendingPayment[];
  period: ExportPeriod; selectedYear: number; selectedMonth: number;
}) {
  const { transactions, accounts, budgets, goals, pendingItems, period, selectedYear, selectedMonth } = params;
  const filtered = filterByPeriod(transactions, period, selectedYear, selectedMonth);
  const payload  = {
    exportedAt: new Date().toISOString(),
    period:     periodLabel(period, selectedYear, selectedMonth),
    accounts, budgets, goals, pendingItems,
    transactions: filtered,
  };
  const blob = new Blob([JSON.stringify(payload, null, 2)], { type: "application/json" });
  const url  = URL.createObjectURL(blob);
  const a    = document.createElement("a");
  a.href     = url;
  a.download = `FLUJO_Export_${format(new Date(), "yyyy_MM_dd")}.json`;
  a.click();
  URL.revokeObjectURL(url);
}
