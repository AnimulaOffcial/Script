// ==============================================================================
// Animula Official — Secure Key System Backend (Node.js + Express)
// Supabase + Roblox Binding + Anti-Bypass
// ==============================================================================

const express = require('express');
const crypto = require('crypto');
const path = require('path');
const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const cors = require('cors');

const app = express();
const PORT = parseInt(process.env.PORT, 10) || 3000;
const IS_PROD = process.env.NODE_ENV === 'production';
const ALLOWED_ORIGIN = process.env.ALLOWED_ORIGIN || (IS_PROD ? '' : '*');
const SECRET = process.env.SECRET;

if (!SECRET) {
  console.error('[FATAL] SECRET env var is required');
  process.exit(1);
}

const SUPABASE_URL = process.env.SUPABASE_URL || '';
const SUPABASE_ANON = process.env.SUPABASE_ANON || '';

if (IS_PROD && (!SUPABASE_URL || !SUPABASE_ANON)) {
  console.error('[FATAL] SUPABASE_URL and SUPABASE_ANON are required in production');
  process.exit(1);
}

let supa = null;
try {
  const { createClient } = require('@supabase/supabase-js');
  // Prefer service_role for server-side writes (bypasses RLS).
  // Fall back to anon only if service_role is not configured (development).
  const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE || SUPABASE_ANON;
  if (SUPABASE_URL && SUPABASE_KEY && SUPABASE_URL.includes('supabase.co')) {
    supa = createClient(SUPABASE_URL, SUPABASE_KEY, {
      auth: { persistSession: false, autoRefreshToken: false }
    });
    console.log('[Supabase] connected (key=' + (process.env.SUPABASE_SERVICE_ROLE ? 'service_role' : 'anon') + ')');
  }
} catch (e) {
  console.warn('[Supabase] not available (npm install @supabase/supabase-js to enable):', e.message);
}

const TOKEN_REGEX = /^[A-Za-z0-9]{50}$/;
const ROBLOX_REGEX = /^[A-Za-z0-9_]{3,20}$/;
const CHARSET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
const TOKEN_REGEX_FS = /^[A-Za-z0-9]{20}$/;

const GENERATE_EXPIRY = 15 * 60 * 1000;
const GETKEY_EXPIRY = 24 * 60 * 60 * 1000;

const store = new Map();
const getkeyIndex = new Map();

// Periodic cleanup of expired entries to prevent unbounded memory growth
setInterval(() => {
  const now = Date.now();
  for (const [tok, rec] of store.entries()) {
    if (now - rec.createdAt > GETKEY_EXPIRY) store.delete(tok);
  }
  for (const [tok, rec] of getkeyIndex.entries()) {
    if (now - rec.createdAt > GETKEY_EXPIRY) getkeyIndex.delete(tok);
  }
}, 5 * 60 * 1000).unref();

// Unbiased random token (rejection sampling) - no modulo bias
function randToken(len = 50) {
  const out = [];
  const bytes = crypto.randomBytes(len * 2);
  let bi = 0;
  while (out.length < len) {
    if (bi >= bytes.length) {
      const more = crypto.randomBytes(len * 2);
      bytes.set(more, bi % bytes.length);
      bi = 0;
      if (bytes.length === 0) break;
    }
    const b = bytes[bi++];
    if (b < 248) out.push(CHARSET[b % CHARSET.length]); // 248 = floor(256/62)*62, reject 248..255
  }
  return out.join('');
}

function randAnimulaKey(plan) {
  if (plan === 'lifetime' || plan === '30d' || plan === '7d') {
    return 'Animula-ps-' + randToken(50);
  }
  return 'Animula-fs-' + randToken(20);
}

function safeEqStr(a, b) {
  if (typeof a !== 'string' || typeof b !== 'string') return false;
  const ab = Buffer.from(a);
  const bb = Buffer.from(b);
  if (ab.length !== bb.length) return false;
  return crypto.timingSafeEqual(ab, bb);
}

function hmac(data) {
  return crypto.createHmac('sha256', SECRET).update(data).digest('hex');
}

function deriveGetToken(generateToken) {
  const hex = hmac(generateToken + '|getkey|v3');
  let out = '';
  for (let i = 0; i < 50; i++) {
    const idx = parseInt(hex.substr((i * 2) % 64, 2), 16) % CHARSET.length;
    const mix = (CHARSET.indexOf(generateToken[i % 50]) + idx) % CHARSET.length;
    out += CHARSET[mix];
  }
  return out;
}

