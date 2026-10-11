# Neutral Redesign and Two-Tab Restructure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the canopy-green visual system with a neutral, Ecosia-style palette and restructure Walkable Shanghai into two tabs (Map, Me), with a route list and route card on the map, fixed route tags, a walker-activity hook, save-equals-download, and a settings-list Me tab.

**Architecture:** SwiftUI app over SwiftData. Catalogue data is bundled JSON served through `RouteStore`; walker state lives in SwiftData stores injected through the environment. Pure list logic (`RouteList`) decides what the map sheet shows and is unit-tested apart from views. All map drawing stays behind one wrapper view, `RouteMapView`.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, MapKit (kept after comparing AMap, Tencent, Baidu, Mapbox and MapLibre; see `research/map-provider/`), XCTest/XCUITest, Xcode 26.6.

**Spec:** `docs/superpowers/specs/2026-10-11-ecosia-redesign-design.md`

## Global Constraints

- Repository root: `/Users/aurae25/walkable-shanghai`. App project: `WalkableShanghai/`. All paths below are relative to `WalkableShanghai/` unless they start with `docs/` or `research/`.
- Deployment target iOS 18.0; Swift 6 language mode. Do not change `Scripts/generate_project.py` except in Task 8.
- `xcode-select` points at the Command Line Tools and must not be changed. Prefix every `xcodebuild` and `xcrun` command with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.
- Simulators: `iPhone 17 Pro` (iOS 26.5) is the default destination; `iPhone 16 Pro` (iOS 18.6) is the second.
- Sources live in folder-synchronised groups: adding or deleting a `.swift` file under `Sources/`, `Tests/` or `UITests/` needs no project change.
- Every interface string goes in `Sources/Resources/Localizable.xcstrings` with both `en` and `zh-Hans` values, and is read through `"key".localized(language)` (or `L10n.string(_:_:count:)` for plurals). Route content goes through `LocalizedText`.
- Every colour comes from a `Theme` token. No literal colours in feature code.
- Every interactive control has an `accessibilityIdentifier`; icon-only controls also have an `accessibilityLabel`.
- Code style: match the surrounding file. One space around `=`. No aligned columns. Never run a formatter. Doc comments explain *why*, in the file's existing voice.
- Interface copy is exactly as given in the spec and this plan. Add no extra labels, subtitles or helper text.
- Green appears only on primary buttons, the route line, selected states, the filled bookmark and the Featured tag.
- Commit after every task from the repository root. Do not add Claude attribution trailers to commits.

Common commands (run from `WalkableShanghai/`):

```bash
# Build
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project WalkableShanghai.xcodeproj -scheme WalkableShanghai -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5

# Unit tests only (about 1 minute)
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project WalkableShanghai.xcodeproj -scheme WalkableShanghai -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:WalkableShanghaiTests 2>&1 | grep -E 'Test Case .* (passed|failed)|error:|TEST (SUCCEEDED|FAILED)' | tail -40

# One UI test class
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project WalkableShanghai.xcodeproj -scheme WalkableShanghai -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:WalkableShanghaiUITests/<ClassName> 2>&1 | grep -E 'Test Case .* (passed|failed)|error:|TEST (SUCCEEDED|FAILED)' | tail -40
```

Adding strings: use this helper rather than hand-editing JSON. Save it once as `Scripts/strings.py` in Task 2 and reuse it.

```python
#!/usr/bin/env python3
"""Add, replace or remove keys in Localizable.xcstrings.

    python3 Scripts/strings.py set KEY "English" "中文" ["comment"]
    python3 Scripts/strings.py plural KEY "one English" "other English" "中文"
    python3 Scripts/strings.py remove PREFIX_OR_KEY [...]
"""
import json, sys
PATH = "Sources/Resources/Localizable.xcstrings"

def unit(value):
    return {"stringUnit": {"state": "translated", "value": value}}

def main():
    with open(PATH, encoding="utf-8") as f:
        catalog = json.load(f)
    strings = catalog["strings"]
    command, args = sys.argv[1], sys.argv[2:]
    if command == "set":
        key, en, zh = args[:3]
        entry = {"extractionState": "manual", "localizations": {"en": unit(en), "zh-Hans": unit(zh)}}
        if len(args) > 3:
            entry["comment"] = args[3]
        strings[key] = entry
    elif command == "plural":
        key, one, other, zh = args
        strings[key] = {"extractionState": "manual", "localizations": {
            "en": {"variations": {"plural": {"one": unit(one), "other": unit(other)}}},
            "zh-Hans": {"variations": {"plural": {"other": unit(zh)}}},
        }}
    elif command == "remove":
        for target in args:
            for key in [k for k in strings if k == target or (target.endswith(".") and k.startswith(target))]:
                del strings[key]
    else:
        sys.exit(f"unknown command {command}")
    with open(PATH, "w", encoding="utf-8") as f:
        json.dump(catalog, f, ensure_ascii=False, indent=2, sort_keys=True)
        f.write("\n")

main()
```

## File Map

Created:

| File | Responsibility |
|---|---|
| `Scripts/strings.py` | String-catalogue edits from the command line |
| `Sources/DesignSystem/Palette.swift` | Raw light/dark hex pairs for every colour role; the contrast test reads these |
| `Sources/Data/RouteTag.swift` | The fixed, developer-owned tag list |
| `Sources/Data/RouteActivity.swift` | `ActivityPeriod`, `WalkCounts`, `RouteActivityProvider`, `OfflineActivityProvider` |
| `Sources/Features/Map/RouteList.swift` | Pure list logic: options, sections, Nearby/Popular ordering, search |
| `Sources/Features/Map/RouteListSheet.swift` | The "Routes" header, dropdown, period selector, sections and rows |
| `Sources/Features/Map/RouteCard.swift` | The collapsible route card shown in the sheet |
| `Sources/Features/Map/MapStyleOption.swift` | Map / Satellite / Traffic choice |
| `Sources/Features/Map/NearbyOrigin.swift` | Where Nearby measures from |
| `Sources/Features/Me/MeScreen.swift` | The settings list |
| `Sources/Features/Me/DownloadsScreen.swift` | Downloaded routes and Remove all downloads |
| `Tests/PaletteContrastTests.swift` | WCAG checks on every text/background pair |
| `Tests/RouteListTests.swift` | Options, ordering, sections, search |
| `Tests/RouteActivityTests.swift` | The activity hook |
| `UITests/Support/AppLaunch.swift` | Shared launch and query helpers for UI tests |
| `UITests/RouteListUITests.swift`, `UITests/RouteCardUITests.swift`, `UITests/MeTabUITests.swift`, `UITests/ScreenshotUITests.swift` | UI coverage for the new screens |

Deleted: `Sources/Features/Community/` (all), `Sources/Data/CommunityStore.swift`, `Sources/Features/Saved/SavedScreen.swift`, `Sources/Features/Route/FeaturedScreen.swift`, `Sources/Features/Route/RouteDetailScreen.swift` (Task 10, after `FlowRow` moves), `Sources/Features/Shell/PlaceholderScreen.swift`, `Tests/CommunityTests.swift`, `UITests/CommunityUITests.swift`, `UITests/SavedUITests.swift`, `UITests/RouteDetailUITests.swift`, `UITests/RedesignScreenshotUITests.swift`, `Screenshots/redesign/`.

Modified (main ones): `Data/Models.swift`, `Data/Repositories.swift`, `Data/RouteUserState.swift`, `Data/SavedRoutesStore.swift`, `Data/OfflineStore.swift`, `Data/WalkRecords.swift`, `Data/WalkStore.swift`, `DesignSystem/Theme.swift`, `DesignSystem/Materials.swift`, `DesignSystem/Components.swift`, `Features/Map/MapDiscoverScreen.swift`, `Features/Map/RouteMapView.swift`, `Features/Shell/MainTabView.swift`, `Features/Profile/ProfileScreen.swift`, `Features/Tracking/*`, `Features/Builder/RouteBuilderScreen.swift`, `Localization/AppSettings.swift`, `App/WalkableShanghaiApp.swift`, `Resources/SampleData.json`, `DESIGN.md`, `README.md`.

---

### Task 1: Baseline

**Files:** none.

- [ ] **Step 1: Confirm a clean tree**

Run from the repository root: `git status --short`
Expected: no output.

- [ ] **Step 2: Build and run the unit tests**

Run the build and unit-test commands above.
Expected: `BUILD SUCCEEDED`, then `TEST SUCCEEDED` with 72 unit tests passed. If anything fails, stop and report; do not start Task 2 on a red baseline.

---

### Task 2: Remove Community, Saved, Featured and route notes

Deletes everything the spec removes, so later tasks restyle and rework only what survives. After this task the app has two tabs, the walk summary has one Done action, and stored walks no longer carry `isPosted`.

**Files:**
- Create: `Scripts/strings.py` (code in Global Constraints)
- Delete: `Sources/Features/Community/FeedScreen.swift`, `Sources/Features/Community/CommentsScreen.swift`, `Sources/Features/Community/FeedModels.swift`, `Sources/Data/CommunityStore.swift`, `Sources/Features/Saved/SavedScreen.swift`, `Sources/Features/Route/FeaturedScreen.swift`, `Sources/Features/Shell/PlaceholderScreen.swift`, `Tests/CommunityTests.swift`, `UITests/CommunityUITests.swift`, `UITests/SavedUITests.swift`, `UITests/RedesignScreenshotUITests.swift`
- Modify: `Sources/Data/Models.swift`, `Sources/Data/Repositories.swift`, `Sources/Data/RouteUserState.swift`, `Sources/Data/OfflineStore.swift`, `Sources/Data/WalkRecords.swift`, `Sources/Data/WalkStore.swift`, `Sources/App/WalkableShanghaiApp.swift`, `Sources/Features/Shell/MainTabView.swift`, `Sources/Features/Map/MapDiscoverScreen.swift`, `Sources/Features/Route/RouteDetailScreen.swift`, `Sources/Features/Tracking/WalkSummaryScreen.swift`, `Sources/Features/Profile/ProfileScreen.swift`, `Sources/Resources/SampleData.json`, `Sources/Resources/Localizable.xcstrings`
- Test: `Tests/SampleDataTests.swift`, `Tests/UserStateTests.swift`, `Tests/WalkStoreTests.swift`, `Tests/OfflineTests.swift`, `Tests/ProfileTests.swift`

**Interfaces:**
- Produces: `WalkStore.record(routeId:startedAt:endedAt:distanceMeters:elapsedSeconds:note:photo:)` (no `isPosted`); `OfflineStore.download(route:imageSize:)` (no `notes`); `OfflineBundle` without `notesData`; `MainTabView.Tab` = `.map`, `.you`; `SampleData` = `routes`, `profile` (Task 4 adds `activity`).

- [ ] **Step 1: Update the walk-store test to describe the new behaviour**

In `Tests/WalkStoreTests.swift`, delete `testBothButtonsStoreTheWalkAndOnlyTheFlagDiffers` and remove every `isPosted:` argument from `record(...)` calls in the file. Add:

```swift
    func testDoneStoresTheWalk() throws {
        let container = try UserStateContainer.make(inMemory: true)
        let store = WalkStore(container: container)
        store.record(
            routeId: "wukang",
            startedAt: Date(timeIntervalSince1970: 0),
            endedAt: Date(timeIntervalSince1970: 3_000),
            distanceMeters: 3_400,
            elapsedSeconds: 3_000,
            note: "",
            photo: nil
        )
        XCTAssertEqual(WalkStore(container: container).walkCount, 1)
    }
```

- [ ] **Step 2: Run the unit tests to see them fail**

Expected: the build fails with `missing argument for parameter 'isPosted'`.

- [ ] **Step 3: Delete the removed screens, store and tests**

```bash
cd /Users/aurae25/walkable-shanghai/WalkableShanghai
git rm -q Sources/Features/Community/FeedScreen.swift Sources/Features/Community/CommentsScreen.swift Sources/Features/Community/FeedModels.swift Sources/Data/CommunityStore.swift Sources/Features/Saved/SavedScreen.swift Sources/Features/Route/FeaturedScreen.swift Sources/Features/Shell/PlaceholderScreen.swift Tests/CommunityTests.swift UITests/CommunityUITests.swift UITests/SavedUITests.swift UITests/RedesignScreenshotUITests.swift
```

- [ ] **Step 4: Trim the models**

In `Sources/Data/Models.swift`, delete `RouteComment`, `Post`, `RouteCollection` and `FeaturedEdition`, and reduce `SampleData` to:

```swift
/// The whole bundled catalogue, as decoded from `SampleData.json`.
struct SampleData: Codable, Sendable {
    let routes: [Route]
    let profile: UserProfileSeed
}
```

In `Sources/Data/Repositories.swift`:
- delete `CommentRepository` and `FeedRepository`, and remove them from `BundledDataSource`'s conformance list;
- delete `featuredEdition()` from `RouteRepository` and `BundledDataSource`;
- delete `comments(forRoute:)`, `posts()`, `collections()` from `BundledDataSource`;
- in `RouteStore`, delete `featuredEdition`, `comments(forRoute:)`, `posts()`, `collections()` and `totalKm(of:)`.

In `Sources/Resources/SampleData.json`, delete the top-level keys `comments`, `_commentsNote`, `posts`, `collections`, `featured`, `_featuredNote`:

```bash
python3 - <<'EOF'
import json
p = "Sources/Resources/SampleData.json"
d = json.load(open(p, encoding="utf-8"))
for k in ["comments", "_commentsNote", "posts", "collections", "featured", "_featuredNote"]:
    d.pop(k, None)
json.dump(d, open(p, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
open(p, "a").write("\n")
EOF
```

- [ ] **Step 5: Drop notes from offline bundles and `isPosted` from walks**

`Sources/Data/OfflineStore.swift`: delete the `notesData` property, its init parameter and its term in `byteCount`; delete `storedNotes(_:)`; change `download` to:

```swift
    @discardableResult
    func download(route: Route, imageSize: CGSize = CGSize(width: 900, height: 560)) -> OfflineBundle? {
        guard let routeData = try? JSONEncoder().encode(route),
              let image = RouteImageRenderer.pngData(for: route, size: imageSize)
        else { return nil }

        // Replace rather than duplicate, so re-downloading refreshes.
        remove(routeId: route.id)

        let bundle = OfflineBundle(routeId: route.id, routeData: routeData, mapImage: image)
        context.insert(bundle)
        persist()
        reload()
        return bundle
    }
```

Update the type's doc comment: a downloaded route is its own data and a picture of its line (no notes).

`Sources/Data/WalkRecords.swift`: delete `isPosted` (property, init parameter, assignment). Rewrite the type comment's sentence about posting to: "A walk is written here when the walker taps Done on the summary."

`Sources/Data/WalkStore.swift`: remove the `isPosted` parameter from `record(...)` and from the `StoredWalk` it builds.

`Sources/Data/RouteUserState.swift`: remove `PostLike.self, UserComment.self` from `UserStateContainer.schema`.

- [ ] **Step 6: Two tabs**

Replace the body of `Sources/Features/Shell/MainTabView.swift` with:

```swift
import SwiftUI

/// The two-tab shell: the map, and the walker's own settings.
///
/// Each tab owns its own `NavigationStack`, so a push inside one does not
/// disturb the other.
struct MainTabView: View {

    @Environment(AppSettings.self) private var settings

    enum Tab: Hashable { case map, you }

    @Binding var selection: Tab

    var body: some View {
        let language = settings.language

        TabView(selection: $selection) {
            NavigationStack {
                MapDiscoverScreen()
            }
            .tabItem {
                Label("tab.map".localized(language), systemImage: "map")
            }
            .tag(Tab.map)

            NavigationStack {
                ProfileScreen()
            }
            .tabItem {
                Label("tab.me".localized(language), systemImage: "person")
            }
            .tag(Tab.me)
        }
        .tint(Theme.accent)
    }
}
```

(`ProfileScreen` becomes `MeScreen` in Task 11.)

In `Sources/Features/Profile/ProfileScreen.swift`, delete `var onOpenSaved` and the "Offline downloads" settings row that called it.

