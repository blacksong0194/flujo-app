"use client";
import { useState, useEffect } from "react";
import { useFinanceStore } from "@/store/useFinanceStore";
import { createClient } from "@/lib/supabase/client";
import { Modal } from "@/components/ui";
import { ACCOUNT_COLORS } from "@/lib/utils";
import type { AccountType, Account } from "@/types";
import toast from "react-hot-toast";
import { Trash2 } from "lucide-react";

interface Props {
  open: boolean;
  onClose: () => void;
  editingAccount?: Account | null;
  onEditingChange?: (account: Account | null) => void;
}

const ACCOUNT_TYPES: { value: AccountType; label: string }[] = [
  { value: "banco", label: "Banco" },
  { value: "cooperativa", label: "Cooperativa" },
  { value: "efectivo", label: "Efectivo" },
  { value: "inversion", label: "Depósito / Inversión" },
  { value: "deuda", label: "Deuda / Tarjeta" },
  { value: "prestamo", label: "Préstamo" },
];

export default function AccountModal({ open, onClose, editingAccount, onEditingChange }: Props) {
  const supabase = createClient();
  const { accounts, fetchAll } = useFinanceStore();
  const [form, setForm] = useState({ name: "", type: "banco" as AccountType, balance: "0", color: "#3b82f6" });
  const [loading, setLoading] = useState(false);
  const [showConfirmDelete, setShowConfirmDelete] = useState(false);
  const [deleting, setDeleting] = useState(false);

  // Cargar datos de la cuenta si está en modo edición
  useEffect(() => {
    if (editingAccount) {
      setForm({
        name: editingAccount.name,
        type: editingAccount.type,
        balance: editingAccount.balance.toString(),
        color: editingAccount.color,
      });
    } else {
      setForm({ name: "", type: "banco", balance: "0", color: "#3b82f6" });
    }
  }, [editingAccount]);

  const set = (k: string, v: string) => setForm((f) => ({ ...f, [k]: v }));

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.name.trim()) {
      toast.error("El nombre es requerido");
      return;
    }

    setLoading(true);
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      if (editingAccount) {
        // Editar cuenta existente
        const { error } = await supabase
          .from("accounts")
          .update({
            name: form.name.trim(),
            type: form.type,
            balance: parseFloat(form.balance),
            color: ACCOUNT_COLORS[form.type] ?? form.color,
          })
          .eq("id", editingAccount.id)
          .eq("user_id", user.id);

        if (error) {
          toast.error(error.message);
          return;
        }
        toast.success("Cuenta actualizada");
      } else {
        // Crear nueva cuenta
        const { error } = await supabase.from("accounts").insert({
          user_id: user.id,
          name: form.name.trim(),
          type: form.type,
          balance: parseFloat(form.balance),
          color: ACCOUNT_COLORS[form.type] ?? form.color,
          is_active: true,
        });

        if (error) {
          toast.error(error.message);
          return;
        }
        toast.success("Cuenta creada");
      }

      await fetchAll();
      onClose();
      if (onEditingChange) onEditingChange(null);
      setForm({ name: "", type: "banco", balance: "0", color: "#3b82f6" });
    } catch (err) {
      console.error(err);
      toast.error("Error al guardar la cuenta");
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async () => {
    if (!editingAccount) return;
    setDeleting(true);
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      // Verificar que no tenga movimientos (opcional pero recomendado)
      const { data: transactions, error: txError } = await supabase
        .from("transactions")
        .select("id")
        .eq("account_id", editingAccount.id)
        .eq("user_id", user.id);

      if (txError) {
        toast.error("Error al verificar movimientos");
        return;
      }

      if (transactions && transactions.length > 0) {
        toast.error("No se puede eliminar: la cuenta tiene movimientos asociados");
        setDeleting(false);
        return;
      }

      // Eliminar la cuenta
      const { error } = await supabase
        .from("accounts")
        .delete()
        .eq("id", editingAccount.id)
        .eq("user_id", user.id);

      if (error) {
        toast.error(error.message);
        return;
      }

      toast.success("Cuenta eliminada");
      await fetchAll();
      onClose();
      if (onEditingChange) onEditingChange(null);
      setShowConfirmDelete(false);
    } catch (err) {
      console.error(err);
      toast.error("Error al eliminar");
    } finally {
      setDeleting(false);
    }
  };

  // Auto-eliminar cuentas de deuda/préstamo que lleguen a cero
  const checkAutoDelete = async () => {
    if (!editingAccount) return;
    const isDebtType = ["deuda", "prestamo"].includes(editingAccount.type);
    const balanceAfter = parseFloat(form.balance);

    if (isDebtType && balanceAfter === 0) {
      const confirmed = window.confirm(
        `La cuenta "${form.name}" llegó a $0. ¿Eliminarla automáticamente?`
      );
      if (confirmed) {
        await handleDelete();
      }
    }
  };

  const isEditing = !!editingAccount;
  const isDebtType = ["deuda", "prestamo"].includes(form.type);

  return (
    <>
      <Modal open={open} onClose={onClose} title={isEditing ? "Editar cuenta" : "Nueva cuenta"}>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="label-base">Nombre de la cuenta</label>
            <input
              type="text"
              value={form.name}
              onChange={(e) => set("name", e.target.value)}
              placeholder="Ej: Banco Popular, Efectivo..."
              className="input-base"
              required
            />
          </div>

          <div>
            <label className="label-base">Tipo de cuenta</label>
            <select
              value={form.type}
              onChange={(e) => set("type", e.target.value)}
              className="input-base"
            >
              {ACCOUNT_TYPES.map((t) => (
                <option key={t.value} value={t.value}>
                  {t.label}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="label-base">Saldo (RD$)</label>
            <input
              type="number"
              step="0.01"
              value={form.balance}
              onChange={(e) => set("balance", e.target.value)}
              onBlur={checkAutoDelete}
              className="input-base"
            />
            <p className="text-xs text-muted mt-1">
              {isDebtType
                ? "Para deudas, ingresa el valor negativo (ej: -50000)"
                : "Saldo disponible en la cuenta"}
            </p>
            {isDebtType && parseFloat(form.balance) === 0 && (
              <p className="text-xs text-brand-400 mt-1 font-medium">
                ✓ Deuda pagada — se eliminará automáticamente al guardar
              </p>
            )}
          </div>

          <div className="flex gap-3 pt-2">
            <button type="button" onClick={onClose} className="flex-1 btn-ghost border border-surface-500">
              Cancelar
            </button>
            {isEditing && (
              <button
                type="button"
                onClick={() => setShowConfirmDelete(true)}
                className="px-3 py-2 rounded-xl border border-red-500/30 text-red-400 hover:bg-red-500/10 transition-all flex items-center gap-2 justify-center"
              >
                <Trash2 size={14} />
                Eliminar
              </button>
            )}
            <button type="submit" disabled={loading} className="flex-1 btn-primary">
              {loading ? "Guardando..." : isEditing ? "Actualizar" : "Crear cuenta"}
            </button>
          </div>
        </form>
      </Modal>

      {/* Modal de confirmación para eliminar */}
      {showConfirmDelete && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
          <div className="bg-surface-700 border border-surface-500 rounded-2xl w-full max-w-sm p-6 space-y-4">
            <h3 className="text-base font-semibold text-slate-200">Eliminar cuenta</h3>
            <p className="text-sm text-slate-400">
              ¿Estás seguro de que quieres eliminar "{editingAccount?.name}"? Esta acción no se puede deshacer.
            </p>
            <div className="flex gap-3">
              <button
                onClick={() => setShowConfirmDelete(false)}
                className="flex-1 btn-ghost"
              >
                Cancelar
              </button>
              <button
                onClick={handleDelete}
                disabled={deleting}
                className="flex-1 py-2.5 rounded-xl text-sm font-semibold transition-all"
                style={{
                  background: "#ef444020",
                  color: "#ef4444",
                  border: "1px solid #ef444050",
                }}
              >
                {deleting ? "Eliminando..." : "Sí, eliminar"}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
