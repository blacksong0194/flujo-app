"use client";
import { X } from "lucide-react";
import { cn } from "@/lib/utils";

// ─── Modal ────────────────────────────────────────────────────────────────────
interface ModalProps {
  open: boolean;
  onClose: () => void;
  title: string;
  children: React.ReactNode;
  size?: "sm" | "md" | "lg";
}

export function Modal({ open, onClose, title, children, size = "md" }: ModalProps) {
  if (!open) return null;
  const widths = { sm: "max-w-sm", md: "max-w-md", lg: "max-w-lg" };
  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 animate-fade-in"
      onClick={onClose}
    >
      <div
        className={cn("w-full bg-surface-700 border border-surface-500 rounded-2xl p-6 animate-slide-up", widths[size])}
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between mb-5">
          <h3 className="text-base font-semibold text-slate-100">{title}</h3>
          <button
            onClick={onClose}
            className="text-muted hover:text-slate-200 hover:bg-surface-600 p-1.5 rounded-lg transition-all"
          >
            <X size={16} />
          </button>
        </div>
        {children}
      </div>
    </div>
  );
}

// ─── PageHeader ───────────────────────────────────────────────────────────────
interface PageHeaderProps {
  title: string;
  subtitle?: string;
  action?: React.ReactNode;
}

export function PageHeader({ title, subtitle, action }: PageHeaderProps) {
  return (
    <div className="flex items-start justify-between mb-7">
      <div>
        <h1 className="text-2xl font-bold text-slate-100 tracking-tight">{title}</h1>
        {subtitle && <p className="text-sm text-muted mt-1">{subtitle}</p>}
      </div>
      {action && <div>{action}</div>}
    </div>
  );
}

// ─── KPI Metric Card ──────────────────────────────────────────────────────────
interface MetricCardProps {
  label: string;
  value: string;
  subvalue?: string;
  accent?: string;
  icon?: React.ReactNode;
  trend?: { value: number; label: string };
}

export function MetricCard({ label, value, subvalue, accent = "#10b981", icon, trend }: MetricCardProps) {
  const positive = trend ? trend.value >= 0 : true;
  return (
    <div
      className="bg-surface-800 rounded-xl p-5 border border-surface-500"
      style={{ borderTop: `3px solid ${accent}` }}
    >
      <div className="flex items-start justify-between mb-3">
        <p className="label-base mb-0">{label}</p>
        {icon && <span className="text-muted">{icon}</span>}
      </div>
      <p className="text-2xl font-bold tracking-tight" style={{ color: accent }}>
        {value}
      </p>
      {subvalue && <p className="text-xs text-muted mt-1">{subvalue}</p>}
      {trend && (
        <p className={cn("text-xs font-medium mt-2", positive ? "text-brand-400" : "text-red-400")}>
          {positive ? "▲" : "▼"} {Math.abs(trend.value).toFixed(1)}% {trend.label}
        </p>
      )}
    </div>
  );
}

// ─── Empty State ──────────────────────────────────────────────────────────────
interface EmptyStateProps {
  icon: React.ReactNode;
  title: string;
  description: string;
  action?: React.ReactNode;
}

export function EmptyState({ icon, title, description, action }: EmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center py-16 text-center">
      <div className="w-14 h-14 rounded-2xl bg-surface-600 flex items-center justify-center mb-4 text-muted">
        {icon}
      </div>
      <h3 className="text-base font-semibold text-slate-300 mb-1">{title}</h3>
      <p className="text-sm text-muted max-w-xs mb-5">{description}</p>
      {action}
    </div>
  );
}

// ─── Alert Banner ─────────────────────────────────────────────────────────────
interface AlertBannerProps {
  type: "danger" | "warning" | "info";
  title: string;
  message: string;
}

const alertStyles = {
  danger:  { bg: "bg-red-500/8",   border: "border-red-500/30",   text: "text-red-400" },
  warning: { bg: "bg-amber-500/8", border: "border-amber-500/30", text: "text-amber-400" },
  info:    { bg: "bg-blue-500/8",  border: "border-blue-500/30",  text: "text-blue-400" },
};

export function AlertBanner({ type, title, message }: AlertBannerProps) {
  const s = alertStyles[type];
  return (
    <div className={cn("rounded-xl border px-4 py-3 flex gap-3", s.bg, s.border)}>
      <span className={cn("text-lg leading-none mt-0.5", s.text)}>
        {type === "danger" ? "⚠" : type === "warning" ? "◆" : "ℹ"}
      </span>
      <div>
        <p className={cn("text-sm font-semibold", s.text)}>{title}</p>
        <p className="text-xs text-muted mt-0.5">{message}</p>
      </div>
    </div>
  );
}

// ─── Progress Bar ─────────────────────────────────────────────────────────────
interface ProgressBarProps {
  percent: number;
  color?: string;
  size?: "sm" | "md";
}

export function ProgressBar({ percent, color = "#10b981", size = "md" }: ProgressBarProps) {
  const clamped = Math.min(Math.max(percent, 0), 100);
  const h = size === "sm" ? "h-1.5" : "h-2.5";
  return (
    <div className={cn("w-full bg-surface-500 rounded-full overflow-hidden", h)}>
      <div
        className="h-full rounded-full transition-all duration-500"
        style={{ width: `${clamped}%`, background: color }}
      />
    </div>
  );
}

// ─── Type Tag ─────────────────────────────────────────────────────────────────
export function TypeTag({ type }: { type: "income" | "expense" | "transfer" }) {
  const map = {
    income:   { label: "Ingreso",    cls: "badge-income" },
    expense:  { label: "Egreso",     cls: "badge-expense" },
    transfer: { label: "Transferencia", cls: "bg-blue-500/15 text-blue-400 text-xs font-semibold px-2.5 py-0.5 rounded-full" },
  };
  const { label, cls } = map[type];
  return <span className={cls}>{label}</span>;
}
