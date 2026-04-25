"use client";
import { useState } from "react";
import { useFinanceStore } from "@/store/useFinanceStore";
import { Modal } from "@/components/ui";
import toast from "react-hot-toast";

interface Props {
  open: boolean;
  onClose: () => void;
  initial?: { type?: "income" | "expense" | "transfer" };
}

export default function TransactionModal({ open, onClose, initial }: Props) {
  const { accounts, categories, addTransaction, fetchAll } = useFinanceStore();
  const today = new Date().toISOString().split("T")[0];

  const [type, setType] = useState<"income" | "expense" | "transfer">(initial?.type ?? "income");
  const [form, setForm] = useState({
    transaction_date: today,
    category_id: "",
    account_id: "",
    to_account_id: "",
    amount: "",
    detail: "",
    is_recurring: false,
  });
  const [loading, setLoading] = useState(false);

  const set = (k: string, v: string | boolean) => setForm((f) => ({ ...f, [k]: v }));

  const filteredCategories = categories.filter((c) =>
    type === "income" ? c.movement_type === 1 : type === "expense" ? c.movement_type === 2 : false
  );
  const activeAccounts = accounts.filter((a) => a.is_active);
  const destinationAccounts = activeAccounts.filter((a) => a.id !== form.account_id);

  const fromAccount = activeAccounts.find((a) => a.id === form.account_id);
  const toAccount = activeAccounts.find((a) => a.id === form.to_account_id);
  const amount = parseFloat(form.amount) || 0;

  const newFromBalance = fromAccount ? fromAccount.balance - amount : 0;
  const newToBalance = toAccount ? toAccount.balance + amount : 0;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (type === "transfer") {
      if (!form.account_id) { toast.error("Selecciona cuenta de salida"); return; }
      if (!form.to_account_id) { toast.error("Selecciona cuenta de entrada"); return; }
      if (form.account_id === form.to_account_id) { toast.error("Las cuentas deben ser diferentes"); return; }
      if (!form.amount || parseFloat(form.amount) <= 0) { toast.error("Ingresa un monto válido"); return; }
      if (fromAccount && parseFloat(form.amount) > fromAccount.balance) { toast.error("Saldo insuficiente"); return; }

      setLoading(true);
      try {
        const { createClient } = await import("@/lib/supabase/client");
        const supabase = createClient();
        const { data: { user } } = await supabase.auth.getUser();
        
        if (!user) { toast.error("No autenticado"); return; }

        // Crear transacción de salida
        await supabase.from("transactions").insert({
          user_id: user.id,
          account_id: form.account_id,
          amount: -parseFloat(form.amount),
          type: "transfer",
          detail: `Transferencia a ${toAccount?.name}`,
          transaction_date: form.transaction_date,
          category_id: null,
          is_recurring: false,
        });

        // Crear transacción de entrada
        await supabase.from("transactions").insert({
          user_id: user.id,
          account_id: form.to_account_id,
          amount: parseFloat(form.amount),
          type: "transfer",
          detail: `Transferencia desde ${fromAccount?.name}`,
          transaction_date: form.transaction_date,
          category_id: null,
          is_recurring: false,
        });

        // Actualizar balances
        await supabase.from("accounts").update({ balance: newFromBalance }).eq("id", form.account_id);
        await supabase.from("accounts").update({ balance: newToBalance }).eq("id", form.to_account_id);

        // Recargar todo
        await fetchAll();

        toast.success("Transferencia completada");
        onClose();
        setForm({ transaction_date: today, category_id: "", account_id: "", to_account_id: "", amount: "", detail: "", is_recurring: false });
      } catch (error) {
        console.error(error);
        toast.error("Error al transferir");
      } finally {
        setLoading(false);
      }
    } else {
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
        setForm({ transaction_date: today, category_id: "", account_id: "", to_account_id: "", amount: "", detail: "", is_recurring: false });
      } catch {
        toast.error("Error al guardar el movimiento");
      } finally {
        setLoading(false);
      }
    }
  };

  return (
    <Modal open={open} onClose={onClose} title="Nuevo movimiento">
      <div className="flex gap-2 mb-5">
        {(["income", "expense", "transfer"] as const).map((t) => (
          <button
            key={t}
            type="button"
            onClick={() => { setType(t); set("category_id", ""); set("account_id", ""); set("to_account_id", ""); }}
            className="flex-1 py-2.5 rounded-xl border text-sm font-semibold transition-all duration-150"
            style={{
              borderColor: type === t ? (t === "income" ? "#10b981" : t === "expense" ? "#ef4444" : "#3b82f6") : "#1e2a3a",
              background: type === t ? (t === "income" ? "rgba(16,185,129,0.1)" : t === "expense" ? "rgba(239,68,68,0.1)" : "rgba(59,130,246,0.1)") : "transparent",
              color: type === t ? (t === "income" ? "#10b981" : t === "expense" ? "#ef4444" : "#3b82f6") : "#4a6b8a",
            }}
          >
            {t === "income" ? "↑ Ingreso" : t === "expense" ? "↓ Egreso" : "⇄ Transferencia"}
          </button>
        ))}
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
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

        {type !== "transfer" && (
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
        )}

        {type !== "transfer" && (
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
        )}

        <div>
          <label className="label-base">{type === "transfer" ? "Cuenta DE (salida)" : "Cuenta / Almacén"}</label>
          <select
            value={form.account_id}
            onChange={(e) => set("account_id", e.target.value)}
            className="input-base"
            required
          >
            <option value="">Seleccionar cuenta...</option>
            {activeAccounts.map((a) => (
              <option key={a.id} value={a.id}>{a.name} (RD${a.balance.toLocaleString()})</option>
            ))}
          </select>
        </div>

        {type === "transfer" && (
          <div>
            <label className="label-base">Cuenta A (entrada)</label>
            <select
              value={form.to_account_id}
              onChange={(e) => set("to_account_id", e.target.value)}
              className="input-base"
              required
            >
              <option value="">Seleccionar cuenta...</option>
              {destinationAccounts.map((a) => (
                <option key={a.id} value={a.id}>{a.name} (RD${a.balance.toLocaleString()})</option>
              ))}
            </select>
          </div>
        )}

        {type === "transfer" && fromAccount && toAccount && amount > 0 && (
          <div className="bg-slate-700 rounded-lg p-4 space-y-2 text-sm">
            <div className="font-semibold text-slate-100">Resumen de transferencia:</div>
            <div className="flex justify-between text-slate-300">
              <span>{fromAccount.name}</span>
              <span>RD${fromAccount.balance.toLocaleString()} → RD${newFromBalance.toLocaleString()}</span>
            </div>
            <div className="border-t border-slate-600 pt-2 flex justify-between text-slate-300">
              <span>{toAccount.name}</span>
              <span>RD${toAccount.balance.toLocaleString()} → RD${newToBalance.toLocaleString()}</span>
            </div>
          </div>
        )}

        {type !== "transfer" && (
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
        )}

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
              background: type === "income" ? "#10b981" : type === "expense" ? "#ef4444" : "#3b82f6",
            }}
          >
            {loading ? "Guardando..." : type === "transfer" ? "Transferir" : "Registrar"}
          </button>
        </div>
      </form>
    </Modal>
  );
}
