"use client";
import { useState, useEffect } from "react";
import { PageHeader } from "@/components/ui";
import { createClient } from "@/lib/supabase/client";
import { DEFAULT_INCOME_CATEGORIES, DEFAULT_EXPENSE_CATEGORIES, CATEGORY_COLORS } from "@/lib/utils";
import { useFinanceStore } from "@/store/useFinanceStore";
import { ExportModal } from "@/components/modals/ExportModal";
import type { Category } from "@/types";
import toast from "react-hot-toast";

const CATEGORY_ICONS = ["💰","💼","🎯","🏠","📈","⚖️","💡","🍽️","🛍️","🛡️","❤️","🏛️","🔖","🔧","🎉","📚","🚗","🛒","👕","💊","🎓","✈️","🏋️","🎮","📱","🏦","💎","🌱","🎨","🐾"];

// ─── Modal: Nueva Categoría ───────────────────────────────────────────────────
function NewCategoryModal({ onClose, onSaved }: { onClose: () => void; onSaved: () => void }) {
  const supabase = createClient();
  const [form, setForm] = useState({ name: "", icon: "💰", color: CATEGORY_COLORS[0], movement_type: 1 });
  const [saving, setSaving] = useState(false);

  const handleSave = async () => {
    if (!form.name.trim()) { toast.error("El nombre es requerido"); return; }
    setSaving(true);
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) { setSaving(false); return; }
    const { error } = await supabase.from("categories").insert({
      user_id: user.id,
      name: form.name.trim(),
      icon: form.icon,
      color: form.color,
      movement_type: form.movement_type,
    });
    setSaving(false);
    if (error) { toast.error(error.message); return; }
    toast.success("Categoría creada");
    onSaved();
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
      <div className="bg-surface-700 border border-surface-500 rounded-2xl w-full max-w-md p-6 space-y-5">
        <div className="flex items-center justify-between">
          <h3 className="text-base font-semibold text-slate-200">Nueva categoría</h3>
          <button onClick={onClose} className="text-muted hover:text-slate-300 text-xl leading-none">×</button>
        </div>

        {/* Tipo */}
        <div>
          <label className="label-base">Tipo</label>
          <div className="flex gap-2">
            {[{ label: "Ingreso", value: 1, color: "#10b981" }, { label: "Egreso", value: 2, color: "#ef4444" }].map((t) => (
              <button
                key={t.value}
                onClick={() => setForm((f) => ({ ...f, movement_type: t.value }))}
                className="flex-1 py-2 rounded-lg text-sm font-semibold border transition-all"
                style={{
                  borderColor: form.movement_type === t.value ? t.color : "#1e2a3a",
                  background: form.movement_type === t.value ? `${t.color}20` : "transparent",
                  color: form.movement_type === t.value ? t.color : "#4a6b8a",
                }}
              >
                {t.label}
              </button>
            ))}
          </div>
        </div>

        {/* Nombre */}
        <div>
          <label className="label-base">Nombre</label>
          <input
            className="input-base"
            placeholder="Ej: Freelance, Gimnasio..."
            value={form.name}
            onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))}
            maxLength={40}
          />
        </div>

        {/* Ícono */}
        <div>
          <label className="label-base">Ícono</label>
          <div className="grid grid-cols-10 gap-1.5 bg-surface-800 rounded-xl p-3">
            {CATEGORY_ICONS.map((icon) => (
              <button
                key={icon}
                onClick={() => setForm((f) => ({ ...f, icon }))}
                className="text-lg p-1 rounded-lg transition-all hover:bg-surface-600"
                style={{ background: form.icon === icon ? "#10b98130" : undefined, outline: form.icon === icon ? "2px solid #10b981" : undefined }}
              >
                {icon}
              </button>
            ))}
          </div>
        </div>

        {/* Color */}
        <div>
          <label className="label-base">Color</label>
          <div className="flex gap-2 flex-wrap">
            {CATEGORY_COLORS.map((color) => (
              <button
                key={color}
                onClick={() => setForm((f) => ({ ...f, color }))}
                className="w-7 h-7 rounded-full border-2 transition-all"
                style={{ background: color, borderColor: form.color === color ? "#fff" : "transparent" }}
              />
            ))}
          </div>
        </div>

        {/* Preview */}
        <div className="flex items-center gap-3 bg-surface-800 rounded-xl px-4 py-3">
          <span className="text-xl">{form.icon}</span>
          <span className="text-sm font-medium" style={{ color: form.color }}>{form.name || "Vista previa"}</span>
          <span className="ml-auto text-xs px-2 py-0.5 rounded-full font-semibold" style={{ background: `${form.movement_type === 1 ? "#10b981" : "#ef4444"}20`, color: form.movement_type === 1 ? "#10b981" : "#ef4444" }}>
            {form.movement_type === 1 ? "Ingreso" : "Egreso"}
          </span>
        </div>

        <div className="flex gap-3 pt-1">
          <button onClick={onClose} className="btn-ghost flex-1">Cancelar</button>
          <button onClick={handleSave} disabled={saving} className="btn-primary flex-1">
            {saving ? "Guardando..." : "Crear categoría"}
          </button>
        </div>
      </div>
    </div>
  );
}