In `Sources/App/WalkableShanghaiApp.swift`, delete the `community` state, its initialisation and its `.environment(community)` line; change the offline back-fill loop to call `offlineStore.download(route: route)`.

- [ ] **Step 7: Strip featured, notes and posting from the remaining screens**

`Sources/Features/Map/MapDiscoverScreen.swift`: delete `showingFeatured`, its `navigationDestination`, `featuredBanner(language:)` and the `if filter == .featured { … }` block that showed it.

`Sources/Features/Route/RouteDetailScreen.swift`: delete `CommunityStore` from the environment, `showingComments` and its destination, `noteCount(for:)`, and the "Notes" button; change `setOffline` to call `offline.download(route: route)`.

`Sources/Features/Tracking/WalkSummaryScreen.swift`: replace the two buttons with one, and drop the flag from `finish`:

```swift
                Button("summary.done".localized(language)) {
                    finish()
                }
                .buttonStyle(.primaryClassical)
                .accessibilityIdentifier("summary-done-button")
```

```swift
    private func finish() {
        // Guard against a double tap writing the walk twice.
        guard !hasSaved else { return }
        hasSaved = true

        walks.record(
            routeId: route.id,
            startedAt: session.startedAt ?? Date(),
            endedAt: session.endedAt ?? Date(),
            distanceMeters: session.distanceMeters,
            elapsedSeconds: session.elapsed,
            note: note,
            photo: photoData
        )
        onDone()
    }
```

Update the file's opening doc comment so it no longer mentions "Post to feed" or "Keep it private".

- [ ] **Step 8: Strings**

```bash
cd /Users/aurae25/walkable-shanghai/WalkableShanghai
python3 Scripts/strings.py remove feed. comments. featured. saved. time. placeholder. tab.saved tab.community summary.post summary.private route.notes map.filter.featured
python3 Scripts/strings.py set summary.done "Done" "完成" "Stores the finished walk."
```

(`map.filter.featured` returns in Task 9 under a new key.)

- [ ] **Step 9: Fix the remaining unit tests**

- `Tests/SampleDataTests.swift`: delete `testCollectionTotalsAreComputedNotStored`; in `testCatalogueDecodesWithExpectedCounts` and `testEveryReferenceResolves`, delete every assertion about comments, posts, collections or the featured edition.
- `Tests/UserStateTests.swift`: delete `testFeaturedEditionDecodesAndIsBilingual`.
- `Tests/ProfileTests.swift`: delete `testRelativeTimeCountsCorrectlyAtOne`.
- `Tests/OfflineTests.swift`: remove every `notes:` argument and every assertion on `storedNotes` or `notesData`.

- [ ] **Step 10: Run the unit tests**

Expected: `TEST SUCCEEDED`. Fix compile errors the compiler names (they will all be references to deleted types) by deleting the reference.

- [ ] **Step 11: Check the on-disk store still opens**

The schema lost two entities and two attributes; SwiftData migrates that automatically, but if it could not, `makeOrFallBack` would silently run in memory. Verify on a simulator that has the previous build's data:

```bash
cd /Users/aurae25/walkable-shanghai/WalkableShanghai
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
git -C .. stash -q && xcodebuild -project WalkableShanghai.xcodeproj -scheme WalkableShanghai -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath /tmp/ws-old build -quiet && git -C .. stash pop -q
xcrun simctl boot "iPhone 17 Pro" 2>/dev/null; xcrun simctl uninstall booted com.walkableshanghai.app
xcrun simctl install booted /tmp/ws-old/Build/Products/Debug-iphonesimulator/WalkableShanghai.app
xcrun simctl launch booted com.walkableshanghai.app; sleep 5; xcrun simctl terminate booted com.walkableshanghai.app
xcodebuild -project WalkableShanghai.xcodeproj -scheme WalkableShanghai -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath /tmp/ws-new build -quiet
xcrun simctl install booted /tmp/ws-new/Build/Products/Debug-iphonesimulator/WalkableShanghai.app
xcrun simctl launch --console-pty booted com.walkableshanghai.app 2>&1 | head -40 & sleep 8; kill %1
```

Expected: no line containing `Could not open the user-state store`. If it appears, stop and report.

- [ ] **Step 12: Commit**

```bash
cd /Users/aurae25/walkable-shanghai
git add -A
git commit -m "Remove Community, Saved, Featured and route notes; one Done action on the walk summary"
```

---

### Task 3: Neutral palette

**Files:**
- Create: `Sources/DesignSystem/Palette.swift`, `Tests/PaletteContrastTests.swift`
- Modify: `Sources/DesignSystem/Theme.swift`, `Sources/DesignSystem/Materials.swift`, `Sources/DesignSystem/Components.swift`, `Sources/Features/Map/RouteMapView.swift`, `Sources/Features/Offline/RouteImageRenderer.swift`, every file that calls `.canopyWash()` or a removed token (the compiler lists them)

**Interfaces:**
- Produces: `Palette.Pair { light: UInt32; dark: UInt32 }` and the `Palette` roles below; `Theme` colour tokens `bg`, `surface`, `surfaceRaised`, `fill`, `separator`, `label`, `labelSecondary`, `labelTertiary`, `accent`, `primaryFill`, `onPrimaryFill`, `featuredFill`, `onFeaturedFill`, `grabHandle`. Removed: `Theme.Foliage`, `Theme.Canopy`, `accentStrong`, `accentMuted`, `accentFill`, `onAccentFill`, `accentSoft`, `onAccentSoft`, `sunlight`, `mist`, `pinDisc`, `progressFill`, `barFill`, `CanopyWash`, `.canopyWash()`.

- [ ] **Step 1: Write the failing contrast test**

`Tests/PaletteContrastTests.swift`:

```swift
import XCTest
@testable import WalkableShanghai

/// Every text/background pairing the app uses must meet WCAG AA in both
/// appearances. The values are read from `Palette`, the same numbers `Theme`
/// draws with, so the test and the screens cannot disagree.
final class PaletteContrastTests: XCTestCase {

    private func luminance(_ hex: UInt32) -> Double {
        func channel(_ shift: UInt32) -> Double {
            let value = Double((hex >> shift) & 0xFF) / 255
            return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(16) + 0.7152 * channel(8) + 0.0722 * channel(0)
    }

    private func ratio(_ a: UInt32, _ b: UInt32) -> Double {
        let (la, lb) = (luminance(a), luminance(b))
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    private func assertPair(_ text: Palette.Pair, on ground: Palette.Pair, minimum: Double = 4.5, _ name: String, line: UInt = #line) {
        XCTAssertGreaterThanOrEqual(ratio(text.light, ground.light), minimum, "\(name) (light)", line: line)
        XCTAssertGreaterThanOrEqual(ratio(text.dark, ground.dark), minimum, "\(name) (dark)", line: line)
    }

    func testBodyTextReadsOnEveryGround() {
        for (groundName, ground) in [("bg", Palette.bg), ("surface", Palette.surface), ("surfaceRaised", Palette.surfaceRaised), ("fill", Palette.fill)] {
            assertPair(Palette.label, on: ground, "label on \(groundName)")
            assertPair(Palette.labelSecondary, on: ground, "labelSecondary on \(groundName)")
            assertPair(Palette.labelTertiary, on: ground, "labelTertiary on \(groundName)")
            assertPair(Palette.accent, on: ground, "accent on \(groundName)")
        }
    }

    func testFilledControlsCarryReadableLabels() {
        assertPair(Palette.onPrimaryFill, on: Palette.primaryFill, "primary button label")
        assertPair(Palette.onFeaturedFill, on: Palette.featuredFill, "featured tag label")
    }

    func testGroundsAreNeutral() {
        // Saturation of each ground, in HSL terms. The canopy palette failed
        // because the grounds themselves were green; these must stay grey.
        for pair in [Palette.bg, Palette.surface, Palette.surfaceRaised, Palette.fill, Palette.separator] {
            for hex in [pair.light, pair.dark] {
                let r = Double((hex >> 16) & 0xFF), g = Double((hex >> 8) & 0xFF), b = Double(hex & 0xFF)
                XCTAssertLessThanOrEqual(max(r, g, b) - min(r, g, b), 16, String(format: "ground %06X is tinted", hex))
            }
        }
    }
}
```

- [ ] **Step 2: Run it to see it fail**

Expected: compile error, `cannot find 'Palette' in scope`.

- [ ] **Step 3: Add the palette**

`Sources/DesignSystem/Palette.swift`:

```swift
import Foundation

/// The raw numbers behind every colour in the app, one light/dark pair per role.
///
/// Kept apart from `Theme` so the contrast test can read plain integers rather
/// than resolving SwiftUI colours. The direction comes from
/// `research/ecosia-design-research.md`: neutral grounds in both appearances,
/// near-neutral text, and green only where it marks something — primary
/// buttons, the route line, selection, the bookmark, the Featured tag.
enum Palette {
    struct Pair: Sendable {
        let light: UInt32
        let dark: UInt32
    }

    static let bg = Pair(light: 0xF8F8F6, dark: 0x1A1A1A)
    static let surface = Pair(light: 0xFFFFFF, dark: 0x242424)
    static let surfaceRaised = Pair(light: 0xFFFFFF, dark: 0x2F2F2E)
    static let fill = Pair(light: 0xF0F0EB, dark: 0x333333)
    static let separator = Pair(light: 0xDEDED9, dark: 0x42423F)

    static let label = Pair(light: 0x2B2B29, dark: 0xF4F4F1)
    static let labelSecondary = Pair(light: 0x63635D, dark: 0xB5B5AE)
    static let labelTertiary = Pair(light: 0x6B6B65, dark: 0xA3A39C)

    static let accent = Pair(light: 0x3F6B23, dark: 0xA9D27E)
    static let primaryFill = Pair(light: 0x3F6B23, dark: 0xA9D27E)
    static let onPrimaryFill = Pair(light: 0xFFFFFF, dark: 0x1A1A1A)
    static let featuredFill = Pair(light: 0xD6E89A, dark: 0xD6E89A)
    static let onFeaturedFill = Pair(light: 0x2B2B29, dark: 0x1A1A1A)
}
```

- [ ] **Step 4: Point `Theme` at the palette**

In `Sources/DesignSystem/Theme.swift`, replace everything from the start of the colour section through `grabHandle` (the `Foliage` enum, all colour constants, the `Canopy` enum, `progressFill`, `barFill`) with:

```swift
    // MARK: - Colour roles

    static let bg = adaptive(Palette.bg)
    static let surface = adaptive(Palette.surface)
    static let surfaceRaised = adaptive(Palette.surfaceRaised)
    static let fill = adaptive(Palette.fill)
    static let separator = adaptive(Palette.separator)

    static let label = adaptive(Palette.label)
    static let labelSecondary = adaptive(Palette.labelSecondary)
    static let labelTertiary = adaptive(Palette.labelTertiary)

    /// The route line, selected states, the filled bookmark and links.
    static let accent = adaptive(Palette.accent)
    /// Primary buttons only.
    static let primaryFill = adaptive(Palette.primaryFill)
    static let onPrimaryFill = adaptive(Palette.onPrimaryFill)
    /// The Featured tag only.
    static let featuredFill = adaptive(Palette.featuredFill)
    static let onFeaturedFill = adaptive(Palette.onFeaturedFill)

    static let grabHandle = adaptiveAlpha(light: (0x2B2B29, 0.24), dark: (0xFFFFFF, 0.30))
```

In `Theme.Map`, delete the four `grade*` constants. Change the shadow colours' light hex from `0x161F13` to `0x000000` (alphas unchanged). Add, next to `adaptive(light:dark:)`:

```swift
    static func adaptive(_ pair: Palette.Pair) -> Color {
        adaptive(light: pair.light, dark: pair.dark)
    }
```

Rewrite the type's top doc comment to describe the neutral system in two or three sentences and point at `Palette.swift` and `DESIGN.md`.

- [ ] **Step 5: Remove the canopy wash and re-point components**

`Sources/DesignSystem/Materials.swift`: delete `canopyWash(height:)` and `struct CanopyWash`. Change `card(radius:)` to:

```swift
    func card(radius: CGFloat = Theme.Radius.md) -> some View {
        background(Theme.surface, in: Theme.shape(radius))
            .overlay { Theme.shape(radius).strokeBorder(Theme.separator, lineWidth: Theme.hairline) }
            .elevationSm()
    }
```

Replace every `.canopyWash()` / `.canopyWash(height: …)` call in the app with `.screenBackground()`.

`Sources/DesignSystem/Components.swift`, token by token:
- `SegmentedRing`: selected text `Theme.onPrimaryFill`, selected capsule `Theme.primaryFill`, track `Theme.fill`. Replace the track comment with: "A neutral well; the selected segment carries the only colour."
- `TagChip`: replace `Style` with `enum Style { case featured, neutral }`; `.featured` → foreground `Theme.onFeaturedFill`, background `Theme.featuredFill`; `.neutral` → foreground `Theme.label`, background `Theme.fill`; delete the outline overlay.
- `AvatarInitial`: emphasised → foreground `Theme.label`, background `Theme.fill`, ring `Theme.separator`.
- `PrimaryButtonStyle`: `Theme.onPrimaryFill` on `Theme.primaryFill`.
- `SecondaryButtonStyle`: `Theme.label` on `Theme.fill`.
- `CircularIconButton`: default tint `Theme.label`, background `Theme.fill`.
- `EmptyStateNote`: icon colour `Theme.labelTertiary`.

For every other compile error from a removed token, use this mapping: `accentSoft` → `fill`; `onAccentSoft` → `label`; `accentFill` → `primaryFill`; `onAccentFill` → `onPrimaryFill`; `accentMuted`, `accentStrong` → `accent`; `mist` → `separator`; `pinDisc` → `surface`; `progressFill`, `barFill` → `Theme.accent` (as a flat `ShapeStyle`); `sunlight` → delete the use.

- [ ] **Step 6: Stop tinting the basemap**

In `Sources/Features/Map/RouteMapView.swift`, delete `BasemapGradeOverlay` (type, the `map.addOverlay(BasemapGradeOverlay.make(), …)` line and its renderer branch, with their comments). The basemap now shows in MapKit's own muted style. Route lines keep `Theme.accent`; casing keeps `Theme.Map.casingLight/Dark`.

- [ ] **Step 7: Run the unit tests**

Expected: `TEST SUCCEEDED`, including the three new contrast tests.

- [ ] **Step 8: Look at it**

Build, install and launch on the iOS 26.5 simulator in light and dark (`xcrun simctl ui booted appearance dark`), screenshot the map and Me tabs with `xcrun simctl io booted screenshot /tmp/ws-<name>.png`, and read the screenshots. No green ground, card or wash should remain; only the route line, selected segment and primary buttons are green.

- [ ] **Step 9: Commit**

```bash
cd /Users/aurae25/walkable-shanghai
git add -A
git commit -m "Replace the canopy palette with neutral grounds and green primary actions"
```

---

### Task 4: Route model — fixed tags, updated date, no dead ends

**Files:**
- Create: `Sources/Data/RouteTag.swift`
- Modify: `Sources/Data/Models.swift`, `Sources/Data/Repositories.swift`, `Sources/Data/WalkStore.swift`, `Sources/Resources/SampleData.json`, `Sources/Resources/Localizable.xcstrings`, every view the compiler flags (`RouteDetailScreen`, `MapDiscoverScreen`, `TrackingScreen`, `DesignSystemGalleryView`, `RouteMapView`)
- Test: `Tests/SampleDataTests.swift`, `Tests/WalkStoreTests.swift`, `Tests/ProfileTests.swift`

**Interfaces:**
- Produces:
  - `enum RouteTag: String, Codable, CaseIterable, Sendable { case featured, popular }` with `var localizationKey: String` (`"tag.featured"`, `"tag.popular"`).
  - `Route` fields: `id`, `km`, `minutes`, `name: LocalizedText`, `note: LocalizedText`, `authorName`, `authorInitial`, `tags: [RouteTag]`, `updatedAt: Date`, `points`, `pin`; computed `isFeatured: Bool`.
  - `SampleDataLoader.decoder` (ISO-8601 dates) used for every catalogue decode.
  - `DraftRoute.asRoute(authorName:authorInitial:) -> Route`.
  - `RouteStore.mineRouteIds: Set<String>`.

