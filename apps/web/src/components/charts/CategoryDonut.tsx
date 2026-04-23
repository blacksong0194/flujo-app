"use client";
import { PieChart, Pie, Cell, Tooltip, ResponsiveContainer } from "recharts";
import { formatCurrency } from "@/lib/finance";

interface DataPoint { name: string; value: number; color: string }

const CustomTooltip = ({ active, payload }: any) => {
  if (!active || !payload?.length) return null;
  return (
    <div className="bg-surface-600 border border-surface-400 rounded-xl p-3 text-xs shadow-xl">
      <p className="font-semibold text-slate-200">{payload[0].name}</p>
      <p style={{ color: payload[0].payload.color }}>{formatCurrency(payload[0].value, "DOP", true)}</p>
    </div>
  );
};

export default function CategoryDonut({ data }: { data: DataPoint[] }) {
  const total = data.reduce((s, d) => s + d.value, 0);

  return (
    <div className="relative">
      <ResponsiveContainer width="100%" height={140}>
        <PieChart>
          <Pie
            data={data}
            cx="50%"
            cy="50%"
            innerRadius={45}
            outerRadius={62}
            paddingAngle={3}
            dataKey="value"
            strokeWidth={0}
          >
            {data.map((d, i) => (
              <Cell key={i} fill={d.color} />
            ))}
          </Pie>
          <Tooltip content={<CustomTooltip />} />
        </PieChart>
      </ResponsiveContainer>
      {/* Center label */}
      <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
        <div className="text-center">
          <p className="text-xs text-muted">Total</p>
          <p className="text-sm font-bold text-slate-200">{formatCurrency(total, "DOP", true)}</p>
        </div>
      </div>
      {/* Legend */}
      <div className="flex justify-center gap-4 mt-1">
        {data.map((d) => (
          <div key={d.name} className="flex items-center gap-1.5">
            <span className="w-2 h-2 rounded-full" style={{ background: d.color }} />
            <span className="text-xs text-muted">{d.name}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
