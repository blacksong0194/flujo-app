"use client";
import { useEffect, useState } from "react";
import { useRecurringStore } from "@/store/useRecurringStore";
import { useFinanceStore } from "@/store/useFinanceStore";
import type { RecurringPayment } from "@/types";

function fmtAmount(n: number) {
  return new Intl.NumberFormat("es-DO", { style: "currency", currency: "DOP" }).format(n);
}

function getDaysLeft(autoDebitAt: string) {
  const diff = new Date(autoDebitAt).getTime() - Date.now();
  const h = Math.floor(diff / 3600000);
  const m = Math.floor((diff % 3600000) / 60000);
  return h + "h " + m + "m";
}

export default function RecurringPage() {
  const { recurringPayments, isLoading, fetchRecurring, deleteRecurring, executeRecurring, scheduleAutoDebit } = useRecurringStore();
  const { accounts, categories } = useFinanceStore();
  const [showModal, setShowModal] = useState(false);
  const [editing, setEditing] = useState<RecurringPayment | null>(null);

  useEffect(() => { fetchRecurring(); }, []);

  const isPending = (rp: RecurringPayment) => {
    const due = new Date(rp.next_payment_date);
    const today = new Date(); today.setHours(0, 0, 0, 0);
    return rp.status === "active" && due <= today;
  };

  const inWindow = (rp: RecurringPayment) =>
    !!rp.auto_debit_at && new Date(rp.auto_debit_at) > new Date();

  return (
    <div className="p-6 max-w-3xl mx-auto">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-white">Pagos Recurrentes</h1>
          <p className="text-sm text-gray-400">Gestiona tus pagos fijos mensuales</p>
        </div>
        <button
          onClick={() => { setEditing(null); setShowModal(true); }}
          className="bg-emerald-500 hover:bg-emerald-600 text-white px-4 py-2 rounded-lg text-sm font-semibold transition"
        >
          + Agregar
        </button>
      </div>

      {isLoading ? (
        <div className="flex justify-center py-20">
          <div className="w-8 h-8 border-2 border-emerald-500 border-t-transparent rounded-full animate-spin" />
        </div>
      ) : recurringPayments.length === 0 ? (
        <div className="text-center py-20 text-gray-500">
          <p className="text-4xl mb-4">🔄</p>
          <p className="font-semibold text-white">Sin pagos recurrentes</p>
          <p className="text-sm mt-1">Agrega pagos fijos mensuales para gestionarlos automaticamente</p>
        </div>
      ) : (
        <div className="space-y-3">
          {recurringPayments.map(rp => (
            <div key={rp.id} className={"bg-[#1a1f2e] rounded-xl p-4 border " + (isPending(rp) ? "border-red-500/40" : "border-white/10")}>
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-emerald-500/10 flex items-center justify-center text-emerald-400 text-lg">🔄</div>
                  <div>
                    <p className="font-semibold text-white">{rp.name}</p>
                    <p className="text-xs text-gray-400">Dia {rp.day_of_month} de cada mes · {rp.account?.name}</p>
                  </div>
                </div>
                <p className="text-red-400 font-bold text-lg">{fmtAmount(rp.amount)}</p>
              </div>

              {isPending(rp) && (
                <div className={"mt-3 px-3 py-2 rounded-lg text-xs flex items-center gap-2 " + (inWindow(rp) ? "bg-amber-500/10 text-amber-400 border border-amber-500/20" : "bg-red-500/10 text-red-400 border border-red-500/20")}>
                  {inWindow(rp) ? "Debito automatico en " + getDaysLeft(rp.auto_debit_at!) + " — puedes editar antes" : "Pago pendiente para hoy"}
                </div>
              )}

              <div className="flex gap-2 mt-3">
                {isPending(rp) && rp.is_auto && !rp.auto_debit_at && (
                  <button onClick={() => scheduleAutoDebit(rp.id)}
                    className="flex-1 bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 text-xs font-semibold py-2 rounded-lg transition">
                    Activar debito (5h)
                  </button>
                )}
                {isPending(rp) && (!rp.is_auto || (rp.auto_debit_at && !inWindow(rp))) && (
                  <button onClick={() => executeRecurring(rp)}
                    className="flex-1 bg-emerald-500 hover:bg-emerald-600 text-white text-xs font-semibold py-2 rounded-lg transition">
                    Ejecutar ahora
                  </button>
                )}
                <button onClick={() => { setEditing(rp); setShowModal(true); }}
                  className="flex-1 bg-white/5 hover:bg-white/10 text-white text-xs font-semibold py-2 rounded-lg transition">
                  Editar
                </button>
                <button onClick={() => { if (confirm("Eliminar " + rp.name + "?")) deleteRecurring(rp.id); }}
                  className="bg-red-500/10 hover:bg-red-500/20 text-red-400 text-xs font-semibold px-3 py-2 rounded-lg transition">
                  🗑
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {showModal && (
        <RecurringModal
          existing={editing}
          accounts={accounts.filter(a => a.type !== "deuda" && a.type !== "prestamo")}
          categories={categories.filter(c => c.movement_type === 2)}
          onClose={() => setShowModal(false)}
        />
      )}
    </div>
  );
}

function RecurringModal({ existing, accounts, categories, onClose }: {
  existing: RecurringPayment | null;
  accounts: any[];
  categories: any[];
  onClose: () => void;
}) {
  const { addRecurring, updateRecurring } = useRecurringStore();
  const [name, setName] = useState(existing?.name ?? "");
  const [amount, setAmount] = useState(existing?.amount?.toString() ?? "");
  const [accountId, setAccountId] = useState(existing?.account_id ?? "");
  const [showAccounts, setShowAccounts] = useState(false);
  const [categoryId, setCategoryId] = useState(existing?.category_id ?? "");
  const [day, setDay] = useState(existing?.day_of_month ?? 1);
  const [isAuto, setIsAuto] = useState(existing?.is_auto ?? false);
  const [loading, setLoading] = useState(false);

  async function submit() {
    if (!name || !amount || !accountId) return;
    setLoading(true);
    const now = new Date();
    const nextDate = new Date(now.getFullYear(), now.getMonth(), day).toISOString().split("T")[0];
    const data = {
      name, amount: parseFloat(amount), account_id: accountId,
      category_id: categoryId || undefined, day_of_month: day,
      next_payment_date: nextDate, is_auto: isAuto, status: "active" as const,
    };
    if (existing) await updateRecurring(existing.id, data);
    else await addRecurring(data);
    setLoading(false);
    onClose();
  }

  return (
    <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4" onClick={onClose}>
      <div className="bg-[#1a1f2e] rounded-2xl p-6 w-full max-w-md border border-white/10" onClick={e => e.stopPropagation()}>
        <div className="flex justify-between items-center mb-5">
          <h2 className="text-lg font-bold text-white">{existing ? "Editar pago" : "Nuevo pago recurrente"}</h2>
          <button onClick={onClose} className="text-gray-400 hover:text-white">x</button>
        </div>

        <div className="space-y-4">
          <input value={name} onChange={e => setName(e.target.value)} placeholder="Nombre del pago"
            className="w-full bg-white/5 border border-white/10 rounded-lg px-4 py-2 text-white text-sm outline-none focus:border-emerald-500" />

          <input value={amount} onChange={e => setAmount(e.target.value)} placeholder="Monto" type="number"
            className="w-full bg-white/5 border border-white/10 rounded-lg px-4 py-2 text-white text-sm outline-none focus:border-emerald-500" />

          <div className="relative">
            <button type="button" onClick={() => setShowAccounts(!showAccounts)}
              className="w-full flex justify-between items-center px-4 py-2 rounded-lg text-sm border border-white/10 bg-white/5 hover:border-white/20 transition">
              <span className={accountId ? "text-white" : "text-gray-400"}>
                {accountId ? (accounts.find(a => a.id === accountId)?.name ?? "Selecciona cuenta") : "Selecciona cuenta"}
              </span>
              <span className="text-gray-400 text-xs">{showAccounts ? "▲" : "▼"}</span>
            </button>
            {showAccounts && (
              <div className="absolute left-0 right-0 mt-1 border border-white/10 rounded-xl overflow-hidden bg-[#0f1420] z-50 shadow-2xl">
                {accounts.map((a) => (
                  <button key={a.id} type="button"
                    onClick={() => { setAccountId(a.id); setShowAccounts(false); }}
                    className={"w-full flex justify-between items-center px-4 py-3 text-sm transition hover:bg-white/5 border-b border-white/5 last:border-0 " + (accountId === a.id ? "text-emerald-400 bg-emerald-500/10" : "text-white")}>
                    <span>{a.name}</span>
                  </button>
                ))}
              </div>
            )}
          </div>

          <select value={categoryId} onChange={e => setCategoryId(e.target.value)}
            className="w-full bg-white/5 border border-white/10 rounded-lg px-4 py-2 text-white text-sm outline-none focus:border-emerald-500">
            <option value="">Sin categoria</option>
            {categories.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
          </select>

          <div className="flex items-center gap-3">
            <label className="text-sm text-gray-400">Dia del mes:</label>
            <input value={day} onChange={e => setDay(Math.min(31, Math.max(1, parseInt(e.target.value) || 1)))}
              type="number" min={1} max={31}
              className="w-20 bg-white/5 border border-white/10 rounded-lg px-3 py-2 text-white text-sm outline-none focus:border-emerald-500" />
          </div>

          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-semibold text-white">Debito automatico</p>
              <p className="text-xs text-gray-400">Se ejecuta con 5h para editar</p>
            </div>
            <div onClick={() => setIsAuto(!isAuto)}
              className={"w-11 h-6 rounded-full cursor-pointer transition relative " + (isAuto ? "bg-emerald-500" : "bg-white/10")}>
              <div className={"absolute top-1 w-4 h-4 bg-white rounded-full transition-all " + (isAuto ? "left-6" : "left-1")} />
            </div>
          </div>
        </div>

        <div className="flex gap-3 mt-6">
          <button onClick={onClose} className="flex-1 bg-white/5 hover:bg-white/10 text-white py-2 rounded-lg text-sm font-semibold transition">
            Cancelar
          </button>
          <button onClick={submit} disabled={loading}
            className="flex-1 bg-emerald-500 hover:bg-emerald-600 text-white py-2 rounded-lg text-sm font-semibold transition disabled:opacity-50">
            {loading ? "Guardando..." : existing ? "Actualizar" : "Guardar"}
          </button>
        </div>
      </div>
    </div>
  );
}