- [ ] **Step 1: Write the failing tests**

Add to `Tests/SampleDataTests.swift`:

```swift
    func testTagsComeFromTheFixedListAndFeaturedIsATag() throws {
        let data = try SampleDataLoader.load()
        let featured = data.routes.filter(\.isFeatured)
        XCTAssertEqual(featured.map(\.id), ["wukang"])
        XCTAssertTrue(featured[0].tags.contains(.featured))
    }

    func testEveryRouteHasAnUpdatedDate() throws {
        let data = try SampleDataLoader.load()
        let calendar = Calendar(identifier: .gregorian)
        for route in data.routes {
            XCTAssertGreaterThanOrEqual(calendar.component(.year, from: route.updatedAt), 2026, route.id)
        }
    }

    func testEveryTagHasBothLanguages() {
        for tag in RouteTag.allCases {
            XCTAssertNotEqual(L10n.string(tag.localizationKey, .english), tag.localizationKey)
            XCTAssertNotEqual(L10n.string(tag.localizationKey, .chinese), tag.localizationKey)
        }
    }
```

Delete `testExactlyOneFeaturedRoute` (replaced above). In `testEveryRouteIsFullyBilingual`, keep only the `name` and `note` checks.

In `Tests/WalkStoreTests.swift`, replace `testDrawnRoutesAreNumberedAfterTheCatalogue` with:

```swift
    func testDrawnRoutesFollowTheCatalogueAndAreMarkedMine() throws {
        let container = try UserStateContainer.make(inMemory: true)
        let walks = WalkStore(container: container)
        _ = walks.saveDraftRoute(
            name: "Mine",
            coordinates: [
                CLLocationCoordinate2D(latitude: 31.21, longitude: 121.43),
                CLLocationCoordinate2D(latitude: 31.22, longitude: 121.44),
            ],
            tagKeys: []
        )
        let store = RouteStore()
        let catalogueCount = store.routes.count
        store.setDrawnRoutes(walks.draftRoutes, authorName: "Ben Qiu", authorInitial: "邱")

        XCTAssertEqual(store.routes.count, catalogueCount + 1)
        let drawn = try XCTUnwrap(store.routes.last)
        XCTAssertEqual(store.mineRouteIds, [drawn.id])
        XCTAssertTrue(drawn.tags.isEmpty)
    }
```

(Task 12 removes the `tagKeys` argument and updates this call.)

In `Tests/ProfileTests.swift`, change `testTheShareMessageCarriesTheRouteAndItsFigures` to assert the message contains the route name, `"3.4"` and `"52"`, and does **not** contain "dead end" or "断点".

- [ ] **Step 2: Run them to see them fail**

Expected: compile errors for `RouteTag`, `updatedAt`, `mineRouteIds`.

- [ ] **Step 3: Add the tag list**

`Sources/Data/RouteTag.swift`:

```swift
import Foundation

/// The tags a route can carry.
///
/// A fixed list the developers own, not free text: tags mark something the
/// app vouches for, like a featured or popular walk. Adding one means adding a
/// case here and its two strings (`tag.<case>`) to the string catalogue.
enum RouteTag: String, Codable, CaseIterable, Sendable {
    case featured
    case popular

    var localizationKey: String { "tag.\(rawValue)" }
}
```

```bash
python3 Scripts/strings.py set tag.featured "Featured" "精选" "Route tag chosen by the editors."
python3 Scripts/strings.py set tag.popular "Popular" "热门" "Route tag chosen by the editors."
```

- [ ] **Step 4: Reshape `Route`**

In `Sources/Data/Models.swift`, replace `Route` with:

```swift
/// The core entity: a walk someone has done end to end and published.
struct Route: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let km: Double
    let minutes: Int

    let name: LocalizedText
    /// The description shown on the route card.
    let note: LocalizedText

    let authorName: String
    /// One character, drawn in the avatar circle.
    let authorInitial: String

    /// From the fixed list in `RouteTag`. Order is display order.
    let tags: [RouteTag]
    /// When the route's line or description last changed.
    let updatedAt: Date

    let points: [Coordinate]
    /// Where the map pin sits — not necessarily on the line.
    let pin: Coordinate

    var isFeatured: Bool { tags.contains(.featured) }
}
```

In `Sources/Data/Repositories.swift`:
- `allRoutes()` returns `data.routes` in file order (no sort);
- `featuredRoute()` uses `isFeatured`;
- add to `SampleDataLoader`:

```swift
    /// The one decoder for catalogue JSON. Dates are ISO 8601 calendar dates
    /// ("2026-10-03") so the file stays readable.
    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        formatter.dateFormat = "yyyy-MM-dd"
        decoder.dateDecodingStrategy = .formatted(formatter)
        return decoder
    }
```

and use `decoder.decode(SampleData.self, from: raw)` in `load`.

In `RouteStore`, add `private(set) var mineRouteIds: Set<String> = []` and rewrite `setDrawnRoutes`:

```swift
    /// Folds the walker's drawn routes in after the catalogue, oldest first.
    func setDrawnRoutes(_ drafts: [DraftRoute], authorName: String, authorInitial: String) {
        let drawn = drafts
            .sorted { $0.createdAt < $1.createdAt }
            .map { $0.asRoute(authorName: authorName, authorInitial: authorInitial) }
        routes = bundledRoutes + drawn
        mineRouteIds = Set(drawn.map(\.id))
    }
```

In `Sources/Data/WalkStore.swift`, change `DraftRoute.asRoute(number:authorName:authorInitial:)` to `asRoute(authorName:authorInitial:)` building:

```swift
        return Route(
            id: id,
            km: km,
            minutes: minutes,
            name: LocalizedText(en: name, zh: name),
            note: LocalizedText(en: "", zh: ""),
            authorName: authorName,
            authorInitial: authorInitial,
            tags: [],
            updatedAt: createdAt,
            points: line.map { Coordinate(lat: $0.latitude, lng: $0.longitude) },
            pin: Coordinate(lat: line.first?.latitude ?? 0, lng: line.first?.longitude ?? 0)
        )
```


- [ ] **Step 5: Rewrite the catalogue fields**

```bash
python3 - <<'EOF'
import json
p = "Sources/Resources/SampleData.json"
d = json.load(open(p, encoding="utf-8"))
updated = {"wukang": "2026-10-03", "creek": "2026-09-27", "fuxing": "2026-09-18", "bund": "2026-10-08", "century": "2026-08-30"}
tags = {"wukang": ["featured", "popular"], "creek": ["popular"]}
for r in d["routes"]:
    for k in ["number", "breaks", "area", "kicker", "tag1", "tag2", "walkCount", "downloadSize", "isFeatured"]:
        r.pop(k, None)
    r["tags"] = tags.get(r["id"], [])
    r["updatedAt"] = updated[r["id"]]
json.dump(d, open(p, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
open(p, "a").write("\n")
EOF
python3 -c "import json; print([r['id'] for r in json.load(open('Sources/Resources/SampleData.json'))['routes']])"
```

Expected output lists five ids. If an id differs from the five in `updated`, the script raises `KeyError`; add the missing id with a 2026 date and rerun.

Update `_comment` in the JSON to describe the new route fields in one sentence.

- [ ] **Step 6: Follow the compiler through the views**

Build. For each error:
- `route.number` → remove (pins and rows are identified by `route.id`; `RoutePinAnnotation` loses `number`, its view draws a plain dot of `Theme.accent` on `Theme.surface`, identifier `route-pin-<id>`);
- `route.breaks`, `unit.deadEnds`, `track.deadEndsAhead`, `route.deadEndCount` → delete the figure or line;
- `route.kicker`, `tag1`, `tag2`, `area` → delete;
- `walkCount` → delete (the credit line is rebuilt in Task 10).

The share message drops dead ends:

```bash
python3 Scripts/strings.py set route.share.message "%1\$@ — %2\$@ km, %3\$@ min. On Walkable Shanghai." "%1\$@ —— %2\$@ 公里，%3\$@ 分钟。来自 Walkable Shanghai。"
python3 Scripts/strings.py remove unit.deadEnds track.deadEndsAhead route.deadEndCount route.walkCount route.credit
```

`shareText` passes three arguments: name, km, minutes.

- [ ] **Step 7: Run the unit tests**

Expected: `TEST SUCCEEDED`.

- [ ] **Step 8: Commit**

```bash
cd /Users/aurae25/walkable-shanghai
git add -A
git commit -m "Give routes a fixed tag list and an updated date; drop dead ends, kickers and numbers"
```

---

### Task 5: Walker-activity hook

**Files:**
- Create: `Sources/Data/RouteActivity.swift`, `Tests/RouteActivityTests.swift`
- Modify: `Sources/Data/Models.swift` (`SampleData.activity`), `Sources/Data/Repositories.swift` (`RouteStore.activity`), `Sources/Resources/SampleData.json`

**Interfaces:**
- Produces:
  - `enum ActivityPeriod: String, CaseIterable, Sendable { case today, week, month, allTime }` with `localizationKey` (`"period.today"` …).
  - `struct WalkCounts: Codable, Hashable, Sendable { let today, week, month, allTime: Int }` with `func count(for: ActivityPeriod) -> Int`.
  - `protocol RouteActivityProvider: Sendable { func walkingNow(routeId: String) -> Int; func walks(routeId: String, period: ActivityPeriod) -> Int }`.
  - `struct OfflineActivityProvider: RouteActivityProvider` (`init(counts: [String: WalkCounts])`).
  - `RouteStore.activity: any RouteActivityProvider`.

- [ ] **Step 1: Write the failing tests**

`Tests/RouteActivityTests.swift`:

```swift
import XCTest
@testable import WalkableShanghai

final class RouteActivityTests: XCTestCase {

    func testWalkingNowIsZeroWithoutAServer() {
        let provider = OfflineActivityProvider(counts: ["wukang": WalkCounts(today: 2, week: 9, month: 30, allTime: 120)])
        XCTAssertEqual(provider.walkingNow(routeId: "wukang"), 0)
        XCTAssertEqual(provider.walkingNow(routeId: "unknown"), 0)
    }

    func testPeriodCountsComeFromTheBundle() {
        let provider = OfflineActivityProvider(counts: ["wukang": WalkCounts(today: 2, week: 9, month: 30, allTime: 120)])
        XCTAssertEqual(provider.walks(routeId: "wukang", period: .today), 2)
        XCTAssertEqual(provider.walks(routeId: "wukang", period: .week), 9)
        XCTAssertEqual(provider.walks(routeId: "wukang", period: .month), 30)
        XCTAssertEqual(provider.walks(routeId: "wukang", period: .allTime), 120)
        XCTAssertEqual(provider.walks(routeId: "unknown", period: .week), 0)
    }

    func testTheStoreServesTheBundledCounts() {
        let store = RouteStore()
        XCTAssertGreaterThan(store.activity.walks(routeId: "wukang", period: .allTime), 0)
        XCTAssertEqual(store.activity.walkingNow(routeId: "wukang"), 0)
    }

    func testEveryPeriodHasBothLanguages() {
        for period in ActivityPeriod.allCases {
            XCTAssertNotEqual(L10n.string(period.localizationKey, .english), period.localizationKey)
            XCTAssertNotEqual(L10n.string(period.localizationKey, .chinese), period.localizationKey)
        }
    }
}
```

- [ ] **Step 2: Run them to see them fail**

Expected: compile errors for the new types.

- [ ] **Step 3: Implement**

`Sources/Data/RouteActivity.swift`:

```swift
import Foundation

/// The windows Popular can rank by.
enum ActivityPeriod: String, CaseIterable, Sendable {
    case today, week, month, allTime

    var localizationKey: String { "period.\(rawValue)" }
}

/// How many walks a route had in each window.
struct WalkCounts: Codable, Hashable, Sendable {
    let today: Int
    let week: Int
    let month: Int
    let allTime: Int

    func count(for period: ActivityPeriod) -> Int {
        switch period {
        case .today: return today
        case .week: return week
        case .month: return month
        case .allTime: return allTime
        }
    }
}

/// Live and recent activity on routes: who is walking now, and how often each
/// route was walked lately.
///
/// Only a server can know either. Every screen asks through this protocol so
/// that a networked provider can replace the offline one without any view
/// changing.
protocol RouteActivityProvider: Sendable {
    func walkingNow(routeId: String) -> Int
    func walks(routeId: String, period: ActivityPeriod) -> Int
}

/// The provider the app ships with while there is no server.
///
/// Walking-now is zero, which is also what a connected app should show when
/// it cannot reach the server. Recent walk counts come from the bundled
/// catalogue so Popular has something real to sort.
struct OfflineActivityProvider: RouteActivityProvider {
    let counts: [String: WalkCounts]

    func walkingNow(routeId: String) -> Int { 0 }

    func walks(routeId: String, period: ActivityPeriod) -> Int {
        counts[routeId]?.count(for: period) ?? 0
    }
}
```

In `SampleData` add `let activity: [String: WalkCounts]`. In `RouteStore` add:

```swift
    /// Who is walking what. Offline for now; see `RouteActivityProvider`.
    @ObservationIgnored private(set) var activity: any RouteActivityProvider = OfflineActivityProvider(counts: [:])
```

and set `activity = OfflineActivityProvider(counts: data.activity)` in `init` after loading.

Add the counts and strings:

```bash
python3 - <<'EOF'
import json
p = "Sources/Resources/SampleData.json"
d = json.load(open(p, encoding="utf-8"))
d["_activityNote"] = "Recent walk counts per route. Bundled until a server provides them; walking-now is never bundled."
d["activity"] = {
    "wukang": {"today": 3, "week": 14, "month": 52, "allTime": 410},
    "creek": {"today": 1, "week": 9, "month": 31, "allTime": 260},
    "fuxing": {"today": 0, "week": 4, "month": 22, "allTime": 190},
    "bund": {"today": 2, "week": 11, "month": 27, "allTime": 330},
    "century": {"today": 0, "week": 0, "month": 6, "allTime": 75},
}
json.dump(d, open(p, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
open(p, "a").write("\n")
EOF
python3 Scripts/strings.py set period.today "Today" "今天"
python3 Scripts/strings.py set period.week "This week" "本周"
python3 Scripts/strings.py set period.month "This month" "本月"
python3 Scripts/strings.py set period.allTime "All time" "全部"
```

If the five route ids differ from these, use the real ids.

- [ ] **Step 4: Run the unit tests**

Expected: `TEST SUCCEEDED`.

- [ ] **Step 5: Commit**

```bash
cd /Users/aurae25/walkable-shanghai
git add -A
git commit -m "Add the walker-activity hook with an offline provider"
```

---

### Task 6: Saving a route downloads it

**Files:**
- Modify: `Sources/Data/RouteUserState.swift`, `Sources/Data/SavedRoutesStore.swift`, `Sources/App/WalkableShanghaiApp.swift`, `Sources/Features/Route/RouteDetailScreen.swift`
- Test: `Tests/UserStateTests.swift`, `Tests/OfflineTests.swift`

**Interfaces:**
- Consumes: `OfflineStore.download(route:imageSize:)`, `OfflineStore.remove(routeId:)` (Task 2).
- Produces: `@MainActor SavedRoutesStore` with `init(container:offline:resetToSeed:)`, `isSaved(_:)`, `savedRouteIds`, `savedCount`, `setSaved(_:route:)`, `toggleSaved(_ route: Route)`, `removeAllDownloads()`, `ensureDownloads(routes:)`. Removed: `isOffline`, `offlineRouteIds`, `offlineCount`, `toggleOffline`, `seededOffline`, `RouteUserState.isOffline`.

- [ ] **Step 1: Rewrite the user-state tests**

In `Tests/UserStateTests.swift`, mark the class `@MainActor`, delete `testSavedAndOfflineAreIndependent`, change every `SavedRoutesStore(container:…)` to pass `offline: OfflineStore(container: container)`, change `toggleSaved("id")` calls to `toggleSaved(route("id"))` with this helper in the class:

