"use client";
import {
  AreaChart, Area, XAxis, YAxis, Tooltip,
  ResponsiveContainer, CartesianGrid,
} from "recharts";
import { calcTrend, formatCurrency } from "@/lib/finance";
import type { Transaction } from "@/types";

interface Props { transactions: Transaction[] }

const CustomTooltip = ({ active, payload, label }: any) => {
  if (!active || !payload?.length) return null;
  return (
    <div className="bg-surface-600 border border-surface-400 rounded-xl p-3 shadow-xl text-xs">
      <p className="text-muted capitalize mb-2 font-medium">{label}</p>
      {payload.map((p: any) => (
        <div key={p.name} className="flex items-center gap-2 mb-1">
          <span className="w-2 h-2 rounded-full" style={{ background: p.color }} />
          <span className="text-muted">{p.name}:</span>
          <span className="font-semibold text-slate-200">{formatCurrency(p.value, "DOP", true)}</span>
        </div>
      ))}
    </div>
  );
};

export default function TrendChart({ transactions }: Props) {
  const data = calcTrend(transactions, 6);

  return (
    <ResponsiveContainer width="100%" height={200}>
      <AreaChart data={data} margin={{ top: 5, right: 5, left: -20, bottom: 0 }}>
        <defs>
          <linearGradient id="gIncome" x1="0" y1="0" x2="0" y2="1">
            <stop offset="5%"  stopColor="#10b981" stopOpacity={0.3} />
            <stop offset="95%" stopColor="#10b981" stopOpacity={0} />
          </linearGradient>
          <linearGradient id="gExpense" x1="0" y1="0" x2="0" y2="1">
            <stop offset="5%"  stopColor="#ef4444" stopOpacity={0.25} />
            <stop offset="95%" stopColor="#ef4444" stopOpacity={0} />
          </linearGradient>
        </defs>
        <CartesianGrid strokeDasharray="3 3" stroke="#1e2a3a" vertical={false} />
        <XAxis
          dataKey="month"
          tick={{ fill: "#4a6b8a", fontSize: 11 }}
          axisLine={false}
          tickLine={false}
          style={{ textTransform: "capitalize" }}
        />
        <YAxis
          tick={{ fill: "#4a6b8a", fontSize: 10 }}
          axisLine={false}
          tickLine={false}
          tickFormatter={(v) => formatCurrency(v, "DOP", true)}
        />
        <Tooltip content={<CustomTooltip />} />
        <Area
          type="monotone"
          dataKey="ingresos"
          name="Ingresos"
          stroke="#10b981"
          strokeWidth={2}
          fill="url(#gIncome)"
          dot={false}
          activeDot={{ r: 4, fill: "#10b981" }}
        />
        <Area
          type="monotone"
          dataKey="egresos"
          name="Egresos"
          stroke="#ef4444"
          strokeWidth={2}
          fill="url(#gExpense)"
          dot={false}
          activeDot={{ r: 4, fill: "#ef4444" }}
        />
      </AreaChart>
    </ResponsiveContainer>
  );
}