function signReturn(generateToken, questId) {
  return crypto.createHmac('sha256', SECRET).update(generateToken + '|return|' + questId + '|v3').digest('hex').slice(0, 32);
}

function verifyReturn(generateToken, questId, sig) {
  if (!sig || typeof sig !== 'string') return false;
  const expected = signReturn(generateToken, questId);
  if (sig.length !== expected.length) return false;
  return crypto.timingSafeEqual(Buffer.from(sig), Buffer.from(expected));
}

app.set('trust proxy', 1);

app.use(helmet({
  contentSecurityPolicy: {
    useDefaults: true,
    directives: {
      'default-src': ["'self'"],
      'script-src': ["'self'", "'unsafe-inline'", 'https://cdn.tailwindcss.com', 'https://unpkg.com', 'https://cdn.jsdelivr.net'],
      'style-src': ["'self'", "'unsafe-inline'", 'https://fonts.googleapis.com', 'https://cdn.jsdelivr.net'],
      'font-src': ["'self'", 'https://fonts.gstatic.com', 'https://cdn.jsdelivr.net', 'data:'],
      'img-src': ["'self'", 'data:', 'https:', 'blob:'],
      'connect-src': ["'self'", 'https://users.roproxy.com', 'https://thumbnails.roproxy.com', 'https://eiykqbkfljqxwfqdffpo.supabase.co', 'https://creators.lootlabs.gg'],
      'frame-ancestors': ["'none'"],
      'base-uri': ["'self'"],
    }
  },
  crossOriginEmbedderPolicy: false,
  referrerPolicy: { policy: 'strict-origin-when-cross-origin' },
  hsts: IS_PROD ? { maxAge: 31536000, includeSubDomains: true, preload: true } : false
}));

app.use(cors({
  origin: (origin, cb) => {
    if (!origin) return cb(null, true);
    if (ALLOWED_ORIGIN === '*') return cb(null, true);
    if (ALLOWED_ORIGIN && origin === ALLOWED_ORIGIN) return cb(null, true);
    return cb(new Error('CORS blocked'));
  },
  methods: ['GET', 'POST'],
  allowedHeaders: ['Content-Type'],
  maxAge: 600
}));

app.use(express.json({ limit: '64kb' }));
app.use(express.urlencoded({ extended: true, limit: '64kb' }));

// Rate limiters
const globalLimiter = rateLimit({ windowMs: 60 * 1000, max: 60, standardHeaders: true, legacyHeaders: false, message: { ok: false, error: 'RATE_LIMITED' } });
app.use(globalLimiter);

const generateLimiter = rateLimit({ windowMs: 60 * 1000, max: 6, standardHeaders: true, legacyHeaders: false, message: { ok: false, error: 'RATE_LIMITED', msg: 'Rate limit 6/min' } });
const paymentLimiter  = rateLimit({ windowMs: 60 * 1000, max: 3, standardHeaders: true, legacyHeaders: false, message: { ok: false, error: 'RATE_LIMITED', msg: 'Payment rate limit 3/min' } });
const robloxLimiter   = rateLimit({ windowMs: 60 * 1000, max: 20, standardHeaders: true, legacyHeaders: false, message: { ok: false, error: 'RATE_LIMITED', msg: 'Rate limit 20/min' } });
const lootLimiter     = rateLimit({ windowMs: 60 * 1000, max: 20, standardHeaders: true, legacyHeaders: false, message: { ok: false, error: 'RATE_LIMITED', msg: 'Rate limit 20/min' } });

app.use(express.static(path.join(__dirname)));

