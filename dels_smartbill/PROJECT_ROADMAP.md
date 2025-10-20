# DELS SmartBill - Project Roadmap

**Last Updated:** October 20, 2025  
**Current Version:** 1.0.0+1 (In Development)  
**Status:** Core Features Complete, Sync & Polish In Progress

---

## 🎯 Project Overview

DELS SmartBill is an **offline-first Flutter billing application** with Supabase backend, designed for DELS company employees to manage products, customers, and invoices across multiple devices with seamless synchronization.

### Key Features Implemented ✅
- ✅ **Local-First Architecture** - Floor database with SQLite
- ✅ **Products Management** - Full CRUD with search and filtering
- ✅ **Customer Management** - Add customers inline during invoice creation
- ✅ **Invoice Creation** - Customer autocomplete, product cart, total calculations
- ✅ **Dashboard** - Real-time metrics (sales, invoices, products, customers)
- ✅ **Reports** - Date range filtering, historical invoice summaries
- ✅ **Error Handling** - Comprehensive try-catch, empty states, retry buttons
- ✅ **Database Migration** - Implemented v1→v2 migration system
- ✅ **Supabase Integration** - Schema applied, RLS policies, triggers for invoice numbering
- ✅ **Code Quality** - All dart analyze warnings cleared

---

## 📊 Current State Analysis

### What's Working
| Component | Status | Notes |
|-----------|--------|-------|
| Local Database | ✅ Complete | Floor v1.5.0 with migrations |
| Products CRUD | ✅ Complete | Full UI with optimistic updates |
| Customers CRUD | ✅ Complete | Inline add + search |
| Invoice Creation | ✅ Complete | Cart logic, total calculation |
| Dashboard Metrics | ✅ Complete | Error handling, empty states |
| Reports | ✅ Complete | Date filtering, summaries |
| Supabase Schema | ✅ Complete | Tables, RLS, indices, triggers |
| Authentication Gate | 🟡 Scaffolded | UI ready, Google OAuth not wired |
| Sync Service | 🟡 Skeleton | Structure in place, logic TODO |

### What Needs Work
| Component | Priority | Effort | Dependencies |
|-----------|----------|--------|--------------|
| Sync Push/Pull | 🔴 High | Medium | Supabase credentials |
| Riverpod State Mgmt | 🔴 High | Medium | None |
| Repository Layer | 🟡 Medium | Medium | Riverpod |
| Google OAuth | 🔴 High | Small | Supabase config |
| Background Sync | 🟡 Medium | Small | Sync logic |
| Unit Tests | 🟢 Low | Large | Repository layer |
| Printing | 🟢 V2 | Large | Printer library |
| Backup/Restore | 🟢 V2 | Medium | None |

---

## 🗓️ Implementation Phases

### Phase 1: Foundation ✅ (COMPLETE)
**Goal:** Working offline-first app with core features  
**Status:** ✅ Done - Merged to GitHub on Oct 20, 2025

- [x] Flutter project scaffolding
- [x] Dependencies installation (Floor, Supabase, Riverpod, etc.)
- [x] Supabase project setup and schema application
- [x] Floor database entities, DAOs, migrations
- [x] Products page with CRUD operations
- [x] Invoice creation page with cart logic
- [x] Dashboard with metrics
- [x] Reports with date filtering
- [x] Error handling and empty states
- [x] Database migration system
- [x] Git repo initialization and GitHub push

**Key Achievements:**
- 0 compilation errors, 0 lint warnings
- Robust error handling throughout
- Clean architecture with separation of concerns
- Comprehensive documentation in FIXES_APPLIED.md

---

### Phase 2: Data Synchronization 🔄 (IN PROGRESS)
**Goal:** Bidirectional sync between local DB and Supabase  
**Status:** 🟡 In Progress - Skeleton created, logic pending

**Priority Tasks:**

