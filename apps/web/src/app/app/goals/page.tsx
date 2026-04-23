"use client";
import { useState } from "react";
import { useFinanceStore } from "@/store/useFinanceStore";
import { PageHeader, EmptyState, ProgressBar, Modal } from "@/components/ui";
import { formatCurrency } from "@/lib/finance";
import { calcGoalProgress } from "@/lib/finance";
import { Plus, Target, CheckCircle2 } from "lucide-react";
import toast from "react-hot-toast";

const GOAL_COLORS = ["#10b981", "#3b82f6", "#8b5cf6", "#f59e0b", "#ef4444", "#06b6d4"];

export default function GoalsPage() {
  const [showModal, setShowModal] = useState(false);
  const [form, setForm] = useState({
    name: "", target_amount: "", current_amount: "0",
    target_date: "", color: "#10b981", description: "",
  });
  const [loading, setLoading] = useState(false);
  const set = (k: string, v: string) => setForm((f) => ({ ...f, [k]: v }));

  const { goals, addGoal, updateGoal, summary } = useFinanceStore();

  const goalsWithProgress = goals.map((g) => {
    const { progress_percent, monthly_needed, eta_months } = calcGoalProgress(
      g.target_amount,
      g.current_amount,
      g.target_date,
      summary?.ahorrado
    );
    return { ...g, progress_percent, monthly_needed, eta_months };
  });

  const completed = goalsWithProgress.filter(g => g.progress_percent >= 100);
  const active    = goalsWithProgress.filter(g => g.progress_percent < 100);

  const handleAdd = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      await addGoal({
        name: form.name,
        target_amount: parseFloat(form.target_amount),
        current_amount: parseFloat(form.current_amount || "0"),
        target_date: form.target_date || undefined,
        color: form.color,
        description: form.description,
      });
      toast.success("¡Meta creada!");
      setShowModal(false);
      setForm({ name: "", target_amount: "", current_amount: "0", target_date: "", color: "#10b981", description: "" });
    } catch { toast.error("Error al crear la meta"); }
    finally { setLoading(false); }
  };

  const handleDeposit = async (goal: (typeof goalsWithProgress)[0]) => {
    const amount = prompt(`¿Cuánto quieres ahorrar para "${goal.name}"? (RD$)`);
    if (!amount || isNaN(parseFloat(amount))) return;
    const newAmount = goal.current_amount + parseFloat(amount);
    await updateGoal(goal.id, { current_amount: newAmount });
    toast.success(`+${formatCurrency(parseFloat(amount))} agregado a "${goal.name}"`);
  };

  return (
    <>
      <PageHeader
        title="Metas de ahorro"
        subtitle="Define objetivos financieros y rastrea tu progreso"
        action={
          <button onClick={() => setShowModal(true)} className="btn-primary flex items-center gap-2">
            <Plus size={15} /> Nueva meta
          </button>
        }
      />

      {goalsWithProgress.length === 0 ? (
        <EmptyState
          icon={<Target size={24} />}
          title="Sin metas configuradas"
          description="Establece objetivos de ahorro como un fondo de emergencia, vacaciones o un bien. FLUJO te ayudará a llegar."
          action={
            <button onClick={() => setShowModal(true)} className="btn-primary">
              Crear primera meta
            </button>
          }
        />
      ) : (
        <>
          {/* Active Goals */}
          {active.length > 0 && (
            <>
              <h2 className="text-xs font-semibold text-muted uppercase tracking-wider mb-3">
                En progreso ({active.length})
              </h2>
              <div className="grid grid-cols-2 gap-4 mb-8">
                {active.map((g) => (
                  <div key={g.id} className="card" style={{ borderTop: `3px solid ${g.color}` }}>
                    <div className="flex items-start justify-between mb-3">
                      <div>
                        <div className="w-8 h-8 rounded-xl mb-2 flex items-center justify-center text-lg"
                          style={{ background: `${g.color}20` }}>
                          🎯
                        </div>
                        <p className="text-sm font-semibold text-slate-200">{g.name}</p>
                        {g.description && <p className="text-xs text-muted mt-0.5">{g.description}</p>}
                      </div>
                      <span
                        className="text-xs font-bold"
                        style={{ color: g.color }}
                      >
                        {g.progress_percent.toFixed(0)}%
                      </span>
                    </div>

                    <div className="flex justify-between text-xs text-muted mb-2">
                      <span>
                        Ahorrado:{" "}
                        <span className="font-semibold text-slate-300">
                          {formatCurrency(g.current_amount, "DOP", true)}
                        </span>
                      </span>
                      <span>
                        Meta:{" "}
                        <span className="font-semibold text-slate-300">
                          {formatCurrency(g.target_amount, "DOP", true)}
                        </span>
                      </span>
                    </div>

                    <ProgressBar percent={g.progress_percent} color={g.color} />

                    <div className="mt-3 space-y-1">
                      {g.target_date && (
                        <p className="text-xs text-muted">
                          📅 Fecha límite: <span className="text-slate-300">{g.target_date}</span>
                        </p>
                      )}
                      {g.monthly_needed > 0 && (
                        <p className="text-xs text-muted">
                          💰 Ahorro mensual necesario:{" "}
                          <span className="text-slate-300 font-semibold">
                            {formatCurrency(g.monthly_needed, "DOP", true)}
                          </span>
                        </p>
                      )}
                      {g.eta_months && (
                        <p className="text-xs text-muted">
                          ⏱ ETA: <span className="text-slate-300 font-semibold">{g.eta_months} meses</span>
                        </p>
                      )}
                    </div>

                    <button
                      onClick={() => handleDeposit(g)}
                      className="mt-4 w-full py-2 rounded-xl text-xs font-semibold transition-all duration-150
                                 border hover:opacity-90"
                      style={{
                        borderColor: g.color,
                        color: g.color,
                        background: `${g.color}10`,
                      }}
                    >
                      + Agregar ahorro
                    </button>
                  </div>
                ))}
              </div>
            </>
          )}

          {/* Completed Goals */}
          {completed.length > 0 && (
            <>
              <h2 className="text-xs font-semibold text-muted uppercase tracking-wider mb-3">
                Completadas ✓ ({completed.length})
              </h2>
              <div className="grid grid-cols-3 gap-4">
                {completed.map((g) => (
                  <div key={g.id} className="card border-brand-500/30 bg-brand-500/5">
                    <CheckCircle2 size={20} className="text-brand-400 mb-2" />
                    <p className="text-sm font-semibold text-slate-200">{g.name}</p>
                    <p className="text-xs text-muted mt-1">
                      {formatCurrency(g.target_amount)} — Meta cumplida
                    </p>
                  </div>
                ))}
              </div>
            </>
          )}
        </>
      )}

      {/* Add Goal Modal */}
      <Modal open={showModal} onClose={() => setShowModal(false)} title="Nueva meta de ahorro">
        <form onSubmit={handleAdd} className="space-y-4">
          <div>
            <label className="label-base">Nombre de la meta</label>
            <input type="text" value={form.name} onChange={(e) => set("name", e.target.value)}
              placeholder="Ej: Fondo de emergencia, Vacaciones..." className="input-base" required />
          </div>
          <div>
            <label className="label-base">Descripción (opcional)</label>
            <input type="text" value={form.description} onChange={(e) => set("description", e.target.value)}
              placeholder="Detalle de la meta..." className="input-base" />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="label-base">Monto objetivo (RD$)</label>
              <input type="number" min="1" value={form.target_amount} onChange={(e) => set("target_amount", e.target.value)}
                placeholder="50000" className="input-base" required />
            </div>
            <div>
              <label className="label-base">Ya tengo (RD$)</label>
              <input type="number" min="0" value={form.current_amount} onChange={(e) => set("current_amount", e.target.value)}
                placeholder="0" className="input-base" />
            </div>
          </div>
          <div>
            <label className="label-base">Fecha límite (opcional)</label>
            <input type="date" value={form.target_date} onChange={(e) => set("target_date", e.target.value)} className="input-base" />
          </div>
          <div>
            <label className="label-base">Color</label>
            <div className="flex gap-2 mt-1">
              {GOAL_COLORS.map((c) => (
                <button key={c} type="button" onClick={() => set("color", c)}
                  className="w-7 h-7 rounded-full transition-all"
                  style={{
                    background: c,
                    outline: form.color === c ? `2px solid ${c}` : "none",
                    outlineOffset: "2px",
                  }}
                />
              ))}
            </div>
          </div>
          <div className="flex gap-3 pt-2">
            <button type="button" onClick={() => setShowModal(false)} className="flex-1 btn-ghost border border-surface-500">Cancelar</button>
            <button type="submit" disabled={loading} className="flex-1 btn-primary">{loading ? "Guardando..." : "Crear meta"}</button>
          </div>
        </form>
      </Modal>
    </>
  );
}
