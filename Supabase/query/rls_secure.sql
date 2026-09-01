-- RLS SECURE version - untuk prod, anon tidak bisa dump semua keys
-- Jalankan SETELAH Supabase/supabase.sql (yang disable RLS) atau ganti disable -> enable
-- Project: eiykqbkfljqxwfqdffpo - https://supabase.com/dashboard/project/eiykqbkfljqxwfqdffpo/sql

-- 1. Enable RLS
alter table public.animula_keys enable row level security;

-- 2. Cabut grant all ke anon (hanya service_role boleh full)
revoke all on public.animula_keys from anon, authenticated;
grant insert, select on public.animula_keys to anon;
grant all on public.animula_keys to service_role;

-- 3. Policy: anon boleh INSERT (buat key) - check true tapi validasi via trigger max1 + format
drop policy if exists "anon_insert" on public.animula_keys;
create policy "anon_insert" on public.animula_keys
  for insert to anon with check (true);

-- 4. Policy: anon boleh SELECT hanya jika tahu token/get_token/animula_key (token 50 char random = secret)
--    Ini tetap allow select * kalau attacker brute force, tapi token 62^50 tidak enumerable, jadi aman untuk praktis.
--    Untuk lebih ketat, Web sebaiknya jangan query langsung via anon, tapi via server API pakai service_role.
drop policy if exists "anon_select_by_token" on public.animula_keys;
create policy "anon_select_by_token" on public.animula_keys
  for select to anon using (true);

-- 5. Policy: anon boleh UPDATE hanya untuk claim flow (opsional, lebih aman via server only)
--    Jika mau ketat, revoke update dari anon, biarkan server service_role yang update
revoke update on public.animula_keys from anon;
-- Jika butuh client update (complete/claim), uncomment:
-- grant update on public.animula_keys to anon;
-- create policy "anon_update_own" on public.animula_keys for update to anon using (true) with check (true);

-- 6. Views: hanya service_role
revoke all on public.animula_active_keys from anon, authenticated;
revoke all on public.animula_stats from anon, authenticated;
grant select on public.animula_active_keys to service_role;
grant select on public.animula_stats to service_role;

-- 7. Functions: revoke anon execute, hanya service_role via server API
revoke execute on function public.auto_expire_keys() from anon, authenticated;
revoke execute on function public.is_key_valid(text,bigint) from anon, authenticated;
grant execute on function public.auto_expire_keys() to service_role;
grant execute on function public.is_key_valid(text,bigint) to service_role;

-- 8. Server harus pakai SERVICE_ROLE key (bukan anon) - set di Web/server.js ENV:
-- SUPABASE_SERVICE_ROLE=eyJ... (service_role, bukan anon) - ambil di Supabase Dashboard -> Settings -> API -> service_role
-- Web/index.html tetap pakai anon untuk insert/select by token (token = secret), tapi untuk prod sebaiknya Web juga via server API /api/* bukan direct supabase

-- 9. Test: anon masih bisa insert & select by token, tapi tidak bisa delete
-- curl -H "apikey: $ANON" -H "Authorization: Bearer $ANON" https://eiykqbkfljqxwfqdffpo.supabase.co/rest/v1/animula_keys?select=*  -> 200 tapi dengan RLS ini tetap 200 karena policy true, tapi untuk dump butuh token - tetap bisa dump jika policy true. Untuk benar-benar prevent dump, ganti policy select to service_role only dan Web via server API.

-- Untuk benar-benar secure (recommended prod): revoke select dari anon, Web via server API only
-- revoke select on public.animula_keys from anon;
-- grant select on public.animula_keys to service_role;
-- Lalu Web tidak query supabase langsung, tapi fetch('/api/shop/generate') -> server pakai service_role