```swift
    private func route(_ id: String) -> Route {
        RouteStore().route(id: id)!
    }
```

and add:

```swift
    func testSavingDownloadsAndUnsavingDeletes() throws {
        let container = try UserStateContainer.make(inMemory: true)
        let offline = OfflineStore(container: container)
        let saved = SavedRoutesStore(container: container, offline: offline, resetToSeed: true)

        saved.setSaved(false, route: route("fuxing"))
        XCTAssertFalse(offline.hasBundle("fuxing"))

        saved.setSaved(true, route: route("fuxing"))
        XCTAssertTrue(saved.isSaved("fuxing"))
        XCTAssertTrue(offline.hasBundle("fuxing"))

        saved.setSaved(false, route: route("fuxing"))
        XCTAssertFalse(saved.isSaved("fuxing"))
        XCTAssertFalse(offline.hasBundle("fuxing"))
    }

    func testRemoveAllDownloadsAlsoClearsBookmarks() throws {
        let container = try UserStateContainer.make(inMemory: true)
        let offline = OfflineStore(container: container)
        let saved = SavedRoutesStore(container: container, offline: offline, resetToSeed: true)
        saved.ensureDownloads(routes: RouteStore().routes)
        XCTAssertFalse(offline.bundles.isEmpty)

        saved.removeAllDownloads()
        XCTAssertTrue(offline.bundles.isEmpty)
        XCTAssertEqual(saved.savedCount, 0)
    }

    func testEnsureDownloadsBacksEverySavedRoute() throws {
        let container = try UserStateContainer.make(inMemory: true)
        let offline = OfflineStore(container: container)
        let saved = SavedRoutesStore(container: container, offline: offline, resetToSeed: true)
        saved.ensureDownloads(routes: RouteStore().routes)
        XCTAssertEqual(Set(offline.bundles.map(\.routeId)), saved.savedRouteIds)
    }
```

Update `testAFreshStoreSeedsTheDesignedState` to assert only `savedRouteIds == SavedRoutesStore.seededSaved`.

- [ ] **Step 2: Run them to see them fail**

Expected: compile errors (`offline:` argument, `setSaved`, `removeAllDownloads`, `ensureDownloads`).

- [ ] **Step 3: Implement**

`Sources/Data/RouteUserState.swift`: delete `isOffline` from the model and its init.

`Sources/Data/SavedRoutesStore.swift`: mark the class `@MainActor`; delete `seededOffline`, `offlineRouteIds`, `isOffline`, `offlineCount`, `toggleOffline`; store the offline store; seed only saved ids. New public surface:

```swift
    @ObservationIgnored private let offline: OfflineStore

    init(container: ModelContainer, offline: OfflineStore, resetToSeed: Bool = false) {
        self.context = ModelContext(container)
        self.offline = offline
        if resetToSeed {
            wipe()
        }
        seedIfEmpty()
        reload()
    }

    /// Saving and downloading are one state: a saved route is kept on the
    /// phone so it works without a network, and unsaving frees the space.
    func setSaved(_ isSaved: Bool, route: Route) {
        let row = rowOrCreate(route.id)
        row.isSaved = isSaved
        persist()
        if isSaved {
            offline.download(route: route)
        } else {
            offline.remove(routeId: route.id)
        }
        reload()
    }

    func toggleSaved(_ route: Route) {
        setSaved(!isSaved(route.id), route: route)
    }

    /// Builds the download for any saved route that lacks one — the seeded
    /// routes on first launch, or routes saved before saving meant downloading.
    func ensureDownloads(routes: [Route]) {
        for route in routes where isSaved(route.id) && !offline.hasBundle(route.id) {
            offline.download(route: route)
        }
    }

    /// Frees every download. Because saved and downloaded are one state, this
    /// also clears the bookmarks.
    func removeAllDownloads() {
        for row in allRows() where row.isSaved {
            row.isSaved = false
            offline.remove(routeId: row.routeId)
        }
        persist()
        reload()
    }
```

Update the class doc comment to say saved routes are downloaded automatically. `seedIfEmpty` inserts `RouteUserState(routeId: id, isSaved: true)` for each `seededSaved` id. `reload` sets only `savedRouteIds`.

`Sources/App/WalkableShanghaiApp.swift`: create `offlineStore` before `savedRoutesStore`, pass it in, and replace the offline back-fill loop with `savedRoutesStore.ensureDownloads(routes: routeStore.routes)` after the route store is built.

`Sources/Features/Route/RouteDetailScreen.swift` (temporary until Task 10): delete the download/offline-ready button and `setOffline`; the bookmark calls `saved.toggleSaved(route)`.

`Tests/OfflineTests.swift`: replace any use of `isOffline`/`toggleOffline` with `offline.hasBundle`.

- [ ] **Step 4: Run the unit tests**

Expected: `TEST SUCCEEDED`.

- [ ] **Step 5: Commit**

```bash
cd /Users/aurae25/walkable-shanghai
git add -A
git commit -m "Make saving a route download it, and unsaving delete the download"
```

---

### Task 7: Route list logic

Pure functions that decide what the sheet lists, in what order and under which headings. No SwiftUI.

**Files:**
- Create: `Sources/Features/Map/RouteList.swift`, `Tests/RouteListTests.swift`

**Interfaces:**
- Consumes: `Route`, `RouteTag`, `ActivityPeriod`, `RouteActivityProvider`.
- Produces:

```swift
enum RouteListOption: String, CaseIterable, Sendable { case nearby, popular, featured, mine, saved }   // localizationKey "routes.option.<raw>"
struct RouteListQuery: Equatable, Sendable { var option: RouteListOption = .nearby; var period: ActivityPeriod = .week; var searchText = "" }
struct RouteListSection: Equatable, Sendable { enum Kind: Sendable { case all, mine, saved }; let kind: Kind; let routes: [Route]; let offersNewRoute: Bool }
enum RouteList {
    static let peoplesSquare: Coordinate
    static func sections(routes: [Route], query: RouteListQuery, mineIds: Set<String>, savedIds: Set<String>, origin: Coordinate?, activity: any RouteActivityProvider) -> [RouteListSection]
    static func matches(_ route: Route, search: String) -> Bool
}
```

- [ ] **Step 1: Write the failing tests**

`Tests/RouteListTests.swift`:

```swift
import XCTest
@testable import WalkableShanghai

final class RouteListTests: XCTestCase {

    private func route(_ id: String, lat: Double, lng: Double, tags: [RouteTag] = [], en: String? = nil, zh: String? = nil) -> Route {
        Route(
            id: id, km: 1, minutes: 12,
            name: LocalizedText(en: en ?? id, zh: zh ?? id),
            note: LocalizedText(en: "", zh: ""),
            authorName: "A", authorInitial: "A",
            tags: tags, updatedAt: Date(timeIntervalSince1970: 0),
            points: [Coordinate(lat: lat, lng: lng), Coordinate(lat: lat + 0.001, lng: lng)],
            pin: Coordinate(lat: lat, lng: lng)
        )
    }

    private let near = Coordinate(lat: 31.2304, lng: 121.4737)
    private lazy var routes = [
        route("far", lat: 31.30, lng: 121.60, tags: [.featured], en: "Far Loop", zh: "远环"),
        route("close", lat: 31.231, lng: 121.474, en: "Close Lane", zh: "近巷"),
        route("mid", lat: 31.25, lng: 121.50, tags: [.popular], en: "Middle Walk", zh: "中段"),
        route("draft-1", lat: 31.24, lng: 121.48, en: "My Line", zh: "My Line"),
    ]
    private let activity = OfflineActivityProvider(counts: [
        "far": WalkCounts(today: 0, week: 2, month: 9, allTime: 50),
        "close": WalkCounts(today: 1, week: 7, month: 8, allTime: 20),
        "mid": WalkCounts(today: 0, week: 0, month: 30, allTime: 90),
    ])

    private func ids(_ query: RouteListQuery, origin: Coordinate? = nil, saved: Set<String> = []) -> [[String]] {
        RouteList.sections(routes: routes, query: query, mineIds: ["draft-1"], savedIds: saved, origin: origin, activity: activity)
            .map { $0.routes.map(\.id) }
    }

    func testNearbyIsTheDefaultAndSortsByDistance() {
        XCTAssertEqual(RouteListQuery().option, .nearby)
        XCTAssertEqual(ids(RouteListQuery(), origin: near), [["close", "draft-1", "mid", "far"]])
    }

    func testNearbyFallsBackToPeoplesSquare() {
        XCTAssertEqual(ids(RouteListQuery(), origin: nil), ids(RouteListQuery(), origin: RouteList.peoplesSquare))
    }

    func testPopularRanksByThePeriodAndDropsUnwalkedRoutes() {
        XCTAssertEqual(ids(RouteListQuery(option: .popular, period: .week)), [["close", "far"]])
        XCTAssertEqual(ids(RouteListQuery(option: .popular, period: .month)), [["mid", "far", "close"]])
        XCTAssertEqual(ids(RouteListQuery(option: .popular, period: .today)), [["close"]])
        XCTAssertEqual(ids(RouteListQuery(option: .popular, period: .allTime)), [["mid", "far", "close"]])
    }

    func testFeaturedKeepsOnlyFeaturedRoutes() {
        XCTAssertEqual(ids(RouteListQuery(option: .featured)), [["far"]])
    }

    func testMineListsOnlyTheWalkersRoutesAndOffersANewOne() {
        let sections = RouteList.sections(routes: routes, query: RouteListQuery(option: .mine), mineIds: ["draft-1"], savedIds: [], origin: nil, activity: activity)
        XCTAssertEqual(sections.map(\.kind), [.mine])
        XCTAssertEqual(sections[0].routes.map(\.id), ["draft-1"])
        XCTAssertTrue(sections[0].offersNewRoute)
    }

    func testSavedShowsMineFirstThenSavedWithoutRepeats() {
        let sections = RouteList.sections(routes: routes, query: RouteListQuery(option: .saved), mineIds: ["draft-1"], savedIds: ["mid", "draft-1"], origin: nil, activity: activity)
        XCTAssertEqual(sections.map(\.kind), [.mine, .saved])
        XCTAssertEqual(sections[0].routes.map(\.id), ["draft-1"])
        XCTAssertTrue(sections[0].offersNewRoute)
        XCTAssertEqual(sections[1].routes.map(\.id), ["mid"])
        XCTAssertFalse(sections[1].offersNewRoute)
    }

    func testSearchMatchesEitherLanguageIgnoringCaseAndSpaces() {
        XCTAssertEqual(ids(RouteListQuery(option: .nearby, searchText: "  lane "), origin: near), [["close"]])
        XCTAssertEqual(ids(RouteListQuery(option: .nearby, searchText: "远"), origin: near), [["far"]])
        XCTAssertEqual(ids(RouteListQuery(option: .nearby, searchText: ""), origin: near).first?.count, 4)
    }

    func testEmptySectionsAreStillReturnedSoTheSheetCanExplainThem() {
        let sections = RouteList.sections(routes: routes, query: RouteListQuery(option: .saved), mineIds: [], savedIds: [], origin: nil, activity: activity)
        XCTAssertEqual(sections.map(\.kind), [.mine, .saved])
        XCTAssertTrue(sections.allSatisfy { $0.routes.isEmpty })
    }

    func testEveryOptionHasBothLanguages() {
        for option in RouteListOption.allCases {
            XCTAssertNotEqual(L10n.string(option.localizationKey, .english), option.localizationKey)
            XCTAssertNotEqual(L10n.string(option.localizationKey, .chinese), option.localizationKey)
        }
    }
}
```

- [ ] **Step 2: Run them to see them fail**

Expected: compile errors for `RouteList`, `RouteListQuery`, `RouteListOption`, `RouteListSection`.

- [ ] **Step 3: Implement**

`Sources/Features/Map/RouteList.swift`:

```swift
import Foundation
import CoreLocation

/// The five ways the Routes sheet can list routes.
enum RouteListOption: String, CaseIterable, Sendable {
    case nearby, popular, featured, mine, saved

    var localizationKey: String { "routes.option.\(rawValue)" }
}

/// Everything that decides the sheet's contents.
struct RouteListQuery: Equatable, Sendable {
    var option: RouteListOption = .nearby
    /// Only Popular reads this.
    var period: ActivityPeriod = .week
    var searchText = ""
}

struct RouteListSection: Equatable, Sendable {
    enum Kind: Sendable { case all, mine, saved }

    let kind: Kind
    let routes: [Route]
    /// The walker's own section carries the New route button.
    let offersNewRoute: Bool
}

/// What the sheet lists, decided without any view.
///
/// Kept pure so every ordering rule is a unit test rather than a screenshot.
/// The map's pins are drawn from the same sections, so the two never disagree.
enum RouteList {

    /// Where Nearby measures from when the walker's location is unknown.
    static let peoplesSquare = Coordinate(lat: 31.2304, lng: 121.4737)

    static func sections(
        routes: [Route],
        query: RouteListQuery,
        mineIds: Set<String>,
        savedIds: Set<String>,
        origin: Coordinate?,
        activity: any RouteActivityProvider
    ) -> [RouteListSection] {
        let visible = routes.filter { matches($0, search: query.searchText) }

        switch query.option {
        case .nearby:
            let from = location(origin ?? peoplesSquare)
            let sorted = visible.sorted {
                location($0.pin).distance(from: from) < location($1.pin).distance(from: from)
            }
            return [RouteListSection(kind: .all, routes: sorted, offersNewRoute: false)]

        case .popular:
            let ranked = visible
                .map { ($0, activity.walks(routeId: $0.id, period: query.period)) }
                .filter { $0.1 > 0 }
                .enumerated()
                // Ties keep catalogue order, so the list does not shuffle
                // between launches.
                .sorted { $0.element.1 != $1.element.1 ? $0.element.1 > $1.element.1 : $0.offset < $1.offset }
                .map { $0.element.0 }
            return [RouteListSection(kind: .all, routes: ranked, offersNewRoute: false)]

        case .featured:
            return [RouteListSection(kind: .all, routes: visible.filter(\.isFeatured), offersNewRoute: false)]

        case .mine:
            return [RouteListSection(kind: .mine, routes: visible.filter { mineIds.contains($0.id) }, offersNewRoute: true)]

        case .saved:
            let mine = visible.filter { mineIds.contains($0.id) }
            // A route the walker drew and also bookmarked shows once, as theirs.
            let saved = visible.filter { savedIds.contains($0.id) && !mineIds.contains($0.id) }
            return [
                RouteListSection(kind: .mine, routes: mine, offersNewRoute: true),
                RouteListSection(kind: .saved, routes: saved, offersNewRoute: false),
            ]
        }
    }

    /// Case-insensitive match on the route name in either language.
    static func matches(_ route: Route, search: String) -> Bool {
        let needle = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return true }
        return route.name.en.localizedCaseInsensitiveContains(needle)
            || route.name.zh.localizedCaseInsensitiveContains(needle)
    }

    private static func location(_ coordinate: Coordinate) -> CLLocation {
        CLLocation(latitude: coordinate.lat, longitude: coordinate.lng)
    }
}
```


```bash
python3 Scripts/strings.py set routes.option.nearby "Nearby" "附近"
python3 Scripts/strings.py set routes.option.popular "Popular" "热门"
python3 Scripts/strings.py set routes.option.featured "Featured" "精选"
python3 Scripts/strings.py set routes.option.mine "Mine" "我的"
python3 Scripts/strings.py set routes.option.saved "Saved" "已收藏"
```

- [ ] **Step 4: Run the unit tests**

Expected: `TEST SUCCEEDED`.

- [ ] **Step 5: Commit**

```bash
cd /Users/aurae25/walkable-shanghai
git add -A
git commit -m "Add the route-list logic behind the Routes sheet"
```

---

### Task 8: Map styles on MapKit

The app stays on Apple MapKit. The comparison is in `research/map-provider/`. MapKit is the only option that is lawful to show in mainland China with no licence or account, offers satellite and traffic there, and fits the existing wrapper. AMap, Tencent and Baidu need commercial licences (¥50,000/year) and Chinese accounts, and lack English labels or arm64 simulator support. Mapbox and MapLibre are not lawful or reliable for users inside mainland China. This task adds the three styles to the existing wrapper and makes the wrapper redraw when its mode changes, which the route card (Task 10) relies on.

