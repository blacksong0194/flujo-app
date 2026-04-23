"use client";
import { useState } from "react";
import { useFinanceStore } from "@/store/useFinanceStore";
import { Modal } from "@/components/ui";
import { ACCOUNT_COLORS } from "@/lib/utils";
import type { AccountType } from "@/types";
import toast from "react-hot-toast";

interface Props { open: boolean; onClose: () => void }

const ACCOUNT_TYPES: { value: AccountType; label: string }[] = [
  { value: "banco", label: "Banco" },
  { value: "cooperativa", label: "Cooperativa" },
  { value: "efectivo", label: "Efectivo" },
  { value: "inversion", label: "Depósito / Inversión" },
  { value: "deuda", label: "Deuda / Tarjeta" },
  { value: "prestamo", label: "Préstamo" },
];

export default function AccountModal({ open, onClose }: Props) {
  const { addAccount } = useFinanceStore();
  const [form, setForm] = useState({ name: "", type: "banco" as AccountType, balance: "0", color: "#3b82f6" });
  const [loading, setLoading] = useState(false);
  const set = (k: string, v: string) => setForm((f) => ({ ...f, [k]: v }));

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      await addAccount({
        name: form.name,
        type: form.type,
        balance: parseFloat(form.balance),
        color: ACCOUNT_COLORS[form.type] ?? form.color,
        is_active: true,
      });
      toast.success("Cuenta creada");
      onClose();
      setForm({ name: "", type: "banco", balance: "0", color: "#3b82f6" });
    } catch {
      toast.error("Error al crear la cuenta");
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal open={open} onClose={onClose} title="Nueva cuenta">
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
              <option key={t.value} value={t.value}>{t.label}</option>
            ))}
          </select>
        </div>

        <div>
          <label className="label-base">Saldo inicial (RD$)</label>
          <input
            type="number"
            step="0.01"
            value={form.balance}
            onChange={(e) => set("balance", e.target.value)}
            className="input-base"
          />
          <p className="text-xs text-muted mt-1">
            Para deudas, ingresa el valor negativo (ej: -50000)
          </p>
        </div>

        <div className="flex gap-3 pt-2">
          <button type="button" onClick={onClose} className="flex-1 btn-ghost border border-surface-500">
            Cancelar
          </button>
          <button type="submit" disabled={loading} className="flex-1 btn-primary">
            {loading ? "Guardando..." : "Crear cuenta"}
          </button>
        </div>
      </form>
    </Modal>
  );
}
