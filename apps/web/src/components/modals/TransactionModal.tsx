"use client";
import { useState } from "react";
import { useFinanceStore } from "@/store/useFinanceStore";
import { Modal } from "@/components/ui";
import toast from "react-hot-toast";

interface Props {
  open: boolean;
  onClose: () => void;
  initial?: { type?: "income" | "expense" };
}

export default function TransactionModal({ open, onClose, initial }: Props) {
  const { accounts, categories, addTransaction } = useFinanceStore();
  const today = new Date().toISOString().split("T")[0];

  const [type, setType] = useState<"income" | "expense">(initial?.type ?? "income");
  const [form, setForm] = useState({
    transaction_date: today,
    category_id: "",
    account_id: "",
    amount: "",
    detail: "",
    is_recurring: false,
  });
  const [loading, setLoading] = useState(false);

  const set = (k: string, v: string | boolean) => setForm((f) => ({ ...f, [k]: v }));

  const filteredCategories = categories.filter((c) =>
    type === "income" ? c.movement_type === 1 : c.movement_type === 2
  );
  const activeAccounts = accounts.filter((a) => a.is_active);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.account_id) { toast.error("Selecciona una cuenta"); return; }
    if (!form.category_id) { toast.error("Selecciona una categoría"); return; }
    if (!form.amount || parseFloat(form.amount) <= 0) { toast.error("Ingresa un monto válido"); return; }

    setLoading(true);
    try {
      await addTransaction({
        account_id: form.account_id,
        category_id: form.category_id,
        amount: parseFloat(form.amount),
        detail: form.detail,
        transaction_date: form.transaction_date,
        type,
        is_recurring: form.is_recurring,
      });
      toast.success("Movimiento registrado");
      onClose();
      setForm({ transaction_date: today, category_id: "", account_id: "", amount: "", detail: "", is_recurring: false });
    } catch {
      toast.error("Error al guardar el movimiento");
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal open={open} onClose={onClose} title="Nuevo movimiento">
      {/* Type selector */}
      <div className="flex gap-2 mb-5">
        {(["income", "expense"] as const).map((t) => (
          <button
            key={t}
            type="button"
            onClick={() => { setType(t); set("category_id", ""); }}
            className="flex-1 py-2.5 rounded-xl border text-sm font-semibold transition-all duration-150"
            style={{
              borderColor: type === t ? (t === "income" ? "#10b981" : "#ef4444") : "#1e2a3a",
              background: type === t ? (t === "income" ? "rgba(16,185,129,0.1)" : "rgba(239,68,68,0.1)") : "transparent",
              color: type === t ? (t === "income" ? "#10b981" : "#ef4444") : "#4a6b8a",
            }}
          >
            {t === "income" ? "↑ Ingreso" : "↓ Egreso"}
          </button>
        ))}
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        {/* Date */}
        <div>
          <label className="label-base">Fecha</label>
          <input
            type="date"
            value={form.transaction_date}
            onChange={(e) => set("transaction_date", e.target.value)}
            className="input-base"
            required
          />
        </div>

        {/* Amount */}
        <div>
          <label className="label-base">Monto (RD$)</label>
          <input
            type="number"
            step="0.01"
            min="0.01"
            value={form.amount}
            onChange={(e) => set("amount", e.target.value)}
            placeholder="0.00"
            className="input-base text-lg font-semibold"
            required
          />
        </div>

        {/* Detail */}
        <div>
          <label className="label-base">Descripción</label>
          <input
            type="text"
            value={form.detail}
            onChange={(e) => set("detail", e.target.value)}
            placeholder="Describe el movimiento..."
            className="input-base"
            required
          />
        </div>

        {/* Category */}
        <div>
          <label className="label-base">Categoría</label>
          <select
            value={form.category_id}
            onChange={(e) => set("category_id", e.target.value)}
            className="input-base"
            required
          >
            <option value="">Seleccionar categoría...</option>
            {filteredCategories.map((c) => (
              <option key={c.id} value={c.id}>{c.icon} {c.name}</option>
            ))}
          </select>
        </div>

        {/* Account */}
        <div>
          <label className="label-base">Cuenta / Almacén</label>
          <select
            value={form.account_id}
            onChange={(e) => set("account_id", e.target.value)}
            className="input-base"
            required
          >
            <option value="">Seleccionar cuenta...</option>
            {activeAccounts.map((a) => (
              <option key={a.id} value={a.id}>{a.name}</option>
            ))}
          </select>
        </div>

        {/* Recurring */}
        <label className="flex items-center gap-3 cursor-pointer group">
          <div
            className="relative w-10 h-5 rounded-full transition-colors duration-200"
            style={{ background: form.is_recurring ? "#10b981" : "#1e2a3a" }}
            onClick={() => set("is_recurring", !form.is_recurring)}
          >
            <div
              className="absolute top-0.5 w-4 h-4 bg-white rounded-full shadow transition-all duration-200"
              style={{ left: form.is_recurring ? "calc(100% - 18px)" : "2px" }}
            />
          </div>
          <span className="text-sm text-slate-300 group-hover:text-slate-200 transition-colors">
            Movimiento recurrente mensual
          </span>
        </label>

        {/* Submit */}
        <div className="flex gap-3 pt-2">
          <button
            type="button"
            onClick={onClose}
            className="flex-1 btn-ghost border border-surface-500"
          >
            Cancelar
          </button>
          <button
            type="submit"
            disabled={loading}
            className="flex-1 btn-primary"
            style={{
              background: type === "income" ? "#10b981" : "#ef4444",
            }}
          >
            {loading ? "Guardando..." : "Registrar"}
          </button>
        </div>
      </form>
    </Modal>
  );
}