**Files:**
- Create: `Sources/Features/Map/MapStyleOption.swift`, `Tests/MapStyleTests.swift`
- Modify: `Sources/Localization/AppSettings.swift`, `Sources/Features/Map/RouteMapView.swift`

**Interfaces:**
- Produces:
  - `enum MapStyleOption: String, CaseIterable, Sendable { case standard, satellite, traffic }` with `localizationKey` (`"map.style.<raw>"`) and `systemImage`.
  - `AppSettings.mapStyle: MapStyleOption`, persisted under `settings.mapStyle`, default `.standard`.
  - `RouteMapView.style: MapStyleOption` (default `.standard`) and `RouteMapView.configuration(for: MapStyleOption) -> MKMapConfiguration`.
  - Wrapper contract used by Tasks 9 and 10: the map redraws and re-frames whenever the set of routes, the mode or the appearance changes; the `MKMapView` carries accessibility identifier `route-map` and accessibility value equal to the style's raw value; pins are identified `route-pin-<routeId>`.

- [ ] **Step 1: Write the failing tests**

`Tests/MapStyleTests.swift`:

```swift
import XCTest
import MapKit
@testable import WalkableShanghai

@MainActor
final class MapStyleTests: XCTestCase {

    func testEachStyleMapsToItsMapKitConfiguration() throws {
        let standard = try XCTUnwrap(RouteMapView.configuration(for: .standard) as? MKStandardMapConfiguration)
        XCTAssertEqual(standard.emphasisStyle, .muted)
        XCTAssertFalse(standard.showsTraffic)

        let traffic = try XCTUnwrap(RouteMapView.configuration(for: .traffic) as? MKStandardMapConfiguration)
        XCTAssertTrue(traffic.showsTraffic)

        XCTAssertTrue(RouteMapView.configuration(for: .satellite) is MKHybridMapConfiguration)
    }

    func testTheChoicePersistsAndDefaultsToStandard() {
        let defaults = UserDefaults(suiteName: "MapStyleTests")!
        defaults.removePersistentDomain(forName: "MapStyleTests")

        XCTAssertEqual(AppSettings(defaults: defaults).mapStyle, .standard)

        let settings = AppSettings(defaults: defaults)
        settings.mapStyle = .satellite
        XCTAssertEqual(AppSettings(defaults: defaults).mapStyle, .satellite)
    }

    func testEveryStyleHasBothLanguages() {
        for style in MapStyleOption.allCases {
            XCTAssertNotEqual(L10n.string(style.localizationKey, .english), style.localizationKey)
            XCTAssertNotEqual(L10n.string(style.localizationKey, .chinese), style.localizationKey)
        }
    }
}
```

- [ ] **Step 2: Run them to see them fail**

Expected: compile errors for `MapStyleOption`, `mapStyle`, `configuration(for:)`.

- [ ] **Step 3: The option and the setting**

`Sources/Features/Map/MapStyleOption.swift`:

```swift
import Foundation

/// The three basemaps the walker can choose between on the map.
enum MapStyleOption: String, CaseIterable, Sendable {
    case standard
    case satellite
    case traffic

    var localizationKey: String { "map.style.\(rawValue)" }

    var systemImage: String {
        switch self {
        case .standard: return "map"
        case .satellite: return "globe.asia.australia"
        case .traffic: return "car"
        }
    }
}
```

In `Sources/Localization/AppSettings.swift`, add `static let mapStyle = "settings.mapStyle"` to `Key`, and:

```swift
    var mapStyle: MapStyleOption {
        didSet {
            guard mapStyle != oldValue else { return }
            defaults.set(mapStyle.rawValue, forKey: Key.mapStyle)
        }
    }
```

initialised in `init` with `self.mapStyle = defaults.string(forKey: Key.mapStyle).flatMap(MapStyleOption.init(rawValue:)) ?? .standard`.

```bash
cd /Users/aurae25/walkable-shanghai/WalkableShanghai
python3 Scripts/strings.py set map.style.standard "Map" "地图"
python3 Scripts/strings.py set map.style.satellite "Satellite" "卫星"
python3 Scripts/strings.py set map.style.traffic "Traffic" "路况"
python3 Scripts/strings.py set map.style.button "Map style" "地图样式" "Accessibility label for the map-style button."
```

- [ ] **Step 4: Teach the wrapper the styles**

In `Sources/Features/Map/RouteMapView.swift`:

- declare `var style: MapStyleOption = .standard` directly after `let routes: [Route]`, so the memberwise initialiser takes it as `RouteMapView(mode:routes:style:bottomInset:topInset:onSelectRoute:…)`;
- add, as a static function on `RouteMapView`:

```swift
    /// MapKit's configuration for each style.
    ///
    /// Standard keeps the muted emphasis so the route reads over the map, and
    /// hides Apple's points of interest, which compete with our pins. Traffic
    /// is the same map with traffic drawn. Satellite is imagery with street
    /// labels (MapKit's hybrid), because bare imagery gives a walker nothing
    /// to read.
    static func configuration(for style: MapStyleOption) -> MKMapConfiguration {
        switch style {
        case .standard, .traffic:
            let configuration = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .muted)
            configuration.pointOfInterestFilter = .excludingAll
            configuration.showsTraffic = style == .traffic
            return configuration
        case .satellite:
            let configuration = MKHybridMapConfiguration(elevationStyle: .flat)
            configuration.pointOfInterestFilter = .excludingAll
            return configuration
        }
    }
```

- in `makeUIView`, replace the three configuration lines and their comment with `map.preferredConfiguration = Self.configuration(for: style)`, and add `map.accessibilityIdentifier = "route-map"` and `map.accessibilityValue = style.rawValue`;
- add `var lastStyle: MapStyleOption?` to `Coordinator`, and at the top of `updateUIView`, after `context.coordinator.parent = self`:

```swift
        if context.coordinator.lastStyle != style {
            context.coordinator.lastStyle = style
            map.preferredConfiguration = Self.configuration(for: style)
            map.accessibilityValue = style.rawValue
        }
```

- add the mode to the redraw signature, so selecting a route redraws (pins off, one line) even when the list already held only that route:

```swift
        let signature = routes.map(\.id).joined(separator: ",") + "|\(mode)|\(colorScheme)"
```

- update the comment above the signature to mention the mode.

- [ ] **Step 5: Run the unit tests**

Expected: `TEST SUCCEEDED`, including `MapStyleTests`.

- [ ] **Step 6: Look at each style on both runtimes**

The style can be forced with a launch argument, because `AppSettings` reads `UserDefaults` and the argument domain wins:

```bash
cd /Users/aurae25/walkable-shanghai/WalkableShanghai
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
for device in "iPhone 17 Pro" "iPhone 16 Pro"; do
  xcodebuild -project WalkableShanghai.xcodeproj -scheme WalkableShanghai -sdk iphonesimulator -destination "platform=iOS Simulator,name=$device" -derivedDataPath /tmp/ws-style build -quiet
  xcrun simctl boot "$device" 2>/dev/null
  xcrun simctl install "$device" /tmp/ws-style/Build/Products/Debug-iphonesimulator/WalkableShanghai.app
  for style in standard satellite traffic; do
    xcrun simctl terminate "$device" com.walkableshanghai.app 2>/dev/null
    xcrun simctl launch "$device" com.walkableshanghai.app -settings.hasSeenOnboarding YES -settings.mapStyle $style
    sleep 8
    xcrun simctl io "$device" screenshot "/tmp/ws-style-${device// /-}-$style.png"
  done
done
```

Read all six screenshots. Record in the task comment which runtimes draw scenery for which style. On 2026-10-11 Apple's China map endpoints answered from this Mac over a VPN, so the iOS 26.5 blank-basemap problem in the README may be gone; report what the screenshots show, not what the README says. If a style is blank on a runtime, that is a network fact to document in Task 14, not a code bug — do not work around it.

- [ ] **Step 7: Commit**

```bash
cd /Users/aurae25/walkable-shanghai
git add -A
git commit -m "Add Map, Satellite and Traffic styles to the MapKit wrapper"
```

---

### Task 9: Routes sheet — dropdown, period selector, sections, rows, search

**Files:**
- Create: `Sources/Features/Map/RouteListSheet.swift`, `Sources/Features/Map/NearbyOrigin.swift`, `UITests/Support/AppLaunch.swift`, `UITests/RouteListUITests.swift`, `UITests/MapStyleUITests.swift`
- Modify: `Sources/Features/Map/MapDiscoverScreen.swift`, `Sources/DesignSystem/Components.swift` (`RouteRow`), `Sources/App/WalkableShanghaiApp.swift` (nothing new to inject; `RouteStore` already carries `activity` and `mineRouteIds`)
- Delete: `UITests/MapDiscoverUITests.swift` (its coverage moves to `RouteListUITests` and, in Task 10, `RouteCardUITests`)

**Interfaces:**
- Consumes: `RouteList.sections(...)`, `RouteListQuery`, `RouteListOption`, `RouteListSection`, `ActivityPeriod`, `RouteStore.activity`, `RouteStore.mineRouteIds`, `SavedRoutesStore.savedRouteIds`, `MapStyleOption`, `AppSettings.mapStyle`, `RouteMapView` (Task 8 contract).
- Produces:
  - `RouteRow(routeId: String, name: String, detail: String, status: String)` (no number).
  - `RouteListSheet(query: Binding<RouteListQuery>, sections: [RouteListSection], onSelect: (String) -> Void, onNewRoute: () -> Void)`.
  - `NearbyOrigin.current() -> Coordinate?`.
  - Identifiers: `map-search-field`, `map-style-button`, `routes-option-menu`, `period-today|week|month|allTime`, `routes-section-mine`, `routes-section-saved`, `new-route-button`, `routes-empty-all|mine|saved`, `route-row-<id>`, `route-row-status-<id>`, `sheet-handle`, `record-button`.
  - UI-test helpers in `UITests/Support/AppLaunch.swift`: `launchWalkable(language:resetState:mapStyle:arguments:)`, `anyElement(_:_:)`, `attachScreenshot(_:_:)`, `revealRow(_:_:)`, `chooseRoutesOption(_:_:)`.

- [ ] **Step 1: Add the shared UI-test helpers**

`UITests/Support/AppLaunch.swift`:

```swift
import XCTest

/// Launch and query helpers shared by every UI test.
///
/// Named so they cannot collide with the private helpers older test classes
/// still declare.
extension XCTestCase {

    /// Launches past onboarding, in the language asked for, from the seeded
    /// state unless `resetState` is false. Location is ignored so Nearby
    /// measures from People's Square and the order is fixed.
    /// `mapStyle` pins the basemap for the launch; pass nil to read whatever
    /// the previous launch stored.
    func launchWalkable(language: String = "english", resetState: Bool = true, mapStyle: String? = "standard", arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-settings.language", language, "-settings.hasSeenOnboarding", "YES", "-uitest.ignoreLocation"]
            + (resetState ? ["-uitest.resetUserState"] : [])
            + (mapStyle.map { ["-settings.mapStyle", $0] } ?? [])
            + arguments
        app.launch()
        XCTAssertTrue(anyElement(app, "routes-option-menu").waitForExistence(timeout: 10), "the Routes sheet never appeared")
        return app
    }

    /// An element by identifier, whatever type it surfaces as.
    func anyElement(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    func attachScreenshot(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    /// A row below the fold still exists to XCUITest, and tapping it lands on
    /// whatever covers it. Expand the sheet first when the row is not hittable.
    func revealRow(_ app: XCUIApplication, _ routeId: String) -> XCUIElement {
        let row = app.buttons["route-row-\(routeId)"]
        XCTAssertTrue(row.waitForExistence(timeout: 5), "row \(routeId) missing")
        if !row.isHittable {
            anyElement(app, "sheet-handle").tap()
        }
        return row
    }

    /// Picks an option from the Routes dropdown by its visible title.
    func chooseRoutesOption(_ app: XCUIApplication, _ title: String) {
        anyElement(app, "routes-option-menu").tap()
        let item = app.buttons[title].firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 3), "menu item \(title) missing")
        item.tap()
    }

    /// Row identifiers in on-screen order, top to bottom.
    func visibleRowOrder(_ app: XCUIApplication) -> [String] {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'route-row-'")).allElementsBoundByIndex
            .sorted { $0.frame.minY < $1.frame.minY }
            .map { String($0.identifier.dropFirst("route-row-".count)) }
    }
}
```

- [ ] **Step 2: Write the failing UI tests**

`UITests/RouteListUITests.swift`:

```swift
import XCTest

/// The Routes sheet: its five options, Popular's period selector, the
/// sections under Saved, search, and what each row says.
final class RouteListUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testNearbyIsTheDefaultAndOrdersFromPeoplesSquare() {
        let app = launchWalkable()
        XCTAssertTrue(anyElement(app, "routes-option-menu").label.contains("Nearby"))
        anyElement(app, "sheet-handle").tap()
        XCTAssertEqual(visibleRowOrder(app), ["fuxing", "bund", "creek", "wukang", "century"])
        attachScreenshot(app, "routes-nearby-en")
    }

    func testRowsShowFiguresUpdatedDateAndWalkingNow() {
        let app = launchWalkable()
        let status = anyElement(app, "route-row-status-fuxing")
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertTrue(status.label.contains("Last updated:"))
        XCTAssertTrue(status.label.contains("0 walking now"))
        XCTAssertFalse(app.staticTexts["1"].exists, "rows must not be numbered")
    }

    func testPopularHasAPeriodSelectorAndRanksByIt() {
        let app = launchWalkable()
        chooseRoutesOption(app, "Popular")
        XCTAssertTrue(anyElement(app, "period-week").isSelected)
        anyElement(app, "sheet-handle").tap()
        XCTAssertEqual(visibleRowOrder(app), ["wukang", "bund", "creek", "fuxing"])

        anyElement(app, "period-month").tap()
        XCTAssertEqual(visibleRowOrder(app), ["wukang", "creek", "bund", "fuxing", "century"])
    }

    func testFeaturedListsOnlyFeaturedRoutes() {
        let app = launchWalkable()
        chooseRoutesOption(app, "Featured")
        XCTAssertEqual(visibleRowOrder(app), ["wukang"])
        XCTAssertFalse(anyElement(app, "period-week").exists)
    }

    func testMineOffersANewRouteThatOpensTheBuilder() {
        let app = launchWalkable()
        chooseRoutesOption(app, "Mine")
        XCTAssertTrue(anyElement(app, "routes-empty-mine").exists)
        anyElement(app, "new-route-button").tap()
        XCTAssertTrue(anyElement(app, "builder-map").waitForExistence(timeout: 5))
    }

    func testSavedShowsMineAboveSaved() {
        let app = launchWalkable()
        chooseRoutesOption(app, "Saved")
        let mine = anyElement(app, "routes-section-mine")
        let saved = anyElement(app, "routes-section-saved")
        XCTAssertTrue(mine.exists && saved.exists)
        XCTAssertLessThan(mine.frame.minY, saved.frame.minY)
        XCTAssertTrue(anyElement(app, "new-route-button").exists)
        anyElement(app, "sheet-handle").tap()
        XCTAssertEqual(Set(visibleRowOrder(app)), ["wukang", "creek", "century"])
    }

    func testSearchFiltersByName() {
        let app = launchWalkable()
        let field = anyElement(app, "map-search-field")
        field.tap()
        field.typeText("bund")
        XCTAssertEqual(visibleRowOrder(app), ["bund"])
    }

    func testTheSheetReadsInChinese() {
        let app = launchWalkable(language: "chinese")
        XCTAssertTrue(anyElement(app, "routes-option-menu").label.contains("附近"))
        XCTAssertTrue(app.staticTexts["路线"].exists)
        XCTAssertTrue(anyElement(app, "route-row-status-fuxing").label.contains("人正在走"))
        attachScreenshot(app, "routes-nearby-zh")
    }
}
```

