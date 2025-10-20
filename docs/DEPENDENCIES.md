# Dependency Status

## Current State (October 20, 2025)

### Direct Dependencies
All direct dependencies are at their latest compatible versions:
- ✅ `flutter_localizations` (SDK)
- ✅ `cupertino_icons: ^1.0.8`
- ✅ `supabase_flutter: ^2.10.3`
- ✅ `flutter_riverpod: ^3.0.3`
- ✅ `connectivity_plus: ^7.0.0`
- ✅ `intl: ^0.20.2`
- ✅ `uuid: ^4.5.1`
- ✅ `workmanager: ^0.9.0+3`
- ✅ `shared_preferences: ^2.5.3`
- ✅ `path_provider: ^2.1.5`
- ✅ `floor: ^1.5.0`
- ✅ `sqflite: ^2.4.2`
- ✅ `json_annotation: ^4.9.0`
- ✅ `freezed_annotation: ^3.1.0`

### Dev Dependencies
- ✅ `flutter_lints: ^6.0.0` (updated from 5.0.0)
- ⚠️ `build_runner: ^2.4.13` (latest is 2.9.0, but constrained by floor_generator)
- ⚠️ `floor_generator: ^1.5.0` (latest available, but uses older analyzer/build_runner versions)

### Why Some Packages Show as Outdated

The 19 outdated transitive dependencies are constrained by `floor_generator: ^1.5.0`, which depends on:
- `analyzer: ^6.4.1` (latest is 8.4.0)
- `build_runner: ^2.4.0` (latest is 2.9.0)
- Other older build toolchain packages

### Resolution Options

1. **Current approach (RECOMMENDED)**: Keep floor_generator at 1.5.0
   - ✅ Stable and tested
   - ✅ Works perfectly for our use case
   - ✅ All **runtime** dependencies are latest
   - ℹ️ Only **build-time** tools are older versions
   - ℹ️ These older versions don't affect the final app

2. **Alternative**: Wait for floor_generator updates
   - The Floor package maintainers will eventually update to newer analyzer/build_runner
   - No functional impact on the app right now

3. **Alternative**: Switch to a different ORM
   - Would require significant refactoring
   - Not recommended at this stage

## Impact Assessment

### ✅ No Impact on Runtime
- The outdated packages are **transitive dev dependencies** only used during code generation
- They do NOT get bundled into the final app
- App performance, security, and features are unaffected

### ✅ Build Process Works Perfectly
- Code generation runs successfully
- All tests pass
- Analyzer is clean
- App builds and runs without issues

## Recommendation

**Keep current configuration.** The "outdated" warnings are for build tools, not runtime dependencies. All packages that affect the actual app are up-to-date. When floor_generator releases a new version compatible with newer build tools, we can upgrade then.

## Monitoring

Run `flutter pub outdated` periodically to check for updates, especially:
- `floor` and `floor_generator` for ORM updates
- `supabase_flutter` for backend SDK improvements
- Security-related packages

Last checked: October 20, 2025
