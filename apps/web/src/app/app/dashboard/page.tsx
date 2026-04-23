"use client";
import { useState } from "react";
import { useFinanceStore } from "@/store/useFinanceStore";
import { PageHeader, MetricCard, AlertBanner } from "@/components/ui";
import TransactionModal from "@/components/modals/TransactionModal";
import TrendChart from "@/components/charts/TrendChart";
import CategoryDonut from "@/components/charts/CategoryDonut";
import RecentTransactions from "@/components/dashboard/RecentTransactions";
import PeriodSelector from "@/components/dashboard/PeriodSelector";
import { formatCurrency } from "@/lib/finance";
import { Plus, Wallet, TrendingDown, TrendingUp, Activity } from "lucide-react";

export default function DashboardPage() {
  const [showModal, setShowModal] = useState(false);
  const {
    summary, alerts, totalLiquid, totalDebt, netWorth,
    transactions, selectedYear, selectedMonth, isLoading,
  } = useFinanceStore();

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <div className="w-8 h-8 border-2 border-brand-500 border-t-transparent rounded-full animate-spin mx-auto mb-3" />
          <p className="text-sm text-muted">Cargando tus finanzas...</p>
        </div>
      </div>
    );
  }

  const debtRatio = (totalLiquid + totalDebt) > 0
    ? totalDebt / (totalLiquid + totalDebt)
    : 0;

  return (
    <>
      <PageHeader
        title="Dashboard"
        subtitle={`Resumen financiero • ${selectedMonth}/${selectedYear}`}
        action={
          <div className="flex gap-3">
            <PeriodSelector />
            <button onClick={() => setShowModal(true)} className="btn-primary flex items-center gap-2">
              <Plus size={15} /> Nuevo movimiento
            </button>
          </div>
        }
      />

      {/* Alerts */}
      {alerts.length > 0 && (
        <div className="space-y-2 mb-6">
          {alerts.map((a) => (
            <AlertBanner key={a.id} type={a.type} title={a.title} message={a.message} />
          ))}
        </div>
      )}

      {/* KPI Row */}
      <div className="grid grid-cols-4 gap-4 mb-5">
        <MetricCard
          label="Balance líquido"
          value={formatCurrency(totalLiquid, "DOP", true)}
          subvalue={`${totalLiquid >= 0 ? "Activo" : "Sobregirado"}`}
          accent={totalLiquid >= 0 ? "#10b981" : "#ef4444"}
          icon={<Wallet size={16} />}
        />
        <MetricCard
          label="Ingresos del mes"
          value={formatCurrency(summary?.ingresos ?? 0, "DOP", true)}
          subvalue={`${((summary?.tasa_ahorro ?? 0) * 100).toFixed(0)}% tasa de ahorro`}
          accent="#10b981"
          icon={<TrendingUp size={16} />}
        />
        <MetricCard
          label="Egresos del mes"
          value={formatCurrency(summary?.egresos ?? 0, "DOP", true)}
          subvalue={`Ahorro: ${formatCurrency(summary?.ahorrado ?? 0, "DOP", true)}`}
          accent="#ef4444"
          icon={<TrendingDown size={16} />}
        />
        <MetricCard
          label="Patrimonio neto"
          value={formatCurrency(netWorth, "DOP", true)}
          subvalue={`Deuda: ${formatCurrency(totalDebt, "DOP", true)}`}
          accent={netWorth >= 0 ? "#3b82f6" : "#ef4444"}
          icon={<Activity size={16} />}
        />
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-3 gap-4 mb-5">
        <div className="col-span-2 card">
          <h3 className="text-sm font-semibold text-slate-300 mb-4">Tendencia de flujo — últimos 6 meses</h3>
          <TrendChart transactions={transactions} />
        </div>
        <div className="card">
          <h3 className="text-sm font-semibold text-slate-300 mb-4">Activos vs. Deudas</h3>
          <CategoryDonut
            data={[
              { name: "Líquido", value: Math.max(totalLiquid, 0), color: "#10b981" },
              { name: "Deudas", value: totalDebt, color: "#ef4444" },
            ]}
          />
          <div className="mt-4 space-y-2">
            {[
              { label: "Balance líquido", val: totalLiquid, color: "#10b981" },
              { label: "Deuda total",     val: -totalDebt,  color: "#ef4444" },
              { label: "Patrimonio neto", val: netWorth,    color: netWorth >= 0 ? "#10b981" : "#ef4444" },
            ].map((r) => (
              <div key={r.label} className="flex justify-between text-sm">
                <span className="text-muted">{r.label}</span>
                <span className="font-semibold" style={{ color: r.color }}>
                  {formatCurrency(r.val, "DOP", true)}
                </span>
              </div>
            ))}
            <div className="pt-2 border-t border-surface-500">
              <div className="flex justify-between text-sm">
                <span className="text-muted">Ratio deuda</span>
                <span className={`font-semibold ${debtRatio > 0.7 ? "text-red-400" : "text-brand-400"}`}>
                  {(debtRatio * 100).toFixed(1)}%
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Recent Transactions */}
      <div className="card">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-sm font-semibold text-slate-300">Movimientos recientes</h3>
          <a href="/app/transactions" className="text-xs text-brand-400 hover:text-brand-300 transition-colors">
            Ver todos →
          </a>
        </div>
        <RecentTransactions transactions={transactions.slice(0, 8)} />
      </div>

      <TransactionModal open={showModal} onClose={() => setShowModal(false)} />
    </>
  );
}
