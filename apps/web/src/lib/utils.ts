import { clsx, type ClassValue } from "clsx";

export function cn(...inputs: ClassValue[]) {
  return clsx(inputs);
}

export function getInitials(name: string): string {
  return name
    .split(" ")
    .map((n) => n[0])
    .slice(0, 2)
    .join("")
    .toUpperCase();
}

export function generateId(): string {
  return Math.random().toString(36).slice(2, 11);
}

export const ACCOUNT_COLORS: Record<string, string> = {
  banco: "#3b82f6",
  cooperativa: "#8b5cf6",
  efectivo: "#a3a3a3",
  inversion: "#06b6d4",
  deuda: "#ef4444",
  prestamo: "#f97316",
};

export const CATEGORY_COLORS: string[] = [
  "#10b981", "#3b82f6", "#8b5cf6", "#f59e0b", "#ef4444",
  "#06b6d4", "#f97316", "#84cc16", "#ec4899", "#6366f1",
];

export const DEFAULT_INCOME_CATEGORIES = [
  { name: "Ing. de ajuste", icon: "⚖️", color: "#64748b" },
  { name: "Ing. x salario", icon: "💼", color: "#10b981" },
  { name: "Ing. x asesoría", icon: "🎯", color: "#3b82f6" },
  { name: "Ing. x arriendo", icon: "🏠", color: "#8b5cf6" },
  { name: "Ing. x inversión", icon: "📈", color: "#f59e0b" },
];

export const DEFAULT_EXPENSE_CATEGORIES = [
  { name: "Egr. de ajuste", icon: "⚖️", color: "#64748b" },
  { name: "Ser. Públicos", icon: "💡", color: "#f59e0b" },
  { name: "Alimentación", icon: "🍽️", color: "#10b981" },
  { name: "Compras", icon: "🛍️", color: "#ec4899" },
  { name: "Pólizas", icon: "🛡️", color: "#3b82f6" },
  { name: "Renta", icon: "🏠", color: "#8b5cf6" },
  { name: "Salud & Pensión", icon: "❤️", color: "#ef4444" },
  { name: "Impuestos", icon: "🏛️", color: "#6366f1" },
  { name: "Membresías", icon: "🔖", color: "#06b6d4" },
  { name: "Reparaciones", icon: "🔧", color: "#f97316" },
  { name: "Esparcimientos", icon: "🎉", color: "#84cc16" },
  { name: "Educación", icon: "📚", color: "#3b82f6" },
  { name: "Transporte", icon: "🚗", color: "#f59e0b" },
  { name: "Despensas", icon: "🛒", color: "#10b981" },
  { name: "Vestuarios", icon: "👕", color: "#ec4899" },
  { name: "Medicinas", icon: "💊", color: "#ef4444" },
];