#### 1. Implement Sync Push Logic 🔴 **HIGH PRIORITY**
**Effort:** Medium (2-3 days)

**Steps:**
1. In `SyncService.push()`:
   - Query all DAOs for `isDirty=true` records
   - Map local entities to Supabase format (handle UUID differences)
   - Upsert to Supabase: `supabase.from('products').upsert(mappedData)`
   - Handle soft deletes: if `isDeleted=true`, delete from Supabase
   - Clear `isDirty` flag on successful sync
2. Add error handling:
   - Network errors → Queue for retry
   - Validation errors → Log and notify user
   - Conflict errors → Last-write-wins strategy
3. Add logging for debugging

**Files to Modify:**
- `lib/services/sync_service.dart` - Main implementation
- `lib/data/db/daos/*.dart` - Add `findDirty()` methods if needed

**Testing:**
- Create products offline
- Call sync, verify in Supabase dashboard
- Test soft delete sync
- Test network failure handling

---

#### 2. Implement Sync Pull Logic 🔴 **HIGH PRIORITY**
**Effort:** Medium (2-3 days)

**Steps:**
1. In `SyncService.pull()`:
   - Get `lastSync` timestamp from SharedPreferences
   - Call Supabase RPCs: `fetch_products_since(lastSync)`, etc.
   - Map remote data to local entities
   - Merge into Floor: `dao.upsert(entity)` or `dao.delete()` based on `deleted_at`
   - Handle conflicts: Compare `updated_at`, keep most recent
   - Update `lastSync` timestamp
2. Add batch processing for large datasets
3. Show progress indicator for long syncs

**Files to Modify:**
- `lib/services/sync_service.dart` - Main implementation
- `lib/data/db/daos/*.dart` - Ensure upsert handles conflicts

**Testing:**
- Modify data in Supabase directly
- Call pull, verify local DB updates
- Test with large datasets (100+ records)
- Test conflict resolution (same record modified locally and remotely)

---

#### 3. Add Riverpod State Management 🔴 **HIGH PRIORITY**
**Effort:** Medium (2-3 days)

**Why:** 
- Current approach (direct DB calls in UI) is not scalable
- Hard to test without mocking DB
- No reactive updates across the app

**Steps:**
1. Create providers in `lib/providers/`:
   ```dart
   // app_providers.dart
   final appDatabaseProvider = Provider<AppDatabase>(...);
   final syncServiceProvider = Provider<SyncService>(...);
   final authStateProvider = StreamProvider<Session?>(...);
   final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(...);
   
   // data_providers.dart
   final productsProvider = FutureProvider<List<ProductEntity>>(...);
   final customersProvider = FutureProvider<List<CustomerEntity>>(...);
   final invoicesProvider = FutureProvider<List<InvoiceEntity>>(...);
   ```

2. Update UI pages:
   - Replace `openAppDatabase()` with `ref.read(appDatabaseProvider)`
   - Replace manual state management with `ref.watch()`
   - Add `ConsumerWidget` or `ConsumerStatefulWidget`

3. Add loading/error states automatically with `AsyncValue`

**Files to Create:**
- `lib/providers/app_providers.dart`
- `lib/providers/data_providers.dart`

**Files to Modify:**
- `lib/main.dart` - Wrap with ProviderScope
- All pages - Convert to Consumer widgets
- `lib/services/sync_service.dart` - Accept providers as dependencies

**Testing:**
- Verify hot reload works with providers
- Test that changes reflect across pages
- Test error states automatically handled

---

#### 4. Implement Repository Layer 🟡 **MEDIUM PRIORITY**
**Effort:** Medium (3-4 days)

