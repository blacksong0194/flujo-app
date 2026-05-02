"use client";
import { useState } from "react";
import { useFinanceStore } from "@/store/useFinanceStore";
import { useRecurringStore } from "@/store/useRecurringStore";
import { createClient } from "@/lib/supabase/client";
import { formatCurrency } from "@/lib/finance";
import type { Account } from "@/types";
import toast from "react-hot-toast";

interface Props {
  account: Account;
  onClose: () => void;
}

export default function DebtModal({ account, onClose }: Props) {
  const { accounts, fetchAll } = useFinanceStore();
  const { addDebtAutoPayment } = useRecurringStore();
  const supabase = createClient();

  const [mode, setMode] = useState<"pay" | "add">("pay");
  const [amount, setAmount] = useState("");
  const [fromAccountId, setFromAccountId] = useState("");
  const [showAccounts, setShowAccounts] = useState(false);
  const [autoPayment, setAutoPayment] = useState(false);
  const [autoDay, setAutoDay] = useState(1);
  const [loading, setLoading] = useState(false);

  const liquidAccounts = accounts.filter(
    (a) => !["deuda", "prestamo"].includes(a.type) && a.is_active
  );

  const parsedAmount = parseFloat(amount) || 0;
  const fromAccount = accounts.find((a) => a.id === fromAccountId);
  const selectedAccount = liquidAccounts.find((a) => a.id === fromAccountId);

  const newDebtBalance = mode === "pay"
    ? account.balance - parsedAmount
    : account.balance + parsedAmount;

  const newFromBalance = fromAccount
    ? mode === "pay"
      ? fromAccount.balance - parsedAmount
      : fromAccount.balance + parsedAmount
    : null;

  async function submit() {
    if (!amount || !fromAccountId || parsedAmount <= 0) {
      toast.error("Completa todos los campos");
      return;
    }
    setLoading(true);
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      if (mode === "pay") {
        await supabase.from("accounts").update({ balance: newDebtBalance }).eq("id", account.id);
        await supabase.from("accounts").update({ balance: newFromBalance }).eq("id", fromAccountId);
        await supabase.from("transactions").insert({
          user_id: user.id,
          account_id: fromAccountId,
          category_id: null,
          amount: -parsedAmount,
          detail: "Pago a " + account.name,
          transaction_date: new Date().toISOString().split("T")[0],
          type: "expense",
          is_recurring: false,
        });
        if (autoPayment) {
          await addDebtAutoPayment(account.id, fromAccountId, parsedAmount, autoDay);
        }
        toast.success("Pago registrado");
      } else {
        await supabase.from("accounts").update({ balance: newDebtBalance }).eq("id", account.id);
        await supabase.from("accounts").update({ balance: newFromBalance }).eq("id", fromAccountId);
        await supabase.from("transactions").insert({
          user_id: user.id,
          account_id: fromAccountId,
          category_id: null,
          amount: parsedAmount,
          detail: "Nueva deuda: " + account.name,
          transaction_date: new Date().toISOString().split("T")[0],
          type: "income",
          is_recurring: false,
        });
        toast.success("Deuda agregada");
      }

      await fetchAll();
      onClose();
    } catch (err) {
      console.error(err);
      toast.error("Error al procesar");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4" onClick={onClose}>
      <div className="bg-[#1a1f2e] rounded-2xl p-6 w-full max-w-md border border-white/10 max-h-[90vh] overflow-y-auto" onClick={(e) => e.stopPropagation()}>

        <div className="flex justify-between items-start mb-5">
          <div>
            <h2 className="text-lg font-bold text-white">Gestionar deuda</h2>
            <p className="text-xs text-gray-400">{account.name}</p>
          </div>
          <button onClick={onClose} className="text-gray-400 hover:text-white text-xl">x</button>
        </div>

        <div className="bg-red-500/10 border border-red-500/20 rounded-xl px-4 py-3 flex justify-between items-center mb-5">
          <p className="text-sm text-gray-400">Balance actual</p>
          <p className="text-lg font-bold text-red-400">{formatCurrency(account.balance)}</p>
        </div>

        <div className="flex gap-2 mb-5">
          <button onClick={() => { setMode("pay"); setAutoPayment(false); }}
            className={"flex-1 py-2.5 rounded-xl text-sm font-semibold transition border " + (mode === "pay" ? "border-emerald-500 bg-emerald-500/10 text-emerald-400" : "border-white/10 text-gray-400")}>
            Pagar deuda
          </button>
          <button onClick={() => { setMode("add"); setAutoPayment(false); }}
            className={"flex-1 py-2.5 rounded-xl text-sm font-semibold transition border " + (mode === "add" ? "border-red-500 bg-red-500/10 text-red-400" : "border-white/10 text-gray-400")}>
            Nueva deuda
          </button>
        </div>

        <div className="mb-4">
          <label className="text-xs text-gray-400 font-semibold mb-1 block">Monto</label>
          <input value={amount} onChange={(e) => setAmount(e.target.value)}
            type="number" placeholder="0.00"
            className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white text-lg font-bold outline-none focus:border-emerald-500 transition" />
        </div>

        <div className="mb-4">
          <label className="text-xs text-gray-400 font-semibold mb-1 block">
            {mode === "pay" ? "Pagar desde cuenta" : "Acreditar a cuenta"}
          </label>
          <div className="relative">
            <button type="button" onClick={() => setShowAccounts(!showAccounts)}
              className="w-full flex justify-between items-center px-4 py-3 rounded-xl text-sm border border-white/10 bg-white/5 hover:border-white/20 transition">
              <span className={selectedAccount ? "text-white" : "text-gray-400"}>
                {selectedAccount ? selectedAccount.name : "Selecciona cuenta"}
              </span>
              <span className="text-gray-400 text-xs">{showAccounts ? "▲" : "▼"}</span>
            </button>
            {showAccounts && (
              <div className="absolute left-0 right-0 mt-1 border border-white/10 rounded-xl overflow-hidden bg-[#0f1420] z-50 shadow-2xl">
                {liquidAccounts.map((a) => (
                  <button key={a.id} type="button"
                    onClick={() => { setFromAccountId(a.id); setShowAccounts(false); }}
                    className={"w-full flex justify-between items-center px-4 py-3 text-sm transition hover:bg-white/5 border-b border-white/5 last:border-0 " + (fromAccountId === a.id ? "text-emerald-400 bg-emerald-500/10" : "text-white")}>
                    <span>{a.name}</span>
                    <span className="text-gray-400 text-xs">{formatCurrency(a.balance)}</span>
                  </button>
                ))}
              </div>
            )}
          </div>
        </div>

        {fromAccountId && parsedAmount > 0 && (
          <div className="bg-white/5 rounded-xl px-4 py-3 mb-4 space-y-2">
            <div className="flex justify-between text-sm">
              <span className="text-gray-400 truncate mr-2">{account.name}</span>
              <span className={"font-semibold " + (mode === "pay" ? "text-emerald-400" : "text-red-400")}>
                {formatCurrency(newDebtBalance)}
              </span>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-gray-400 truncate mr-2">{fromAccount?.name}</span>
              <span className={"font-semibold " + ((newFromBalance ?? 0) >= 0 ? "text-white" : "text-red-400")}>
                {formatCurrency(newFromBalance ?? 0)}
              </span>
            </div>
          </div>
        )}

        {mode === "pay" && (
          <div className={"border rounded-xl p-4 mb-5 transition " + (autoPayment ? "border-emerald-500/40 bg-emerald-500/5" : "border-white/10")}>
            <div className="flex justify-between items-center">
              <div>
                <p className="text-sm font-semibold text-white">Pago automatico mensual</p>
                <p className="text-xs text-gray-400">Se debita cada mes automaticamente</p>
              </div>
              <div onClick={() => setAutoPayment(!autoPayment)}
                className={"w-11 h-6 rounded-full cursor-pointer transition relative " + (autoPayment ? "bg-emerald-500" : "bg-white/10")}>
                <div className={"absolute top-1 w-4 h-4 bg-white rounded-full transition-all " + (autoPayment ? "left-6" : "left-1")} />
              </div>
            </div>
            {autoPayment && (
              <div className="mt-4 flex items-center gap-3">
                <label className="text-sm text-gray-400">Dia del mes:</label>
                <input value={autoDay}
                  onChange={(e) => setAutoDay(Math.min(31, Math.max(1, parseInt(e.target.value) || 1)))}
                  type="number" min={1} max={31}
                  className="w-20 bg-white/5 border border-white/10 rounded-lg px-3 py-2 text-white text-sm outline-none focus:border-emerald-500" />
                <span className="text-xs text-gray-500">Max. 28 en febrero</span>
              </div>
            )}
          </div>
        )}

        <div className="flex gap-3">
          <button onClick={onClose} className="flex-1 bg-white/5 hover:bg-white/10 text-white py-3 rounded-xl text-sm font-semibold transition">
            Cancelar
          </button>
          <button onClick={submit} disabled={loading}
            className={"flex-1 py-3 rounded-xl text-sm font-semibold transition text-white disabled:opacity-50 " + (mode === "pay" ? "bg-emerald-500 hover:bg-emerald-600" : "bg-red-500 hover:bg-red-600")}>
            {loading ? "Procesando..." : mode === "pay" ? "Pagar" : "Agregar deuda"}
          </button>
        </div>
      </div>
    </div>
  );
}