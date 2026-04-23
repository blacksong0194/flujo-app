"use client";
import { useMemo } from "react";
import { useFinanceStore } from "@/store/useFinanceStore";
import { PageHeader } from "@/components/ui";
import PeriodSelector from "@/components/dashboard/PeriodSelector";
import {
  BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer,
  CartesianGrid, Cell, PieChart, Pie, Legend,
} from "recharts";
import {
  calcCategoryTotals, formatCurrency, filterByPeriod, calcTrend,
} from "@/lib/finance";
import { BarChart3 } from "lucide-react";

const CustomTooltip = ({ active, payload, label }: any) => {
  if (!active || !payload?.length) return null;
  return (
    <div className="bg-surface-600 border border-surface-400 rounded-xl p-3 text-xs shadow-xl">
      <p className="text-muted mb-1 font-medium capitalize">{label}</p>
      {payload.map((p: any, i: number) => (
        <div key={i} className="flex items-center gap-2">
          <span className="w-2 h-2 rounded-full" style={{ background: p.color ?? p.fill }} />
          <span className="text-muted">{p.name}:</span>
          <span className="font-semibold text-slate-200">{formatCurrency(p.value, "DOP", true)}</span>
        </div>
      ))}
    </div>
  );
};

export default function ReportsPage() {
  const { transactions, selectedYear, selectedMonth, summary } = useFinanceStore();

  const periodTx     = useMemo(() => filterByPeriod(transactions, selectedYear, selectedMonth), [transactions, selectedYear, selectedMonth]);
  const expenseCats  = useMemo(() => calcCategoryTotals(periodTx, "expense").slice(0, 8), [periodTx]);
  const incomeCats   = useMemo(() => calcCategoryTotals(periodTx, "income").slice(0, 6), [periodTx]);
  const trend        = useMemo(() => calcTrend(transactions, 7), [transactions]);

  const debtRatio = summary
    ? summary.egresos > 0 && summary.ingresos > 0
      ? (summary.egresos / summary.ingresos) * 100
      : 0
    : 0;

  return (
    <>
      <PageHeader
        title="Reportes & Análisis"
        subtitle="Análisis financiero detallado del período"
        action={<PeriodSelector />}
      />

      {/* KPI summary */}
      <div className="grid grid-cols-4 gap-4 mb-6">
        {[
          { label: "Ingresos",        val: formatCurrency(summary?.ingresos ?? 0, "DOP", true), color: "#10b981" },
          { label: "Egresos",         val: formatCurrency(summary?.egresos ?? 0, "DOP", true),  color: "#ef4444" },
          { label: "Ahorrado",        val: formatCurrency(summary?.ahorrado ?? 0, "DOP", true), color: "#3b82f6" },
          { label: "Tasa de ahorro",  val: `${((summary?.tasa_ahorro ?? 0) * 100).toFixed(1)}%`, color: "#f59e0b" },
        ].map((s) => (
          <div key={s.label} className="stat-card">
            <p className="label-base">{s.label}</p>
            <p className="text-xl font-bold" style={{ color: s.color }}>{s.val}</p>
          </div>
        ))}
      </div>

      {/* Two charts */}
      <div className="grid grid-cols-2 gap-5 mb-5">
        {/* Expenses by category */}
        <div className="card">
          <h3 className="text-sm font-semibold text-slate-300 mb-4">Egresos por categoría</h3>
          {expenseCats.length === 0 ? (
            <div className="flex items-center justify-center h-48 text-muted text-sm">
              Sin egresos en este período
            </div>
          ) : (
            <ResponsiveContainer width="100%" height={250}>
              <BarChart data={expenseCats} layout="vertical" margin={{ left: 0, right: 10 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#1e2a3a" horizontal={false} />
                <XAxis type="number" tick={{ fill: "#4a6b8a", fontSize: 10 }} axisLine={false} tickLine={false}
                  tickFormatter={(v) => formatCurrency(v, "DOP", true)} />
                <YAxis type="category" dataKey="category_name" tick={{ fill: "#94a3b8", fontSize: 11 }}
                  axisLine={false} tickLine={false} width={110} />
                <Tooltip content={<CustomTooltip />} />
                <Bar dataKey="total" name="Total" radius={[0, 6, 6, 0]}>
                  {expenseCats.map((e, i) => (
                    <Cell key={i} fill={e.category_color} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          )}
        </div>

        {/* Monthly trend */}
        <div className="card">
          <h3 className="text-sm font-semibold text-slate-300 mb-4">Balance mensual — 7 meses</h3>
          <ResponsiveContainer width="100%" height={250}>
            <BarChart data={trend} margin={{ top: 5, right: 5, left: -20, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#1e2a3a" vertical={false} />
              <XAxis dataKey="month" tick={{ fill: "#4a6b8a", fontSize: 11 }} axisLine={false} tickLine={false}
                style={{ textTransform: "capitalize" }} />
              <YAxis tick={{ fill: "#4a6b8a", fontSize: 10 }} axisLine={false} tickLine={false}
                tickFormatter={(v) => formatCurrency(v, "DOP", true)} />
              <Tooltip content={<CustomTooltip />} />
              <Bar dataKey="ingresos" name="Ingresos" fill="#10b981" radius={[4, 4, 0, 0]} />
              <Bar dataKey="egresos"  name="Egresos"  fill="#ef4444" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Income distribution */}
      <div className="grid grid-cols-3 gap-5 mb-5">
        <div className="card col-span-1">
          <h3 className="text-sm font-semibold text-slate-300 mb-4">Ingresos por fuente</h3>
          {incomeCats.length === 0 ? (
            <div className="flex items-center justify-center h-40 text-muted text-sm">Sin ingresos</div>
          ) : (
            <ResponsiveContainer width="100%" height={200}>
              <PieChart>
                <Pie data={incomeCats.map(c => ({ ...c, name: c.category_name, value: c.total }))}
                  dataKey="value" cx="50%" cy="50%" innerRadius={50} outerRadius={70} paddingAngle={3} strokeWidth={0}>
                  {incomeCats.map((c, i) => <Cell key={i} fill={c.category_color} />)}
                </Pie>
                <Tooltip formatter={(v: number) => formatCurrency(v, "DOP", true)} />
                <Legend formatter={(v) => <span className="text-xs text-muted">{v}</span>} />
              </PieChart>
            </ResponsiveContainer>
          )}
        </div>

        {/* Ratios */}
        <div className="card col-span-2">
          <h3 className="text-sm font-semibold text-slate-300 mb-5">Indicadores financieros del período</h3>
          <div className="grid grid-cols-2 gap-4">
            {[
              {
                label: "Ratio ingreso/egreso",
                value: summary?.egresos && summary?.ingresos
                  ? `${(summary.ingresos / summary.egresos).toFixed(2)}x`
                  : "—",
                note: "Meta: >1.2x",
                color: (summary?.ingresos ?? 0) / Math.max(summary?.egresos ?? 1, 1) >= 1.2 ? "#10b981" : "#f59e0b",
              },
              {
                label: "Gasto sobre ingresos",
                value: `${debtRatio.toFixed(1)}%`,
                note: debtRatio < 80 ? "Nivel saludable" : "Alto — revisar",
                color: debtRatio < 80 ? "#10b981" : "#ef4444",
              },
              {
                label: "Transacciones del mes",
                value: `${periodTx.length}`,
                note: `${periodTx.filter(t => t.type === "income").length} ingresos / ${periodTx.filter(t => t.type === "expense").length} egresos`,
                color: "#3b82f6",
              },
              {
                label: "Promedio por transacción",
                value: periodTx.length > 0
                  ? formatCurrency(periodTx.reduce((s, t) => s + t.amount, 0) / periodTx.length, "DOP", true)
                  : "—",
                note: "Monto promedio por movimiento",
                color: "#8b5cf6",
              },
            ].map((r) => (
              <div key={r.label} className="bg-surface-800 rounded-xl p-4 border border-surface-500">
                <p className="label-base">{r.label}</p>
                <p className="text-xl font-bold mt-1" style={{ color: r.color }}>{r.value}</p>
                <p className="text-xs text-muted mt-1">{r.note}</p>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Expense categories table */}
      {expenseCats.length > 0 && (
        <div className="card">
          <h3 className="text-sm font-semibold text-slate-300 mb-4">
            Detalle de egresos — top {expenseCats.length} categorías
          </h3>
          <div className="space-y-0.5">
            {expenseCats.map((c, i) => {
              const pct = summary?.egresos ? (c.total / summary.egresos) * 100 : 0;
              return (
                <div key={c.category_id} className="flex items-center gap-4 py-2.5 px-2 rounded-lg hover:bg-surface-600/30 transition-colors">
                  <span className="text-xs text-muted w-5 text-right">{i + 1}</span>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between mb-1">
                      <span className="text-sm font-medium text-slate-200">{c.category_name}</span>
                      <span className="text-sm font-bold text-red-400">{formatCurrency(c.total)}</span>
                    </div>
                    <div className="w-full bg-surface-500 rounded-full h-1.5">
                      <div className="h-1.5 rounded-full transition-all" style={{ width: `${pct}%`, background: c.category_color }} />
                    </div>
                  </div>
                  <span className="text-xs text-muted w-12 text-right">{pct.toFixed(1)}%</span>
                  <span className="text-xs text-muted w-10 text-right">{c.count} mov.</span>
                </div>
              );
            })}
          </div>
        </div>
      )}
    </>
  );
}
