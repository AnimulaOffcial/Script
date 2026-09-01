# Animula Official — Web Key System (Anti-Bypass)

> `/` info script, `/shop` jual key, `/generetekey/XXXX...50` → LootBoost, `/getkey/YYYY...50` → `Animula-fs-XXXX...20`

## Fitur Keamanan (paling penting — anti bypass)
- **Token 50 char** `[A-Za-z0-9]` via `crypto.getRandomValues` / `crypto.randomBytes` (bukan Math.random)
- **HMAC-SHA256 bind**: `getToken = HMAC(SECRET, generateToken + "|getkey|v3")` → 50 char base62. Tidak bisa tebak / forge.
- **State machine**: `CREATED → LOOT_STARTED → LOOT_COMPLETED → CLAIMED`. `/getkey` cek state `LOOT_COMPLETED` + HMAC match. Direct `/getkey` tanpa loot → `BYPASS_DETECTED`.
- **Generate ≠ GetKey**: validasi terpisah, kalau pakai generate token sebagai getkey langsung block.
- **Expiry**: Generate 15 menit, GetKey 24 jam.
- **One-time claim**: setelah claim, token hangus.
- **Rate limit**: 6 req/menit, block 2 menit jika bruteforce. Server: express-rate-limit, client: localStorage sliding window.
- **Integrity**: client DB `SHA256(JSON + SECRET)` cek tampering setiap load + interval 7s. Tamper → wipe.
- **Anti too-fast**: LootBoost minimal 5 detik, anti instant bypass.
- **No leak**: error messages tidak expose SECRET / internal.

## Struktur
```
Web/
  index.html   # SPA premium (Home, Shop, Generate, GetKey) — standalone anti-bypass
  server.js    # Express backend validasi server-side (production)
  package.json
  vercel.json  # SPA rewrite untuk Vercel
  .htaccess    # SPA rewrite untuk Apache/cPanel
```

## Jalankan

### Opsi A — Static only (tanpa server, pakai localStorage HMAC)
Buka langsung `index.html` via Live Server / `npx serve Web`.

### Opsi B — Dengan Node backend (lebih aman, server-side HMAC)
```bash
cd Web
npm install
npm start
# http://localhost:3000
```
API:
- `POST /api/shop/generate {plan}` → `{token, url}`
- `GET  /api/generetekey/:token/validate`
- `POST /api/generetekey/:token/complete` → `{getToken, animulaKey}`
- `GET  /api/getkey/:token/validate` → `{animulaKey}`
- `POST /api/getkey/:token/claim`

Untuk Supabase (Information.txt): ganti `store` Map dengan `supabase.from('keys')`.

## Deploy
- **Vercel**: push, vercel.json sudah handle SPA. Untuk backend, deploy sebagai Node atau pisah API.
- **cPanel**: upload `index.html` + `.htaccess`.
- **Cloudflare Pages**: set `_redirects` : `/* /index.html 200`.

## UI
Tailwind CDN, Ocean theme (Furina), glass, glow-border, responsive, copy buttons, toast, progress, LootBoost simulasi.

## Celah yang sudah di-patch
| Celah | Patch |
|-------|-------|
| Brute force token | Rate limit + 62^50 entropy |
| Forge getToken | HMAC-SHA256 secret server |
| Direct /getkey bypass | State check LOOT_COMPLETED |
| LocalStorage edit | SHA256 integrity |
| Instant complete | 5s minimal + 7s timer |
| Replay claim | One-time flag |
| XSS / iframe | Helmet + CSP |