// ==============================================================================
// API: Roblox Proxy (Avatar & Profile)
// ==============================================================================
app.get('/api/roblox/user/:username', robloxLimiter, async (req, res) => {
  const username = (req.params.username || '').trim();
  if (!ROBLOX_REGEX.test(username)) {
    return res.status(400).json({ ok: false, error: 'INVALID_USERNAME' });
  }

  try {
    // Use roproxy for CORS-friendly requests
    let r = await fetch('https://users.roproxy.com/v1/usernames/users', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ usernames: [username], excludeBannedUsers: false })
    });
    let data = await r.json();

    // Retry with official Roblox API if roproxy returned empty or errored
    if (!data.data || data.data.length === 0) {
      try {
        const r2 = await fetch('https://users.roblox.com/v1/usernames/users', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ usernames: [username], excludeBannedUsers: false })
        });
        const d2 = await r2.json();
        if (d2.data && d2.data.length > 0) data = d2;
      } catch {}
    }

    if (!data.data || data.data.length === 0) {
      return res.status(404).json({ ok: false, error: 'NOT_FOUND', msg: 'Roblox user not found' });
    }

    const user = data.data[0];
    let avatar = `https://www.roblox.com/headshot/thumb?userId=${user.id}&width=150&height=150&format=png`;

    try {
      const ar = await fetch(`https://thumbnails.roproxy.com/v1/users/avatar?userIds=${user.id}&size=150x150&format=Png&isCircular=true`);
      const aj = await ar.json();
      if (aj.data && aj.data[0] && aj.data[0].imageUrl) avatar = aj.data[0].imageUrl;
    } catch {}

    let detail = {};
    try {
      const dr = await fetch(`https://users.roproxy.com/v1/users/${user.id}`);
      detail = await dr.json();
    } catch {}

    res.json({
      ok: true,
      id: user.id,
      username: user.name,
      displayName: user.displayName || detail.displayName || user.name,
      avatar,
      description: detail.description || '',
      created: detail.created || '',
      isBanned: detail.isBanned || false
    });
  } catch (e) {
    console.error('Roblox fetch error', e);
    res.status(500).json({ ok: false, error: 'ROBLOX_API_ERROR' });
  }
});

// ==============================================================================
// LootLabs API (Content Locker & URL Encryption)
// ==============================================================================
const LOOTLABS_TOKEN = process.env.LOOTLABS_TOKEN || '';
const LOOTLABS_QUESTS = {
  animula_main: { title: 'Animula - Get Key', tier_id: 4, number_of_tasks: 3, theme: 3, desc: 'Maximum Profit • 3 steps' },
  animula_alt: { title: 'Animula - Alternative', tier_id: 3, number_of_tasks: 3, theme: 3, desc: 'Profit Maximization • 3 steps' }
};

app.post('/api/lootlabs/create', lootLimiter, async (req, res) => {
  const { destination, questId, title, tier_id, number_of_tasks } = req.body;
  if (!destination) return res.status(400).json({ ok: false, error: 'DESTINATION_REQUIRED' });

  const q = LOOTLABS_QUESTS[questId] || LOOTLABS_QUESTS.animula_main;
  const finalTitle = title || q.title;
  const finalTier = tier_id || q.tier_id;
  const finalTasks = number_of_tasks || q.number_of_tasks;

  // If no real token configured, simulate locally
  if (!LOOTLABS_TOKEN || LOOTLABS_TOKEN.includes('YOUR_')) {
    const fakeId = crypto.randomBytes(4).toString('hex');
    const fakeUrl = `https://lootdest.org/s/${fakeId}?dest=${encodeURIComponent(destination)}`;
    console.log(`[LootLabs SIMULATE] ${q.title} -> ${fakeUrl} (no API token)`);
    return res.json({ ok: true, url: fakeUrl, mode: 'simulate', quest: q });
  }

  try {
    const r = await fetch('https://creators.lootlabs.gg/api/public/content_locker', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${LOOTLABS_TOKEN}` },
      body: JSON.stringify({
        title: finalTitle,
        url: destination,
        tier_id: finalTier,
        number_of_tasks: finalTasks,
        theme: q.theme,
        thumbnail: 'https://raw.githubusercontent.com/AnimulaOffcial/UI/main/logo.png'
      })
    });

    const j = await r.json();
    if (j && typeof j.message === 'string' && j.message.includes('Unauthorized')) {
      return res.status(401).json({ ok: false, error: 'LOOTLABS_UNAUTHORIZED', msg: 'Invalid LootLabs API token' });
    }

    let lootUrl = j.url || j.link || j.data?.url;
    if (!lootUrl && Array.isArray(j.message) && j.message[0]?.loot_url) {
      lootUrl = j.message[0].loot_url;
    } else if (!lootUrl && j.message && typeof j.message === 'object' && j.message.loot_url) {
      lootUrl = j.message.loot_url;
    }

    if (!lootUrl) {
      console.warn('LootLabs create unexpected response', j);
      return res.json({ ok: true, url: `https://lootdest.org/s/${crypto.randomBytes(4).toString('hex')}`, mode: 'fallback', raw: j });
    }

    console.log(`[LootLabs CREATE] ${q.title} tier ${finalTier} tasks ${finalTasks} -> ${lootUrl} (live)`);
    return res.json({ ok: true, url: lootUrl, mode: 'live', quest: q, raw: j });
  } catch (e) {
    console.error('LootLabs create error', e);
    return res.json({ ok: true, url: `https://lootdest.org/s/${crypto.randomBytes(4).toString('hex')}`, mode: 'fallback', error: e.message });
  }
});

