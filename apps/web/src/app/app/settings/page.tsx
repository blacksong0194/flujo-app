"use client";
import { useState, useEffect } from "react";
import { PageHeader } from "@/components/ui";
import { createClient } from "@/lib/supabase/client";
import { DEFAULT_INCOME_CATEGORIES, DEFAULT_EXPENSE_CATEGORIES } from "@/lib/utils";
import { useFinanceStore } from "@/store/useFinanceStore";
import toast from "react-hot-toast";

export default function SettingsPage() {
  const supabase = createClient();
  const { categories, fetchAll } = useFinanceStore();
  const [profile, setProfile] = useState({ full_name: "", email: "" });
  const [savingProfile, setSavingProfile] = useState(false);
  const [seedingCategories, setSeedingCategories] = useState(false);

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

  const sections = [
    {
      title: "Perfil",
      content: (
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
      ),
    },
    {
      title: "Preferencias",
      content: (
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
      ),
    },
    {
      title: "Categorías",
      content: (
        <div>
          <div className="flex items-center justify-between mb-4">
            <div>
              <p className="text-sm text-slate-300">
                {categories.length} categorías configuradas
              </p>
              <p className="text-xs text-muted mt-0.5">
                {categories.filter((c) => c.movement_type === 1).length} ingresos ·{" "}
                {categories.filter((c) => c.movement_type === 2).length} egresos
              </p>
            </div>
            <button onClick={seedCategories} disabled={seedingCategories} className="btn-outline text-sm">
              {seedingCategories ? "Cargando..." : "Cargar categorías predeterminadas"}
            </button>
          </div>
          <div className="grid grid-cols-2 gap-2 max-h-56 overflow-y-auto pr-1">
            {categories.map((c) => (
              <div key={c.id} className="flex items-center gap-2 bg-surface-800 rounded-lg px-3 py-2">
                <span className="text-sm">{c.icon}</span>
                <span className="text-sm text-slate-300 truncate">{c.name}</span>
                <span className="ml-auto text-xs text-muted">{c.movement_type === 1 ? "↑" : "↓"}</span>
              </div>
            ))}
          </div>
        </div>
      ),
    },
    {
      title: "Datos & Privacidad",
      content: (
        <div className="space-y-3">
          {[
            { label: "Exportar todos mis datos (JSON)", action: "Exportar", handler: () => toast("Próximamente"), color: "#3b82f6" },
            { label: "Exportar como Excel (.xlsx)", action: "Exportar", handler: () => toast("Próximamente"), color: "#10b981" },
            { label: "Eliminar todos los movimientos", action: "Eliminar", handler: () => toast.error("Acción destructiva — próximamente con confirmación"), color: "#f59e0b" },
            { label: "Eliminar cuenta permanentemente", action: "Eliminar", handler: () => toast.error("Contacta soporte para eliminar tu cuenta"), color: "#ef4444" },
          ].map((row) => (
            <div key={row.label} className="flex items-center justify-between py-3 border-b border-surface-500 last:border-0">
              <span className="text-sm text-slate-400">{row.label}</span>
              <button
                onClick={row.handler}
                className="text-xs font-semibold px-3 py-1.5 rounded-lg border transition-all"
                style={{ borderColor: `${row.color}50`, color: row.color, background: `${row.color}10` }}
              >
                {row.action}
              </button>
            </div>
          ))}
        </div>
      ),
    },
    {
      title: "Sincronización en la nube",
      content: (
        <div className="space-y-3">
          <div className="flex items-center gap-3 p-4 bg-brand-500/8 border border-brand-500/20 rounded-xl">
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
      ),
    },
  ];

  return (
    <>
      <PageHeader title="Ajustes" subtitle="Configura tu experiencia en FLUJO" />
      <div className="max-w-2xl space-y-5">
        {sections.map((s) => (
          <div key={s.title} className="card">
            <h3 className="text-sm font-semibold text-slate-200 mb-4 pb-3 border-b border-surface-500">
              {s.title}
            </h3>
            {s.content}
          </div>
        ))}
      </div>
    </>
  );
}
