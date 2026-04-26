// flujo/apps/api-server/src/server.js
const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const { createClient } = require('@supabase/supabase-js');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;

// ─── Middleware ────────────────────────────────────────────────────────────────
app.use(cors({
  origin: process.env.CORS_ORIGIN
    ? process.env.CORS_ORIGIN.split(',')
    : ['http://localhost:3000', 'http://localhost:3001', 'http://localhost:5173'],
}));
app.use(express.json());

// ─── Supabase client ───────────────────────────────────────────────────────────
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

// ─── Helper: extraer usuario del token ────────────────────────────────────────
async function getUserFromToken(req, res) {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) {
    res.status(401).json({ error: 'Token requerido' });
    return null;
  }
  const { data: { user }, error } = await supabase.auth.getUser(token);
  if (error || !user) {
    res.status(401).json({ error: 'No autorizado' });
    return null;
  }
  return user;
}

// ──────────────────────────────────────────────────────────────────────────────
// HEALTH CHECK
// ──────────────────────────────────────────────────────────────────────────────
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// ──────────────────────────────────────────────────────────────────────────────
// AUTH
// ──────────────────────────────────────────────────────────────────────────────

// Registro
app.post('/auth/register', async (req, res) => {
  try {
    const { email, password, fullName } = req.body;
    if (!email || !password || !fullName)
      return res.status(400).json({ error: 'Email, password y nombre son requeridos' });

    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: { data: { full_name: fullName } },
    });
    if (error) return res.status(400).json({ error: error.message });

    res.json({ success: true, user: data.user });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Login
app.post('/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password)
      return res.status(400).json({ error: 'Email y contraseña son requeridos' });

    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) return res.status(400).json({ error: error.message });

    res.json({
      success: true,
      user: data.user,
      session: data.session,
      accessToken: data.session.access_token,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ──────────────────────────────────────────────────────────────────────────────
// CUENTAS
// ──────────────────────────────────────────────────────────────────────────────

app.get('/accounts', async (req, res) => {
  try {
    const user = await getUserFromToken(req, res);
    if (!user) return;

    const { data, error } = await supabase
      .from('accounts')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false });

    if (error) return res.status(400).json({ error: error.message });
    res.json({ accounts: data || [] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/accounts', async (req, res) => {
  try {
    const user = await getUserFromToken(req, res);
    if (!user) return;

    const { name, type, balance, color } = req.body;
    if (!name || !type)
      return res.status(400).json({ error: 'Nombre y tipo son requeridos' });

    const { data, error } = await supabase
      .from('accounts')
      .insert({ user_id: user.id, name, type, balance: parseFloat(balance) || 0, color: color || '#3b82f6', is_active: true })
      .select();

    if (error) return res.status(400).json({ error: error.message });
    res.json({ success: true, account: data[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put('/accounts/:id', async (req, res) => {
  try {
    const user = await getUserFromToken(req, res);
    if (!user) return;

    const { name, balance, color } = req.body;

    const { data, error } = await supabase
      .from('accounts')
      .update({ name, balance: parseFloat(balance), color })
      .eq('id', req.params.id)
      .eq('user_id', user.id)
      .select();

    if (error) return res.status(400).json({ error: error.message });
    res.json({ success: true, account: data[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/accounts/:id', async (req, res) => {
  try {
    const user = await getUserFromToken(req, res);
    if (!user) return;

    const { data: transactions } = await supabase
      .from('transactions')
      .select('id')
      .eq('account_id', req.params.id)
      .eq('user_id', user.id);

    if (transactions && transactions.length > 0)
      return res.status(400).json({ error: 'No se puede eliminar: la cuenta tiene movimientos' });

    const { error } = await supabase
      .from('accounts')
      .delete()
      .eq('id', req.params.id)
      .eq('user_id', user.id);

    if (error) return res.status(400).json({ error: error.message });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ──────────────────────────────────────────────────────────────────────────────
// CATEGORÍAS
// ──────────────────────────────────────────────────────────────────────────────

app.get('/categories', async (req, res) => {
  try {
    const user = await getUserFromToken(req, res);
    if (!user) return;

    const { data, error } = await supabase
      .from('categories')
      .select('*')
      .eq('user_id', user.id)
      .order('movement_type');

    if (error) return res.status(400).json({ error: error.message });
    res.json({ categories: data || [] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/categories', async (req, res) => {
  try {
    const user = await getUserFromToken(req, res);
    if (!user) return;

    const { name, icon, color, movement_type } = req.body;
    if (!name || !movement_type)
      return res.status(400).json({ error: 'Nombre y tipo de movimiento son requeridos' });

    const { data, error } = await supabase
      .from('categories')
      .insert({ user_id: user.id, name, icon: icon || '💰', color: color || '#10b981', movement_type })
      .select();

    if (error) return res.status(400).json({ error: error.message });
    res.json({ success: true, category: data[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/categories/:id', async (req, res) => {
  try {
    const user = await getUserFromToken(req, res);
    if (!user) return;

    const { error } = await supabase
      .from('categories')
      .delete()
      .eq('id', req.params.id)
      .eq('user_id', user.id);

    if (error) return res.status(400).json({ error: error.message });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ──────────────────────────────────────────────────────────────────────────────
// TRANSACCIONES
// ──────────────────────────────────────────────────────────────────────────────

app.get('/transactions', async (req, res) => {
  try {
    const user = await getUserFromToken(req, res);
    if (!user) return;

    const { data, error } = await supabase
      .from('transactions')
      .select('*, account:accounts(name, color), category:categories(name, icon, color)')
      .eq('user_id', user.id)
      .order('transaction_date', { ascending: false });

    if (error) return res.status(400).json({ error: error.message });
    res.json({ transactions: data || [] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/transactions', async (req, res) => {
  try {
    const user = await getUserFromToken(req, res);
    if (!user) return;

    const { account_id, category_id, amount, type, detail, transaction_date } = req.body;
    if (!account_id || !amount || !type)
      return res.status(400).json({ error: 'Cuenta, monto y tipo son requeridos' });

    const { data, error } = await supabase
      .from('transactions')
      .insert({
        user_id: user.id,
        account_id,
        category_id: category_id || null,
        amount: parseFloat(amount),
        type,
        detail: detail || '',
        transaction_date: transaction_date || new Date().toISOString().split('T')[0],
      })
      .select();

    if (error) return res.status(400).json({ error: error.message });
    res.json({ success: true, transaction: data[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/transactions/:id', async (req, res) => {
  try {
    const user = await getUserFromToken(req, res);
    if (!user) return;

    const { error } = await supabase
      .from('transactions')
      .delete()
      .eq('id', req.params.id)
      .eq('user_id', user.id);

    if (error) return res.status(400).json({ error: error.message });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ──────────────────────────────────────────────────────────────────────────────
// TRANSFERENCIAS ENTRE CUENTAS  ← NUEVO
// ──────────────────────────────────────────────────────────────────────────────

// Crear transferencia (genera 2 transacciones y actualiza ambos balances)
app.post('/transactions/transfer', async (req, res) => {
  try {
    const user = await getUserFromToken(req, res);
    if (!user) return;

    const { from_account_id, to_account_id, amount, detail, transaction_date } = req.body;

    // Validaciones
    if (!from_account_id || !to_account_id || !amount)
      return res.status(400).json({ error: 'Cuentas origen/destino y monto son requeridos' });

    if (from_account_id === to_account_id)
      return res.status(400).json({ error: 'Las cuentas de origen y destino deben ser diferentes' });

    const parsedAmount = parseFloat(amount);
    if (parsedAmount <= 0)
      return res.status(400).json({ error: 'El monto debe ser mayor a 0' });

    // Verificar que ambas cuentas pertenecen al usuario y obtener sus saldos
    const { data: accounts, error: accError } = await supabase
      .from('accounts')
      .select('id, name, balance')
      .in('id', [from_account_id, to_account_id])
      .eq('user_id', user.id);

    if (accError || !accounts || accounts.length !== 2)
      return res.status(400).json({ error: 'Una o ambas cuentas no fueron encontradas' });

    const fromAccount = accounts.find(a => a.id === from_account_id);
    const toAccount = accounts.find(a => a.id === to_account_id);

    if (fromAccount.balance < parsedAmount)
      return res.status(400).json({ error: `Saldo insuficiente en "${fromAccount.name}"` });

    const txDate = transaction_date || new Date().toISOString().split('T')[0];
    const txDetail = detail || `Transferencia de ${fromAccount.name} a ${toAccount.name}`;

    // Crear las 2 transacciones en paralelo
    const [txOut, txIn] = await Promise.all([
      supabase.from('transactions').insert({
        user_id: user.id,
        account_id: from_account_id,
        amount: -parsedAmount,
        type: 'transfer',
        detail: `${txDetail} → ${toAccount.name}`,
        transaction_date: txDate,
        transfer_to: to_account_id,
      }).select(),
      supabase.from('transactions').insert({
        user_id: user.id,
        account_id: to_account_id,
        amount: parsedAmount,
        type: 'transfer',
        detail: `${txDetail} ← ${fromAccount.name}`,
        transaction_date: txDate,
        transfer_from: from_account_id,
      }).select(),
    ]);

    if (txOut.error) return res.status(400).json({ error: txOut.error.message });
    if (txIn.error) return res.status(400).json({ error: txIn.error.message });

    // Actualizar balances de ambas cuentas
    await Promise.all([
      supabase.from('accounts')
        .update({ balance: fromAccount.balance - parsedAmount })
        .eq('id', from_account_id)
        .eq('user_id', user.id),
      supabase.from('accounts')
        .update({ balance: toAccount.balance + parsedAmount })
        .eq('id', to_account_id)
        .eq('user_id', user.id),
    ]);

    res.json({
      success: true,
      transfer: {
        from: { account: fromAccount.name, newBalance: fromAccount.balance - parsedAmount },
        to: { account: toAccount.name, newBalance: toAccount.balance + parsedAmount },
        amount: parsedAmount,
        transactionOut: txOut.data[0],
        transactionIn: txIn.data[0],
      },
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Obtener historial de transferencias
app.get('/transactions/transfer/all', async (req, res) => {
  try {
    const user = await getUserFromToken(req, res);
    if (!user) return;

    const { data, error } = await supabase
      .from('transactions')
      .select('*, account:accounts(name, color)')
      .eq('user_id', user.id)
      .eq('type', 'transfer')
      .order('transaction_date', { ascending: false });

    if (error) return res.status(400).json({ error: error.message });
    res.json({ transfers: data || [] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ──────────────────────────────────────────────────────────────────────────────
// PRESUPUESTOS
// ──────────────────────────────────────────────────────────────────────────────

app.get('/budgets', async (req, res) => {
  try {
    const user = await getUserFromToken(req, res);
    if (!user) return;

    const { data, error } = await supabase
      .from('budgets')
      .select('*, category:categories(name, icon, color)')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false });

    if (error) return res.status(400).json({ error: error.message });
    res.json({ budgets: data || [] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/budgets', async (req, res) => {
  try {
    const user = await getUserFromToken(req, res);
    if (!user) return;

    const { category_id, limit_amount, period, name } = req.body;
    if (!limit_amount || !period)
      return res.status(400).json({ error: 'Monto límite y período son requeridos' });

    const { data, error } = await supabase
      .from('budgets')
      .insert({ user_id: user.id, category_id: category_id || null, name, limit_amount: parseFloat(limit_amount), period })
      .select();

    if (error) return res.status(400).json({ error: error.message });
    res.json({ success: true, budget: data[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/budgets/:id', async (req, res) => {
  try {
    const user = await getUserFromToken(req, res);
    if (!user) return;

    const { error } = await supabase
      .from('budgets')
      .delete()
      .eq('id', req.params.id)
      .eq('user_id', user.id);

    if (error) return res.status(400).json({ error: error.message });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ──────────────────────────────────────────────────────────────────────────────
// METAS
// ──────────────────────────────────────────────────────────────────────────────

app.get('/goals', async (req, res) => {
  try {
    const user = await getUserFromToken(req, res);
    if (!user) return;

    const { data, error } = await supabase
      .from('goals')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false });

    if (error) return res.status(400).json({ error: error.message });
    res.json({ goals: data || [] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/goals', async (req, res) => {
  try {
    const user = await getUserFromToken(req, res);
    if (!user) return;

    const { name, target_amount, current_amount, deadline, icon } = req.body;
    if (!name || !target_amount)
      return res.status(400).json({ error: 'Nombre y monto objetivo son requeridos' });

    const { data, error } = await supabase
      .from('goals')
      .insert({
        user_id: user.id,
        name,
        target_amount: parseFloat(target_amount),
        current_amount: parseFloat(current_amount) || 0,
        deadline: deadline || null,
        icon: icon || '🎯',
      })
      .select();

    if (error) return res.status(400).json({ error: error.message });
    res.json({ success: true, goal: data[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put('/goals/:id', async (req, res) => {
  try {
    const user = await getUserFromToken(req, res);
    if (!user) return;

    const { current_amount } = req.body;

    const { data, error } = await supabase
      .from('goals')
      .update({ current_amount: parseFloat(current_amount) })
      .eq('id', req.params.id)
      .eq('user_id', user.id)
      .select();

    if (error) return res.status(400).json({ error: error.message });
    res.json({ success: true, goal: data[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/goals/:id', async (req, res) => {
  try {
    const user = await getUserFromToken(req, res);
    if (!user) return;

    const { error } = await supabase
      .from('goals')
      .delete()
      .eq('id', req.params.id)
      .eq('user_id', user.id);

    if (error) return res.status(400).json({ error: error.message });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ──────────────────────────────────────────────────────────────────────────────
// EXPORTAR DATOS
// ──────────────────────────────────────────────────────────────────────────────

app.get('/export/json', async (req, res) => {
  try {
    const user = await getUserFromToken(req, res);
    if (!user) return;

    const [accounts, categories, transactions, budgets, goals] = await Promise.all([
      supabase.from('accounts').select('*').eq('user_id', user.id),
      supabase.from('categories').select('*').eq('user_id', user.id),
      supabase.from('transactions').select('*').eq('user_id', user.id),
      supabase.from('budgets').select('*').eq('user_id', user.id),
      supabase.from('goals').select('*').eq('user_id', user.id),
    ]);

    const exported = {
      exportedAt: new Date().toISOString(),
      user: { id: user.id, email: user.email },
      accounts: accounts.data || [],
      categories: categories.data || [],
      transactions: transactions.data || [],
      budgets: budgets.data || [],
      goals: goals.data || [],
    };

    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Content-Disposition', `attachment; filename="flujo-export-${new Date().toISOString().split('T')[0]}.json"`);
    res.json(exported);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ──────────────────────────────────────────────────────────────────────────────
// INICIAR SERVIDOR
// ──────────────────────────────────────────────────────────────────────────────

app.listen(PORT, () => {
  console.log(`✓ FLUJO API Server corriendo en http://localhost:${PORT}`);
  console.log(`✓ Ambiente: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = app;