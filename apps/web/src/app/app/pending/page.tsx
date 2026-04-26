"use client";
// apps/web/src/app/app/pending/page.tsx
import { useEffect, useState } from "react";
import {
  Clock, Plus, CheckCircle2, AlertTriangle,
  AlertCircle, Trash2, DollarSign,
} from "lucide-react";
import { usePendingStore }      from "@/store/usePendingStore";
import { useFinanceStore }       from "@/store/useFinanceStore";
import PendingPaymentModal       from "@/components/modals/PendingPaymentModal";
import type { PendingPayment, PendingStatus } from "@/types/pending";
import { cn } from "@/lib/utils";

const fmt = (n: number) =>
  new Intl.NumberFormat("es-DO", { style: "currency", currency: "DOP" }).format(n);

const fmtDate = (d: string) =>
  new Date(d + "T00:00:00").toLocaleDateString("es-DO", {
    day: "numeric", month: "short", year: "numeric",
  });

const STATUS_CONFIG: Record<PendingStatus, { label: string; color: string; icon: React.ReactNode }> = {
  pending:   { label: "Pendiente",  color: "text-blue-400   bg-blue-400/10   border-blue-400/20",   icon: <Clock size={12} /> },
  due_soon:  { label: "Por vencer", color: "text-amber-400  bg-amber-400/10  border-amber-400/20",  icon: <AlertTriangle size={12} /> },
  overdue:   { label: "Vencido",    color: "text-red-400    bg-red-400/10    border-red-400/20",    icon: <AlertCircle size={12} /> },
  collected: { label: "Cobrado",    color: "text-emerald-400 bg-emerald-400/10 border-emerald-400/20", icon: <CheckCircle2 size={12} /> },
};