`UITests/MapStyleUITests.swift`:

```swift
import XCTest

/// The map-style button switches between Map, Satellite and Traffic, and the
/// choice survives a relaunch.
final class MapStyleUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func chooseStyle(_ app: XCUIApplication, _ title: String) {
        anyElement(app, "map-style-button").tap()
        let item = app.buttons[title].firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 3), "style \(title) missing")
        item.tap()
    }

    func testEachStyleCanBeChosen() {
        let app = launchWalkable()
        let map = anyElement(app, "route-map")
        XCTAssertEqual(map.value as? String, "standard")
        chooseStyle(app, "Satellite")
        XCTAssertEqual(map.value as? String, "satellite")
        attachScreenshot(app, "map-style-satellite")
        chooseStyle(app, "Traffic")
        XCTAssertEqual(map.value as? String, "traffic")
        attachScreenshot(app, "map-style-traffic")
        chooseStyle(app, "Map")
        XCTAssertEqual(map.value as? String, "standard")
    }

    func testTheChoiceSurvivesRelaunch() {
        var app = launchWalkable()
        chooseStyle(app, "Satellite")
        app.terminate()
        app = launchWalkable(resetState: false, mapStyle: nil)
        XCTAssertEqual(anyElement(app, "route-map").value as? String, "satellite")
        chooseStyle(app, "Map")
    }

    func testTheMenuReadsInChinese() {
        let app = launchWalkable(language: "chinese")
        anyElement(app, "map-style-button").tap()
        XCTAssertTrue(app.buttons["卫星"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["路况"].exists)
    }
}
```

- [ ] **Step 3: Run them to see them fail**

Run the `RouteListUITests` and `MapStyleUITests` classes.
Expected: failures at `launchWalkable` — `routes-option-menu` never appears.

- [ ] **Step 4: Strings**

```bash
cd /Users/aurae25/walkable-shanghai/WalkableShanghai
python3 Scripts/strings.py set routes.title "Routes" "路线" "Heading on the map sheet."
python3 Scripts/strings.py set routes.section.mine "Mine" "我的"
python3 Scripts/strings.py set routes.section.saved "Saved" "已收藏"
python3 Scripts/strings.py set routes.newRoute "New route" "新建路线"
python3 Scripts/strings.py set routes.updated "Last updated: %@" "更新于：%@"
python3 Scripts/strings.py plural routes.walkingNow "%lld walking now" "%lld walking now" "%lld 人正在走"
python3 Scripts/strings.py set routes.empty "No routes match." "没有符合的路线。"
python3 Scripts/strings.py set routes.empty.mine "Routes you draw appear here." "你绘制的路线会显示在这里。"
python3 Scripts/strings.py set routes.empty.saved "Bookmark a route to keep it here, offline." "收藏路线后，它会离线保存在这里。"
python3 Scripts/strings.py remove map.routesInView map.filter. map.empty
```

- [ ] **Step 5: Where Nearby measures from**

`Sources/Features/Map/NearbyOrigin.swift`:

```swift
import CoreLocation

/// The walker's last known position, for ordering Nearby.
///
/// Reads what Core Location already has rather than asking for permission:
/// the map should not open with a prompt. With no permission or no fix, Nearby
/// measures from People's Square (`RouteList.peoplesSquare`). UI tests pass
/// `-uitest.ignoreLocation` so the order does not depend on the simulator.
@MainActor
enum NearbyOrigin {
    static func current() -> Coordinate? {
        if ProcessInfo.processInfo.arguments.contains("-uitest.ignoreLocation") { return nil }
        let manager = CLLocationManager()
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            guard let location = manager.location else { return nil }
            return Coordinate(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
        default:
            return nil
        }
    }
}
```

- [ ] **Step 6: Rows without numbers**

Replace `RouteRow` in `Sources/DesignSystem/Components.swift`:

```swift
/// One route in a list: name, figures, and when it last changed and who is on it.
struct RouteRow: View {
    let routeId: String
    let name: String
    let detail: String
    let status: String

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Space.s3) {
            VStack(alignment: .leading, spacing: Theme.Space.s1) {
                Text(name)
                    .font(Typography.rowTitle)
                    .foregroundStyle(Theme.label)
                    .multilineTextAlignment(.leading)
                Text(detail)
                    .font(Typography.meta)
                    .foregroundStyle(Theme.labelSecondary)
                    .tabularFigures()
                Text(status)
                    .font(Typography.meta)
                    .foregroundStyle(Theme.labelTertiary)
                    .accessibilityIdentifier("route-row-status-\(routeId)")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.labelTertiary)
        }
        .padding(.vertical, Theme.Space.s3)
        .contentShape(Rectangle())
    }
}
```

Fix the other `RouteRow` call sites the compiler reports (the design-system gallery) with sample values.

- [ ] **Step 7: The sheet's content**

`Sources/Features/Map/RouteListSheet.swift`:

```swift
import SwiftUI

/// The list half of the map sheet: the Routes heading and its dropdown,
/// Popular's period selector, then the sections `RouteList` decided on.
struct RouteListSheet: View {

    @Environment(AppSettings.self) private var settings
    @Environment(RouteStore.self) private var store

    @Binding var query: RouteListQuery
    let sections: [RouteListSection]
    let onSelect: (String) -> Void
    let onNewRoute: () -> Void

    var body: some View {
        let language = settings.language

        VStack(spacing: 0) {
            header(language: language)

            if query.option == .popular {
                SegmentedRing(
                    options: ActivityPeriod.allCases.map { ($0, $0.localizationKey.localized(language)) },
                    selection: $query.period,
                    identifiers: ActivityPeriod.allCases.map { "period-\($0.rawValue)" }
                )
                .padding(.horizontal, Theme.Space.s4)
                .padding(.bottom, Theme.Space.s2)
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                        sectionView(section, language: language)
                    }
                }
                .padding(.horizontal, Theme.Space.s4)
                // Clears the tab bar, which draws over the sheet.
                .padding(.bottom, Theme.Space.s8 + 56)
            }
        }
    }

    private func header(language: AppLanguage) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Space.s2) {
            Text("routes.title".localized(language))
                .font(Typography.heading)
                .foregroundStyle(Theme.label)

            Menu {
                Picker(selection: $query.option) {
                    ForEach(RouteListOption.allCases, id: \.self) { option in
                        Text(option.localizationKey.localized(language)).tag(option)
                    }
                } label: {
                    EmptyView()
                }
            } label: {
                HStack(spacing: Theme.Space.s1) {
                    Text(query.option.localizationKey.localized(language))
                        .font(Typography.secondary.weight(.semibold))
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(Theme.label)
                .padding(.horizontal, Theme.Space.s3)
                .padding(.vertical, Theme.Space.s1 + 2)
                .background(Theme.fill, in: Capsule())
            }
            .accessibilityIdentifier("routes-option-menu")

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.Space.s4)
        .padding(.bottom, Theme.Space.s2)
    }

    @ViewBuilder
    private func sectionView(_ section: RouteListSection, language: AppLanguage) -> some View {
        switch section.kind {
        case .all:
            EmptyView()
        case .mine:
            Text("routes.section.mine".localized(language))
                .sectionLabel()
                .padding(.top, Theme.Space.s3)
                .accessibilityIdentifier("routes-section-mine")
        case .saved:
            Text("routes.section.saved".localized(language))
                .sectionLabel()
                .padding(.top, Theme.Space.s4)
                .accessibilityIdentifier("routes-section-saved")
        }

        if section.offersNewRoute {
            Button("routes.newRoute".localized(language), action: onNewRoute)
                .buttonStyle(.primaryClassical)
                .padding(.vertical, Theme.Space.s2)
                .accessibilityIdentifier("new-route-button")
        }

        if section.routes.isEmpty {
            EmptyStateNote(text: emptyText(section.kind, language: language), identifier: "routes-empty-\(section.kind)")
        }

        ForEach(section.routes) { route in
            Button {
                onSelect(route.id)
            } label: {
                RouteRow(
                    routeId: route.id,
                    name: route.name(language),
                    detail: figures(route, language: language),
                    status: status(route, language: language)
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("route-row-\(route.id)")
            SeparatorRule()
        }
    }

    private func emptyText(_ kind: RouteListSection.Kind, language: AppLanguage) -> String {
        switch kind {
        case .all: return "routes.empty".localized(language)
        case .mine: return "routes.empty.mine".localized(language)
        case .saved: return "routes.empty.saved".localized(language)
        }
    }

    private func figures(_ route: Route, language: AppLanguage) -> String {
        "\(String(format: "%.1f", route.km)) \("unit.km".localized(language)) · \(route.minutes) \("unit.min".localized(language))"
    }

    private func status(_ route: Route, language: AppLanguage) -> String {
        let date = route.updatedAt.formatted(.dateTime.day().month(.abbreviated).locale(language.locale))
        let walking = L10n.string("routes.walkingNow", language, count: store.activity.walkingNow(routeId: route.id))
        return "\("routes.updated".localized(language, date)) · \(walking)"
    }
}
```

`"key".localized(language, arg…)` is the existing interpolating helper in `Sources/Localization/L10n.swift`.

- [ ] **Step 8: Wire the sheet into the map screen**

In `Sources/Features/Map/MapDiscoverScreen.swift`:
- delete `enum Filter`, `@State filter`, the `SegmentedRing` in `controls`, the sheet header with `routes-in-view-count`, and the old `ScrollView` of rows;
- add state and environment:

```swift
    @Environment(WalkStore.self) private var walks

    @State private var query = RouteListQuery()
    @State private var origin: Coordinate?
    @State private var isShowingBuilder = false
```

- replace `listedRoutes` with:

```swift
    private var sections: [RouteListSection] {
        RouteList.sections(
            routes: store.routes,
            query: query,
            mineIds: store.mineRouteIds,
            savedIds: saved.savedRouteIds,
            origin: origin,
            activity: store.activity
        )
    }

    /// What the map draws: every route listed, once, in list order.
    private var listedRoutes: [Route] {
        var seen = Set<String>()
        return sections.flatMap(\.routes).filter { seen.insert($0.id).inserted }
    }
```

- make the search field real:

```swift
            HStack(spacing: Theme.Space.s2) {
                Image(systemName: "magnifyingglass")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.labelSecondary)
                TextField("map.search".localized(language), text: $query.searchText)
                    .font(Typography.secondary)
                    .foregroundStyle(Theme.label)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("map-search-field")
            }
            .padding(.horizontal, Theme.Space.s4)
            .frame(minHeight: 46)
            .floatingSurface(in: Capsule())
```

- put the map-style button beside the search field, in one `HStack(spacing: Theme.Space.s2)` with the search capsule:

```swift
            Menu {
                Picker(selection: Bindable(settings).mapStyle) {
                    ForEach(MapStyleOption.allCases, id: \.self) { style in
                        Label(style.localizationKey.localized(language), systemImage: style.systemImage).tag(style)
                    }
                } label: {
                    EmptyView()
                }
            } label: {
                Image(systemName: settings.mapStyle.systemImage)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.label)
                    .frame(width: 46, height: 46)
                    .floatingSurface(in: Circle(), interactive: true)
            }
            .accessibilityIdentifier("map-style-button")
            .accessibilityLabel("map.style.button".localized(language))
```

- pass `style: settings.mapStyle` to `RouteMapView`;
- in the sheet, below `grabHandle`, place:

```swift
                RouteListSheet(
                    query: $query,
                    sections: sections,
                    onSelect: { selectedRouteId = $0 },
                    onNewRoute: { isShowingBuilder = true }
                )
```

- add `.onAppear { origin = NearbyOrigin.current() }` and

```swift
        .fullScreenCover(isPresented: $isShowingBuilder) {
            NavigationStack { RouteBuilderScreen() }
        }
```

- reduce `topInset` passed to `RouteMapView` to 76 (the segmented control is gone).

Rewrite the type's doc comment: the map, a search field, the map-style button (Task 8), the record button, and a sheet that lists routes or shows one route's card (Task 10).

Delete `UITests/MapDiscoverUITests.swift`.

- [ ] **Step 9: Run the new UI tests and the unit tests**

Run `RouteListUITests` and `MapStyleUITests`, then the unit tests.
Expected: all pass. If `testPopularHasAPeriodSelectorAndRanksByIt` sees fewer rows than expected, the sheet did not expand — check `sheet-handle` is hittable above the period selector.

- [ ] **Step 10: Commit**

```bash
cd /Users/aurae25/walkable-shanghai
git add -A
git commit -m "Add the Routes sheet with its dropdown, Popular periods, sections, rows and search"
```

---

### Task 10: Route card over the map

**Files:**
- Create: `Sources/Features/Map/RouteCard.swift`, `UITests/RouteCardUITests.swift`
- Modify: `Sources/Features/Map/MapDiscoverScreen.swift`, `Sources/DesignSystem/Components.swift` (receives `FlowRow`)
- Delete: `Sources/Features/Route/RouteDetailScreen.swift`, `UITests/RouteDetailUITests.swift`

**Interfaces:**
- Consumes: `RouteMapView` redraws and re-frames when `mode` or `routes` change (Task 8 contract); `SavedRoutesStore.toggleSaved(_:)`; `RouteStore.activity`.
- Produces: `RouteCard(route:isExpanded:isSaved:walkingNow:onToggleSaved:onClose:onBegin:)`. Identifiers: `route-card`, `route-card-title`, `route-card-figures`, `route-card-description`, `route-card-tags`, `route-card-creator`, `route-card-walking-now`, `save-toggle`, `share-button`, `route-card-close`, `start-walking-button`.

- [ ] **Step 1: Write the failing UI tests**

`UITests/RouteCardUITests.swift`:

```swift
import XCTest

/// The route card: opened from a row or a pin, expanded in the spec's order,
/// collapsible to title and figures, and the actions on it.
final class RouteCardUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func openCard(_ app: XCUIApplication, _ routeId: String) {
        revealRow(app, routeId).tap()
        XCTAssertTrue(anyElement(app, "route-card").waitForExistence(timeout: 5))
    }

    func testARowOpensTheCardExpandedInOrder() {
        let app = launchWalkable()
        openCard(app, "wukang")

        let order = ["route-card-title", "route-card-figures", "route-card-description", "route-card-tags", "route-card-creator", "start-walking-button"]
        let tops = order.map { anyElement(app, $0) }.map { element -> CGFloat in
            XCTAssertTrue(element.exists, "\(element) missing")
            return element.frame.minY
        }
        XCTAssertEqual(tops, tops.sorted(), "card sections out of order")

        XCTAssertEqual(anyElement(app, "route-card-figures").label, "3.4 km · 52 min")
        XCTAssertTrue(app.staticTexts["Featured"].exists)
        XCTAssertTrue(app.staticTexts["Popular"].exists)
        XCTAssertEqual(anyElement(app, "route-card-walking-now").label, "0 walking now")
        XCTAssertFalse(app.staticTexts["Featured route"].exists, "no header line above the title")
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'dead end'")).count, 0)
        XCTAssertTrue(anyElement(app, "share-button").exists)
        XCTAssertTrue(anyElement(app, "save-toggle").exists)
        attachScreenshot(app, "route-card-expanded-en")
    }

    func testTheCardCollapsesToTitleAndFigures() {
        let app = launchWalkable()
        openCard(app, "wukang")
        anyElement(app, "sheet-handle").tap()
        XCTAssertTrue(anyElement(app, "route-card-title").exists)
        XCTAssertTrue(anyElement(app, "route-card-figures").exists)
        XCTAssertFalse(anyElement(app, "start-walking-button").exists)
        attachScreenshot(app, "route-card-collapsed-en")
    }

    func testCloseReturnsToTheList() {
        let app = launchWalkable()
        openCard(app, "creek")
        anyElement(app, "route-card-close").tap()
        XCTAssertTrue(anyElement(app, "routes-option-menu").waitForExistence(timeout: 3))
        XCTAssertFalse(anyElement(app, "route-card").exists)
    }

    func testAPinOpensTheSameCard() {
        let app = launchWalkable()
        let pin = anyElement(app, "route-pin-bund")
        XCTAssertTrue(pin.waitForExistence(timeout: 10))
        pin.tap()
        XCTAssertTrue(anyElement(app, "route-card").waitForExistence(timeout: 5))
        XCTAssertEqual(anyElement(app, "route-card-title").label, "The Bund to Yuyuan")
    }

    func testBookmarkingSavesAndSurvivesRelaunch() {
        var app = launchWalkable()
        openCard(app, "fuxing")
        anyElement(app, "save-toggle").tap()
        app.terminate()

        app = launchWalkable(resetState: false)
        chooseRoutesOption(app, "Saved")
        XCTAssertTrue(revealRow(app, "fuxing").exists)
    }

    func testShareOpensTheShareSheet() {
        let app = launchWalkable()
        openCard(app, "wukang")
        anyElement(app, "share-button").tap()
        XCTAssertTrue(app.otherElements["ActivityListView"].waitForExistence(timeout: 5)
            || app.navigationBars["UIActivityContentView"].waitForExistence(timeout: 5))
    }

    func testBeginRouteStartsTracking() {
        let app = launchWalkable(arguments: ["-uitest.simulateWalk", "wukang"])
        openCard(app, "wukang")
        anyElement(app, "start-walking-button").tap()
        XCTAssertTrue(anyElement(app, "recording-state").waitForExistence(timeout: 5))
    }

    func testTheCardReadsInChinese() {
        let app = launchWalkable(language: "chinese")
        openCard(app, "wukang")
        XCTAssertEqual(anyElement(app, "route-card-title").label, "武康路与法租界弄堂")
        XCTAssertTrue(app.staticTexts["精选"].exists)
        XCTAssertEqual(anyElement(app, "route-card-walking-now").label, "0 人正在走")
        attachScreenshot(app, "route-card-expanded-zh")
    }
}
```

