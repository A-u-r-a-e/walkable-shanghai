# JWalk status

The state of the app as of 27 October 2026 (commit `1fa9d6a` on `main`): what
works and how it was checked, known bugs, technical debt, what a release still
needs, and the roadmap. Paths are relative to `JWalk/`.

## What works

| Feature | Checked by |
|---|---|
| Map with Nearby, Popular (today / week / month / all time), Featured, Mine and Saved lists; search by name in both languages | `RouteListTests`, `RouteListUITests` |
| Map, Satellite and Traffic styles, remembered across launches | `MapStyleTests`, `MapStyleUITests` |
| Route card: expand, collapse, close, open from a pin, bookmark, share, Begin route | `RouteCardUITests` |
| Bookmarking downloads the route; removing the bookmark or Remove all downloads deletes it | `UserStateTests`, `OfflineTests`, `MeTabUITests` |
| Tracking a route: clock from the wall clock, distance, pace, remaining, progress, pause and resume, backgrounding | `TrackingTests`, `TrackingUITests` |
| REC records a free walk; the summary can save it as a route in Mine | `TrackingTests`, `SummaryAndBuilderUITests` |
| Walk summary: figures, personal best, photo, note; walks survive relaunch | `WalkStoreTests`, `SummaryAndBuilderUITests` |
| Route builder: draw, undo, save, and the saved route on the map | `WalkStoreTests`, `SummaryAndBuilderUITests` |
| Sharing: send as file and link; open a link cold or while running; save to keep; refusal of bad links; size limits | `RouteShareTests`, `ShareUITests` |
| Me: profile with computed statistics and a six-month chart, language switch, downloads, location access, How JWalk works | `ProfileTests`, `ProfileUITests`, `MeTabUITests` |
| English and Chinese throughout, including plurals | `SampleDataTests`, `ProfileTests`, the Chinese variant in each UI test class |
| Light and dark appearance, with every text pairing at WCAG AA | `PaletteContrastTests`, screenshots in `Screenshots/neutral/` |
| Largest Dynamic Type size on the profile | `ProfileUITests` |

The suite is 95 unit tests and 64 UI tests. On 22 October 2026, before the
commit, every one of them passed on an iPhone 17 Pro simulator (iOS 26.5) and
an iPhone 16 Pro simulator (iOS 18.6): the full suite ran on both, and the
tests changed afterwards were rerun on both.

## Not verified

These have only ever run in the simulator, or not at all:

- **Anything on a real iPhone.** No device build has been made. Real GPS,
  background tracking with the screen locked, battery use, and accuracy in
  Shanghai's narrow streets are untested.
- **Opening a `.jwalk` file** from Files, AirDrop or WeChat. The file format is
  unit-tested and links were tested end to end, but the file path through iOS
  has not been tried.
- **WGS-84 vs GCJ-02 offsets.** MapKit's China basemap uses GCJ-02, the shifted
  coordinate system Chinese maps are required to use. MapKit is expected to
  handle the shift, but nobody has checked on a device in Shanghai that a
  recorded line sits on the street it was walked on.
- **Traffic colouring.** The Traffic style is set correctly but has never shown
  congestion in the simulator.

## Known bugs

In rough order of importance.

1. **GPS probably runs from app launch, not only during a walk.**
   `CoreLocationProvider.locationManagerDidChangeAuthorization`
   (`Sources/Features/Tracking/LocationProvider.swift`) calls `start()` whenever
   permission is granted. Core Location calls that method when the manager is
   created, and the manager is created in `JWalkApp.init`. So on a phone that
   already granted permission, location updates (with background updates
   allowed) start at launch and run until a walk ends. The fixes are discarded,
   but the GPS keeps running and uses battery. Found by reading the code; not
   confirmed on a device. The fix: only call `start()` from the authorisation
   callback when a walk is waiting for permission.
2. **A denied location permission is never shown.** `TrackingSession` sets
   `locationDenied`, and the tests check it, but `TrackingScreen` never reads
   it. A walker who denied permission sees a clock running with no distance.
3. **A broken catalogue fails silently.** `RouteStore.loadFailure` is set when
   `SampleData.json` cannot be read, but nothing displays it; the app shows
   empty lists.
4. **A store that cannot be opened loses data silently.**
   `UserStateContainer.makeOrFallBack` falls back to an in-memory store with only
   a log line. After a schema change that SwiftData cannot migrate, walks,
   routes and bookmarks would vanish for that session and anything new would be
   lost at quit, with no message to the walker.
5. **The broken-link alert may not show** while a full-screen cover is up (the
   builder, or How JWalk works), because the alert is attached to the root view
   beneath it.
6. **The asset catalogue's accent colour is still gold** (`#B68235` in
   `Resources/Assets.xcassets/AccentColor.colorset`), left from the original
   design. The code tints the tab bar and most controls green over it, but any
   system control without an explicit tint shows gold.
7. **The map re-frames when the language or appearance changes**, losing the
   walker's panning, because both are part of `RouteMapView`'s redraw
   signature.
8. **A search match can be framed behind the keyboard**, because the map's
   bottom inset is the sheet's height and ignores the keyboard.
9. **The tracking figure card is stretched** to about twice the height of its
   figures (`Screenshots/neutral/light/10-tracking.png`, `13-free-walk.png`).
10. **Disabled primary and secondary buttons look the same** (both grey), and
    the Me list's custom chevrons are heavier and darker than the system's.