export default function PendingPage() {
  const { payments, summary, isLoading, fetchPending, deletePending } = usePendingStore();
  const { accounts, fetchAll } = useFinanceStore();

  const [modalMode,    setModalMode]    = useState<"create" | "collect">("create");
  const [modalOpen,    setModalOpen]    = useState(false);
  const [selected,     setSelected]     = useState<PendingPayment | undefined>();
  const [activeFilter, setActiveFilter] = useState<PendingStatus | "all">("all");

  useEffect(() => {
    fetchPending();
    if (accounts.length === 0) fetchAll();
  }, []);

  const filtered = activeFilter === "all"
    ? payments
    : payments.filter(p => p.computed_status === activeFilter);

  const openCreate = () => {
    setModalMode("create");
    setSelected(undefined);
    setModalOpen(true);
  };

  const openCollect = (p: PendingPayment) => {
    setModalMode("collect");
    setSelected(p);
    setModalOpen(true);
  };

  const handleDelete = async (p: PendingPayment) => {
    if (!confirm(`¿Eliminar el pendiente de ${p.debtor_name}?`)) return;
    await deletePending(p.id);
  };

  return (
    <div className="p-6 max-w-4xl mx-auto">

      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-white">Cobros pendientes</h1>
          <p className="text-sm text-muted mt-0.5">Facturas y deudas por cobrar</p>
        </div>
        <button
          onClick={openCreate}
          className="flex items-center gap-2 px-4 py-2.5 bg-amber-500 hover:bg-amber-400
                     text-black text-sm font-medium rounded-xl transition-all"
        >
          <Plus size={16} />
          Nuevo pendiente
        </button>
      </div>

      {/* Summary cards */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 mb-6">
        {[
          { key: "overdue",   label: "Vencidos",   value: summary.overdue,   color: "text-red-400",     bg: "bg-red-400/10" },
          { key: "due_soon",  label: "Por vencer",  value: summary.due_soon,  color: "text-amber-400",   bg: "bg-amber-400/10" },
          { key: "pending",   label: "A tiempo",    value: summary.pending,   color: "text-blue-400",    bg: "bg-blue-400/10" },
          { key: "collected", label: "Cobrados",    value: summary.collected, color: "text-emerald-400", bg: "bg-emerald-400/10" },
        ].map(card => (
          <button
            key={card.key}
            onClick={() => setActiveFilter(prev => prev === card.key ? "all" : card.key as PendingStatus)}
            className={cn(
              "rounded-xl p-4 border text-left transition-all",
              activeFilter === card.key
                ? `${card.bg} border-current`
                : "bg-surface-800 border-surface-500 hover:border-surface-400"
            )}
          >
            <p className="text-xs text-muted mb-1">{card.label}</p>
            <p className={cn("text-2xl font-bold", card.color)}>{card.value}</p>
          </button>
        ))}
      </div>

      {/* Total por cobrar */}
      {summary.total > 0 && (
        <div className="flex items-center gap-3 mb-5 px-4 py-3 bg-surface-800
                        border border-surface-500 rounded-xl">
          <DollarSign size={16} className="text-amber-400" />
          <span className="text-sm text-muted">Total por cobrar:</span>
          <span className="text-sm font-bold text-amber-400 ml-auto">
            {fmt(payments.filter(p => p.status !== "collected").reduce((acc, p) => acc + p.amount, 0))}
          </span>
        </div>
      )}

      {/* Lista */}
      {isLoading ? (
        <div className="flex items-center justify-center py-16 text-muted text-sm">Cargando...</div>
      ) : filtered.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-16 text-center">
          <Clock size={36} className="text-surface-500 mb-3" />
          <p className="text-sm text-muted">
            {activeFilter === "all"
              ? "No tienes cobros pendientes"
              : `No hay pagos en estado "${STATUS_CONFIG[activeFilter as PendingStatus]?.label}"`}
          </p>
          {activeFilter === "all" && (
            <button
              onClick={openCreate}
              className="mt-4 text-xs text-amber-400 hover:text-amber-300 underline underline-offset-2"
            >
              Registrar el primero
            </button>
          )}
        </div>
      ) : (
        <div className="space-y-2">
          {filtered.map(p => {
            const cfg = STATUS_CONFIG[p.computed_status];
            return (
              <div
                key={p.id}
                className="flex items-center gap-4 px-4 py-4 bg-surface-800
                           border border-surface-500 rounded-xl hover:border-surface-400 transition-all"
              >
                <span className={cn(
                  "flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium border shrink-0",
                  cfg.color
                )}>
                  {cfg.icon}{cfg.label}
                </span>

                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-white truncate">{p.debtor_name}</p>
                  {p.description && (
                    <p className="text-xs text-muted truncate mt-0.5">{p.description}</p>
                  )}
                  <p className="text-xs text-muted mt-0.5">
                    {p.status === "collected"
                      ? `Cobrado el ${fmtDate(p.collected_date!)}`
                      : `Vence ${fmtDate(p.due_date)}`}
                  </p>
                </div>

                <p className={cn(
                  "text-base font-bold shrink-0",
                  p.status === "collected" ? "text-emerald-400" : "text-white"
                )}>
                  {fmt(p.amount)}
                </p>

                {p.status !== "collected" && (
                  <div className="flex items-center gap-1 shrink-0">
                    <button
                      onClick={() => openCollect(p)}
                      className="flex items-center gap-1.5 px-3 py-1.5 bg-emerald-500/15
                                 hover:bg-emerald-500/25 text-emerald-400 text-xs rounded-lg
                                 border border-emerald-500/20 transition-all"
                    >
                      <CheckCircle2 size={13} />Cobrar
                    </button>
                    <button
                      onClick={() => handleDelete(p)}
                      className="p-1.5 text-muted hover:text-red-400 hover:bg-red-500/10 rounded-lg transition-all"
                    >
                      <Trash2 size={14} />
                    </button>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}

      <PendingPaymentModal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        mode={modalMode}
        payment={selected}
      />
    </div>
  );
}
