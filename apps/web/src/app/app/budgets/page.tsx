"use client";
import { useState } from "react";
import { useFinanceStore } from "@/store/useFinanceStore";
import { PageHeader, EmptyState, ProgressBar, Modal } from "@/components/ui";
import { formatCurrency } from "@/lib/finance";
import { calcBudgetProgress, filterByPeriod } from "@/lib/finance";
import { Plus, PieChart } from "lucide-react";
import toast from "react-hot-toast";

export default function BudgetsPage() {
  const [showModal, setShowModal] = useState(false);
  const [form, setForm] = useState({ category_id: "", amount: "", alert_at_percent: "80" });
  const [loading, setLoading] = useState(false);
  const set = (k: string, v: string) => setForm((f) => ({ ...f, [k]: v }));

  const {
    budgets, categories, transactions,
    selectedYear, selectedMonth, addBudget
  } = useFinanceStore();

  const expenseCategories = categories.filter((c) => c.movement_type === 2);

  // Compute spent per category for the period
  const periodTx = filterByPeriod(transactions, selectedYear, selectedMonth);
  const spentMap = new Map<string, number>();
  periodTx.filter(t => t.type === "expense").forEach(t => {
    spentMap.set(t.category_id, (spentMap.get(t.category_id) ?? 0) + t.amount);
  });

  const budgetsWithProgress = budgets.map((b) => {
    const spent = spentMap.get(b.category_id) ?? 0;
    const { remaining, percent, status } = calcBudgetProgress(b.amount, spent);
    return { ...b, spent, remaining, percent_used: percent, status };
  });

  const handleAdd = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.category_id) { toast.error("Selecciona una categoría"); return; }
    setLoading(true);
    try {
      await addBudget({
        category_id: form.category_id,
        amount: parseFloat(form.amount),
        period: "monthly",
        alert_at_percent: parseInt(form.alert_at_percent),
      });
      toast.success("Presupuesto creado");
      setShowModal(false);
      setForm({ category_id: "", amount: "", alert_at_percent: "80" });
    } catch { toast.error("Error al crear presupuesto"); }
    finally { setLoading(false); }
  };

  const totalBudgeted = budgetsWithProgress.reduce((s, b) => s + b.amount, 0);
  const totalSpent    = budgetsWithProgress.reduce((s, b) => s + (b.spent ?? 0), 0);

  return (
    <>
      <PageHeader
        title="Presupuesto mensual"
        subtitle="Controla tus límites de gasto por categoría"
        action={
          <button onClick={() => setShowModal(true)} className="btn-primary flex items-center gap-2">
            <Plus size={15} /> Nuevo presupuesto
          </button>
        }
      />

      {/* Overview */}
      <div className="grid grid-cols-3 gap-4 mb-7">
        {[
          { label: "Total presupuestado", val: totalBudgeted,           color: "#3b82f6" },
          { label: "Total gastado",       val: totalSpent,              color: "#ef4444" },
          { label: "Disponible restante", val: totalBudgeted - totalSpent, color: totalBudgeted >= totalSpent ? "#10b981" : "#ef4444" },
        ].map((s) => (
          <div key={s.label} className="stat-card" style={{ borderTop: `3px solid ${s.color}` }}>
            <p className="label-base">{s.label}</p>
            <p className="text-xl font-bold" style={{ color: s.color }}>
              {formatCurrency(s.val, "DOP", true)}
            </p>
          </div>
        ))}
      </div>

      {budgetsWithProgress.length === 0 ? (
        <EmptyState
          icon={<PieChart size={24} />}
          title="Sin presupuestos configurados"
          description="Define límites de gasto por categoría y recibe alertas cuando te estés excediendo."
          action={
            <button onClick={() => setShowModal(true)} className="btn-primary">
              Crear primer presupuesto
            </button>
          }
        />
      ) : (
        <div className="grid grid-cols-2 gap-4">
          {budgetsWithProgress.map((b) => {
            const statusColor = b.status === "over" ? "#ef4444" : b.status === "warning" ? "#f59e0b" : "#10b981";
            const progressColor = b.status === "over" ? "#ef4444" : b.status === "warning" ? "#f59e0b" : "#10b981";
            return (
              <div key={b.id} className="card">
                <div className="flex items-start justify-between mb-3">
                  <div>
                    <p className="text-sm font-semibold text-slate-200">
                      {b.category?.icon} {b.category?.name ?? "Sin nombre"}
                    </p>
                    <p className="text-xs text-muted mt-0.5">Presupuesto mensual</p>
                  </div>
                  <span
                    className="text-xs font-semibold px-2.5 py-1 rounded-full"
                    style={{ background: `${statusColor}15`, color: statusColor }}
                  >
                    {b.status === "over" ? "Excedido" : b.status === "warning" ? "Atención" : "Normal"}
                  </span>
                </div>

                <div className="flex justify-between text-xs text-muted mb-2">
                  <span>Gastado: <span className="font-semibold text-slate-300">{formatCurrency(b.spent ?? 0)}</span></span>
                  <span>Límite: <span className="font-semibold text-slate-300">{formatCurrency(b.amount)}</span></span>
                </div>

                <ProgressBar percent={b.percent_used ?? 0} color={progressColor} />

                <div className="flex justify-between mt-2">
                  <span className="text-xs text-muted">{(b.percent_used ?? 0).toFixed(0)}% utilizado</span>
                  <span
                    className="text-xs font-semibold"
                    style={{ color: statusColor }}
                  >
                    {(b.remaining ?? 0) >= 0
                      ? `RD$${formatCurrency(b.remaining ?? 0)} restante`
                      : `RD$${formatCurrency(Math.abs(b.remaining ?? 0))} excedido`}
                  </span>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Add Budget Modal */}
      <Modal open={showModal} onClose={() => setShowModal(false)} title="Nuevo presupuesto">
        <form onSubmit={handleAdd} className="space-y-4">
          <div>
            <label className="label-base">Categoría</label>
            <select value={form.category_id} onChange={(e) => set("category_id", e.target.value)} className="input-base" required>
              <option value="">Seleccionar categoría...</option>
              {expenseCategories.map((c) => (
                <option key={c.id} value={c.id}>{c.icon} {c.name}</option>
              ))}
            </select>
          </div>
          <div>
            <label className="label-base">Límite mensual (RD$)</label>
            <input type="number" min="1" step="1" value={form.amount} onChange={(e) => set("amount", e.target.value)} placeholder="0" className="input-base" required />
          </div>
          <div>
            <label className="label-base">Alertar al (%)</label>
            <input type="number" min="50" max="100" value={form.alert_at_percent} onChange={(e) => set("alert_at_percent", e.target.value)} className="input-base" />
            <p className="text-xs text-muted mt-1">Recibirás una alerta cuando alcances este porcentaje del límite</p>
          </div>
          <div className="flex gap-3 pt-2">
            <button type="button" onClick={() => setShowModal(false)} className="flex-1 btn-ghost border border-surface-500">Cancelar</button>
            <button type="submit" disabled={loading} className="flex-1 btn-primary">{loading ? "Guardando..." : "Crear presupuesto"}</button>
          </div>
        </form>
      </Modal>
    </>
  );
}
