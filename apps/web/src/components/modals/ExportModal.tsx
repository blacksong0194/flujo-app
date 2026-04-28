"use client";
// apps/web/src/components/modals/ExportModal.tsx

import { useState } from "react";
import { Download, FileSpreadsheet, FileJson, X, CheckCircle2, Clock, Calendar } from "lucide-react";
import { exportExcel, exportJSON, type ExportPeriod } from "@/lib/exportService";
import { useFinanceStore } from "@/store/useFinanceStore";
import { usePendingStore } from "@/store/usePendingStore";
import toast from "react-hot-toast";

interface ExportModalProps {
  onClose: () => void;
}

export function ExportModal({ onClose }: ExportModalProps) {
  const { transactions, accounts, budgets, goals, selectedYear, selectedMonth } = useFinanceStore();
  const { payments: pendingItems } = usePendingStore();

  const [period, setPeriod]       = useState<ExportPeriod>("currentMonth");
  const [loadingXlsx, setLoadingXlsx] = useState(false);
  const [loadingJson, setLoadingJson] = useState(false);

  const commonParams = {
    transactions,
    accounts,
    budgets,
    goals,
    pendingItems,
    period,
    selectedYear,
    selectedMonth,
  };

  const handleExcelExport = async () => {
    setLoadingXlsx(true);
    try {
      await exportExcel(commonParams);
      toast.success("Reporte Excel generado");
      onClose();
    } catch (e) {
      toast.error("Error al generar Excel");
      console.error(e);
    } finally {
      setLoadingXlsx(false);
    }
  };

  const handleJsonExport = async () => {
    setLoadingJson(true);
    try {
      await exportJSON(commonParams);
      toast.success("Datos exportados en JSON");
      onClose();
    } catch (e) {
      toast.error("Error al exportar JSON");
      console.error(e);
    } finally {
      setLoadingJson(false);
    }
  };

  const periods: { value: ExportPeriod; label: string; subtitle: string; icon: React.ReactNode }[] = [
    {
      value:    "currentMonth",
      label:    "Mes actual",
      subtitle: "Solo los movimientos del mes seleccionado",
      icon:     <Calendar size={16} />,
    },
    {
      value:    "last3Months",
      label:    "Últimos 3 meses",
      subtitle: "Movimientos de los últimos 3 meses",
      icon:     <Clock size={16} />,
    },
  ];

  const sheets = [
    "Resumen general (KPIs + patrimonio + metas)",
    "Movimientos filtrados por período",
    "Cuentas con balances",
    "Presupuestos configurados",
    "Cobros pendientes",
  ];

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
      <div className="bg-surface-700 border border-surface-500 rounded-2xl w-full max-w-md p-6 space-y-5">

        {/* Header */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-brand-500/15 flex items-center justify-center">
              <Download size={16} className="text-brand-400" />
            </div>
            <div>
              <h3 className="text-sm font-semibold text-slate-200">Exportar reporte</h3>
              <p className="text-xs text-muted">Elige el período y el formato</p>
            </div>
          </div>
          <button onClick={onClose} className="text-muted hover:text-slate-300 transition-colors">
            <X size={18} />
          </button>
        </div>

        {/* Period selector */}
        <div className="space-y-2">
          <p className="text-xs font-semibold text-muted uppercase tracking-wider">Período</p>
          {periods.map((p) => (
            <button
              key={p.value}
              onClick={() => setPeriod(p.value)}
              className="w-full flex items-center gap-3 px-4 py-3 rounded-xl border transition-all text-left"
              style={{
                borderColor: period === p.value ? "#10b981" : "#1e2a3a",
                background:  period === p.value ? "#10b98110" : "transparent",
              }}
            >
              <span style={{ color: period === p.value ? "#10b981" : "#4a6b8a" }}>
                {p.icon}
              </span>
              <div className="flex-1">
                <p
                  className="text-sm font-semibold"
                  style={{ color: period === p.value ? "#10b981" : "#cbd5e1" }}
                >
                  {p.label}
                </p>
                <p className="text-xs text-muted">{p.subtitle}</p>
              </div>
              {period === p.value && (
                <CheckCircle2 size={16} className="text-brand-400 shrink-0" />
              )}
            </button>
          ))}
        </div>

        {/* What's included */}
        <div className="bg-surface-800 rounded-xl p-4 space-y-2">
          <p className="text-xs font-semibold text-muted uppercase tracking-wider mb-3">
            El reporte incluye
          </p>
          {sheets.map((s) => (
            <div key={s} className="flex items-center gap-2">
              <div className="w-1.5 h-1.5 rounded-full bg-brand-400 shrink-0" />
              <span className="text-xs text-slate-400">{s}</span>
            </div>
          ))}
        </div>

        {/* Action buttons */}
        <div className="grid grid-cols-2 gap-3">
          {/* Excel */}
          <button
            onClick={handleExcelExport}
            disabled={loadingXlsx || loadingJson}
            className="flex flex-col items-center gap-2 p-4 rounded-xl border transition-all disabled:opacity-50"
            style={{
              borderColor: "#10b98150",
              background:  "#10b98108",
            }}
          >
            {loadingXlsx ? (
              <div className="w-6 h-6 border-2 border-brand-400 border-t-transparent rounded-full animate-spin" />
            ) : (
              <FileSpreadsheet size={24} className="text-brand-400" />
            )}
            <span className="text-xs font-semibold text-brand-400">
              {loadingXlsx ? "Generando..." : "Excel (.xlsx)"}
            </span>
            <span className="text-[10px] text-muted text-center leading-tight">
              5 hojas · compatible con Excel y Google Sheets
            </span>
          </button>

          {/* JSON */}
          <button
            onClick={handleJsonExport}
            disabled={loadingXlsx || loadingJson}
            className="flex flex-col items-center gap-2 p-4 rounded-xl border transition-all disabled:opacity-50"
            style={{
              borderColor: "#3b82f650",
              background:  "#3b82f608",
            }}
          >
            {loadingJson ? (
              <div className="w-6 h-6 border-2 border-blue-400 border-t-transparent rounded-full animate-spin" />
            ) : (
              <FileJson size={24} className="text-blue-400" />
            )}
            <span className="text-xs font-semibold text-blue-400">
              {loadingJson ? "Exportando..." : "JSON"}
            </span>
            <span className="text-[10px] text-muted text-center leading-tight">
              Datos completos · respaldo total
            </span>
          </button>
        </div>

        <button onClick={onClose} className="btn-ghost w-full text-sm">
          Cancelar
        </button>
      </div>
    </div>
  );
}