// ─── Modal: Confirmar acción destructiva ──────────────────────────────────────
function ConfirmModal({ title, message, confirmLabel, confirmColor, onConfirm, onClose }: {
  title: string; message: string; confirmLabel: string; confirmColor: string;
  onConfirm: () => Promise<void>; onClose: () => void;
}) {
  const [loading, setLoading] = useState(false);
  const handle = async () => { setLoading(true); await onConfirm(); setLoading(false); onClose(); };
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
      <div className="bg-surface-700 border border-surface-500 rounded-2xl w-full max-w-sm p-6 space-y-4">
        <h3 className="text-base font-semibold text-slate-200">{title}</h3>
        <p className="text-sm text-slate-400">{message}</p>
        <div className="flex gap-3 pt-1">
          <button onClick={onClose} className="btn-ghost flex-1">Cancelar</button>
          <button onClick={handle} disabled={loading}
            className="flex-1 py-2.5 rounded-xl text-sm font-semibold transition-all"
            style={{ background: `${confirmColor}20`, color: confirmColor, border: `1px solid ${confirmColor}50` }}>
            {loading ? "Procesando..." : confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );
}

// ─── Page principal ───────────────────────────────────────────────────────────
export default function SettingsPage() {
  const supabase = createClient();
  const { categories, fetchAll, transactions, accounts } = useFinanceStore();
  const [profile, setProfile] = useState({ full_name: "", email: "" });
  const [savingProfile, setSavingProfile] = useState(false);
  const [seedingCategories, setSeedingCategories] = useState(false);
  const [showNewCategory, setShowNewCategory] = useState(false);
  const [confirmModal, setConfirmModal] = useState<null | { title: string; message: string; confirmLabel: string; confirmColor: string; onConfirm: () => Promise<void>; }>(null);
  const [deletingCategoryId, setDeletingCategoryId] = useState<string | null>(null);
  const [showExportModal, setShowExportModal] = useState(false);

  useEffect(() => {
    supabase.auth.getUser().then(({ data: { user } }) => {
      if (user) setProfile({ full_name: user.user_metadata?.full_name ?? "", email: user.email ?? "" });
    });
  }, []);

  const handleProfileSave = async (e: React.FormEvent) => {
    e.preventDefault();
    setSavingProfile(true);
    const { error } = await supabase.auth.updateUser({ data: { full_name: profile.full_name } });
    setSavingProfile(false);
    if (error) toast.error(error.message);
    else toast.success("Perfil actualizado");
  };

  const seedCategories = async () => {
    setSeedingCategories(true);
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;
    const all = [
      ...DEFAULT_INCOME_CATEGORIES.map((c) => ({ ...c, user_id: user.id, movement_type: 1 })),
      ...DEFAULT_EXPENSE_CATEGORIES.map((c) => ({ ...c, user_id: user.id, movement_type: 2 })),
    ];
    const { error } = await supabase.from("categories").upsert(all, { onConflict: "user_id,name" });
    setSeedingCategories(false);
    if (error) toast.error(error.message);
    else { toast.success("Categorías predeterminadas cargadas"); fetchAll(); }
  };

  const deleteCategory = async (cat: Category) => {
    setDeletingCategoryId(cat.id);
    const { error } = await supabase.from("categories").delete().eq("id", cat.id);
    setDeletingCategoryId(null);
    if (error) toast.error("No se puede eliminar: tiene movimientos asociados");
    else { toast.success("Categoría eliminada"); fetchAll(); }
  };

  // ── Exportar — delega al ExportModal ────────────────────────────────────────
  const openExportModal = () => setShowExportModal(true);

  // ── Eliminar todos los movimientos ──────────────────────────────────────────
  const deleteAllTransactions = async () => {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;
    const { error } = await supabase.from("transactions").delete().eq("user_id", user.id);
    if (error) toast.error(error.message);
    else { toast.success("Todos los movimientos eliminados"); fetchAll(); }
  };

  // ── Eliminar cuenta ──────────────────────────────────────────────────────────
  const deleteAccount = async () => {
    const { error } = await supabase.auth.admin?.deleteUser ? toast("Contacta soporte para eliminar tu cuenta") as unknown as { error: null } : { error: null };
    // Sign out and let the user know
    await supabase.auth.signOut();
    toast.success("Sesión cerrada. Contacta soporte para completar la eliminación.");
    void error;
  };

  const incomeCategories = categories.filter((c) => c.movement_type === 1);
  const expenseCategories = categories.filter((c) => c.movement_type === 2);

  return (
    <>
      {showNewCategory && (
        <NewCategoryModal onClose={() => setShowNewCategory(false)} onSaved={fetchAll} />
      )}
      {confirmModal && (
        <ConfirmModal {...confirmModal} onClose={() => setConfirmModal(null)} />
      )}
      {showExportModal && (
        <ExportModal onClose={() => setShowExportModal(false)} />
      )}

      <PageHeader title="Ajustes" subtitle="Configura tu experiencia en FLUJO" />
      <div className="max-w-2xl space-y-5">

        {/* ── Perfil ── */}
        <div className="card">
          <h3 className="text-sm font-semibold text-slate-200 mb-4 pb-3 border-b border-surface-500">Perfil</h3>
          <form onSubmit={handleProfileSave} className="space-y-4">
            <div>
              <label className="label-base">Nombre completo</label>
              <input type="text" value={profile.full_name}
                onChange={(e) => setProfile((p) => ({ ...p, full_name: e.target.value }))}
                className="input-base" />
            </div>
            <div>
              <label className="label-base">Correo electrónico</label>
              <input type="email" value={profile.email} disabled className="input-base opacity-50 cursor-not-allowed" />
            </div>
            <button type="submit" disabled={savingProfile} className="btn-primary">
              {savingProfile ? "Guardando..." : "Guardar cambios"}
            </button>
          </form>
        </div>

        {/* ── Preferencias ── */}
        <div className="card">
          <h3 className="text-sm font-semibold text-slate-200 mb-4 pb-3 border-b border-surface-500">Preferencias</h3>
          <div className="space-y-4">
            {[
              { label: "Moneda principal", value: "Peso Dominicano (DOP)" },
              { label: "Zona horaria", value: "America/Santo_Domingo" },
              { label: "Inicio del período", value: "1 de cada mes" },
              { label: "Formato de fecha", value: "DD/MM/YYYY" },
            ].map((row) => (
              <div key={row.label} className="flex justify-between items-center py-3 border-b border-surface-500 last:border-0">
                <span className="text-sm text-slate-400">{row.label}</span>
                <span className="text-sm font-medium text-slate-200">{row.value}</span>
              </div>
            ))}
          </div>
        </div>

        {/* ── Categorías ── */}
        <div className="card">
          <h3 className="text-sm font-semibold text-slate-200 mb-4 pb-3 border-b border-surface-500">Categorías</h3>
          <div className="space-y-4">

            {/* Resumen + acciones */}
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-slate-300">{categories.length} categorías configuradas</p>
                <p className="text-xs text-muted mt-0.5">
                  {incomeCategories.length} ingresos · {expenseCategories.length} egresos
                </p>
              </div>
              <div className="flex gap-2">
                <button onClick={seedCategories} disabled={seedingCategories} className="btn-ghost text-xs">
                  {seedingCategories ? "Cargando..." : "Cargar predeterminadas"}
                </button>
                <button onClick={() => setShowNewCategory(true)} className="btn-primary text-xs px-3 py-2">
                  + Nueva
                </button>
              </div>
            </div>

            {/* Ingresos */}
            {incomeCategories.length > 0 && (
              <div>
                <p className="text-xs font-semibold text-brand-400 uppercase tracking-wider mb-2">Ingresos</p>
                <div className="space-y-1">
                  {incomeCategories.map((c) => (
                    <div key={c.id} className="flex items-center gap-2 bg-surface-800 rounded-lg px-3 py-2 group">
                      <span className="text-sm">{c.icon}</span>
                      <span className="text-sm text-slate-300 truncate flex-1">{c.name}</span>
                      <span className="w-2 h-2 rounded-full" style={{ background: c.color }} />
                      <button
                        onClick={() => setConfirmModal({
                          title: "Eliminar categoría",
                          message: `¿Eliminar "${c.name}"? Solo se puede eliminar si no tiene movimientos asociados.`,
                          confirmLabel: "Eliminar",
                          confirmColor: "#ef4444",
                          onConfirm: async () => { await deleteCategory(c); },
                        })}
                        disabled={deletingCategoryId === c.id}
                        className="opacity-0 group-hover:opacity-100 text-muted hover:text-red-400 text-xs transition-all ml-1"
                      >
                        ✕
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Egresos */}
            {expenseCategories.length > 0 && (
              <div>
                <p className="text-xs font-semibold text-red-400 uppercase tracking-wider mb-2">Egresos</p>
                <div className="space-y-1">
                  {expenseCategories.map((c) => (
                    <div key={c.id} className="flex items-center gap-2 bg-surface-800 rounded-lg px-3 py-2 group">
                      <span className="text-sm">{c.icon}</span>
                      <span className="text-sm text-slate-300 truncate flex-1">{c.name}</span>
                      <span className="w-2 h-2 rounded-full" style={{ background: c.color }} />
                      <button
                        onClick={() => setConfirmModal({
                          title: "Eliminar categoría",
                          message: `¿Eliminar "${c.name}"? Solo se puede eliminar si no tiene movimientos asociados.`,
                          confirmLabel: "Eliminar",
                          confirmColor: "#ef4444",
                          onConfirm: async () => { await deleteCategory(c); },
                        })}
                        disabled={deletingCategoryId === c.id}
                        className="opacity-0 group-hover:opacity-100 text-muted hover:text-red-400 text-xs transition-all ml-1"
                      >
                        ✕
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {categories.length === 0 && (
              <div className="text-center py-8 text-muted text-sm">
                No tienes categorías.{" "}
                <button onClick={() => setShowNewCategory(true)} className="text-brand-400 hover:underline">Crea una</button>
                {" "}o{" "}
                <button onClick={seedCategories} className="text-brand-400 hover:underline">carga las predeterminadas</button>.
              </div>
            )}
          </div>
        </div>

        {/* ── Datos & Privacidad ── */}
        <div className="card">
          <h3 className="text-sm font-semibold text-slate-200 mb-4 pb-3 border-b border-surface-500">Datos & Privacidad</h3>
          <div className="space-y-3">
            <div className="flex items-center justify-between py-3 border-b border-surface-500">
              <div>
                <span className="text-sm text-slate-400">Exportar reporte financiero</span>
                <p className="text-xs text-muted mt-0.5">Excel multi-hoja o JSON · elige período</p>
              </div>
              <button onClick={openExportModal}
                className="text-xs font-semibold px-3 py-1.5 rounded-lg border transition-all"
                style={{ borderColor: "#10b98150", color: "#10b981", background: "#10b98110" }}>
                Exportar
              </button>
            </div>

            <div className="flex items-center justify-between py-3 border-b border-surface-500">
              <div>
                <span className="text-sm text-slate-400">Eliminar todos los movimientos</span>
                <p className="text-xs text-muted mt-0.5">{transactions.length} movimientos en {accounts.length} cuentas</p>
              </div>
              <button
                onClick={() => setConfirmModal({
                  title: "Eliminar todos los movimientos",
                  message: `¿Estás seguro? Se eliminarán los ${transactions.length} movimientos de forma permanente. Esta acción no se puede deshacer.`,
                  confirmLabel: "Sí, eliminar todo",
                  confirmColor: "#f59e0b",
                  onConfirm: deleteAllTransactions,
                })}
                className="text-xs font-semibold px-3 py-1.5 rounded-lg border transition-all"
                style={{ borderColor: "#f59e0b50", color: "#f59e0b", background: "#f59e0b10" }}>
                Eliminar
              </button>
            </div>

            <div className="flex items-center justify-between py-3">
              <div>
                <span className="text-sm text-slate-400">Eliminar cuenta permanentemente</span>
                <p className="text-xs text-muted mt-0.5">Borra todos tus datos de FLUJO</p>
              </div>
              <button
                onClick={() => setConfirmModal({
                  title: "Eliminar cuenta",
                  message: "Esta acción cerrará tu sesión. Contacta soporte en blacksong0194@gmail.com para completar la eliminación permanente de tu cuenta y datos.",
                  confirmLabel: "Entendido, cerrar sesión",
                  confirmColor: "#ef4444",
                  onConfirm: deleteAccount,
                })}
                className="text-xs font-semibold px-3 py-1.5 rounded-lg border transition-all"
                style={{ borderColor: "#ef444450", color: "#ef4444", background: "#ef444410" }}>
                Eliminar
              </button>
            </div>
          </div>
        </div>

        {/* ── Sincronización ── */}
        <div className="card">
          <h3 className="text-sm font-semibold text-slate-200 mb-4 pb-3 border-b border-surface-500">Sincronización en la nube</h3>
          <div className="space-y-3">
            <div className="flex items-center gap-3 p-4 bg-brand-500/10 border border-brand-500/20 rounded-xl">
              <div className="w-2 h-2 rounded-full bg-brand-400 animate-pulse" />
              <div>
                <p className="text-sm font-medium text-brand-400">Sincronización activa</p>
                <p className="text-xs text-muted">Tus datos se guardan en tiempo real con Supabase</p>
              </div>
            </div>
            <p className="text-xs text-muted">
              FLUJO sincroniza automáticamente todos tus movimientos, cuentas y metas entre todos tus dispositivos. No necesitas hacer nada manual.
            </p>
          </div>
        </div>

      </div>
    </>
  );
}