- [ ] **Step 2: Run them to see them fail**

Expected: failures waiting for `route-card`.

- [ ] **Step 3: Strings**

```bash
python3 Scripts/strings.py set route.begin "Begin route" "开始路线"
python3 Scripts/strings.py set action.close "Close" "关闭"
python3 Scripts/strings.py remove route.startWalking route.download route.offlineReady route.missing
```

- [ ] **Step 4: Move `FlowRow`**

Cut `struct FlowRow: Layout` (with its doc comment) from `RouteDetailScreen.swift` into `Sources/DesignSystem/Components.swift`, after `TagChip`. Then:

```bash
git rm -q Sources/Features/Route/RouteDetailScreen.swift UITests/RouteDetailUITests.swift
```

- [ ] **Step 5: The card**

`Sources/Features/Map/RouteCard.swift`:

```swift
import SwiftUI

/// One route, shown in the map sheet in place of the list.
///
/// Expanded, it carries everything in the order the walker reads it: title
/// (with bookmark, share and close at the right), distance and time, the
/// description, tags, the creator with how many people are on the route now,
/// and Begin route. Collapsed, only the title row and the figures remain.
struct RouteCard: View {

    @Environment(AppSettings.self) private var settings

    let route: Route
    let isExpanded: Bool
    let isSaved: Bool
    let walkingNow: Int
    let onToggleSaved: () -> Void
    let onClose: () -> Void
    let onBegin: () -> Void

    var body: some View {
        let language = settings.language

        VStack(alignment: .leading, spacing: Theme.Space.s3) {
            HStack(alignment: .top, spacing: Theme.Space.s2) {
                Text(route.name(language))
                    .font(Typography.title)
                    .foregroundStyle(Theme.label)
                    .lineLimit(isExpanded ? nil : 1)
                    .fixedSize(horizontal: false, vertical: isExpanded)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("route-card-title")

                iconButton(isSaved ? "bookmark.fill" : "bookmark", tint: isSaved ? Theme.accent : Theme.label, action: onToggleSaved)
                    .accessibilityIdentifier("save-toggle")
                    .accessibilityLabel((isSaved ? "route.save.remove" : "route.save.add").localized(language))

                ShareLink(item: shareText(language)) {
                    iconFace("square.and.arrow.up", tint: Theme.label)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("share-button")
                .accessibilityLabel("route.share".localized(language))

                iconButton("xmark", tint: Theme.labelSecondary, action: onClose)
                    .accessibilityIdentifier("route-card-close")
                    .accessibilityLabel("action.close".localized(language))
            }

            Text(figures(language))
                .font(Typography.secondary)
                .foregroundStyle(Theme.labelSecondary)
                .tabularFigures()
                .accessibilityIdentifier("route-card-figures")

            if isExpanded {
                if !route.note(language).isEmpty {
                    Text(route.note(language))
                        .font(Typography.body)
                        .foregroundStyle(Theme.labelSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("route-card-description")
                }

                if !route.tags.isEmpty {
                    FlowRow(spacing: Theme.Space.s2) {
                        ForEach(route.tags, id: \.self) { tag in
                            TagChip(text: tag.localizationKey.localized(language), style: tag == .featured ? .featured : .neutral)
                        }
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("route-card-tags")
                }

                HStack(spacing: Theme.Space.s2) {
                    AvatarInitial(initial: route.authorInitial, size: 28)
                    Text(route.authorName)
                        .font(Typography.meta)
                        .foregroundStyle(Theme.label)
                    Spacer(minLength: Theme.Space.s2)
                    Text(L10n.string("routes.walkingNow", language, count: walkingNow))
                        .font(Typography.meta)
                        .foregroundStyle(Theme.labelSecondary)
                        .accessibilityIdentifier("route-card-walking-now")
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("route-card-creator")

                Button("route.begin".localized(language), action: onBegin)
                    .buttonStyle(.primaryClassical)
                    .accessibilityIdentifier("start-walking-button")
            }
        }
        .padding(.horizontal, Theme.Space.s4)
        .padding(.bottom, Theme.Space.s4)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("route-card")
    }

    private func figures(_ language: AppLanguage) -> String {
        "\(String(format: "%.1f", route.km)) \("unit.km".localized(language)) · \(route.minutes) \("unit.min".localized(language))"
    }

    private func shareText(_ language: AppLanguage) -> String {
        "route.share.message".localized(language, route.name(language), String(format: "%.1f", route.km), String(route.minutes))
    }

    private func iconButton(_ system: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            iconFace(system, tint: tint)
        }
        .buttonStyle(.plain)
    }

    /// Small, quiet controls; 44pt targets around a 15pt glyph.
    private func iconFace(_ system: String, tint: Color) -> some View {
        Image(systemName: system)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: 32, height: 32)
            .background(Theme.fill, in: Circle())
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
    }
}
```

- [ ] **Step 6: Show the card in the sheet**

In `MapDiscoverScreen`:
- delete the `navigationDestination(item: $selectedRouteId)` that pushed `RouteDetailScreen`;
- add `@State private var cardHeight: CGFloat = 0`;
- the sheet's content becomes:

```swift
                if let route = selectedRouteId.flatMap(store.route(id:)) {
                    RouteCard(
                        route: route,
                        isExpanded: detent == .full,
                        isSaved: saved.isSaved(route.id),
                        walkingNow: store.activity.walkingNow(routeId: route.id),
                        onToggleSaved: { saved.toggleSaved(route) },
                        onClose: {
                            withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                                selectedRouteId = nil
                                detent = .peek
                            }
                        },
                        onBegin: { trackingRoute = route }
                    )
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { cardHeight = $0 }
                } else {
                    RouteListSheet(
                        query: $query,
                        sections: sections,
                        onSelect: { id in
                            withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                                selectedRouteId = id
                                detent = .full
                            }
                        },
                        onNewRoute: { isShowingBuilder = true }
                    )
                }
```

- selecting a route (row or pin) sets `selectedRouteId` and `detent = .full` inside the same spring animation;
- the map shows only the selected route, framed, without pins:

```swift
                RouteMapView(
                    mode: selectedRouteId == nil ? .discover : .detail,
                    routes: selectedRouteId.flatMap(store.route(id:)).map { [$0] } ?? listedRoutes,
                    style: settings.mapStyle,
                    bottomInset: sheetHeight,
                    topInset: 76,
                    onSelectRoute: { id in
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                            selectedRouteId = id
                            detent = .full
                        }
                    }
                )
```

- sheet heights depend on what it shows. Replace `Detent.height(in:)` with a function on the screen:

```swift
    /// The list keeps its two heights. The card's collapsed height fits the
    /// title row and figures; expanded, it fits the card's measured content,
    /// capped at the list's full height.
    private func height(of detent: Detent, in available: CGFloat) -> CGFloat {
        let fullCap = min(560, available * 0.78)
        switch (detent, selectedRouteId != nil) {
        case (.peek, false): return min(300, available * 0.42)
        case (.full, false): return min(540, available * 0.74)
        case (.peek, true): return 136
        case (.full, true): return min(fullCap, max(136, cardHeight + 28))
        }
    }
```

