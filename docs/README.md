# DELS SmartBill

Offline-first Flutter billing app for a single company (DELS) powered by Supabase.

## Quick Start

1. Create a Supabase project. Enable Google Auth.
2. Apply SQL from `supabase/schema.sql`.
3. Create a Flutter app and add dependencies listed in `docs/IMPLEMENTATION_PLAN.md`.
4. Provide `SUPABASE_URL` and `SUPABASE_ANON_KEY` via `--dart-define` or `.env`.

## Architecture

- Single-tenant shared data, RLS: authenticated-only.
- Offline-first: Floor local DB + SyncService (push dirty, pull changes).
- State management: Riverpod.

## Pages

- Dashboard, Products, New Invoice, Reports, Settings.

## Printing (V2)

- Bluetooth discovery, ESC/POS printing, test print flow.

See `docs/IMPLEMENTATION_PLAN.md` for full details.