11. **Phones without a home indicator** may show extra space under the route
    card, because the tab-bar clearance (`MapDiscoverScreen.tabBarClearance`) is
    a constant.
12. **Download sizes ignore the app's language.** `OfflineStore.sizeText` uses
    `ByteCountFormatter`, which follows the phone's locale.
13. **The design-system gallery has English-only strings** ("Done",
    "Featured", "Nearby", "Saved"). It only opens in debug builds.

## Technical debt

- **No SwiftData versioning.** Add a `VersionedSchema` for the current shape
  before the first change that automatic migration cannot handle (see
  `docs/DEVELOPMENT.md`).
- **Unused code:** `WalkStore.walksNewestFirst`, `AppSettings.select(_:)`,
  `Theme.Shadow.lg*`, `View.elevationMd()`, the unused `dismiss` in
  `TrackingScreen`, and a no-op `_ = route` in `TrackingSession.progress`.
  `RouteRepository` has one implementation and is not yet used as a type.
- **Unused strings:** `screen.builder`, `track.walkFinished`, `unit.minutes`.
- **Names and comments from earlier designs.** The button styles are still
  called `.primaryClassical` and `.secondaryClassical`, after the retired
  "Classical" design. Stale comments: `RouteMapView` ("Phase 2 only implements
  `discover`", "Real location is Phase 4"), `RootView` (the builder reachable
  "later, the profile"), `Repositories.swift` ("Phase 1–2 storage"),
  `RouteImageRenderer` ("the Saved screen"), `MapDiscoverScreen` ("opaque paper
  backgrounds"), `OnboardingView` and `Typography` ("gold"). The UI test
  `testEndWalkReachesTheSummaryStubCarryingTheFigures` still calls the summary a
  stub. `SampleData.json`'s `_profileNote` refers to the mockup.
- **Deprecated API:** `Theme.hairline` uses `UIScreen.main`, deprecated since
  iOS 16.
- **Hardcoded summary date locale:** `WalkSummaryScreen.dateLine` uses `en_GB`
  for English.
- **`OfflineStore.storedRoute` returns nil silently** for a download stored in an
  older route format. Shared routes the walker saved depend on it.
- **`SavedRoutesStore.setSaved` ignores a failed download**; the next launch's
  `ensureDownloads` repairs it.
- **Nearby has no tie-break** and recomputes distances inside its sort.
- **Test debt:**
  - `WalkStoreTests.testDoneStoresTheWalk` duplicates
    `testAFinishedWalkIsStoredAndReadBackByANewStore`.
  - `RouteActivityTests.testPeriodCountsComeFromTheBundle` tests an injected
    dictionary, not the bundle.
  - `RouteListTests`: the Nearby test's origin is People's Square, so it cannot
    prove the origin is used; there is an unused `saved:` parameter; search is
    tested on Nearby only.
  - `MapStyleTests` leaves its defaults suite behind.
  - The bookmark UI test does not check the filled icon, and no test checks that
    an open card hides the other pins.
  - `ScreenshotUITests` waits with fixed sleeps.
  - `TrackingUITests`, `ProfileUITests`, `LanguageSwitchUITests` and parts of
    `SummaryAndBuilderUITests` build their own launch instead of `launchJWalk`;
    `LanguageSwitchUITests` is not `@MainActor`.

## What a release still needs

For TestFlight:

- **An app icon.** `Resources/Assets.xcassets/AppIcon.appiconset` is empty.
- **Code signing and the Apple Developer Program** (the paid membership).
- **The location permission flow on a device**: the provider asks for "When In
  Use" only. Check that background tracking with the screen locked is reliable
  with that, or decide to ask for "Always".
- **A contact address** in Me → About. The project owner has not chosen one yet.
- **A privacy policy**, before external testing: what is stored on the phone,
  what is shared, and (with the server) what is published and where.
- **Confirmation that TestFlight in mainland China needs no MIIT filing
  number** (see the server plan, §1).

For the China App Store, later: the MIIT app filing (移动互联网应用程序备案),
App Store metadata in both languages, and screenshots at the required sizes.

## Roadmap

### Next: the first server

`docs/superpowers/plans/2026-10-27-first-server.md` was approved by the project
owner on 27 October 2026; no code exists for it yet. In short:

- Public routes in **CloudKit's public database**, so walkers see strangers'
  routes on the map. Links and files stay.
- **TestFlight first**; the China App Store later.
- Identity is the phone's **iCloud account plus a display name**; no sign-in
  screen.
- Only routes **walked end to end** may be published: REC recordings, and drawn
  routes after a tracked walk covers them. The walker **trims the line's ends by
  hand** before publishing, so it does not reveal where they live.
- Routes are visible at once; walkers can **report and block**; the developer
  hides routes from the CloudKit Console.
- Walking now stays 0 and Popular keeps its bundled counts.

Its ten tasks start with joining the Apple Developer Program and a spike that
checks how CloudKit behaves for mainland Apple accounts.

### Later

These are ideas the project has recorded, not commitments:

- Live walking-now and walk counts from the server, and public routes in Popular.
- Offline map tiles. MapKit cannot store them; this needs another approach.
- Messaging about environmental protection.
- Marking shaded stretches of a route, and walking directions to a route's
  start. The project owner chose to skip both on 22 October 2026.
- Comments or conversation. Removed in the October 2026 redesign; the owner
  chose to keep them out.

## Questions for the project owner

- The contact address for Me → About.
- Whether to ask for "Always" location permission for background tracking.
- The wording of every new string the server plan adds (listed in its
  "Interface copy to approve" section).
