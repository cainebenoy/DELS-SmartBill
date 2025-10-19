# DELS SmartBill — Implementation Plan

This plan turns the concept into an end-to-end, offline-first Flutter app with Supabase.

## Phases Overview

1. Foundations: confirm stack, initialize app, dependencies, Supabase setup, SQL schema + RLS.
2. Data layer (offline-first): domain models, Floor DB, repositories, sync service.
3. App shell and core UI: navigation, placeholder screens.
4. Features: Dashboard, Products CRUD, Invoice creation, Reports, Settings.
5. Quality: errors/empty/loading UX, tests, performance, release docs.
6. V2: Printer setup, ESC/POS print, backup/restore, optional analytics.

## Acceptance Criteria (high level)

- Auth required: unauthenticated users cannot access any data (RLS enforced).
- Offline-first: app fully usable offline; sync reconciles when online.
- Shared single-tenant data: all employees share one dataset.
- Audit: invoices track created_by_user_id.
- Core pages meet the listed UI requirements.

---

## Detailed Tasks and Steps

### 0. Project Decisions
- Choose local DB: Floor (relational, typed schema, migrations) over Hive. Hive remains an option for simple caches.
- State management: Riverpod (robust, testable, fine-grained).
- Invoice numbering: local placeholder `LOCAL-<shortid>`, final sequence assigned by DB on sync.

### 1. Initialize Flutter App
- Create Flutter project (org: `com.dels.smartbill`, name: `dels_smartbill`).
- Configure Android minSdk 23+, multidex if needed; iOS: minimum supported version (per Flutter stable).
- Base layers:
  - `lib/core` (constants, env, utils, theme)
  - `lib/data` (datasources, repositories)
  - `lib/domain` (models)
  - `lib/features` (dashboard, products, invoice, reports, settings)
  - `lib/services` (auth, sync)

### 2. Add Dependencies
- Core: `supabase_flutter`, `flutter_riverpod`.
- Local DB: `floor`, `floor_generator`, `sqflite`, `path_provider`.
- Codegen: `freezed`, `freezed_annotation`, `json_serializable`, `build_runner`.
- Utilities: `connectivity_plus`, `intl`, `uuid`, `workmanager`, `shared_preferences`.
- Dev: `flutter_lints`.
- Scripts: `dart run build_runner build --delete-conflicting-outputs`.

### 3. Supabase Setup
- Create project; capture URL and anon key.
- Enable Google provider. Configure app Redirect URLs (Android/iOS) per supabase_flutter docs.
- Optional: Restrict to DELS email domain in Google OAuth.

### 4. Database Schema, RLS, Triggers, RPCs
- Apply SQL in `supabase/schema.sql` (see file).
- RLS: allow all for `auth.role() = 'authenticated'`.
- Timestamps: `created_at`, `updated_at`, soft delete `deleted_at`.
- Triggers auto-manage timestamps; function + trigger to assign final invoice_number.
- Optional RPCs: fetch changed rows since a timestamp to simplify sync.

### 5. Env Management
- Use `--dart-define` or `flutter_dotenv` to inject `SUPABASE_URL`, `SUPABASE_ANON_KEY`.
- Provide `.env.example` with placeholders.

### 6. Domain Models (Freezed)
- Product, Customer, Invoice, InvoiceItem with shared base fields: `id`, timestamps, `deletedAt`.
- Local sync fields: `isDirty`, `isDeleted`, `updatedLocallyAt`.

### 7. Floor Database
- Entities mirror domain models (with Floor annotations) and DAOs per table.
- Migrations: v1 initial, v2 add indices as needed.
- Indices: names, categories, dates.

### 8. Local and Remote Data Sources
- Local: DAO wrappers; mark dirty on local create/update/delete (soft delete for delete).
- Remote: Supabase CRUD and list-changes (by `updated_at`/`deleted_at`).

### 9. Repositories (Offline-first)
- Write to local first, return local results immediately.
- Schedule sync after mutations when network is available.
- Search and pagination locally; remote only for syncing.

### 10. Sync Service
- Push dirty rows (upsert or delete) to Supabase.
- Pull remote changes since `last_sync_at` per table.
- Conflict resolution: last-write-wins by `updated_at` (V1).
- Maintain sync metadata (SharedPreferences or a small local table).

### 11. Background Sync
- Workmanager periodic task (15 min+) and on app resume.
- Manual "Sync now" UI action.

### 12. Auth Integration
- Initialize Supabase in `main.dart`.
- Google sign-in flow, maintain session.
- Gate routes; logout clears session.
- Capture current user id to set `created_by_user_id` on invoices.

### 13. App Shell & Navigation
- MaterialApp with theme + dark mode.
- Riverpod providers for theme and auth state.
- Bottom navigation with 5 tabs.

### 14. Feature Screens
- Dashboard: Today totals, vs yesterday, recent invoices.
- Products: list, search, add/edit/delete with optimistic updates.
- New Invoice: customer autocomplete, product add, qty controls, total, Save, Save & Print (placeholder).
- Reports: date filters, summary cards, historical list.
- Settings: dark mode, printer setup (placeholder), backup/restore (placeholder), logout.

### 15. Error Handling & UX
- Connectivity banner/toast; sync status notifications.
- Standard Loading/Empty/Error components.
- Undo snackbar for soft deletes.

### 16. Testing
- Unit tests: models, DAOs, repositories, SyncService.
- Widget tests: Products CRUD, Invoice flow, Dashboard metrics.
- Integration: Auth + initial sync (mock or test project).

### 17. Performance
- Ensure indices, limit queries, Riverpod selectors, pagination.

### 18. Release Readiness
- README with setup steps, deep links, env.
- App icons, splash, versioning, changelog.

### 19. V2 Printing & Backup
- Printer discovery & saved device.
- ESC/POS print integration and test print.
- Backup/restore Floor DB or JSON dump.

---

## Risks and Mitigations
- Offline invoice numbering collisions: solved with server-side sequence and local placeholders.
- Sync conflicts: last-write-wins; later consider per-field merges.
- RLS policy too open: limited by OAuth requirement; ensure anon key is not embedded in web builds.
- Background tasks on iOS: constrained; rely on foreground sync + manual trigger.

## Milestone Checkpoints
- M1: Auth + schema + RLS in place, app boots and shows gated home.
- M2: Local DB + repositories + sync pass for products.
- M3: Products UI complete.
- M4: Invoice flow working locally + sync.
- M5: Reports + Dashboard metrics.
- M6: Testing + polish + README.
