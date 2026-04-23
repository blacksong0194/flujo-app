"use client";
import { useEffect } from "react";
import { useFinanceStore } from "@/store/useFinanceStore";

export default function AppShell({ children }: { children: React.ReactNode }) {
  const fetchAll = useFinanceStore((s) => s.fetchAll);

  useEffect(() => {
    fetchAll();
  }, [fetchAll]);

  return (
    <main className="ml-56 flex-1 min-h-screen p-7 max-w-[1400px]">
      {children}
    </main>
  );
}