and use it everywhere `Detent.height(in:)` was used (the drag logic, `resolvedSheetHeight`, the map's bottom inset). The `+ 28` is the grab handle strip.

- the record button keeps riding above the sheet.

- [ ] **Step 7: Run the card and list UI tests**

Run `RouteCardUITests` and `RouteListUITests`.
Expected: all pass. Then build with the largest Dynamic Type (`-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXXXL` as a launch argument in a scratch run) and screenshot the expanded card: at accessibility sizes the card may exceed the cap — confirm its content scrolls rather than clips. If it clips, wrap the expanded part of the card in a `ScrollView` when `cardHeight + 28 > fullCap`.

- [ ] **Step 8: Commit**

```bash
cd /Users/aurae25/walkable-shanghai
git add -A
git commit -m "Show a collapsible route card over the map in place of the route detail screen"
```

---

### Task 11: Me tab as a settings list

**Files:**
- Create: `Sources/Features/Me/MeScreen.swift`, `Sources/Features/Me/DownloadsScreen.swift`, `UITests/MeTabUITests.swift`
- Modify: `Sources/Features/Profile/ProfileScreen.swift`, `Sources/Features/Shell/MainTabView.swift`

**Interfaces:**
- Consumes: `WalkStore.walkCount`, `WalkStore.totalKm`, `RouteStore.profile`, `OfflineStore.bundles`, `OfflineStore.totalBytes`, `OfflineStore.sizeText(bytes:language:)`, `OfflineStore.storedMapImage(_:)`, `SavedRoutesStore.removeAllDownloads()`.
- Produces: `MeScreen`, `DownloadsScreen`. The language picker shows `AppLanguage.endonym` ("English", "中文"). Identifiers: `me-profile-row`, `me-language-picker`, `me-downloads-row`, `me-location-row`, `me-how-it-works-row`, `me-version-row`, `me-design-system-row`, `download-row-<id>`, `downloads-total`, `remove-all-downloads`, `downloads-empty`.

- [ ] **Step 1: Write the failing UI tests**

`UITests/MeTabUITests.swift`:

```swift
import XCTest

/// The Me tab: a settings list whose first row opens the profile.
final class MeTabUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func openMe(_ app: XCUIApplication, title: String = "Me") {
        app.tabBars.buttons[title].tap()
        XCTAssertTrue(anyElement(app, "me-profile-row").waitForExistence(timeout: 5))
    }

    func testTheListHasItsRowsInOrderAndNoAppearanceSetting() {
        let app = launchWalkable()
        openMe(app)
        let order = ["me-profile-row", "me-language-picker", "me-downloads-row", "me-location-row", "me-how-it-works-row", "me-version-row"]
        let tops = order.map { anyElement(app, $0).frame.minY }
        XCTAssertEqual(tops, tops.sorted())
        XCTAssertFalse(app.staticTexts["Appearance"].exists)
        XCTAssertEqual(app.tabBars.buttons.count, 2)
        attachScreenshot(app, "me-en")
    }

    func testTheProfileRowOpensTheProfile() {
        let app = launchWalkable()
        openMe(app)
        anyElement(app, "me-profile-row").tap()
        XCTAssertTrue(anyElement(app, "profile-walk-range-chart").waitForExistence(timeout: 5))
    }

    func testLanguageSwitchesImmediately() {
        let app = launchWalkable()
        openMe(app)
        anyElement(app, "me-language-picker").tap()
        app.buttons["中文"].tap()
        XCTAssertTrue(app.tabBars.buttons["地图"].waitForExistence(timeout: 3))
    }

    func testDownloadsListSavedRoutesAndRemoveAllClearsThem() {
        let app = launchWalkable()
        openMe(app)
        anyElement(app, "me-downloads-row").tap()
        for id in ["wukang", "creek", "century"] {
            XCTAssertTrue(anyElement(app, "download-row-\(id)").waitForExistence(timeout: 5), id)
        }
        anyElement(app, "remove-all-downloads").tap()
        app.sheets.buttons["Remove all downloads"].firstMatch.tap()
        XCTAssertTrue(anyElement(app, "downloads-empty").waitForExistence(timeout: 3))

        app.tabBars.buttons["Map"].tap()
        chooseRoutesOption(app, "Saved")
        XCTAssertTrue(anyElement(app, "routes-empty-saved").exists)
    }

    func testHowItWorksOpensOnboarding() {
        let app = launchWalkable()
        openMe(app)
        anyElement(app, "me-how-it-works-row").tap()
        XCTAssertTrue(app.buttons["Find a route near me"].waitForExistence(timeout: 5))
    }

    func testTheYouTabReadsInChinese() {
        let app = launchWalkable(language: "chinese")
        openMe(app, title: "我")
        XCTAssertTrue(app.staticTexts["已下载路线"].exists)
        attachScreenshot(app, "me-zh")
    }
}
```


- [ ] **Step 2: Run them to see them fail**

Expected: failures waiting for `me-profile-row`.

- [ ] **Step 3: Strings**

```bash
python3 Scripts/strings.py set tab.me "Me" "我" "Second tab: the walker's settings."
python3 Scripts/strings.py remove tab.you
python3 Scripts/strings.py set me.section.preferences "Preferences" "偏好设置"
python3 Scripts/strings.py set me.section.storage "Storage" "存储"
python3 Scripts/strings.py set me.section.privacy "Privacy" "隐私"
python3 Scripts/strings.py set me.section.about "About" "关于"
python3 Scripts/strings.py plural me.walks "%lld walk" "%lld walks" "%lld 次步行"
python3 Scripts/strings.py set me.downloads "Downloaded routes" "已下载路线"
python3 Scripts/strings.py set me.downloads.total "Total %@" "共 %@"
python3 Scripts/strings.py set me.downloads.removeAll "Remove all downloads" "移除全部下载"
python3 Scripts/strings.py set me.downloads.confirm "Saved routes will be unsaved." "已收藏的路线将取消收藏。"
python3 Scripts/strings.py set me.downloads.empty "Saved routes are downloaded here." "收藏的路线会下载到这里。"
python3 Scripts/strings.py set me.location "Location access" "位置权限"
python3 Scripts/strings.py set me.howItWorks "How Walkable Shanghai works" "Walkable Shanghai 使用说明"
python3 Scripts/strings.py set me.version "Version" "版本"
python3 Scripts/strings.py set me.profile "Profile" "个人资料"
python3 Scripts/strings.py set action.cancel "Cancel" "取消"
python3 Scripts/strings.py remove settings.title settings.about settings.routesYouAdded settings.offlineDownloads settings.drawRoute
```

- [ ] **Step 4: The settings list**

`Sources/Features/Me/MeScreen.swift`:

```swift
import SwiftUI

/// The Me tab: an inset grouped list, in the manner of iOS Settings.
///
/// The profile is one row that opens its own page; everything else is a
/// setting. Rows that need an account (sign in, sync, delete account) wait for
/// a backend. There is no appearance setting: the app follows the phone.
struct MeScreen: View {

    @Environment(AppSettings.self) private var settings
    @Environment(RouteStore.self) private var store
    @Environment(WalkStore.self) private var walks
    @Environment(OfflineStore.self) private var offline
    @Environment(\.openURL) private var openURL

    @State private var isShowingOnboarding = false
    @State private var isShowingDesignSystem = false

    var body: some View {
        @Bindable var settings = settings
        let language = settings.language

        List {
            Section {
                NavigationLink {
                    ProfileScreen()
                } label: {
                    profileRow(language: language)
                }
                .accessibilityIdentifier("me-profile-row")
            }

            Section("me.section.preferences".localized(language)) {
                Picker("settings.language".localized(language), selection: $settings.language) {
                    ForEach(AppLanguage.allCases, id: \.self) { option in
                        Text(option.endonym).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityIdentifier("me-language-picker")
            }

            Section("me.section.storage".localized(language)) {
                NavigationLink {
                    DownloadsScreen()
                } label: {
                    LabeledContent("me.downloads".localized(language), value: OfflineStore.sizeText(bytes: offline.totalBytes, language: language))
                }
                .accessibilityIdentifier("me-downloads-row")
            }

            Section("me.section.privacy".localized(language)) {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                } label: {
                    LabeledContent("me.location".localized(language)) {
                        Image(systemName: "arrow.up.forward.app")
                            .foregroundStyle(Theme.labelTertiary)
                    }
                }
                .foregroundStyle(Theme.label)
                .accessibilityIdentifier("me-location-row")
            }

            Section("me.section.about".localized(language)) {
                Button("me.howItWorks".localized(language)) { isShowingOnboarding = true }
                    .foregroundStyle(Theme.label)
                    .accessibilityIdentifier("me-how-it-works-row")
                LabeledContent("me.version".localized(language), value: Self.version)
                    .accessibilityIdentifier("me-version-row")
                #if DEBUG
                Button("settings.designSystem".localized(language)) { isShowingDesignSystem = true }
                    .foregroundStyle(Theme.label)
                    .accessibilityIdentifier("me-design-system-row")
                #endif
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("tab.me".localized(language))
        .fullScreenCover(isPresented: $isShowingOnboarding) {
            OnboardingView(
                onFindRoute: { isShowingOnboarding = false },
                onShareRoute: { isShowingOnboarding = false }
            )
        }
        .sheet(isPresented: $isShowingDesignSystem) {
            NavigationStack { DesignSystemGalleryView() }
        }
    }

    private func profileRow(language: AppLanguage) -> some View {
        HStack(spacing: Theme.Space.s3) {
            AvatarInitial(initial: store.profile?.initial ?? "", size: 48, emphasised: true)
            VStack(alignment: .leading, spacing: 2) {
                Text(store.profile?.name ?? "")
                    .font(Typography.rowTitle)
                    .foregroundStyle(Theme.label)
                Text("\(L10n.string("me.walks", language, count: walks.walkCount)) · \(String(format: "%.1f", walks.totalKm)) \("unit.km".localized(language))")
                    .font(Typography.meta)
                    .foregroundStyle(Theme.labelSecondary)
            }
        }
        .padding(.vertical, Theme.Space.s1)
    }

    private static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "–"
        let build = info?["CFBundleVersion"] as? String ?? "–"
        return "\(short) (\(build))"
    }
}
```


- [ ] **Step 5: Downloads**

`Sources/Features/Me/DownloadsScreen.swift`:

```swift
import SwiftUI

/// Every saved route kept on the phone, with what each occupies.
///
/// Saved and downloaded are one state, so removing all downloads also clears
/// the bookmarks — the confirmation says so.
struct DownloadsScreen: View {

    @Environment(AppSettings.self) private var settings
    @Environment(RouteStore.self) private var store
    @Environment(OfflineStore.self) private var offline
    @Environment(SavedRoutesStore.self) private var saved

    @State private var isConfirmingRemoval = false

    var body: some View {
        let language = settings.language
        let bundles = offline.bundles.sorted { $0.downloadedAt > $1.downloadedAt }

        List {
            if bundles.isEmpty {
                EmptyStateNote(text: "me.downloads.empty".localized(language), identifier: "downloads-empty")
                    .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(bundles, id: \.routeId) { bundle in
                        row(bundle, language: language)
                    }
                } footer: {
                    Text("me.downloads.total".localized(language, OfflineStore.sizeText(bytes: offline.totalBytes, language: language)))
                        .accessibilityIdentifier("downloads-total")
                }

                Section {
                    Button("me.downloads.removeAll".localized(language), role: .destructive) {
                        isConfirmingRemoval = true
                    }
                    .accessibilityIdentifier("remove-all-downloads")
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("me.downloads".localized(language))
        .confirmationDialog(
            "me.downloads.removeAll".localized(language),
            isPresented: $isConfirmingRemoval,
            titleVisibility: .visible
        ) {
            Button("me.downloads.removeAll".localized(language), role: .destructive) {
                saved.removeAllDownloads()
            }
            Button("action.cancel".localized(language), role: .cancel) {}
        } message: {
            Text("me.downloads.confirm".localized(language))
        }
    }

    private func row(_ bundle: OfflineBundle, language: AppLanguage) -> some View {
        let route = store.route(id: bundle.routeId) ?? offline.storedRoute(bundle.routeId)
        return HStack(spacing: Theme.Space.s3) {
            if let image = UIImage(data: bundle.mapImage) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 44)
                    .clipShape(Theme.shape(Theme.Radius.xs))
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(route?.name(language) ?? bundle.routeId)
                    .font(Typography.rowTitle)
                    .foregroundStyle(Theme.label)
                Text(OfflineStore.sizeText(bytes: bundle.byteCount, language: language))
                    .font(Typography.meta)
                    .foregroundStyle(Theme.labelSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("download-row-\(bundle.routeId)")
    }
}
```

- [ ] **Step 6: Slim the profile page and swap the tab root**

`Sources/Features/Profile/ProfileScreen.swift`: delete `settingsSection(...)` and everything only it used (`isShowingOnboarding`, `isShowingDesignSystem`, `isShowingBuilder`, their covers/sheets, the `SavedRoutesStore` environment if now unused); set `.navigationTitle("me.profile".localized(language))`. Update the type comment: the profile page opened from the Me list.

`Sources/Features/Shell/MainTabView.swift`: rename `Tab.you` to `Tab.me`, label the tab with `"tab.me".localized(language)` and the `person` symbol, and make its root `MeScreen()`. Update every other reference to `Tab.you` or `tab.you` the compiler or `grep -rn 'tab.you\|\.you\b' Sources` finds.

- [ ] **Step 7: Run the tests**

Run `MeTabUITests`, `ProfileUITests` and the unit tests. `ProfileUITests` will fail where it expects the profile at the tab root or the old settings rows: in that file, after switching to the Me tab, tap `me-profile-row` before asserting profile content, and delete `testTheThreeSettingsRowsGoWhereTheySay` and `testTheLanguageChoiceSurvivesRelaunch`'s use of the old control (rewrite it to use `me-language-picker`).
Expected: all pass.

- [ ] **Step 8: Commit**

```bash
cd /Users/aurae25/walkable-shanghai
git add -A
git commit -m "Turn the Me tab into a settings list with profile and downloads pages"
```

---

### Task 12: Builder without user tags

**Files:**
- Modify: `Sources/Features/Builder/RouteBuilderScreen.swift`, `Sources/Data/WalkRecords.swift`, `Sources/Data/WalkStore.swift`, `Sources/Resources/Localizable.xcstrings`
- Test: `Tests/WalkStoreTests.swift`, `UITests/SummaryAndBuilderUITests.swift`

**Interfaces:**
- Produces: `WalkStore.saveDraftRoute(name:coordinates:) -> DraftRoute`; `DraftRoute` without `tagKeys`; `BuilderTag` removed.

- [ ] **Step 1: Update the tests**

`Tests/WalkStoreTests.swift`: delete `testEveryBuilderTagIsBilingual`; remove `tagKeys:` from every `saveDraftRoute` call (including the one added in Task 4).
`UITests/SummaryAndBuilderUITests.swift`: remove every tap on `builder-tag-*`.

- [ ] **Step 2: Run the unit tests to see them fail**

Expected: build fails, `missing argument for parameter 'tagKeys'`.

- [ ] **Step 3: Implement**

- `WalkRecords.swift`: delete `DraftRoute.tagKeys` (property, init parameter, assignment) and `enum BuilderTag`.
- `WalkStore.swift`: `saveDraftRoute(name:coordinates:)` builds `DraftRoute(name: name, coordinates: coordinates)`; delete the now-unused `bilingual` helper in `asRoute` if nothing else uses it.
- `RouteBuilderScreen.swift`: delete `chosenTags` and the tag picker row; drop `tagKeys:` from the save call.
- Strings: `python3 Scripts/strings.py remove builder.tag. builder.yourRoute builder.yourRoute.area`

Tags are developer-owned (spec §4); walkers' routes carry none.

- [ ] **Step 4: Run the unit tests and the builder UI tests**

Run the unit tests and `SummaryAndBuilderUITests`.
Expected: unit tests pass. In `SummaryAndBuilderUITests`, delete `testPostToFeedAlsoStoresTheWalk`, change `post-to-feed-button`/`keep-private-button` taps to `summary-done-button`, and change any navigation that opened route detail to `revealRow(app, id).tap()` then `start-walking-button`. Then it passes.

- [ ] **Step 5: Commit**

```bash
cd /Users/aurae25/walkable-shanghai
git add -A
git commit -m "Drop walker-chosen tags from the builder; tags are the fixed developer list"
```

---

### Task 13: Bring the remaining UI tests onto the new structure

**Files:**
- Modify: `UITests/TrackingUITests.swift`, `UITests/LanguageSwitchUITests.swift`, `UITests/ProfileUITests.swift`, `UITests/SummaryAndBuilderUITests.swift`

- [ ] **Step 1: Update each class**

- `TrackingUITests`: where a test opened route detail and tapped Start, use `revealRow(app, "wukang").tap()` then `anyElement(app, "start-walking-button").tap()`. `testRecButtonOnTheMapAlsoStartsAWalk` stays as is. Make its `launchApp` pass `-uitest.ignoreLocation`.
- `LanguageSwitchUITests`: the tab bar has two items; assert `Map`/`Me` (and their Chinese labels) and that `Community`/`Saved` do not exist.
- `ProfileUITests`: every path to the profile goes Me tab → `me-profile-row`. Delete assertions about the removed settings rows.
- Any remaining use of `routes-in-view-count`, `route-pin-<number>`, `map-filter-*`, `featured-banner`, `notes-button`, `offline-toggle` is replaced by the new identifiers or deleted with its assertion.

- [ ] **Step 2: Run the whole UI suite on iOS 26.5**

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project WalkableShanghai.xcodeproj -scheme WalkableShanghai -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test 2>&1 | grep -E 'Test Case .* (passed|failed)|error:|Executed|TEST (SUCCEEDED|FAILED)' | tail -60
```

Expected: `TEST SUCCEEDED`. Budget about 25 minutes. Fix failures one class at a time with `-only-testing`.

- [ ] **Step 3: Commit**

```bash
cd /Users/aurae25/walkable-shanghai
git add -A
git commit -m "Move the remaining UI tests onto the two-tab structure"
```

---

### Task 14: Both iOS versions, screenshots and documentation

**Files:**
- Create: `UITests/ScreenshotUITests.swift`, `Screenshots/neutral/` (generated)
- Delete: `Screenshots/redesign/`
- Modify: `DESIGN.md`, `README.md`

- [ ] **Step 1: Screenshot tests**

`UITests/ScreenshotUITests.swift` captures every screen in light and dark. Appearance is switched with `xcrun simctl ui booted appearance light|dark` between two runs, so the test itself only navigates and attaches:

```swift
import XCTest

/// Walks every screen and attaches a screenshot of each. Run once per
/// appearance (see README, "Screenshots").
final class ScreenshotUITests: XCTestCase {

    func testCaptureEveryScreen() {
        let app = launchWalkable()
        attachScreenshot(app, "01-map-list")
        anyElement(app, "sheet-handle").tap()
        attachScreenshot(app, "02-map-list-expanded")
        chooseRoutesOption(app, "Popular")
        attachScreenshot(app, "03-map-popular")
        chooseRoutesOption(app, "Saved")
        attachScreenshot(app, "04-map-saved")
        chooseRoutesOption(app, "Nearby")
        revealRow(app, "wukang").tap()
        attachScreenshot(app, "05-route-card-expanded")
        anyElement(app, "sheet-handle").tap()
        attachScreenshot(app, "06-route-card-collapsed")
        anyElement(app, "route-card-close").tap()

        app.tabBars.buttons["Me"].tap()
        attachScreenshot(app, "07-me")
        anyElement(app, "me-profile-row").tap()
        attachScreenshot(app, "08-profile")
        app.navigationBars.buttons.firstMatch.tap()
        anyElement(app, "me-downloads-row").tap()
        attachScreenshot(app, "09-downloads")
    }

    func testCaptureTrackingSummaryAndBuilder() {
        let app = launchWalkable(arguments: ["-uitest.simulateWalk", "wukang"])
        revealRow(app, "wukang").tap()
        anyElement(app, "start-walking-button").tap()
        sleep(4)
        attachScreenshot(app, "10-tracking")
        anyElement(app, "end-walk-button").tap()
        XCTAssertTrue(anyElement(app, "summary-done-button").waitForExistence(timeout: 5))
        attachScreenshot(app, "11-walk-summary")
        anyElement(app, "summary-done-button").tap()

        chooseRoutesOption(app, "Mine")
        anyElement(app, "new-route-button").tap()
        XCTAssertTrue(anyElement(app, "builder-map").waitForExistence(timeout: 5))
        attachScreenshot(app, "12-builder")
    }
}
```

Run it on iOS 26.5 in light, then dark, and on iOS 18.6 in light; export attachments:

```bash
cd /Users/aurae25/walkable-shanghai/WalkableShanghai
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
for look in light dark; do
  xcrun simctl boot "iPhone 17 Pro" 2>/dev/null; xcrun simctl ui "iPhone 17 Pro" appearance $look
  rm -rf /tmp/ws-shots-$look.xcresult
  xcodebuild -project WalkableShanghai.xcodeproj -scheme WalkableShanghai -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:WalkableShanghaiUITests/ScreenshotUITests -resultBundlePath /tmp/ws-shots-$look.xcresult -quiet
  mkdir -p Screenshots/neutral/$look
  xcrun xcresulttool export attachments --path /tmp/ws-shots-$look.xcresult --output-path Screenshots/neutral/$look
done
xcrun simctl ui "iPhone 17 Pro" appearance light
git rm -rq Screenshots/redesign
```

`xcresulttool export attachments` names files by UUID and writes a `manifest.json`; rename each file to its attachment name using the manifest (a five-line Python script reading `manifest.json`).

- [ ] **Step 2: Look at every screenshot**

Read each PNG. Check: neutral grounds; green only on primary buttons, the route line, the selected segment, the bookmark and the Featured tag; text readable; nothing clipped; the expanded card fits without scrolling at default text size. Fix anything that fails, rerun, and recheck.

- [ ] **Step 3: Full suite on both iOS versions**

Run the full test command on `iPhone 17 Pro` (iOS 26.5), then on `iPhone 16 Pro` (iOS 18.6).
Expected: `TEST SUCCEEDED` on both. Report the totals from the `Executed … tests` lines.

- [ ] **Step 4: Rewrite the docs**

`DESIGN.md`: replace the canopy system with the neutral system — the palette table from `Palette.swift`, where green may and may not appear, the measured contrast ratios (from `PaletteContrastTests`' pairs), the two tabs, the Routes sheet and its five options, the route card and its two heights, the Me list. Cite `research/ecosia-design-research.md` and `research/instagram-settings-research.md`. Remove all canopy, wash, sunlight and "green real estate" material.

`README.md`: update the opening status, the layout section (folders added and removed), the UI-test notes (shared helpers in `UITests/Support/AppLaunch.swift`, `-uitest.ignoreLocation`), the offline section (saving downloads; no notes; no separate offline flag), the map section per Task 8's outcome, and add a "Screenshots" section with the commands from Step 1. Remove the test counts that are no longer true and state the new ones from Step 3.

- [ ] **Step 5: Commit**

```bash
cd /Users/aurae25/walkable-shanghai
git add -A
git commit -m "Capture neutral screenshots, verify both iOS versions, and rewrite the design and README docs"
```
