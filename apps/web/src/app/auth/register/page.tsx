"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import toast from "react-hot-toast";
import { createClient } from "@/lib/supabase/client";

export default function RegisterPage() {
  const router = useRouter();
  const supabase = createClient();
  const [form, setForm] = useState({ name: "", email: "", password: "" });
  const [loading, setLoading] = useState(false);
  const set = (k: string, v: string) => setForm((f) => ({ ...f, [k]: v }));

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    if (form.password.length < 8) { toast.error("La contraseña debe tener al menos 8 caracteres"); return; }
    setLoading(true);
    const { data, error } = await supabase.auth.signUp({
      email: form.email,
      password: form.password,
      options: { data: { full_name: form.name } },
    });
    setLoading(false);
    if (error) { toast.error(error.message); return; }
    if (data.user) {
      toast.success("¡Cuenta creada! Revisa tu correo para confirmar.");
      router.push("/auth/login");
    }
  };

  return (
    <div className="min-h-screen bg-surface-900 flex items-center justify-center p-4">
      <div className="w-full max-w-sm animate-fade-in">
        <div className="text-center mb-10">
          <h1 className="text-3xl font-bold text-brand-500 tracking-tight">FLUJO</h1>
          <p className="text-xs text-muted uppercase tracking-widest mt-1">Finance OS</p>
        </div>

        <div className="card space-y-5">
          <div>
            <h2 className="text-lg font-semibold text-slate-100">Crear cuenta</h2>
            <p className="text-sm text-muted mt-1">Empieza a controlar tus finanzas hoy</p>
          </div>

          <form onSubmit={handleRegister} className="space-y-4">
            {[
              { label: "Nombre completo", key: "name", type: "text", placeholder: "Tu nombre" },
              { label: "Correo electrónico", key: "email", type: "email", placeholder: "tu@email.com" },
              { label: "Contraseña", key: "password", type: "password", placeholder: "Mínimo 8 caracteres" },
            ].map((f) => (
              <div key={f.key}>
                <label className="label-base">{f.label}</label>
                <input
                  type={f.type}
                  value={form[f.key as keyof typeof form]}
                  onChange={(e) => set(f.key, e.target.value)}
                  placeholder={f.placeholder}
                  className="input-base"
                  required
                />
              </div>
            ))}
            <button type="submit" disabled={loading} className="btn-primary w-full">
              {loading ? "Creando cuenta..." : "Crear cuenta gratis"}
            </button>
          </form>
        </div>

        <p className="text-center text-sm text-muted mt-6">
          ¿Ya tienes cuenta?{" "}
          <Link href="/auth/login" className="text-brand-400 hover:text-brand-300 font-medium">
            Iniciar sesión
          </Link>
        </p>
      </div>
    </div>
  );
}
