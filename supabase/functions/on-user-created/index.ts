// supabase/functions/on-user-created/index.ts
// Supabase Edge Function — triggered by auth.users INSERT via webhook
// Deploy: supabase functions deploy on-user-created

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const DEFAULT_CATEGORIES = [
  // Ingresos (movement_type = 1)
  { name: 'Ing. de ajuste',  movement_type: 1, icon: '⚖️', color: '#64748b' },
  { name: 'Ing. x salario',  movement_type: 1, icon: '💼', color: '#10b981' },
  { name: 'Ing. x asesoría', movement_type: 1, icon: '🎯', color: '#3b82f6' },
  { name: 'Ing. x arriendo', movement_type: 1, icon: '🏠', color: '#8b5cf6' },
  { name: 'Ing. x inversión',movement_type: 1, icon: '📈', color: '#f59e0b' },
  // Egresos (movement_type = 2)
  { name: 'Egr. de ajuste',  movement_type: 2, icon: '⚖️', color: '#64748b' },
  { name: 'Ser. Públicos',   movement_type: 2, icon: '💡', color: '#f59e0b' },
  { name: 'Alimentación',    movement_type: 2, icon: '🍽️', color: '#10b981' },
  { name: 'Compras',         movement_type: 2, icon: '🛍️', color: '#ec4899' },
  { name: 'Pólizas',         movement_type: 2, icon: '🛡️', color: '#3b82f6' },
  { name: 'Renta',           movement_type: 2, icon: '🏠', color: '#8b5cf6' },
  { name: 'Salud & Pensión', movement_type: 2, icon: '❤️', color: '#ef4444' },
  { name: 'Impuestos',       movement_type: 2, icon: '🏛️', color: '#6366f1' },
  { name: 'Membresías',      movement_type: 2, icon: '🔖', color: '#06b6d4' },
  { name: 'Reparaciones',    movement_type: 2, icon: '🔧', color: '#f97316' },
  { name: 'Esparcimientos',  movement_type: 2, icon: '🎉', color: '#84cc16' },
  { name: 'Educación',       movement_type: 2, icon: '📚', color: '#3b82f6' },
  { name: 'Transporte',      movement_type: 2, icon: '🚗', color: '#f59e0b' },
  { name: 'Despensas',       movement_type: 2, icon: '🛒', color: '#10b981' },
  { name: 'Vestuarios',      movement_type: 2, icon: '👕', color: '#ec4899' },
  { name: 'Medicinas',       movement_type: 2, icon: '💊', color: '#ef4444' },
];

Deno.serve(async (req) => {
  const { record } = await req.json(); // auth.users row
  const userId = record.id;

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  // Insert default categories for the new user
  const { error } = await supabase.from('categories').insert(
    DEFAULT_CATEGORIES.map(c => ({ ...c, user_id: userId }))
  );

  if (error) {
    console.error('Error seeding categories:', error);
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }

  console.log(`✅ Seeded ${DEFAULT_CATEGORIES.length} categories for user ${userId}`);
  return new Response(JSON.stringify({ ok: true }), { status: 200 });
});
