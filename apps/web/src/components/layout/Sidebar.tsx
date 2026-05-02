"use client";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import {
  LayoutDashboard, Wallet, ArrowLeftRight, PieChart,
  Target, BarChart3, Settings, LogOut, TrendingUp, Clock, Repeat,
} from "lucide-react";
import { createClient } from "@/lib/supabase/client";
import { usePendingStore } from "@/store/usePendingStore";
import { cn } from "@/lib/utils";
import { useEffect } from "react";

const NAV = [
  { href: "/app/dashboard",    label: "Dashboard",   icon: LayoutDashboard },
  { href: "/app/accounts",     label: "Cuentas",     icon: Wallet },
  { href: "/app/transactions", label: "Movimientos", icon: ArrowLeftRight },
  { href: "/app/pending",      label: "Por cobrar",  icon: Clock },
  { href: "/app/recurring",    label: "Recurrentes", icon: Repeat },
  { href: "/app/budgets",      label: "Presupuesto", icon: PieChart },
  { href: "/app/goals",        label: "Metas",       icon: Target },
  { href: "/app/reports",      label: "Reportes",    icon: BarChart3 },
];

export default function Sidebar() {
  const pathname = usePathname();
  const router   = useRouter();
  const supabase = createClient();
  const { summary, fetchPending } = usePendingStore();

  useEffect(() => { fetchPending(); }, []);

  const alertCount = summary.overdue + summary.due_soon;

  const handleLogout = async () => {
    await supabase.auth.signOut();
    router.push("/auth/login");
    router.refresh();
  };

  return (
    <aside className="w-56 shrink-0 bg-surface-800 border-r border-surface-500
                      flex flex-col fixed top-0 left-0 h-screen z-30">
      <div className="px-6 py-6 border-b border-surface-500">
        <div className="flex items-center gap-2.5">
          <div className="w-8 h-8 rounded-lg bg-brand-500/20 flex items-center justify-center">
            <TrendingUp size={16} className="text-brand-400" />
          </div>
          <div>
            <p className="text-base font-bold text-brand-400 leading-none tracking-tight">FLUJO</p>
            <p className="text-[10px] text-muted uppercase tracking-widest mt-0.5">Finance OS</p>
          </div>
        </div>
      </div>

      <nav className="flex-1 py-4 overflow-y-auto">
        <p className="text-[10px] text-muted uppercase tracking-widest px-5 mb-2">Principal</p>
        {NAV.map(({ href, label, icon: Icon }) => {
          const active    = pathname === href || pathname.startsWith(href + "/");
          const isPending = href === "/app/pending";
          return (
            <Link
              key={href}
              href={href}
              className={cn("nav-item", active ? "nav-item-active" : "nav-item-inactive")}
            >
              <Icon size={16} />
              <span className="flex-1">{label}</span>
              {isPending && alertCount > 0 && (
                <span className="flex items-center justify-center w-5 h-5 rounded-full
                                 bg-red-500 text-white text-[10px] font-bold">
                  {alertCount > 9 ? "9+" : alertCount}
                </span>
              )}
            </Link>
          );
        })}

        <p className="text-[10px] text-muted uppercase tracking-widest px-5 mb-2 mt-6">Sistema</p>
        <Link
          href="/app/settings"
          className={cn("nav-item", pathname === "/app/settings" ? "nav-item-active" : "nav-item-inactive")}
        >
          <Settings size={16} />
          <span>Ajustes</span>
        </Link>
      </nav>

      <div className="px-4 py-4 border-t border-surface-500">
        <button
          onClick={handleLogout}
          className="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg
                     text-sm text-muted hover:text-red-400 hover:bg-red-500/8
                     transition-all duration-150"
        >
          <LogOut size={15} />
          <span>Cerrar sesión</span>
        </button>
      </div>
    </aside>
  );
}
