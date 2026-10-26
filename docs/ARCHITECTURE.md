# JWalk architecture

How the app is put together, how data moves through it, and how each feature
works. Paths are relative to `JWalk/`. For building and testing, see
`JWalk/README.md`; for how screens look, see `JWalk/DESIGN.md`.

## The shape of the app

JWalk is a single SwiftUI app target with no third-party dependencies. It uses
four Apple frameworks beyond SwiftUI: MapKit (the map), Core Location
(tracking), SwiftData (everything stored on the phone) and Swift Charts (the
profile's chart).

```
JWalkApp                       creates every store, injects them into the environment
└── RootView                   onboarding until it has been seen, then the tabs
    └── MainTabView            two tabs, each with its own NavigationStack
        ├── MapDiscoverScreen  the map, the Routes sheet (list or route card), REC
        │   ├── TrackingScreen      pushed when a walk starts
        │   │   └── WalkSummaryScreen   pushed when the walk ends
        │   └── RouteBuilderScreen  full-screen cover, from Mine's New route
        └── MeScreen           settings list
            ├── ProfileScreen
            └── DownloadsScreen
```

There are no view models. State lives in a handful of `@Observable` stores that
every view reads from the environment, and in each view's own `@State`.
Calculations that deserve tests (list ordering, geometry, the walk-range chart,
the share format) are pure functions in their own types, apart from any view.

## Source folders

| Folder | Contents |
|---|---|
| `Sources/App/` | `JWalkApp` (entry point and startup), `RootView`, and `Appearance` (tab and navigation bar tints) |
| `Sources/Data/` | The route model, the catalogue loader and `RouteStore`, the SwiftData models and their stores, route tags, walker activity, and the share format |
| `Sources/DesignSystem/` | `Palette` (raw colour numbers), `Theme` (colour roles, spacing, radii, shadows, map styling), `Typography`, `Materials` (glass and cards), `Components` (shared views and button styles) |
| `Sources/Localization/` | `AppLanguage`, `AppSettings` (the user's choices), `L10n` (string lookup), `LocalizedText` (bilingual content) |
| `Sources/Features/Map/` | The map tab: `MapDiscoverScreen`, `RouteMapView` (the MapKit wrapper), `RouteList` (list rules), `RouteListSheet`, `RouteCard`, map styles, the Nearby origin |
| `Sources/Features/Tracking/` | `TrackingSession` (the walk state machine), location providers, `RouteGeometry`, `TrackingScreen`, `WalkSummaryScreen` |
| `Sources/Features/Builder/` | `RouteBuilderScreen` |
| `Sources/Features/Me/` | `MeScreen`, `DownloadsScreen` |
| `Sources/Features/Profile/` | `ProfileScreen`, `WalkRange` (the chart's data) |
| `Sources/Features/Onboarding/` | `OnboardingView` |
| `Sources/Features/Offline/` | `RouteImageRenderer`, which draws a route line to a PNG |
| `Sources/Features/Shell/` | `MainTabView`, and `DesignSystemGalleryView` (opened from Me in debug builds only) |
| `Sources/Resources/` | `SampleData.json` (the bundled catalogue), `Localizable.xcstrings`, `InfoPlist.xcstrings`, the asset catalogue |
| `Config/Info.plist` | The Info.plist keys build settings cannot express: background location, the `jwalk` URL scheme, the `.jwalk` file type |

## Startup

`JWalkApp.init` builds everything once, in this order:

1. `AppSettings` (a property initialiser, so it exists before `init` runs) reads
   the language, the onboarding flag and the map style from `UserDefaults`.
2. `Appearance.apply()` sets the tab bar's selected tint to the app's green and
   navigation bar buttons to the primary text colour.
3. `UserStateContainer.makeOrFallBack()` opens the SwiftData store. If it cannot
   be opened, it logs and falls back to an in-memory store, so the app runs but
   keeps nothing for that session.
4. Launch arguments are read: `-uitest.resetUserState` wipes stored data, and
   `-uitest.simulateWalk <routeId>` swaps real location for a simulated walk
   along a bundled route.
5. `OfflineStore`, then `SavedRoutesStore` (which seeds three saved routes on a
   fresh install), then the location provider and `TrackingSession`, then
   `WalkStore`.
6. `RouteStore` loads `SampleData.json`, then merges in the walker's own routes
   (`setDrawnRoutes`) and the shared routes they saved earlier
   (`setReceivedRoutes`, read back from their downloads).
7. `SavedRoutesStore.ensureDownloads` makes downloads match bookmarks: it
   builds a missing download for any saved route and deletes a download whose
   route is no longer saved.

`body` puts all six stores and the model container into the environment and
handles `onOpenURL` for shared routes.

## The stores

| Store | Owns | Persists in |
|---|---|---|
| `AppSettings` | Language, whether onboarding has been seen, map style | `UserDefaults`: `settings.language`, `settings.hasSeenOnboarding`, `settings.mapStyle` |
| `RouteStore` | The merged route list, the walker's own route ids, walker activity, a route waiting to open from a link | Nothing; rebuilt at every launch |
| `SavedRoutesStore` | Which routes are bookmarked; saving downloads, unsaving deletes the download | SwiftData `RouteUserState` |
| `OfflineStore` | One download per saved route: the route encoded as JSON, and a PNG of its line | SwiftData `OfflineBundle` |
| `WalkStore` | Finished walks, and routes the walker drew or recorded | SwiftData `StoredWalk` and `DraftRoute` |
| `TrackingSession` | The walk in progress | Nothing; the summary writes the finished walk to `WalkStore` |

Every store except `AppSettings` and `RouteStore` is `@MainActor`. Each
SwiftData store makes its own `ModelContext` from the shared container, keeps
an in-memory copy of its rows for reading, and writes through on every change.
Save errors are printed with a `[JWalk]` prefix and never thrown. No view uses
`@Query` or the model context directly.

## The data model

### Routes

`Route` (`Sources/Data/Models.swift`) is a plain `Codable` struct: id, distance
in km, minutes, a bilingual name and description (`LocalizedText`), the
author's name and one-character initial, tags, the date it last changed, the
line as `[Coordinate]`, and the map pin's position.

A route comes from one of three places, and `RouteStore.routes` merges them
into one list so no screen needs to know which:

| Source | Where it lives | Ids |
|---|---|---|
| The bundled catalogue | `Resources/SampleData.json`, five routes | `wukang`, `creek`, `fuxing`, `bund`, `century` |
| The walker's own routes, drawn in the builder or recorded with REC | SwiftData `DraftRoute`, turned into a `Route` by `DraftRoute.asRoute` | `draft-` plus 8 hexadecimal characters |
| Routes other walkers shared | In memory until the app quits; kept for good only when bookmarked, through the bookmark's download | The sender's id |

The merge keeps the first copy of an id, in the order above, so a shared link
can never replace a catalogue route or one of the walker's own.

A walker's own route has no description and no tags. Its distance is measured
from its line, and its time is 12 minutes per kilometre. Shared routes are
measured the same way on arrival, whatever the sender's copy said.

### Tags and activity

`RouteTag` is a fixed list owned by the developers: `featured` and `popular`.
Walkers cannot tag routes.

`RouteActivityProvider` answers two questions: how many people are walking a
route now, and how many walked it in a period (today, this week, this month,
all time). The only implementation, `OfflineActivityProvider`, returns 0
walking now and the counts bundled in `SampleData.json`. A networked provider
can replace it without any view changing.

### Stored records (SwiftData)

The schema is in `UserStateContainer` (`Sources/Data/RouteUserState.swift`):

| Model | Fields |
|---|---|
| `RouteUserState` | `routeId` (unique), `isSaved` |
| `StoredWalk` | `id`, `routeId`, `startedAt`, `endedAt`, `distanceMeters`, `elapsedSeconds`, `note`, `photo` (external storage) |
| `DraftRoute` | `id`, `name`, `latitudes`, `longitudes`, `createdAt` |
| `OfflineBundle` | `routeId` (unique), `routeData` (the route as JSON), `mapImage` (PNG, external storage), `downloadedAt` |

The store uses SwiftData's default location. There is no `VersionedSchema` or
migration plan: adding an optional field or one with a default works through
SwiftData's automatic migration, but anything more needs a migration plan (see
`docs/DEVELOPMENT.md`).

A walk on a route stores that route's id. A free walk saved as a route stores
the new route's id, and a free walk that was not saved stores `free-walk`.

## How each feature works

### The map and the Routes sheet

`MapDiscoverScreen` is a full-screen `RouteMapView` with a search field, a
map-style menu, a REC button, and a sheet built by hand rather than with
`.presentationDetents`, because the REC button has to ride on the sheet's
height and the map has to frame its routes in the part the sheet leaves
visible. The sheet has two heights for the list and two for a route card; the
exact sizes are in `height(of:in:)`.

`RouteList.sections` decides what each list shows. It is a pure function and
`RouteListTests` covers every rule:

| List | Contents |
|---|---|
| Nearby (default) | Every route, nearest pin first, measured from the walker's last known position, or from People's Square without location permission |
| Popular | Routes walked in the chosen period, most first; routes with no walks are left out |
| Featured | Routes tagged `featured` |
| Mine | The walker's own routes, with a New route button that opens the builder |
| Saved | Two sections: Mine (with New route), then bookmarked routes that are not the walker's own |

Search filters the current list by route name in both languages.

`NearbyOrigin.current()` reads Core Location's last known position without
asking for permission, so the map never opens with a permission prompt.

### The map view

`RouteMapView` wraps `MKMapView` in four modes: `discover` (every listed route
with pins), `detail` (one route, framed), `track` (a walk in progress) and
`build` (tap to add points). Each route is drawn as two polylines, a wide faint
casing and a thin green line, because one line alone disappears over pale
streets. The walked part of a route, the walker's dot and the builder's points
are drawn on top. All colours and widths come from `Theme.Map`.

The map redraws and re-frames only when its signature changes: the route ids,
the mode, light or dark, and the language. Panning and sheet movement leave
the camera alone. In `track` mode it redraws the walked line as the walk
progresses and keeps the walker centred.

The three styles are MapKit configurations: Map (standard, muted, Apple's points
of interest hidden), Satellite (hybrid imagery with labels) and Traffic
(standard with traffic). The choice persists in `AppSettings.mapStyle`.

### Saving is downloading

Bookmarking a route saves it and downloads it in one step. `OfflineStore`
stores the route as JSON and a PNG of its line drawn by `RouteImageRenderer`
from the route's own coordinates. No map tiles are stored: MapKit has no
supported way to keep them. Removing the bookmark deletes the download, and
Me → Downloaded routes → Remove all downloads removes every download and every
bookmark with it.

The route card reads the live route list, which works offline because the
catalogue is bundled. The stored JSON matters for shared routes, which exist
nowhere else once the app restarts, and will matter once the catalogue comes
from a server.

### Tracking

`TrackingSession` is a small state machine: idle, running, paused, ended. It
takes location fixes from a `LocationProviding`: `CoreLocationProvider` on a
phone, or `SimulatedLocationProvider`, which replays a bundled route's line in
25 m steps every 250 ms for UI tests.

- **Elapsed time comes from the wall clock**, never from counting timer ticks.
  The ticker only makes the screen redraw. So the clock stays right when the
  phone locks or the app is suspended.
- **Distance is the sum of steps between accepted fixes.** A fix is ignored
  when its accuracy is invalid or worse than 50 m, when it was taken more than
  5 s before the walk started (Core Location often delivers its last known
  position first), or when it jumps 500 m or more from the previous one.
- **Progress** on a route is distance walked over the route's length, with no
  snapping to the line. Pace appears after 50 m.
- **A free walk** (REC) has no route: no remaining distance and no progress, and
  the map draws the walker's own line.

`TrackingScreen` starts the session when it appears, unless that session is
already running or paused on the same route. End pushes `WalkSummaryScreen`,
which shows distance, moving time, pace and distance over the walker's previous
best, with a "Personal best" chip when the walk is the longest so far. A
photograph and a note are optional. Done writes a `StoredWalk`. On a free walk
with a name, Done first saves the walked line as a `DraftRoute`, thinned to one
point every 10 m, so it appears in Mine. Done then returns to the route list.

Background tracking relies on the `location` background mode in
`Config/Info.plist`; the provider asks for "When In Use" permission.

### The route builder

`RouteBuilderScreen` puts the map in `build` mode. Each tap adds a point; Undo
removes the last. Save needs at least two points, stores a `DraftRoute` (an
empty name becomes "Untitled route") and adds it to `RouteStore` straight away.
It opens from onboarding's "I have a route to share" and from New route in Mine
or Saved.

### Sharing

`Sources/Data/RouteShare.swift` defines the share format and both ways a route
travels without a server.

- **Sending.** The route card's share button hands the share sheet a
  `RouteFile` (a `Transferable` that writes a `.jwalk` file) and a message
  holding the route's name, distance, time and a `jwalk://route?d=…` link.
  Messages and Mail make the link tappable; WeChat, AirDrop and Files carry the
  file.
- **The format.** `SharedRoute`, version 1: JSON with the id, bilingual name and
  description, author and initial, the last-changed date, and the line as
  integer pairs in units of 1e-5 degrees (about a metre). The link carries the
  same JSON, base64url-encoded. Distance and time are not carried; the receiver
  measures them from the line.
- **Limits.** A payload over 512 KB, a line outside 2 to 5000 points, coordinates
  out of range, a name over 120 characters, a description over 2000 or an
  author over 60 is refused. A future date is replaced by today.
- **Receiving.** `onOpenURL` passes a link or a file to `SharedRoute.route(from:)`
  and then to `RouteStore.receive`. The root view switches to the Map tab (past
  onboarding if needed), the Me tab closes anything it was presenting, and the
  map opens the route's card. A walk in progress is not interrupted: the card
  opens when the walk is done. A link or file that holds no usable route raises
  an alert. A file iOS copied into the app's `Documents/Inbox` is deleted after
  reading.

`RouteStore.pendingRouteId` holds the route waiting to open; the map clears it
once the card is open. `RouteStore.receivedCount` only ever increases, so
screens that only need to know a route arrived (the root view, the Me tab) can
watch it without racing the map's clearing of `pendingRouteId`.

### The Me tab and the profile

`MeScreen` is an inset grouped list in the style of iOS Settings: the profile
row, Language, Downloaded routes, Location access (opens the app's page in iOS
Settings), How JWalk works (shows onboarding again), the version, and in debug
builds the design-system gallery.

Nothing on the profile is stored as a number. Walks, kilometres, longest walk
and routes added are computed from `WalkStore` every time the screen draws. The
Walk range chart comes from `WalkRange.lastMonths`, a pure function over stored
walks: the longest walk in each of the last six months.

### Onboarding

`OnboardingView` shows a language switch, the app's statement, three promises
(Length, Time, Walker) and two ways in: find a route near me (the map), or I
have a route to share (the builder). It is shown until either button is tapped,
and again from Me → How JWalk works.

## Language

The app runs in English or Simplified Chinese, chosen inside the app and
independent of the phone's language; the phone's language only picks the first
launch's default. Interface strings are looked up in the chosen language's
`.lproj` bundle by `L10n` rather than through SwiftUI's own lookup, which
follows the phone. Route names and descriptions are content, carried in both
languages by `LocalizedText`, and never go in the String Catalog.
`JWalk/README.md` explains plurals and format arguments.

The system's location permission prompts follow the phone's language, as iOS
shows them.

## Concurrency

The project builds in Swift 6 language mode with strict concurrency checking.
The stores and location providers are `@MainActor`. Core Location's delegate
callbacks are `nonisolated` and hop to the main actor explicitly. `L10n`'s
bundle cache is guarded by a lock.

## Where a server plugs in

The code was shaped so a backend can arrive without views changing:

- `RouteRepository` is the protocol behind the catalogue. Today only
  `BundledDataSource` implements it. The server plan adds a cached
  `CloudRouteRepository`.
- `RouteActivityProvider` is where live walking-now and walk counts plug in.
- `RouteStore` already merges routes from several sources; public routes become
  one more.
- Downloads already store a full snapshot of each saved route, so a saved route
  keeps working after its server copy changes or disappears.

`docs/superpowers/plans/2026-10-27-first-server.md` is the approved plan for
the first server, built on CloudKit.
