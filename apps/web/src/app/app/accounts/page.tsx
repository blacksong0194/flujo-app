"use client";
import { useState } from "react";
import { useFinanceStore } from "@/store/useFinanceStore";
import { PageHeader, EmptyState, ProgressBar } from "@/components/ui";
import AccountModal from "@/components/modals/AccountModal";
import { formatCurrency } from "@/lib/finance";
import { Plus, Wallet, AlertTriangle, TrendingUp } from "lucide-react";
import type { Account } from "@/types";

const TYPE_LABELS: Record<string, string> = {
  banco: "Banco",
  cooperativa: "Cooperativa",
  efectivo: "Efectivo",
  inversion: "Inversión",
  deuda: "Deuda",
  prestamo: "Préstamo",
};

function AccountCard({ account }: { account: Account }) {
  const isDebt = account.type === "deuda" || account.type === "prestamo";
  const isNegative = account.balance < 0 && !isDebt;
  const accent = isDebt ? "#ef4444" : account.balance >= 0 ? account.color : "#ef4444";

  return (
    <div className="card hover:border-surface-400 transition-all duration-150">
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-center gap-3">
          <div
            className="w-10 h-10 rounded-xl flex items-center justify-center"
            style={{ background: `${accent}20` }}
          >
            {isDebt
              ? <AlertTriangle size={16} style={{ color: accent }} />
              : <Wallet size={16} style={{ color: accent }} />
            }
          </div>
          <div>
            <p className="text-sm font-semibold text-slate-200">{account.name}</p>
            <p className="text-xs text-muted">{TYPE_LABELS[account.type]}</p>
          </div>
        </div>
        <span
          className="text-xs font-semibold px-2.5 py-1 rounded-full"
          style={{ background: `${accent}15`, color: accent }}
        >
          {account.is_active ? "Activa" : "Inactiva"}
        </span>
      </div>

      <p
        className="text-2xl font-bold tracking-tight mb-1"
        style={{ color: accent }}
      >
        {formatCurrency(account.balance)}
      </p>

      {isDebt && (
        <div className="mt-3">
          <ProgressBar percent={78} color="#ef4444" />
          <p className="text-xs text-muted mt-1.5">78% del límite utilizado</p>
        </div>
      )}

      {isNegative && (
        <p className="text-xs text-red-400 mt-2 flex items-center gap-1">
          <AlertTriangle size={11} /> Cuenta sobregirada — requiere atención
        </p>
      )}
    </div>
  );
}

export default function AccountsPage() {
  const [showModal, setShowModal] = useState(false);
  const { accounts, totalLiquid, totalDebt, netWorth } = useFinanceStore();

  const liquid   = accounts.filter((a) => !["deuda", "prestamo"].includes(a.type));
  const debts    = accounts.filter((a) => ["deuda", "prestamo"].includes(a.type));

  return (
    <>
      <PageHeader
        title="Cuentas & Almacenes"
        subtitle="Gestiona tus bancos, efectivo, inversiones y deudas"
        action={
          <button onClick={() => setShowModal(true)} className="btn-primary flex items-center gap-2">
            <Plus size={15} /> Nueva cuenta
          </button>
        }
      />

      {/* Summary */}
      <div className="grid grid-cols-3 gap-4 mb-7">
        {[
          { label: "Total líquido",  val: totalLiquid, color: "#10b981", icon: <TrendingUp size={16} /> },
          { label: "Total deudas",   val: -totalDebt,  color: "#ef4444", icon: <AlertTriangle size={16} /> },
          { label: "Patrimonio neto",val: netWorth,    color: netWorth >= 0 ? "#3b82f6" : "#ef4444", icon: <Wallet size={16} /> },
        ].map((s) => (
          <div key={s.label} className="stat-card" style={{ borderTop: `3px solid ${s.color}` }}>
            <div className="flex justify-between items-start mb-2">
              <p className="label-base mb-0">{s.label}</p>
              <span style={{ color: s.color }}>{s.icon}</span>
            </div>
            <p className="text-xl font-bold" style={{ color: s.color }}>{formatCurrency(s.val, "DOP", true)}</p>
          </div>
        ))}
      </div>

      {/* Liquid accounts */}
      <h2 className="text-xs font-semibold text-muted uppercase tracking-wider mb-3">
        Cuentas activas ({liquid.length})
      </h2>
      {liquid.length === 0 ? (
        <EmptyState
          icon={<Wallet size={24} />}
          title="Sin cuentas activas"
          description="Agrega tu primera cuenta bancaria o de efectivo para empezar a registrar movimientos."
          action={
            <button onClick={() => setShowModal(true)} className="btn-primary">
              Agregar cuenta
            </button>
          }
        />
      ) : (
        <div className="grid grid-cols-3 gap-4 mb-8">
          {liquid.map((a) => <AccountCard key={a.id} account={a} />)}
        </div>
      )}

      {/* Debt accounts */}
      {debts.length > 0 && (
        <>
          <h2 className="text-xs font-semibold text-muted uppercase tracking-wider mb-3">
            Deudas & Obligaciones ({debts.length})
          </h2>
          <div className="grid grid-cols-2 gap-4">
            {debts.map((a) => <AccountCard key={a.id} account={a} />)}
          </div>
        </>
      )}

      <AccountModal open={showModal} onClose={() => setShowModal(false)} />
    </>
  );
}
