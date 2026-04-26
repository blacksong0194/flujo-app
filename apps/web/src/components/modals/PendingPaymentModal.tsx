"use client";
// apps/web/src/components/modals/PendingPaymentModal.tsx
import { useState } from "react";
import { X, Clock, User, DollarSign, Calendar, FileText, Wallet } from "lucide-react";
import { usePendingStore } from "@/store/usePendingStore";
import { useFinanceStore } from "@/store/useFinanceStore";
import type { PendingPayment } from "@/types/pending";
import { cn } from "@/lib/utils";

const fmt = (n: number) =>
  new Intl.NumberFormat("es-DO", { style: "currency", currency: "DOP" }).format(n);

interface Props {
  open:     boolean;
  onClose:  () => void;
  mode:     "create" | "collect";
  payment?: PendingPayment;
}

export default function PendingPaymentModal({ open, onClose, mode, payment }: Props) {
  const { addPending, collectPending } = usePendingStore();
  const { accounts, fetchAll }         = useFinanceStore();

  const [debtorName,  setDebtorName]  = useState("");
  const [amount,      setAmount]      = useState("");
  const [description, setDescription] = useState("");
  const [dueDate,     setDueDate]     = useState("");
  const [accountId,   setAccountId]   = useState("");
  const [loading,     setLoading]     = useState(false);
  const [error,       setError]       = useState("");

  if (!open) return null;

  const activeAccounts = accounts.filter(a =>
    a.is_active && !["deuda", "prestamo"].includes(a.type)
  );

  const handleCreate = async () => {
    setError("");
    if (!debtorName.trim()) return setError("El nombre del deudor es requerido");
    if (!amount || parseFloat(amount) <= 0) return setError("Ingresa un monto válido");
    if (!dueDate) return setError("La fecha de vencimiento es requerida");

    setLoading(true);
    await addPending({
      debtor_name: debtorName,
      amount:      parseFloat(amount),
      description,
      due_date:    dueDate,
    });
    setLoading(false);
    handleClose();
  };

  const handleCollect = async () => {
    if (!payment) return;
    setError("");
    if (!accountId) return setError("Selecciona la cuenta donde ingresará el dinero");

    setLoading(true);
    const result = await collectPending(payment.id, accountId);
    if (!result.success) {
      setError(result.error || "Error al registrar el cobro");
      setLoading(false);
      return;
    }
    await fetchAll();
    setLoading(false);
    handleClose();
  };

  const handleClose = () => {
    setDebtorName(""); setAmount(""); setDescription("");
    setDueDate(""); setAccountId(""); setError("");
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
      <div className="relative w-full max-w-md bg-surface-800 rounded-2xl border border-surface-500 shadow-2xl">

        {/* Header */}
        <div className="flex items-center justify-between px-6 py-5 border-b border-surface-500">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-amber-500/15 flex items-center justify-center">
              <Clock size={18} className="text-amber-400" />
            </div>
            <div>
              <h2 className="text-base font-semibold text-white">
                {mode === "create" ? "Nuevo cobro pendiente" : "Registrar cobro"}
              </h2>
              <p className="text-xs text-muted mt-0.5">
                {mode === "create"
                  ? "Registra una deuda por cobrar"
                  : `${payment?.debtor_name} — ${fmt(payment?.amount ?? 0)}`}
              </p>
            </div>
          </div>
          <button onClick={handleClose} className="text-muted hover:text-white transition-colors">
            <X size={20} />
          </button>
        </div>

        {/* Body */}
        <div className="px-6 py-5 space-y-4">

          {mode === "create" && (
            <>
              <div>
                <label className="block text-xs text-muted mb-1.5 font-medium uppercase tracking-wider">
                  Nombre del deudor
                </label>
                <div className="relative">
                  <User size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
                  <input
                    type="text"
                    value={debtorName}
                    onChange={e => setDebtorName(e.target.value)}
                    placeholder="Ej: Juan Pérez"
                    className="w-full pl-9 pr-4 py-2.5 bg-surface-700 border border-surface-500
                               rounded-xl text-sm text-white placeholder:text-muted
                               focus:outline-none focus:border-amber-500 transition-colors"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs text-muted mb-1.5 font-medium uppercase tracking-wider">
                  Monto
                </label>
                <div className="relative">
                  <DollarSign size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
                  <input
                    type="number"
                    value={amount}
                    onChange={e => setAmount(e.target.value)}
                    placeholder="0.00"
                    min="0"
                    step="0.01"
                    className="w-full pl-9 pr-4 py-2.5 bg-surface-700 border border-surface-500
                               rounded-xl text-sm text-white placeholder:text-muted
                               focus:outline-none focus:border-amber-500 transition-colors"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs text-muted mb-1.5 font-medium uppercase tracking-wider">
                  Fecha límite de cobro
                </label>
                <div className="relative">
                  <Calendar size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
                  <input
                    type="date"
                    value={dueDate}
                    onChange={e => setDueDate(e.target.value)}
                    min={new Date().toISOString().split("T")[0]}
                    className="w-full pl-9 pr-4 py-2.5 bg-surface-700 border border-surface-500
                               rounded-xl text-sm text-white
                               focus:outline-none focus:border-amber-500 transition-colors"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs text-muted mb-1.5 font-medium uppercase tracking-wider">
                  Descripción <span className="normal-case">(opcional)</span>
                </label>
                <div className="relative">
                  <FileText size={15} className="absolute left-3 top-3 text-muted" />
                  <textarea
                    value={description}
                    onChange={e => setDescription(e.target.value)}
                    placeholder="Ej: Préstamo para reparación de vehículo"
                    rows={2}
                    className="w-full pl-9 pr-4 py-2.5 bg-surface-700 border border-surface-500
                               rounded-xl text-sm text-white placeholder:text-muted resize-none
                               focus:outline-none focus:border-amber-500 transition-colors"
                  />
                </div>
              </div>
            </>
          )}

          {mode === "collect" && payment && (
            <>
              <div className="bg-emerald-500/10 border border-emerald-500/20 rounded-xl p-4">
                <p className="text-xs text-emerald-400 font-medium uppercase tracking-wider mb-2">
                  Resumen del cobro
                </p>
                <div className="flex justify-between items-center">
                  <span className="text-sm text-muted">De</span>
                  <span className="text-sm text-white font-medium">{payment.debtor_name}</span>
                </div>
                <div className="flex justify-between items-center mt-1">
                  <span className="text-sm text-muted">Monto</span>
                  <span className="text-lg font-bold text-emerald-400">{fmt(payment.amount)}</span>
                </div>
                {payment.description && (
                  <p className="text-xs text-muted mt-2 border-t border-emerald-500/20 pt-2">
                    {payment.description}
                  </p>
                )}
              </div>

              <div>
                <label className="block text-xs text-muted mb-1.5 font-medium uppercase tracking-wider">
                  ¿En qué cuenta ingresa el dinero?
                </label>
                <div className="relative">
                  <Wallet size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
                  <select
                    value={accountId}
                    onChange={e => setAccountId(e.target.value)}
                    className="w-full pl-9 pr-4 py-2.5 bg-surface-700 border border-surface-500
                               rounded-xl text-sm text-white appearance-none
                               focus:outline-none focus:border-emerald-500 transition-colors"
                  >
                    <option value="">Seleccionar cuenta...</option>
                    {activeAccounts.map(a => (
                      <option key={a.id} value={a.id}>
                        {a.name} — {fmt(a.balance)}
                      </option>
                    ))}
                  </select>
                </div>
                {accountId && (
                  <p className="text-xs text-emerald-400 mt-1.5 ml-1">
                    ✓ Se creará una transacción de ingreso automáticamente
                  </p>
                )}
              </div>
            </>
          )}

          {error && (
            <p className="text-xs text-red-400 bg-red-500/10 border border-red-500/20 rounded-lg px-3 py-2">
              {error}
            </p>
          )}
        </div>

        {/* Footer */}
        <div className="flex gap-3 px-6 pb-5">
          <button
            onClick={handleClose}
            className="flex-1 py-2.5 rounded-xl border border-surface-500 text-sm text-muted
                       hover:text-white hover:border-surface-400 transition-all"
          >
            Cancelar
          </button>
          <button
            onClick={mode === "create" ? handleCreate : handleCollect}
            disabled={loading}
            className={cn(
              "flex-1 py-2.5 rounded-xl text-sm font-medium transition-all",
              mode === "create"
                ? "bg-amber-500 hover:bg-amber-400 text-black"
                : "bg-emerald-500 hover:bg-emerald-400 text-black",
              loading && "opacity-60 cursor-not-allowed"
            )}
          >
            {loading
              ? "Procesando..."
              : mode === "create"
              ? "Registrar pendiente"
              : "Confirmar cobro"}
          </button>
        </div>
      </div>
    </div>
  );
}
