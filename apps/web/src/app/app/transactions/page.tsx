"use client";
import { useState, useMemo } from "react";
import { useFinanceStore } from "@/store/useFinanceStore";
import { PageHeader, TypeTag, EmptyState } from "@/components/ui";
import TransactionModal from "@/components/modals/TransactionModal";
import { formatCurrency, formatDate } from "@/lib/finance";
import { Plus, Search, Trash2, ArrowLeftRight } from "lucide-react";
import type { Transaction } from "@/types";
import toast from "react-hot-toast";

export default function TransactionsPage() {
  const [showModal, setShowModal] = useState(false);
  const [modalType, setModalType] = useState<"income" | "expense">("income");
  const [search, setSearch] = useState("");
  const [filter, setFilter] = useState<"all" | "income" | "expense">("all");
  const [acctFilter, setAcctFilter] = useState("all");

  const { transactions, accounts, deleteTransaction } = useFinanceStore();

  const filtered = useMemo(() => {
    return transactions.filter((t) => {
      if (filter !== "all" && t.type !== filter) return false;
      if (acctFilter !== "all" && t.account_id !== acctFilter) return false;
      if (search) {
        const q = search.toLowerCase();
        return (
          t.detail.toLowerCase().includes(q) ||
          (t.category?.name ?? "").toLowerCase().includes(q) ||
          (t.account?.name ?? "").toLowerCase().includes(q)
        );
      }
      return true;
    });
  }, [transactions, filter, acctFilter, search]);

  const totalIncome  = filtered.filter(t => t.type === "income").reduce((s, t) => s + t.amount, 0);
  const totalExpense = filtered.filter(t => t.type === "expense").reduce((s, t) => s + t.amount, 0);

  const handleDelete = async (t: Transaction) => {
    if (!confirm(`¿Eliminar "${t.detail}"?`)) return;
    await deleteTransaction(t.id);
    toast.success("Movimiento eliminado");
  };

  const openModal = (type: "income" | "expense") => {
    setModalType(type);
    setShowModal(true);
  };

  return (
    <>
      <PageHeader
        title="Movimientos"
        subtitle={`${filtered.length} registros encontrados`}
        action={
          <div className="flex gap-2">
            <button onClick={() => openModal("income")} className="btn-outline flex items-center gap-2">
              <Plus size={14} /> Ingreso
            </button>
            <button onClick={() => openModal("expense")} className="btn-primary flex items-center gap-2"
              style={{ background: "#ef4444" }}>
              <Plus size={14} /> Egreso
            </button>
          </div>
        }
      />

      {/* Summary bar */}
      <div className="grid grid-cols-3 gap-4 mb-5">
        {[
          { label: "Ingresos filtrados",  val: totalIncome,   color: "#10b981" },
          { label: "Egresos filtrados",   val: totalExpense,  color: "#ef4444" },
          { label: "Neto filtrado",       val: totalIncome - totalExpense, color: (totalIncome - totalExpense) >= 0 ? "#10b981" : "#ef4444" },
        ].map((s) => (
          <div key={s.label} className="stat-card">
            <p className="label-base">{s.label}</p>
            <p className="text-xl font-bold" style={{ color: s.color }}>
              {formatCurrency(s.val, "DOP", true)}
            </p>
          </div>
        ))}
      </div>

      {/* Filters */}
      <div className="flex gap-3 mb-4 flex-wrap">
        <div className="relative flex-1 min-w-[200px]">
          <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
          <input
            type="text"
            placeholder="Buscar por descripción, categoría o cuenta..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="input-base pl-9"
          />
        </div>

        <select
          value={acctFilter}
          onChange={(e) => setAcctFilter(e.target.value)}
          className="input-base w-auto"
        >
          <option value="all">Todas las cuentas</option>
          {accounts.map((a) => (
            <option key={a.id} value={a.id}>{a.name}</option>
          ))}
        </select>

        <div className="flex rounded-xl border border-surface-500 overflow-hidden">
          {(["all", "income", "expense"] as const).map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className="px-4 py-2 text-xs font-medium transition-all duration-150"
              style={{
                background: filter === f ? "#10b981" : "transparent",
                color: filter === f ? "#fff" : "#4a6b8a",
              }}
            >
              {{ all: "Todos", income: "Ingresos", expense: "Egresos" }[f]}
            </button>
          ))}
        </div>
      </div>

      {/* Table */}
      <div className="card overflow-hidden p-0">
        {/* Header */}
        <div className="grid grid-cols-[120px_1fr_160px_130px_110px_44px] gap-4 px-5 py-3 border-b border-surface-500 bg-surface-800">
          {["Fecha", "Descripción / Categoría", "Cuenta", "Monto", "Tipo", ""].map((h) => (
            <span key={h} className="text-[10px] font-semibold text-muted uppercase tracking-wider">{h}</span>
          ))}
        </div>

        {filtered.length === 0 ? (
          <EmptyState
            icon={<ArrowLeftRight size={24} />}
            title="Sin movimientos"
            description="No se encontraron movimientos con los filtros actuales."
            action={
              <button onClick={() => openModal("income")} className="btn-primary">
                Registrar primer movimiento
              </button>
            }
          />
        ) : (
          <div className="divide-y divide-surface-600">
            {filtered.map((t) => (
              <div
                key={t.id}
                className="grid grid-cols-[120px_1fr_160px_130px_110px_44px] gap-4 px-5 py-3.5
                           hover:bg-surface-600/30 transition-colors items-center group"
              >
                <span className="text-xs text-muted">{formatDate(t.transaction_date)}</span>

                <div className="min-w-0">
                  <p className="text-sm font-medium text-slate-200 truncate">{t.detail}</p>
                  <p className="text-xs text-muted">{t.category?.name ?? "Sin categoría"}</p>
                </div>

                <p className="text-xs text-muted truncate">{t.account?.name ?? "—"}</p>

                <p
                  className="text-sm font-bold"
                  style={{ color: t.type === "income" ? "#10b981" : "#ef4444" }}
                >
                  {t.type === "income" ? "+" : "-"}
                  {formatCurrency(t.amount)}
                </p>

                <TypeTag type={t.type} />

                <button
                  onClick={() => handleDelete(t)}
                  className="opacity-0 group-hover:opacity-100 p-1.5 rounded-lg
                             text-muted hover:text-red-400 hover:bg-red-500/10
                             transition-all duration-150"
                >
                  <Trash2 size={13} />
                </button>
              </div>
            ))}
          </div>
        )}
      </div>

      <TransactionModal
        open={showModal}
        onClose={() => setShowModal(false)}
        initial={{ type: modalType }}
      />
    </>
  );
}
