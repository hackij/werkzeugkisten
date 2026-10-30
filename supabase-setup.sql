-- ============================================================
-- Werkzeugkisten Spengler – Datenbank einrichten
-- In Supabase: links "SQL Editor" → "New query" → alles einfügen → "Run"
-- WICHTIG: Ganz unten die Lehrkraft-PIN ändern!
-- ============================================================

-- Aktueller Bestand: eine Zeile pro Kiste und Werkzeug
create table if not exists public.bestand (
  kiste      int  not null,
  werkzeug   int  not null,
  status     text not null check (status in ('ok','fehlt','mehr')),
  anzahl     int  not null default 0,
  klasse     text,
  phase      text,
  updated_at timestamptz not null default now(),
  primary key (kiste, werkzeug)
);

-- Chronik: jede Kontrolle, jeder Tausch, jede Lehrkraft-Korrektur
create table if not exists public.meldungen (
  id         bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  kiste      int  not null,
  klasse     text,
  phase      text,
  art        text not null check (art in ('kontrolle','tausch','lehrer')),
  fehlt      int[] default '{}',
  mehr       jsonb default '[]',
  werkzeug   int,
  partner    int
);

-- Einstellungen (Lehrkraft-PIN) – für Schüler unsichtbar
create table if not exists public.einstellungen (
  schluessel text primary key,
  wert       text not null
);

-- Zugriffsregeln: Schüler dürfen lesen und melden, aber nichts löschen
alter table public.bestand       enable row level security;
alter table public.meldungen     enable row level security;
alter table public.einstellungen enable row level security;

drop policy if exists "bestand lesen"     on public.bestand;
drop policy if exists "bestand melden"    on public.bestand;
drop policy if exists "bestand ändern"    on public.bestand;
drop policy if exists "meldungen lesen"   on public.meldungen;
drop policy if exists "meldungen anlegen" on public.meldungen;

create policy "bestand lesen"     on public.bestand   for select to anon using (true);
create policy "bestand melden"    on public.bestand   for insert to anon with check (kiste between 1 and 99 and werkzeug between 1 and 16);
create policy "bestand ändern"    on public.bestand   for update to anon using (true) with check (kiste between 1 and 99 and werkzeug between 1 and 16);
create policy "meldungen lesen"   on public.meldungen for select to anon using (true);
create policy "meldungen anlegen" on public.meldungen for insert to anon with check (art = 'kontrolle');
-- (einstellungen: absichtlich keine Regel → niemand liest die PIN über die App)

-- Tausch bestätigen: Kiste "nach" hat das Werkzeug von Kiste "von" erhalten
create or replace function public.tausch_erledigt(p_von int, p_nach int, p_werkzeug int, p_klasse text)
returns boolean language plpgsql security definer set search_path = public as $$
begin
  update bestand set status = 'ok', anzahl = 0, updated_at = now()
   where kiste = p_nach and werkzeug = p_werkzeug and status = 'fehlt';
  if not found then return false; end if;

  update bestand set anzahl = greatest(anzahl - 1, 0),
                     status = case when anzahl - 1 <= 0 then 'ok' else 'mehr' end,
                     updated_at = now()
   where kiste = p_von and werkzeug = p_werkzeug and status = 'mehr';

  insert into meldungen (kiste, klasse, phase, art, werkzeug, partner)
  values (p_nach, p_klasse, 'tausch', 'tausch', p_werkzeug, p_von);
  return true;
end $$;

-- PIN prüfen
create or replace function public.lehrer_pin_ok(p_pin text)
returns boolean language sql security definer set search_path = public as $$
  select exists (select 1 from einstellungen where schluessel = 'lehrer_pin' and wert = p_pin);
$$;

-- Lehrkraft setzt eine Kiste auf vollständig
create or replace function public.lehrer_kiste_ok(p_pin text, p_kiste int)
returns boolean language plpgsql security definer set search_path = public as $$
begin
  if not lehrer_pin_ok(p_pin) then return false; end if;
  insert into bestand (kiste, werkzeug, status, anzahl, klasse, phase, updated_at)
  select p_kiste, w, 'ok', 0, '–', 'lehrer', now() from generate_series(1,16) w
  on conflict (kiste, werkzeug) do update
    set status = 'ok', anzahl = 0, klasse = '–', phase = 'lehrer', updated_at = now();
  insert into meldungen (kiste, klasse, phase, art) values (p_kiste, 'Lehrkraft', 'lehrer', 'lehrer');
  return true;
end $$;

grant execute on function public.tausch_erledigt(int,int,int,text) to anon;
grant execute on function public.lehrer_pin_ok(text)               to anon;
grant execute on function public.lehrer_kiste_ok(text,int)         to anon;

-- Echtzeit einschalten
do $$ begin
  begin alter publication supabase_realtime add table public.bestand;   exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.meldungen; exception when duplicate_object then null; end;
end $$;

-- >>> HIER DEINE PIN EINTRAGEN (statt 1234) <<<
insert into public.einstellungen (schluessel, wert) values ('lehrer_pin', '1234')
on conflict (schluessel) do update set wert = excluded.wert;
