"use client";
import { useState } from "react";
import { useFinanceStore } from "@/store/useFinanceStore";
import { PageHeader, ProgressBar } from "@/components/ui";
import AccountModal from "@/components/modals/AccountModal";
import DebtModal from "@/components/modals/DebtModal";
import { formatCurrency } from "@/lib/finance";
import { Plus, Wallet, AlertTriangle, MoreVertical } from "lucide-react";
import type { Account } from "@/types";

const TYPE_LABELS: Record<string, string> = {
  banco: "Banco",
  cooperativa: "Cooperativa",
  efectivo: "Efectivo",
  inversion: "Inversión",
  deuda: "Deuda",
  prestamo: "Préstamo",
};

function AccountCard({ account, onEdit }: { account: Account; onEdit: (acc: Account) => void }) {
  const isDebt = account.type === "deuda" || account.type === "prestamo";
  const isNegative = account.balance < 0 && !isDebt;
  const accent = isDebt ? "#ef4444" : account.balance >= 0 ? account.color : "#ef4444";

  return (
    <div className="card hover:border-surface-400 transition-all duration-150 group relative">
      <button
        onClick={() => onEdit(account)}
        className="absolute top-3 right-3 opacity-0 group-hover:opacity-100 p-2 hover:bg-surface-700 rounded-lg transition-all"
        title="Editar cuenta"
      >
        <MoreVertical size={16} className="text-muted" />
      </button>
      <div className="flex items-start justify-between mb-4 pr-8">
        <div className="flex items-center gap-3 flex-1">
          <div className="w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0" style={{ background: `${accent}20` }}>
            {isDebt ? <AlertTriangle size={16} style={{ color: accent }} /> : <Wallet size={16} style={{ color: accent }} />}
          </div>
          <div className="min-w-0">
            <p className="text-sm font-semibold text-slate-200 truncate">{account.name}</p>
            <p className="text-xs text-muted">{TYPE_LABELS[account.type]}</p>
          </div>
        </div>
        <span className="text-xs font-semibold px-2.5 py-1 rounded-full flex-shrink-0 ml-2" style={{ background: `${accent}15`, color: accent }}>
          {account.is_active ? "Activa" : "Inactiva"}
        </span>
      </div>
      <p className="text-2xl font-bold tracking-tight mb-1" style={{ color: accent }}>
        {formatCurrency(account.balance)}
      </p>
      {isDebt && (
        <div className="mt-3 mb-10">
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
  const [editingAccount, setEditingAccount] = useState<Account | null>(null);
  const [debtAccount, setDebtAccount] = useState<Account | null>(null);
  const { accounts, totalLiquid, totalDebt, netWorth } = useFinanceStore();

  const liquid = accounts.filter((a) => !["deuda", "prestamo"].includes(a.type));
  const debts  = accounts.filter((a) =>  ["deuda", "prestamo"].includes(a.type));

  const handleOpenCreate = () => { setEditingAccount(null); setShowModal(true); };
  const handleOpenEdit   = (a: Account) => { setEditingAccount(a); setShowModal(true); };
  const handleCloseModal = () => { setShowModal(false); setEditingAccount(null); };

  return (
    <>
      {debtAccount && <DebtModal account={debtAccount} onClose={() => setDebtAccount(null)} />}

      <AccountModal
        open={showModal}
        onClose={handleCloseModal}
        editingAccount={editingAccount}
        onEditingChange={setEditingAccount}
      />

      <PageHeader title="Cuentas" subtitle="Gestiona todas tus cuentas bancarias y deudas" />

      <div className="max-w-5xl space-y-5">
        {accounts.length > 0 && (
          <div className="grid grid-cols-3 gap-3">
            <div className="card">
              <p className="text-xs text-muted mb-1">Activos líquidos</p>
              <p className="text-xl font-bold text-brand-400">{formatCurrency(totalLiquid)}</p>
            </div>
            <div className="card">
              <p className="text-xs text-muted mb-1">Deudas</p>
              <p className="text-xl font-bold text-red-400">{formatCurrency(totalDebt)}</p>
            </div>
            <div className="card">
              <p className="text-xs text-muted mb-1">Patrimonio neto</p>
              <p className="text-xl font-bold" style={{ color: netWorth >= 0 ? "#10b981" : "#ef4444" }}>
                {formatCurrency(netWorth)}
              </p>
            </div>
          </div>
        )}

        {liquid.length > 0 && (
          <div>
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-sm font-semibold text-slate-200 flex items-center gap-2">
                <Wallet size={14} style={{ color: "#3b82f6" }} />
                Cuentas líquidas ({liquid.length})
              </h3>
              <button onClick={handleOpenCreate} className="btn-primary text-xs px-3 py-1.5">
                <Plus size={12} /> Nueva
              </button>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              {liquid.map((acc) => <AccountCard key={acc.id} account={acc} onEdit={handleOpenEdit} />)}
            </div>
          </div>
        )}

        {debts.length > 0 && (
          <div>
            <h3 className="text-sm font-semibold text-slate-200 flex items-center gap-2 mb-3">
              <AlertTriangle size={14} style={{ color: "#ef4444" }} />
              Deudas ({debts.length})
            </h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              {debts.map((acc) => (
                <div key={acc.id} className="flex flex-col gap-2">
                  <AccountCard account={acc} onEdit={handleOpenEdit} />
                  <button
                    onClick={() => setDebtAccount(acc)}
                    className="w-full bg-emerald-500 hover:bg-emerald-600 text-white text-xs font-semibold py-2.5 rounded-xl transition"
                  >
                    Gestionar deuda
                  </button>
                </div>
              ))}
            </div>
          </div>
        )}

        {accounts.length === 0 && (
          <div className="card text-center py-12 space-y-4">
            <div className="flex justify-center"><Wallet size={32} className="text-muted" /></div>
            <div>
              <h3 className="text-sm font-semibold text-slate-200 mb-1">Sin cuentas</h3>
              <p className="text-xs text-muted mb-4">Crea tu primera cuenta para comenzar a registrar tus movimientos</p>
              <button onClick={handleOpenCreate} className="btn-primary text-xs"><Plus size={12} /> Crear cuenta</button>
            </div>
          </div>
        )}

        {debts.length > 0 && (
          <div className="card bg-brand-500/5 border border-brand-500/20">
            <p className="text-xs text-brand-400 flex items-start gap-2">
              <span className="text-sm">ℹ️</span>
              <span>Las cuentas de <strong>deuda y préstamo que lleguen a $0</strong> se eliminarán automáticamente.</span>
            </p>
          </div>
        )}
      </div>
    </>
  );
}