app.post('/api/lootlabs/encrypt', lootLimiter, async (req, res) => {
  const { destination_url } = req.body;
  if (!destination_url) return res.status(400).json({ ok: false, error: 'DESTINATION_REQUIRED' });

  if (!LOOTLABS_TOKEN || LOOTLABS_TOKEN.includes('YOUR_')) {
    const fakeEnc = Buffer.from(destination_url).toString('base64').slice(0, 24);
    return res.json({ ok: true, encrypted: fakeEnc, mode: 'simulate' });
  }

  try {
    const r = await fetch('https://creators.lootlabs.gg/api/public/url_encryptor', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${LOOTLABS_TOKEN}` },
      body: JSON.stringify({ destination_url, api_token: LOOTLABS_TOKEN })
    });

    const j = await r.json();
    let enc = j.encrypted || j.data || j.url;
    if (!enc && typeof j.message === 'string' && j.message.length > 20) enc = j.message;
    else if (!enc && Array.isArray(j.message) && j.message[0]) enc = j.message[0].encrypted || j.message[0];

    if (!enc || typeof enc !== 'string' || enc.length < 10) {
      return res.json({ ok: true, encrypted: Buffer.from(destination_url).toString('base64').slice(0, 24), mode: 'fallback', raw: j });
    }

    console.log(`[LootLabs ENCRYPT] ${destination_url} -> ${enc.slice(0, 16)}... (live)`);
    return res.json({ ok: true, encrypted: enc, mode: 'live', raw: j });
  } catch (e) {
    console.error('LootLabs encrypt error', e);
    return res.json({ ok: true, encrypted: Buffer.from(destination_url).toString('base64').slice(0, 24), mode: 'simulate' });
  }
});

// ==============================================================================
// Key Generation & Lifecycle Endpoints
// ==============================================================================
app.post('/api/shop/generate', generateLimiter, async (req, res) => {
  const plan = (req.body.plan || 'standard').toString().slice(0, 20);
  const roblox = req.body.roblox;

  if (!roblox || !roblox.username || !roblox.id) {
    return res.status(400).json({ ok: false, error: 'ROBLOX_REQUIRED', msg: 'Roblox username required (max 1 per key)' });
  }
  if (!ROBLOX_REGEX.test(roblox.username)) {
    return res.status(400).json({ ok: false, error: 'INVALID_USERNAME' });
  }

  const rid = Number(roblox.id);
  if (!rid || rid < 1) {
    return res.status(400).json({ ok: false, error: 'INVALID_ROBLOX_ID' });
  }

  // Max 1 active key per roblox id (check memory)
  for (const [tok, rec] of store.entries()) {
    if (
      rec.roblox &&
      rec.roblox.id === rid &&
      !rec.claimed &&
      (rec.state === 'LOOT_COMPLETED' || rec.state === 'CLAIMED') &&
      (
        rec.plan === 'lifetime' ||
        (rec.plan === '7d' && Date.now() - rec.lootCompletedAt < 7 * 24 * 60 * 60 * 1000) ||
        (rec.plan === '30d' && Date.now() - rec.lootCompletedAt < 30 * 24 * 60 * 60 * 1000) ||
        (Date.now() - rec.lootCompletedAt < 24 * 60 * 60 * 1000)
      )
    ) {
      return res.status(429).json({ ok: false, error: 'ROBLOX_MAX1', msg: `Account @${roblox.username} already has active key (max 1)` });
    }
  }

  // Check Supabase if available
  if (supa) {
    try {
      const { data, error } = await supa
        .from('animula_keys')
        .select('id')
        .eq('roblox_id', rid)
        .in('state', ['LOOT_COMPLETED', 'CLAIMED'])
        .or('is_unlimited.eq.true,key_expires_at.gt.' + new Date().toISOString())
        .limit(1);

      if (error) {
        if (error.code === 'PGRST205' || error.message.includes('Could not find the table') || error.message.includes('does not exist')) {
          console.warn('Supabase table missing - run supabase.sql at https://supabase.com/dashboard/project/eiykqbkfljqxwfqdffpo/sql');
        } else {
          console.warn('Supabase check error', error.message);
        }
      } else if (data && data.length > 0) {
        return res.status(429).json({ ok: false, error: 'ROBLOX_MAX1', msg: `Account @${roblox.username} already has active key in Supabase (max 1)` });
      }
    } catch (e) {
      console.warn('Supabase check catch', e.message);
    }
  }

  const token = randToken(50);
  const now = Date.now();
  const rec = {
    type: 'generate',
    plan,
    state: 'CREATED',
    createdAt: now,
    lootStartedAt: 0,
    lootCompletedAt: 0,
    expiresAt: now + GENERATE_EXPIRY,
    getToken: null,
    animulaKey: null,
    claimed: false,
    roblox: {
      id: rid,
      username: roblox.username,
      displayName: roblox.displayName || roblox.username,
      avatar: roblox.avatar || '',
      created: roblox.created || ''
    },
    ip: req.ip,
    ua: (req.headers['user-agent'] || '').slice(0, 120)
  };
  store.set(token, rec);

  // Insert into Supabase
  if (supa) {
    try {
      const nowIso = new Date().toISOString();
      const expiresIso = new Date(now + GENERATE_EXPIRY).toISOString();
      const getExpiresIso = new Date(now + GETKEY_EXPIRY).toISOString();
      const { error } = await supa.from('animula_keys').insert({
        token,
        plan,
        state: 'CREATED',
        roblox_username: roblox.username,
        roblox_id: rid,
        roblox_display_name: roblox.displayName || roblox.username,
        roblox_avatar: roblox.avatar || '',
        created_at: nowIso,
        expires_at: expiresIso,
        get_expires_at: getExpiresIso,
        claimed: false
      });

      if (error) {
        if (error.message && error.message.includes('already has an active key')) {
          store.delete(token);
          return res.status(429).json({ ok: false, error: 'ROBLOX_MAX1', msg: error.message });
        }
        if (error.code === 'PGRST205' || error.message.includes('Could not find the table') || error.message.includes('does not exist')) {
          console.warn('Supabase table missing - run supabase.sql at https://supabase.com/dashboard/project/eiykqbkfljqxwfqdffpo/sql (fallback to local)');
        } else {
          console.warn('Supabase insert warn', error.message);
        }
      }
    } catch (e) {
      console.warn('Supabase insert catch', e.message);
    }
  }

  console.log(`[GEN] ${token.slice(0, 8)}... plan=${plan} roblox=@${roblox.username} id=${rid} ip=${req.ip}`);
  res.json({
    ok: true,
    token,
    url: `/generetekey/${token}`,
    expiresIn: GENERATE_EXPIRY,
    roblox: rec.roblox,
    mode: supa ? 'supabase' : 'local'
  });
});

app.get('/api/generetekey/:token/validate', (req, res) => {
  const token = req.params.token;
  if (!TOKEN_REGEX.test(token)) return res.status(400).json({ ok: false, error: 'FORMAT_INVALID' });

  const rec = store.get(token);
  if (!rec || rec.type !== 'generate') return res.status(404).json({ ok: false, error: 'NOT_FOUND' });

  if (Date.now() - rec.createdAt > GENERATE_EXPIRY && rec.state === 'CREATED') {
    store.delete(token);
    return res.status(410).json({ ok: false, error: 'EXPIRED' });
  }

  if (rec.claimed) return res.status(410).json({ ok: false, error: 'ALREADY_CLAIMED' });

  res.json({
    ok: true,
    state: rec.state,
    plan: rec.plan,
    createdAt: rec.createdAt,
    roblox: rec.roblox,
    expiresAt: rec.expiresAt
  });
});

app.post('/api/generetekey/:token/start', (req, res) => {
  const token = req.params.token;
  const rec = store.get(token);
  if (!rec) return res.status(404).json({ ok: false, error: 'NOT_FOUND' });

  rec.state = 'LOOT_STARTED';
  rec.lootStartedAt = Date.now();
  store.set(token, rec);

  if (supa) {
    supa.from('animula_keys').update({ state: 'LOOT_STARTED', loot_started_at: new Date().toISOString() }).eq('token', token).then(() => {});
  }

  res.json({ ok: true });
});

app.post('/api/generetekey/:token/complete', async (req, res) => {
  const token = req.params.token;
  if (!TOKEN_REGEX.test(token)) return res.status(400).json({ ok: false, error: 'FORMAT_INVALID' });

  const rec = store.get(token);
  if (!rec || rec.type !== 'generate') return res.status(404).json({ ok: false, error: 'NOT_FOUND' });
  if (rec.state !== 'LOOT_STARTED' && rec.state !== 'CREATED') return res.status(400).json({ ok: false, error: 'STATE_INVALID' });

  // Free plan (24h) requires both quests completed via LootLabs return detection
  const isPaid = rec.plan === '7d' || rec.plan === '30d' || rec.plan === 'lifetime';
  if (!isPaid) {
    if (!rec.quests || !rec.quests['animula_main']?.completedAt || !rec.quests['animula_alt']?.completedAt) {
      return res.status(400).json({ ok: false, error: 'QUEST_REQUIRED', msg: 'Complete Quest 1 and Quest 2 via LootLabs first' });
    }
  }

  if (rec.getToken) return res.json({ ok: true, getToken: rec.getToken, animulaKey: rec.animulaKey, roblox: rec.roblox });

  const getToken = deriveGetToken(token);
  const animulaKey = randAnimulaKey(rec.plan);

  rec.state = 'LOOT_COMPLETED';
  rec.lootCompletedAt = Date.now();
  rec.getToken = getToken;
  rec.animulaKey = animulaKey;
  rec.getCreatedAt = Date.now();
  store.set(token, rec);

  getkeyIndex.set(getToken, {
    generateToken: token,
    animulaKey,
    createdAt: Date.now(),
    claimed: false,
    roblox: rec.roblox
  });

  if (supa) {
    try {
      await supa.from('animula_keys').update({
        get_token: getToken,
        animula_key: animulaKey,
        state: 'LOOT_COMPLETED',
        loot_completed_at: new Date().toISOString()
      }).eq('token', token);
    } catch {}
  }

  console.log(`[COMPLETE] ${token.slice(0, 8)} -> ${getToken.slice(0, 8)} roblox=@${rec.roblox?.username} key=${animulaKey} ps=${animulaKey.startsWith('Animula-ps-') ? 'ps50' : 'fs20'}`);
  res.json({ ok: true, getToken, animulaKey, url: `https://getkey.animula.wtf/getkey/${getToken}`, roblox: rec.roblox });
});

// LootLabs quest progress — issue signed return URL so only real LootLabs completion can mark done
app.post('/api/generetekey/:token/loot-progress', (req, res) => {
  const token = req.params.token;
  const { questId } = req.body;

  if (!TOKEN_REGEX.test(token)) return res.status(400).json({ ok: false, error: 'FORMAT_INVALID' });
  const rec = store.get(token);
  if (!rec) return res.status(404).json({ ok: false, error: 'NOT_FOUND' });

  const validQuests = ['animula_main', 'animula_alt'];
  if (!validQuests.includes(questId)) return res.status(400).json({ ok: false, error: 'INVALID_QUEST' });

  if (!rec.quests) rec.quests = {};
  if (!rec.quests[questId]) rec.quests[questId] = { startedAt: Date.now(), completedAt: 0, sig: null };

  if (rec.quests[questId].completedAt) {
    return res.json({ ok: true, questId, alreadyCompleted: true, sig: rec.quests[questId].sig });
  }

  rec.quests[questId].startedAt = Date.now();
  rec.quests[questId].sig = signReturn(token, questId);
  store.set(token, rec);

  res.json({ ok: true, questId, sig: rec.quests[questId].sig });
});

// LootLabs return callback — frontend calls this when getkey page is hit with a valid ?sig=
app.post('/api/generetekey/:token/return', (req, res) => {
  const token = req.params.token;
  const { questId, sig } = req.body;

  if (!TOKEN_REGEX.test(token)) return res.status(400).json({ ok: false, error: 'FORMAT_INVALID' });
  const rec = store.get(token);
  if (!rec) return res.status(404).json({ ok: false, error: 'NOT_FOUND', msg: 'Token not found' });

  const validQuests = ['animula_main', 'animula_alt'];
  if (!validQuests.includes(questId)) return res.status(400).json({ ok: false, error: 'INVALID_QUEST' });

  if (!rec.quests || !rec.quests[questId] || !rec.quests[questId].sig) {
    return res.status(400).json({ ok: false, error: 'NOT_STARTED', msg: 'Start the quest first' });
  }

  if (!verifyReturn(token, questId, sig)) {
    return res.status(403).json({ ok: false, error: 'BAD_SIGNATURE', msg: 'Invalid return signature (LootLabs return not detected)' });
  }

  // Quest 2 requires Quest 1 completed
  if (questId === 'animula_alt') {
    const q1 = rec.quests['animula_main'];
    if (!q1 || !q1.completedAt) return res.status(400).json({ ok: false, error: 'QUEST1_REQUIRED', msg: 'Complete Quest 1 first' });
  }

  rec.quests[questId].completedAt = Date.now();
  store.set(token, rec);

  if (rec.quests['animula_main']?.completedAt && rec.quests['animula_alt']?.completedAt) {
    rec.state = 'LOOT_COMPLETED';
    store.set(token, rec);
  }

  res.json({ ok: true, questId });
});

// Backward compat: verify-quest requires a valid sig
app.post('/api/generetekey/:token/verify-quest', (req, res) => {
  const token = req.params.token;
  const { questId, sig } = req.body;

  if (!TOKEN_REGEX.test(token)) return res.status(400).json({ ok: false, error: 'FORMAT_INVALID' });
  const rec = store.get(token);
  if (!rec) return res.status(404).json({ ok: false, error: 'NOT_FOUND', msg: 'Token not found' });

  const validQuests = ['animula_main', 'animula_alt'];
  if (!validQuests.includes(questId)) return res.status(400).json({ ok: false, error: 'INVALID_QUEST' });

  if (!rec.quests || !rec.quests[questId] || !rec.quests[questId].sig) {
    return res.status(400).json({
      ok: false,
      error: 'NOT_STARTED',
      msg: questId === 'animula_alt' ? 'Complete Quest 1 first' : 'Start the quest first'
    });
  }

  if (!verifyReturn(token, questId, sig)) {
    return res.status(403).json({ ok: false, error: 'BAD_SIGNATURE', msg: 'LootLabs return not detected - complete the LootLabs page first' });
  }

  if (questId === 'animula_alt') {
    const q1 = rec.quests['animula_main'];
    if (!q1 || !q1.completedAt) return res.status(400).json({ ok: false, error: 'QUEST1_REQUIRED', msg: 'Complete Quest 1 first' });
  }

  rec.quests[questId].completedAt = Date.now();
  store.set(token, rec);

  if (rec.quests['animula_main']?.completedAt && rec.quests['animula_alt']?.completedAt) {
    rec.state = 'LOOT_COMPLETED';
    store.set(token, rec);
  }

  res.json({ ok: true, questId });
});

// ==============================================================================
// Payment Verification Endpoint (PS Premium Keys)
// ==============================================================================
app.post('/api/payment/verify', paymentLimiter, async (req, res) => {
  const { method, plan, roblox, txProof } = req.body;

  if (!roblox || !roblox.id) return res.status(400).json({ ok: false, error: 'ROBLOX_REQUIRED' });
  if (!ROBLOX_REGEX.test(roblox.username || '')) return res.status(400).json({ ok: false, error: 'INVALID_USERNAME' });

  const rid = Number(roblox.id);
  if (!rid || rid < 1) return res.status(400).json({ ok: false, error: 'INVALID_ROBLOX_ID' });

  const validMethods = ['btc', 'eth', 'paypal', 'usdt', 'etc'];
  const m = (method || '').toLowerCase();
  if (!validMethods.includes(m)) return res.status(400).json({ ok: false, error: 'INVALID_METHOD' });
  if (!['7d', '30d', 'lifetime'].includes(plan)) return res.status(400).json({ ok: false, error: 'INVALID_PLAN' });

  if (process.env.ENABLE_PAYMENT_VERIFY !== 'true') {
    return res.status(501).json({
      ok: false,
      error: 'PAYMENT_VERIFY_DISABLED',
      msg: 'Payment verification is not enabled. Set ENABLE_PAYMENT_VERIFY=true and configure verification logic.'
    });
  }

  if (!txProof || typeof txProof !== 'string' || txProof.length < 10) {
    console.warn(`[PAYMENT] refused no-proof method=${m} plan=${plan} roblox=@${roblox.username} id=${rid} ip=${req.ip}`);
    return res.status(402).json({ ok: false, error: 'PAYMENT_PROOF_REQUIRED', msg: 'Provide valid txProof.' });
  }

  console.log(`[PAYMENT-PENDING] method=${m} plan=${plan} roblox=@${roblox.username} id=${rid} proof=${txProof.slice(0, 32)} ip=${req.ip}`);
  res.json({ ok: true, verified: false, pending: true, msg: 'Payment recorded. Manual verification required.' });
});

// ==============================================================================
// GetKey Page Endpoints
// ==============================================================================
app.get('/api/getkey/:token/validate', (req, res) => {
  const token = req.params.token;
  if (!TOKEN_REGEX.test(token)) return res.status(400).json({ ok: false, error: 'FORMAT_INVALID' });

  if (store.has(token) && store.get(token).type === 'generate') {
    console.warn(`[BYPASS] generate as getkey ip=${req.ip}`);
    return res.status(403).json({ ok: false, error: 'BYPASS_DETECTED', msg: 'Bypass detected!' });
  }

  const rec = getkeyIndex.get(token);
  if (!rec) return res.status(404).json({ ok: false, error: 'NOT_FOUND' });

  if (Date.now() - rec.createdAt > GETKEY_EXPIRY) {
    getkeyIndex.delete(token);
    return res.status(410).json({ ok: false, error: 'EXPIRED' });
  }

  if (rec.claimed) return res.status(410).json({ ok: false, error: 'ALREADY_CLAIMED' });

  const genRec = store.get(rec.generateToken);
  if (!genRec || genRec.state !== 'LOOT_COMPLETED' || genRec.getToken !== token) {
    return res.status(403).json({ ok: false, error: 'BYPASS_DETECTED' });
  }

  res.json({
    ok: true,
    animulaKey: rec.animulaKey,
    generateToken: rec.generateToken,
    roblox: rec.roblox
  });
});

app.post('/api/getkey/:token/claim', (req, res) => {
  const token = req.params.token;
  const rec = getkeyIndex.get(token);
  if (!rec) return res.status(404).json({ ok: false, error: 'NOT_FOUND' });
  if (rec.claimed) return res.status(410).json({ ok: false, error: 'ALREADY_CLAIMED' });

  rec.claimed = true;
  getkeyIndex.set(token, rec);

  const genRec = store.get(rec.generateToken);
  if (genRec) {
    genRec.claimed = true;
    genRec.state = 'CLAIMED';
    store.set(rec.generateToken, genRec);
  }

  if (supa) {
    supa.from('animula_keys').update({
      claimed: true,
      claimed_at: new Date().toISOString(),
      state: 'CLAIMED'
    }).eq('get_token', token).then(() => {});
  }

  res.json({ ok: true, animulaKey: rec.animulaKey, roblox: rec.roblox });
});

// ==============================================================================
// Debug / Health / SPA Routes
// ==============================================================================
app.get('/api/debug/stats', (req, res) => {
  if (IS_PROD) return res.status(404).json({ ok: false, error: 'NOT_FOUND' });
  res.json({
    generateCount: store.size,
    getkeyCount: getkeyIndex.size,
    uptime: process.uptime(),
    supabase: !!supa
  });
});

// Serve Single Page App
app.get(/^\/(?!api\/).*/, (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

// Error handling middleware
app.use((err, req, res, next) => {
  if (err && err.message === 'CORS blocked') {
    return res.status(403).json({ ok: false, error: 'CORS_BLOCKED' });
  }
  console.error(err);
  res.status(500).json({ ok: false, error: 'INTERNAL' });
});

app.listen(PORT, () => {
  console.log(`Animula Secure Server running at http://localhost:${PORT} [Supabase: ${!!supa}, Prod: ${IS_PROD}]`);
});
