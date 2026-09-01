# LootLabs — Animula Link to Get Key

Folder di paling depan untuk LootLabs. 2 quest, 3 step, Maximum Profit, nama Animula link ke getkey.

## Config
- `config.json` — API token + 2 quests (tier 4 Maximum Profit & tier 3 Profit Maximization, both 3 tasks)
- `query/` — contoh request/response

## Cara pakai
1. Buat API key di https://creators.lootlabs.gg → Profile → API Key → Generate
2. Paste ke `config.json` `api_token`
3. Web `Shop → Generate` akan auto buat LootLabs link via `POST /api/public/content_locker` dengan `title: Animula - Get Key`, `url: https://animula.wtf/getkey/{token}`, `tier_id: 4`, `number_of_tasks: 3`
4. Server `POST /api/lootlabs/create` dan `POST /api/lootlabs/encrypt` handle anti-bypass `&data=` AES-256

## API
- Create: `POST https://creators.lootlabs.gg/api/public/content_locker` `{title, url, tier_id:4, number_of_tasks:3}`
- Encrypt (anti-bypass): `POST https://creators.lootlabs.gg/api/public/url_encryptor` `{destination_url, api_token}` → `&data=ENCRYPTED`

Kalau `api_token` masih `YOUR_...`, Web fallback ke **simulate** 7s timer (tidak error).
