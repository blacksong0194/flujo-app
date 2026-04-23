"use client";
import { TypeTag } from "@/components/ui";
import { formatCurrency, formatDate } from "@/lib/finance";
import { ArrowDownLeft, ArrowUpRight } from "lucide-react";
import type { Transaction } from "@/types";

export default function RecentTransactions({ transactions }: { transactions: Transaction[] }) {
  if (transactions.length === 0) {
    return <p className="text-sm text-muted text-center py-8">Sin movimientos registrados aún</p>;
  }

  return (
    <div className="space-y-0.5">
      {transactions.map((t) => (
        <div
          key={t.id}
          className="flex items-center gap-4 py-3 px-2 rounded-lg hover:bg-surface-600/40 transition-all duration-100 cursor-default"
        >
          {/* Icon */}
          <div
            className="w-9 h-9 rounded-xl flex items-center justify-center shrink-0"
            style={{
              background: t.type === "income" ? "rgba(16,185,129,0.12)" : "rgba(239,68,68,0.12)",
            }}
          >
            {t.type === "income"
              ? <ArrowUpRight size={15} className="text-brand-400" />
              : <ArrowDownLeft size={15} className="text-red-400" />
            }
          </div>

          {/* Info */}
          <div className="flex-1 min-w-0">
            <p className="text-sm font-medium text-slate-200 truncate">{t.detail}</p>
            <p className="text-xs text-muted">
              {t.category?.name ?? "Sin categoría"} · {t.account?.name ?? ""}
            </p>
          </div>

          {/* Right side */}
          <div className="text-right shrink-0">
            <p
              className="text-sm font-bold"
              style={{ color: t.type === "income" ? "#10b981" : "#ef4444" }}
            >
              {t.type === "income" ? "+" : "-"}
              {formatCurrency(t.amount)}
            </p>
            <p className="text-xs text-muted">{formatDate(t.transaction_date)}</p>
          </div>
        </div>
      ))}
    </div>
  );
}
