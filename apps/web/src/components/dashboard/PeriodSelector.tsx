"use client";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { useFinanceStore } from "@/store/useFinanceStore";
import { formatMonthYear } from "@/lib/finance";

export default function PeriodSelector() {
  const { selectedYear, selectedMonth, setPeriod } = useFinanceStore();

  const prev = () => {
    if (selectedMonth === 1) setPeriod(selectedYear - 1, 12);
    else setPeriod(selectedYear, selectedMonth - 1);
  };
  const next = () => {
    const now = new Date();
    if (selectedYear === now.getFullYear() && selectedMonth === now.getMonth() + 1) return;
    if (selectedMonth === 12) setPeriod(selectedYear + 1, 1);
    else setPeriod(selectedYear, selectedMonth + 1);
  };

  return (
    <div className="flex items-center gap-1 bg-surface-700 border border-surface-500 rounded-xl px-1 py-1">
      <button onClick={prev} className="p-1.5 rounded-lg hover:bg-surface-600 text-muted hover:text-slate-200 transition-all">
        <ChevronLeft size={15} />
      </button>
      <span className="text-sm font-medium text-slate-300 px-2 min-w-[130px] text-center capitalize">
        {formatMonthYear(selectedYear, selectedMonth)}
      </span>
      <button onClick={next} className="p-1.5 rounded-lg hover:bg-surface-600 text-muted hover:text-slate-200 transition-all">
        <ChevronRight size={15} />
      </button>
    </div>
  );
}