**Why:**
- Better separation of concerns (UI doesn't talk directly to DB)
- Single place to handle business logic
- Easier to test with mock repositories

**Steps:**
1. Create repository interfaces and implementations:
   ```dart
   // lib/domain/repositories/product_repository.dart
   abstract class ProductRepository {
     Future<List<Product>> getAll();
     Future<Product?> getById(String id);
     Future<void> create(Product product);
     Future<void> update(Product product);
     Future<void> delete(String id);
     Future<List<Product>> search(String query);
   }
   
   // lib/data/repositories/product_repository_impl.dart
   class ProductRepositoryImpl implements ProductRepository {
     final ProductDao _dao;
     final SyncService _syncService;
     
     Future<void> create(Product product) async {
       await _dao.insertProduct(product.toEntity());
       await _syncService.push(); // Trigger sync
     }
   }
   ```

2. Create repositories for: Products, Customers, Invoices
3. Move business logic from UI to repositories
4. Update Riverpod providers to use repositories

**Files to Create:**
- `lib/domain/repositories/*.dart` - Interfaces
- `lib/data/repositories/*.dart` - Implementations

**Files to Modify:**
- `lib/providers/data_providers.dart` - Use repositories
- All UI pages - Call repositories instead of DAOs

**Testing:**
- Unit test repositories with mock DAOs
- Verify sync is triggered after mutations
- Test error handling in repositories

---

### Phase 3: Authentication & User Context 🔐 (PENDING)
**Goal:** Secure app with Google OAuth, track user actions  
**Status:** ⏳ Not Started - AuthGate scaffolded

**Tasks:**

#### 5. Complete Google Authentication Flow 🔴 **HIGH PRIORITY**
**Effort:** Small (1 day)

**Steps:**
1. Configure in Supabase Dashboard:
   - Enable Google provider
   - Add redirect URLs: 
     - Android: `com.dels.smartbill://oauth-callback`
     - iOS: `com.dels.smartbill://oauth-callback`
     - Web: `http://localhost:3000/auth/callback` (for testing)
   - Optional: Restrict to `@dels.com` domain

2. Implement in `auth_gate.dart`:
   ```dart
   await supabase.auth.signInWithOAuth(
     OAuthProvider.google,
     redirectTo: 'com.dels.smartbill://oauth-callback',
   );
   ```

3. Handle auth state changes:
   ```dart
   supabase.auth.onAuthStateChange.listen((data) {
     setState(() => _session = data.session);
   });
   ```

4. Add logout in Settings:
   ```dart
   await supabase.auth.signOut();
   ```

5. Enable auth by default: Set `ENABLE_AUTH=true` in main.dart

**Files to Modify:**
- `lib/features/auth/auth_gate.dart` - Implement OAuth
- `lib/features/settings/settings_page.dart` - Add logout button
- `lib/main.dart` - Enable auth gate

**Testing:**
- Test Google sign-in flow on Android
- Test redirect handling
- Test logout and re-sign in
- Test session persistence

---

#### 6. Add User Context to Invoices 🟡 **MEDIUM PRIORITY**
**Effort:** Small (1 day)

**Steps:**
1. Add field to `InvoiceEntity`:
   ```dart
   @ColumnInfo(name: 'created_by_user_id')
   final String? createdByUserId;
   ```

2. Run build_runner to regenerate code

3. Create migration v2→v3 to add column:
   ```dart
   final migration2to3 = Migration(2, 3, (database) async {
     await database.execute(
       'ALTER TABLE InvoiceEntity ADD COLUMN created_by_user_id TEXT'
     );
   });
   ```

4. Capture user ID during invoice creation:
   ```dart
   final userId = supabase.auth.currentUser?.id;
   final invoice = InvoiceEntity(
     ...,
     createdByUserId: userId,
   );
   ```

5. Update sync logic to push user ID to Supabase

**Files to Modify:**
- `lib/data/db/entities/invoice_entity.dart`
- `lib/data/db/app_database.dart` - Add migration
- `lib/features/invoices/invoice_page.dart` - Capture user ID

**Testing:**
- Create invoice as User A, verify user ID saved
- Sync to Supabase, verify `created_by_user_id` column
- Pull from different device, verify user ID preserved

---

### Phase 4: Background & Real-time Sync ⚡ (PENDING)
**Goal:** Automatic sync without user intervention  
**Status:** ⏳ Not Started

**Tasks:**

#### 7. Implement Background Sync with Workmanager 🟡 **MEDIUM PRIORITY**
**Effort:** Small (1 day)

**Steps:**
1. Initialize Workmanager in `main.dart`:
   ```dart
   await Workmanager().initialize(
     callbackDispatcher,
     isInDebugMode: false,
   );
   
   await Workmanager().registerPeriodicTask(
     'sync-task',
     'sync',
     frequency: Duration(minutes: 15),
   );
   ```

2. Define callback:
   ```dart
   void callbackDispatcher() {
     Workmanager().executeTask((task, inputData) async {
       final db = await openAppDatabase();
       await SyncService().push(db);
       await SyncService().pull(db);
       return Future.value(true);
     });
   }
   ```

3. Add app resume listener for immediate sync:
   ```dart
   AppLifecycleState? _lastState;
   
   @override
   void didChangeAppLifecycleState(AppLifecycleState state) {
     if (state == AppLifecycleState.resumed && 
         _lastState == AppLifecycleState.paused) {
       // Trigger sync
     }
     _lastState = state;
   }
   ```

**Files to Modify:**
- `lib/main.dart` - Initialize Workmanager
- Create `lib/services/background_sync.dart` - Callback logic

**Testing:**
- Verify sync runs every 15 minutes (use logs)
- Test on Android (background execution allowed)
- Test on iOS (more restrictive, may need foreground sync)
- Test app resume sync

---

#### 8. Add Connectivity Management 🟡 **MEDIUM PRIORITY**
**Effort:** Small (1 day)

**Steps:**
1. Create connectivity provider:
   ```dart
   final connectivityProvider = StreamProvider<bool>((ref) {
     return Connectivity().onConnectivityChanged.map((result) {
       return result != ConnectivityResult.none;
     });
   });
   ```

2. Show connectivity banner in app:
   ```dart
   final isOnline = ref.watch(connectivityProvider).value ?? true;
   
   if (!isOnline) {
     return Banner(
       message: 'You are offline. Changes will sync when online.',
       child: child,
     );
   }
   ```

3. Disable sync when offline:
   ```dart
   if (isOnline) {
     await syncService.push();
   }
   ```

4. Queue offline changes for later sync

**Files to Create:**
- `lib/providers/connectivity_provider.dart`

**Files to Modify:**
- `lib/main.dart` or shell - Add connectivity banner
- `lib/services/sync_service.dart` - Check connectivity

**Testing:**
- Turn off WiFi, verify banner appears
- Make changes offline, turn on WiFi, verify sync happens
- Test airplane mode

---

### Phase 5: UX Enhancements 🎨 (PENDING)
**Goal:** Polish UI/UX, add power user features  
**Status:** ⏳ Not Started

**Tasks:**

#### 9. Improve Dashboard with Real-time Metrics 🟢 **LOW PRIORITY**
**Effort:** Medium (2 days)

**Ideas:**
- Sales trends: Today vs Yesterday, This Week vs Last Week
- Top 5 selling products (by quantity and revenue)
- Customer leaderboard (most invoices, highest value)
- Recent activity feed (last 10 invoices)
- Charts using `fl_chart` package
- Pull-to-refresh with RefreshIndicator

---

#### 10. Enhance Reports Page Features 🟢 **LOW PRIORITY**
**Effort:** Medium (2-3 days)

**Ideas:**
- Export to CSV/PDF
- Filter by customer, product category, minimum amount
- Sort by date, amount, customer name
- Pagination (show 20 per page)
- Visual summary with daily sales chart
- Print preview

---

#### 11. Polish Settings Page 🟡 **MEDIUM PRIORITY**
**Effort:** Small (1 day)

**Add:**
- Dark mode toggle with persistence
- User profile (name, email, avatar from Google)
- About section (version, developer, license)
- Logout button
- Data management (clear cache, view storage usage)
- App preferences (currency, date format, language)

---

#### 12. Add Loading States and Skeletons 🟢 **LOW PRIORITY**
**Effort:** Small (1 day)

**Replace:**
- CircularProgressIndicator → Shimmer skeletons
- Use `shimmer` package
- Add skeleton screens for Dashboard cards, Reports lists, Products grid
- Show optimistic UI updates

---

### Phase 6: Testing & Quality 🧪 (PENDING)
**Goal:** Ensure reliability and maintainability  
**Status:** ⏳ Not Started

**Tasks:**

#### 13. Write Unit Tests 🟢 **LOW PRIORITY**
**Effort:** Large (5+ days)

**Coverage:**
- ✅ Entity models (serialization, validation)
- ✅ DAOs (CRUD operations)
- ✅ Sync service (push/pull logic, conflict resolution)
- ✅ Repositories (business logic)
- ✅ Utilities (currency format, date helpers)

**Target:** >70% code coverage

---

#### 14. Write Widget Tests 🟢 **LOW PRIORITY**
**Effort:** Large (5+ days)

**Coverage:**
- ProductsPage (list, add/edit dialogs, search)
- InvoicePage (customer autocomplete, cart, save)
- Dashboard (metrics, error states, empty states)
- Reports (date picker, filtering, list)
- Settings (theme toggle, sync button)

---

#### 15. Write Integration Tests 🟢 **LOW PRIORITY**
**Effort:** Medium (3 days)

**Scenarios:**
- Full invoice creation flow
- Offline → Online sync flow
- Multi-device conflict resolution
- Auth flow (sign in → use app → logout)

---

### Phase 7: Advanced Features (V2) 🚀 (FUTURE)
**Goal:** Printing, backup, analytics  
**Status:** ⏳ Not Started

**Tasks:**

#### 16. Implement Print Functionality 🟢 **V2**
**Effort:** Large (1 week)

**Scope:**
- Bluetooth/USB printer setup
- ESC/POS printing library integration
- Invoice template design
- 'Save & Print' button
- Test print feature

**Libraries:**
- `esc_pos_printer` or `blue_thermal_printer`

---

#### 17. Add Backup and Restore 🟢 **V2**
**Effort:** Medium (3 days)

**Scope:**
- Export Floor database to JSON
- Import and merge/replace data
- Cloud backup to Supabase Storage or Google Drive
- Automatic periodic backups
- UI in Settings

---

### Phase 8: Release 📦 (PENDING)
**Goal:** Deploy to production  
**Status:** ⏳ Not Started

**Tasks:**

#### 18. Update README Documentation 🟡 **MEDIUM PRIORITY**
**Effort:** Small (1 day)

**Include:**
- Project overview and features
- Prerequisites
- Setup instructions
- Running the app
- Testing guide
- Architecture overview
- Contributing guidelines
- License

---

#### 19. Design App Icon and Splash Screen 🟡 **MEDIUM PRIORITY**
**Effort:** Small (1 day)

**Steps:**
1. Design 512x512 icon (Material Design guidelines)
2. Use `flutter_launcher_icons` to generate all sizes
3. Design splash screen with branding
4. Use `flutter_native_splash` package
5. Test on all platforms

---

#### 20. Prepare for Release 🟡 **MEDIUM PRIORITY**
**Effort:** Medium (2 days)

**Checklist:**
- Update version to 1.0.0
- Review AndroidManifest.xml
- Configure iOS Info.plist
- Set up signing certificates
- Update app name and description
- Test release builds
- Create store listing assets

---

#### 21. Build and Deploy 🟡 **MEDIUM PRIORITY**
**Effort:** Medium (2 days)

**Platforms:**
- Android: `flutter build appbundle --release`
- iOS: `flutter build ipa --release`
- Windows: `flutter build windows --release`
- Set up CI/CD with GitHub Actions
- Upload to stores
- Document deployment process

---

## 📈 Progress Metrics

### Overall Completion
```
Foundation:         ████████████████████ 100% (Complete)
Synchronization:    ████░░░░░░░░░░░░░░░░  20% (Skeleton)
Authentication:     ██░░░░░░░░░░░░░░░░░░  10% (Scaffolded)
Background Sync:    ░░░░░░░░░░░░░░░░░░░░   0% (Pending)
UX Enhancement:     ░░░░░░░░░░░░░░░░░░░░   0% (Pending)
Testing:            ░░░░░░░░░░░░░░░░░░░░   0% (Pending)
Advanced Features:  ░░░░░░░░░░░░░░░░░░░░   0% (Future)
Release:            ░░░░░░░░░░░░░░░░░░░░   0% (Pending)

TOTAL PROJECT:      ████░░░░░░░░░░░░░░░░  18% Complete
```

### Feature Breakdown
| Feature | Status | Completion |
|---------|--------|------------|
| Local Database | ✅ Complete | 100% |
| Products CRUD | ✅ Complete | 100% |
| Customers CRUD | ✅ Complete | 100% |
| Invoice Creation | ✅ Complete | 100% |
| Dashboard | ✅ Complete | 90% (metrics done, charts pending) |
| Reports | ✅ Complete | 85% (basic done, export pending) |
| Sync Service | 🟡 In Progress | 20% (skeleton done, logic pending) |
| Authentication | 🟡 Scaffolded | 30% (UI done, OAuth pending) |
| Background Sync | ⏳ Pending | 0% |
| Printing | ⏳ Pending | 0% |
| Testing | ⏳ Pending | 5% (1 basic widget test) |

---

## 🎯 Next Sprint Recommendations

### Sprint 1: Core Sync (1-2 weeks) 🔥 **START HERE**
**Objective:** Get data flowing between local DB and Supabase

**Priority Order:**
1. ✅ Implement Sync Push Logic (3 days)
2. ✅ Implement Sync Pull Logic (3 days)
3. ✅ Wire Sync Everywhere (1 day)
4. ✅ Add Error Handling for Sync (1 day)
5. ✅ Test Sync with Real Data (1 day)

**Success Criteria:**
- Create product offline, sync, see in Supabase
- Modify in Supabase, pull, see locally
- Conflict resolution works
- Errors handled gracefully

---

### Sprint 2: State Management & Architecture (1 week)
**Objective:** Make codebase more maintainable and testable

**Priority Order:**
1. ✅ Add Riverpod State Management (3 days)
2. ✅ Implement Repository Layer (3 days)
3. ✅ Refactor UI to Use Providers (1 day)

**Success Criteria:**
- No direct DB calls in UI
- Hot reload works smoothly
- Easier to test with mock repositories

---

### Sprint 3: Authentication & User Context (1 week)
**Objective:** Secure the app and track user actions

**Priority Order:**
1. ✅ Complete Google Authentication (2 days)
2. ✅ Add User Context to Invoices (1 day)
3. ✅ Test Multi-User Scenarios (2 days)

**Success Criteria:**
- Can't access app without signing in
- Each invoice tagged with creator
- Session persists across app restarts

---

### Sprint 4: Background & Connectivity (1 week)
**Objective:** Automatic sync and offline awareness

**Priority Order:**
1. ✅ Add Connectivity Management (1 day)
2. ✅ Implement Background Sync (2 days)
3. ✅ Add Sync Status Indicators (1 day)
4. ✅ Test Offline → Online Sync (1 day)

**Success Criteria:**
- App syncs automatically every 15 min
- Shows offline banner when no internet
- Queues changes for sync when back online

---

### Sprint 5: Polish & Testing (2 weeks)
**Objective:** Make app production-ready

**Priority Order:**
1. ✅ Polish Settings Page (1 day)
2. ✅ Add Loading Skeletons (1 day)
3. ✅ Write Unit Tests (3 days)
4. ✅ Write Widget Tests (3 days)
5. ✅ Write Integration Tests (2 days)
6. ✅ Performance Optimization (2 days)

**Success Criteria:**
- >70% test coverage
- Smooth UX with no janky animations
- All common scenarios tested

---

### Sprint 6: Release (1 week)
**Objective:** Ship v1.0.0 to production

**Priority Order:**
1. ✅ Update Documentation (1 day)
2. ✅ Design Icon & Splash (1 day)
3. ✅ Prepare Release Builds (2 days)
4. ✅ Deploy to Stores (2 days)

**Success Criteria:**
- App available on Play Store
- Complete documentation
- CI/CD pipeline working

---

## 🔧 Technical Debt & Known Issues

### Current Issues
1. **No repository layer** - UI directly accesses DAOs
2. **Minimal error handling in sync** - Network failures not gracefully handled
3. **No offline queue** - Sync attempts immediate, should queue if offline
4. **Hardcoded values** - Some magic numbers and strings need constants
5. **Incomplete tests** - Only 1 basic widget test exists

### Future Improvements
1. **Add proper logging** - Use `logger` package for better debugging
2. **Implement analytics** - Track user behavior (Firebase Analytics)
3. **Add crash reporting** - Sentry or Crashlytics
4. **Optimize database queries** - Add more indices, profile slow queries
5. **Implement pagination** - Large lists (>100 items) need pagination
6. **Add search debouncing** - Search fields trigger too frequently
7. **Better conflict resolution** - Consider per-field merges instead of last-write-wins
8. **Multi-language support** - Currently only EN-IN

---

## 📚 Resources & References

### Documentation
- [Flutter Docs](https://docs.flutter.dev/)
- [Supabase Docs](https://supabase.io/docs)
- [Floor Documentation](https://pub.dev/packages/floor)
- [Riverpod Guide](https://riverpod.dev/)

### Current Architecture
```
dels_smartbill/
├── lib/
│   ├── core/                 # Constants, utilities, design system
│   │   ├── design/          # Colors, typography
│   │   ├── format/          # Currency, date formatters
│   │   └── supabase/        # Supabase client initialization
│   ├── data/                 # Data layer
│   │   └── db/
│   │       ├── entities/    # Floor entities (models)
│   │       ├── daos/        # Data access objects
│   │       └── converters/  # Type converters for Floor
│   ├── features/             # Feature modules
│   │   ├── auth/            # Authentication
│   │   ├── dashboard/       # Dashboard page
│   │   ├── products/        # Products management
│   │   ├── invoices/        # Invoice creation
│   │   ├── reports/         # Reports page
│   │   ├── settings/        # Settings page
│   │   └── shell/           # App shell & navigation
│   └── services/             # Business logic services
│       └── sync_service.dart # Sync orchestration
├── supabase/
│   └── schema.sql           # Database schema for Supabase
└── docs/
    ├── IMPLEMENTATION_PLAN.md
    ├── DEPENDENCIES.md
    └── README.md
```

### Key Dependencies
- **flutter**: ^3.9.2
- **supabase_flutter**: ^2.10.3
- **flutter_riverpod**: ^3.0.3
- **floor**: ^1.5.0
- **sqflite**: ^2.4.2
- **connectivity_plus**: ^7.0.0
- **workmanager**: ^0.9.0+3
- **shared_preferences**: ^2.5.3

---

## 📞 Contact & Support

**Developer:** DELS Development Team  
**Repository:** https://github.com/cainebenoy/DELS-SmartBill  
**License:** Proprietary

---

**Last Updated:** October 20, 2025  
**Next Review:** After Sprint 1 completion
