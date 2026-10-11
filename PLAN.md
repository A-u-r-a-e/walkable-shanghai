# Walkable Shanghai — iOS development plan

Status: Phase 1 proposal, awaiting sign-off. Nothing has been scaffolded.

Source of truth for this plan: `Walkable Shanghai.dc.html` (11 screens, layout plus the inline `<script>` holding all sample data and interaction logic), `walk-map.js` (the map component), and `_ds/classical-.../styles.css` (the design tokens). Everything below is traced to one of those three files. Where the mockup shows something it does not actually drive with data, that is called out rather than invented.

> **Two design amendments, agreed after sign-off, that override the mockup throughout.**
>
> **1. The mockup is a functional spec, not a visual one.** It defines *which screens exist, what they do, the data behind them, and the interactions* — everything in sections 2, 3 and 5 stands. It does **not** define how the iOS app looks. Its HTML layouts, compositions and visual treatments are not to be ported. The visual source of truth is instead the raw Classical token sheet the mockup was itself built from (`_ds/classical-.../styles.css`): its colour roles, spacing scale, radii and component intent. Each screen is designed fresh for a native SwiftUI iPhone app from those tokens.
>
> **2. All typography is sans-serif.** The token sheet's serif pairing (Cormorant Garamond for headings, Lora for body) is retired. The app uses the native system fonts — SF Pro for English, falling back automatically to PingFang SC for Chinese — with Dynamic Type throughout. The Classical *feel* is kept and expressed natively: quiet paper ground, restrained gold used as stroke and accent rather than fill, hairline rules instead of cards, generous spacing, small radii.

---

## 1. What the app is

Walkable Shanghai is a phone app for finding walks in Shanghai that hold together for their whole length. The unit of value is the **route**, and the problem it fixes is a walk that gets cut short — a pavement that ends, an arterial road you cannot cross, a construction detour. Every route in the app was walked end to end by a named person before it was published, and every route carries three honest figures on its face: how far it goes, how long it takes, and how many **dead ends** (break points) it has. Around that sit the supporting parts: a map to discover routes, a tracker that follows you along a route while you walk it, a summary you can post to a feed, notes left by other walkers pinned to specific corners, curated collections from creators, saved and offline routes, and a builder for adding your own route by tapping points on the map. The app runs in one language at a time — English or Chinese — switched by the user inside the app, not by the phone's system setting. The look is deliberate and unusual for a maps app: paper-coloured ground, hairline rules instead of cards, gold used only as a stroke, tabular numerals, and the map itself colour-graded down to match the paper.

---

## 2. Screen inventory

These are the 11 entries in the mockup's own `navDef` list, in its order. The tab bar (`showTabs`) is visible on only four of them: Map, Community, Saved, You.

| # | Screen | id | Tab bar | One line |
|---|---|---|---|---|
| 1 | Onboarding | `onb` | no | The pitch: what the three figures mean, and two ways in |
| 2 | Map & discover | `map` | yes | Full-screen map with pins, filters, and a draggable route list |
| 3 | Featured this month | `featured` | no | Editorial page for one chosen route |
| 4 | Route detail | `route` | no | Everything about one route, and the button that starts the walk |
| 5 | Notes from walkers | `comments` | no | Comment thread for a route, with a compose box |
| 6 | Walk in progress | `track` | no | Live tracking against the route line |
| 7 | Walk summary | `summary` | no | Figures for the walk just finished, plus post-or-keep-private |
| 8 | Route builder | `builder` | no | Tap the map to draw a new route, name it, tag it, save it |
| 9 | Community feed | `feed` | yes | Two tabs: friends' walks, and creators' collections |
| 10 | Saved & offline | `saved` | yes | Downloaded routes and saved routes, in two sections |
| 11 | Profile & settings | `profile` | yes | Your walking stats, and the settings including the language switch |

### Interactions each screen must support

**1. Onboarding** — three static explanation rows (Length / Ends / Walker). Two buttons: "Find a route near me" → Map, "I have a route to share" → Route builder. Reachable again later from Profile → "About Walkable Shanghai".

**2. Map & discover** — an OSM-graded map in `discover` mode showing every listed route's polyline plus a numbered circular pin per route; tapping a pin opens that route's detail (`walk-route-select` event). A search field for routes or streets (in the mockup this is a static label, not a working input — see §7). A three-way filter: Featured / Nearby / Saved, one selected at a time, with a gold inset ring on the selected one. A round REC button, bottom-right, that starts tracking. A bottom sheet with two heights — peek (290pt) and full (520pt) — toggled by its grab handle, animating over 0.28s; the REC button moves with it. Inside the sheet: a "Routes in view" heading with a live count, and one tappable row per route showing number, name, km, minutes, and area. The Saved filter narrows the list *and* the map pins to saved routes only.

**3. Featured this month** — back button, a month kicker ("August 2026"), a large photo, the route's title, a three-figure strip (km / minutes / dead ends), an editorial paragraph, a curator credit with avatar, and "Open the route" → Route detail. In the mockup this content is hardcoded to the Wukang Road route rather than driven by a "featured" flag.

**4. Route detail** — top half is the map in `detail` mode showing this route's line, framed to fit. Floating back button and a save (bookmark) toggle whose fill and border reflect saved state. Below: kicker, title, three tags (a route-quality tag, a time-of-day tag, and the area), the three-figure strip (km / min / dead ends), the walker's note, an author credit line ("Added by X · walked N times"), a download/offline toggle whose label flips between "Download" and "Offline ready", a Share button (not wired in the mockup), "Start walking" → Tracking, and "Notes from walkers (N)" → Comments.

**5. Notes from walkers** — back button, header showing the route name, a scrolling list of comments (avatar initial, name, relative time, body, and an optional pinned location like "Wukang Rd × Hunan Rd" — the pin row is hidden when empty). A compose row pinned to the bottom: text field plus Post. Posting prepends your comment with the time "Just now" and clears the field. Empty or whitespace-only text does nothing.

**6. Walk in progress** — map in `track` mode: the route drawn as a faint dashed line, the walked portion drawn solid in gold, a pulsing walker dot at the current position, and the camera following at zoom 16. A top bar with a pulsing indicator, the route name, and a Recording/Paused label. A bottom panel with a large elapsed clock (mm:ss), km walked against route total, a thin progress bar, and three small figures: pace in min/km, km left, and "ends ahead". Pause/Resume toggles the timer; "End walk" → Summary. In the mockup the elapsed timer ticks once a second only while on this screen and running, progress is `elapsed / 110` capped at 1, and "ends ahead" is hardcoded to "none".

**7. Walk summary** — "Walk complete" kicker, route name, date and time range, a 2×2 figure grid (km walked, moving time, min/km, km over your best), a photo slot, a free-text note box, "Post to feed" → Community feed, and "Keep it private" → Map. Special case in the mockup: if you land here with under 30 seconds tracked, it shows the route's own full figures instead of your partial ones.

**8. Route builder** — map in `build` mode; each tap adds a point, draws a dotted gold line through the points, marks the first point filled and the rest hollow, and reports back a running point count and kilometre total (`walk-point-added`). A hint bar, a "New route" header with "N points · N km", a route-name field, four toggleable tags (Green / Flat / Night walk / Loop), "Undo point", and "Save route" → Map.

**9. Community feed** — sticky header with "Community", a "This week" label, and a Friends/Creators segmented control. **Friends** tab: post cards with avatar initial, name, "walked", the route name (tappable → route detail), relative time, a photo, a note, km · minutes, a like button that toggles and adjusts the count by one, and a reply count that opens that route's comments. **Creators** tab: collection blocks with a photo, "Collection" kicker, title, a meta line (curator · N routes · total km, the total computed by summing the member routes), a numbered list of member routes each showing name and km and each tappable → route detail, and a "Follow this walker" button.

**10. Saved & offline** — header with a live saved count. Two sections. **Offline**: routes marked downloaded, each with a check icon, name, km · min · download size. **Saved routes**: numbered rows with name and km · min · area. Both row types open route detail. A closing note explaining that offline routes keep their tiles and notes.

**11. Profile & settings** — avatar, name, joined-date line, a 2×2 stats grid (walks, km on foot, longest walk, routes added), a "Walk range" bar chart of the longest single walk per month over six labelled months, then Settings: a **Language** English/中文 segmented control that switches the whole app immediately, "Routes you added" (count) → Route builder, "Offline downloads" (count) → Saved, and "About Walkable Shanghai" → Onboarding.

### Navigation behaviour to reproduce

The mockup keeps a back stack: every navigation pushes the screen you left (capped at 8 entries), and the back button pops it, falling back to Map when the stack is empty. Navigating to the same screen you are already on does not push. Entering Tracking resets the elapsed timer to zero and sets it running.

---

## 3. Data model

Fields below are exactly what the mockup's script carries. Bilingual fields appear in the source as paired `…En` / `…Zh` keys; on iOS they become a small `LocalizedText { en, zh }` value resolved against the current language.

### Route
The core entity. Five instances are hardcoded in the mockup.

| Field | Type | Note |
|---|---|---|
| `id` | String | `wukang`, `creek`, `fuxing`, `bund`, `century` |
| `number` | Int | display order, also the number drawn inside the map pin |
| `km` | Double | 2.1 – 5.6 in the sample data |
| `minutes` | Int | walking time |
| `breaks` | Int | dead ends — the app's distinguishing figure |
| `name` | LocalizedText | e.g. "Suzhou Creek, East Bank" / 苏州河东段 |
| `area` | LocalizedText | Xuhui / Hongkou / Huangpu / Pudong |
| `kicker` | LocalizedText | "Featured route", "Word of mouth", "Short walk", "Long walk" |
| `tag1`, `tag2` | LocalizedText | quality tag and time-of-day tag |
| `note` | LocalizedText | the walker's paragraph |
| `authorName` | String | e.g. 张沁, Ben Qiu, M. Lau, 沪上散步 |
| `authorInitial` | String | one character, drawn in the avatar circle |
| `walkCount` | Int | "walked N times" |
| `downloadSize` | String | e.g. "18 MB" — a display string in the mockup, not a computed value |
| `points` | [Coordinate] | 5–9 lat/lng pairs; the polyline |
| `pin` | Coordinate | where the discover marker sits |

Not present but implied by the UI: which segment a dead end falls on (the Bund route says two detours are "marked on the line", but the mockup has no field for them), and a `featured` flag (the Featured screen is hardcoded to Wukang).

### Walk (tracking session)
Not stored in the mockup — it exists only as live state — but the Summary screen defines its shape.

`routeId`, `startedAt`, `endedAt`, `elapsedSeconds`, `distanceKm`, `paceSecondsPerKm`, `progress` (0–1), `isRunning`, plus optional `photo` and `note` from the summary screen, and `isPublic` (Post to feed vs Keep it private). In the mockup `distanceKm = route.km × progress`, `progress = elapsed / 110`, and pace is derived. On device these come from real location updates instead.

### Post (feed item)
`id`, `authorName`, `authorInitial`, `routeId` (→ Route), `relativeTime` (LocalizedText), `km`, `minutes`, `replyCount`, `baseLikes`, `note` (LocalizedText), `photoSlotId`. Runtime state: `isLiked` per post, which adds 1 to the displayed like count.

A Post is the published form of a Walk — Summary's "Post to feed" is the link — but the mockup never actually creates one, so the join is by convention, not by a stored `walkId`.

### Comment
`authorName`, `authorInitial`, `relativeTime` (LocalizedText), `body` (LocalizedText), `pinnedPlace` (LocalizedText, optional — empty means the pin row is hidden). Comments belong to a Route. User-posted comments carry a single-language body and an empty pin, and are prepended to the seeded list.

### Collection
`id`, `name` (LocalizedText), `curatorName` (LocalizedText), `routeIds` ([String] → Route), `photoSlotId`. Route count and total km are computed, not stored. Two collections in the mockup: "Six Concession Walks" (wukang, fuxing, bund) and "Water's Edge" (creek, century).

### UserProfile
`name` ("Ben Qiu"), `initial` (邱), `joinedText`, `walkCount` (34), `totalKm` (118.6), `longestWalkKm` (8.2), `routesAddedCount` (5), `monthlyLongestWalk` (six values driving the bar chart — the labels are localised, the bar heights are hardcoded in the layout), `language` (en | zh). There is no sign-in, no account, and no other user's profile screen anywhere in the mockup.

### Tags
Two distinct things share the word "tag":
- **Display tags on Route detail** — free text per route (`tag1`, `tag2`) plus the area. Not a controlled vocabulary.
- **Builder tags** — a fixed set of four toggles: `green`, `flat`, `night`, `loop`, each with an English and Chinese label. These are the only structured tags in the mockup, and nothing filters by them yet.

### Saved and offline state
Two separate per-route booleans, both user-owned and independent:
- `saved` — the bookmark toggle on Route detail; drives the Saved filter on the map, the saved count, and the Saved routes list. Seeded true for wukang, creek, century.
- `offline` — the Download toggle on Route detail; drives the Offline section and the "Offline downloads" count in Profile. Seeded true for fuxing, wukang.

### RouteDraft (builder)
`points` ([Coordinate], appended by map taps), `pointCount`, `km` (computed from the points), `name` (String), `selectedTags` (the four booleans). Undo removes the last point.

### Relationships

```
UserProfile ──1:N── Walk ──1:1── Route
                     │
                     └──> Post ──N:1── Route
Route ──1:N── Comment
Route ──N:M── Collection
Route ──1:1── SavedState { saved, offline }   (per user)
RouteDraft ──> Route  (on save)
```

---

## 4. Technical decisions

### 4.1 Mapping framework — recommend MapKit, behind a wrapper

The mockup uses Leaflet with raster tiles from OpenStreetMap, colour-graded with a CSS `sepia/saturate/contrast/brightness` filter. That is a web choice, not a requirement.

| | MapKit (SwiftUI `Map`) | MapLibre Native / Mapbox |
|---|---|---|
| Cost & keys | none, ships with iOS | MapLibre free but self-hosted tiles cost; Mapbox is metered |
| Polylines, markers, camera | `MapPolyline`, `Annotation`, `MapCameraPosition` — all native SwiftUI | available, but through a UIKit view you wrap yourself |
| Exact paper styling | limited — a tint overlay on top gets close, but you cannot restyle roads | full control via a style JSON |
| Offline tiles | no supported API | MapLibre has a real offline pack API |
| Mainland China data | Apple supplies licensed China map data | you must source China-legal tiles yourself |
| Effort to first working screen | hours | days |

**Recommendation: MapKit**, with every map screen going through one wrapper type (call it `RouteMapView`) that exposes exactly the four modes the mockup defines — discover, detail, track, build — and the two callbacks (`onRoutePinTapped`, `onPointAdded`). One reason: it is the only option that gets four map modes working with zero dependencies, no keys, no tile bill, and no China map-licensing problem of our own — and the wrapper means swapping in MapLibre later touches one file.

The two things MapKit will not do are known now, not discovered later: it cannot reproduce the exact paper-graded tiles (we approximate with a translucent tint layer over the map, which is what the CSS filter is doing anyway), and it has no offline tile download. Phase 7 is where that bites; see §7.

Style values to carry over from `walk-map.js` so the iOS map matches: accent `#B68235`, ink `#201F1D`, every route line drawn twice (a wide low-opacity ink casing under a thin accent line), start point a filled gold dot, end point a hollow gold ring, discover pins as 30pt paper circles with a gold hairline border and the route number set in the system font, tracking route dashed at 40% with the walked portion solid at 3.4pt, and the walker dot pulsing with a soft gold halo.

### 4.2 Localization — an in-app switch, two layers

The mockup makes the language a user setting on the Profile screen, and switching it re-renders the entire app immediately. Note that there are **two** kinds of text, and they need different machinery:

1. **Interface strings** ("Start walking", "km left", "Post"). These go in a String Catalog (`Localizable.xcstrings`) with `en` and `zh-Hans`. The app stores the chosen language in `@AppStorage`, defaulting to the system locale on first launch, and applies it by setting `\.locale` in the SwiftUI environment at the root view. Anything that resolves a string outside a view (view models, formatters) goes through one small `L10n` helper that takes the locale explicitly, because the environment does not reach non-view code.
2. **Content strings** (route names, notes, areas, kickers, comment bodies). These are *data*, not resources — every route carries both languages at once. They live in the model as a `LocalizedText` struct and are resolved by the same language setting. No String Catalog involvement.

Two typography details that come with the language and are easy to forget: Chinese prose wants looser leading than English (the mockup used 1.95 against 1.7), and figures are set with tabular numerals everywhere they appear (`.monospacedDigit()` on iOS). Both are baked into the shared text styles, not repeated per screen. Type itself is the system font at every size — SF Pro for Latin, PingFang SC substituted automatically for Chinese — so no fonts are bundled and Dynamic Type works without extra work.

If setting `\.locale` turns out to leave some component unlocalised, the fallback is the well-known approach of loading the `zh-Hans.lproj` bundle directly and resolving through it. Keep the `L10n` helper as the single choke point so that change stays contained.

### 4.3 Persistence — SwiftData, but only for what the user owns

Draw the line where a backend would eventually draw it:

- **Catalog data** (routes, seeded comments, posts, collections) ships as a JSON file in the app bundle, decoded into read-only model structs at launch, served through repository types (`RouteRepository`, `FeedRepository`, `CommentRepository`). When a backend arrives, those repositories get a network implementation and a cache; no view changes.
- **User-owned data** (saved flag, offline flag, walks, the summary note and photo, route drafts, comments you posted, likes) goes into **SwiftData**. This is genuinely persistent state, it is small, and SwiftData's `@Query` fits the list screens directly.

SwiftData does not appear in Phase 1 — Phase 1 has nothing to persist. It arrives in Phase 3 with the save/offline toggles, which is the first real user state.

### 4.4 Architecture

SwiftUI-native, no third-party architecture framework. Concretely:

- **State**: `@Observable` classes (the Observation framework) for app-wide stores — `AppSettings` (language), `TrackingSession` (the live walk), `RouteStore`. Injected with `.environment()`. Screen-local state stays in `@State`.
- **Navigation**: a `TabView` with the four tabs, each holding its own `NavigationStack` with a typed path enum. Onboarding is a first-run full-screen cover. Tracking → Summary is a full-screen cover flow (it has no tab bar in the mockup, and ending a walk should not land you back mid-stack). Route builder is likewise a full-screen cover, since it is reachable from both Onboarding and Profile.
- **Views**: plain SwiftUI views with a view model only where there is real logic to hold — tracking, the builder, and the comment composer. Read-only list screens do not need one.
- **Design system**: a `Theme` enum carrying the tokens from `styles.css` — the colour roles and their neutral and gold ramps, the six-step space scale, the three radii, the three shadows — plus a text-style set built on the system font. On top of it sit small shared components: `HairlineRule`, `FigureStrip` (the km/min/dead-ends block), `SegmentedRing` (the gold-inset-ring selector used for filters, feed tabs, and the language switch), `TagChip`, `AvatarInitial`, `RouteRow`, `PrimaryButton` / `SecondaryButton`. Getting these right in Phase 1 is most of what makes later phases fast.

Two rules worth stating up front, both read off the token sheet rather than the mockup's screens. First, **gold is a stroke and a text colour, not a fill** — the sheet's own `.btn-primary` is gold text on a gold hairline over transparent, and selection is a gold inset ring on plain paper. The only tinted fills in the whole system are the tag chips. Second, **separation is done with hairlines, not cards** — `.card` in the sheet is a transparent box with a 1px divider border. Both are easy to lose to default SwiftUI list and form chrome, so list screens use `LazyVStack` with explicit dividers rather than `List`, and no screen uses `.background(.regularMaterial)` or a grouped list style.

How each screen is composed from those tokens is an open design decision per phase, not a transcription of the mockup — see the amendment at the top of this plan.

### 4.5 Minimum iOS version

**iOS 18.0.** Everything needed — Observation, SwiftData, SwiftUI `Map` with `MapPolyline` and `Annotation`, String Catalogs — exists from iOS 17, so 17 is possible if reach matters more; 18 is recommended because it clears several SwiftData rough edges and is already several releases behind current. This is a cheap decision to revisit before Phase 3, and expensive after.

### 4.6 Sample data in early phases, and where a backend slots in

Convert the mockup's `routes`, `commentData`, `postData`, and the two collections into `SampleData.json`, bundled with the app, with a schema matching the model in §3. Load it once at launch. Two rules keep this honest:

- The sample file is the **only** place placeholder content lives. No hardcoded strings in views (the mockup does hardcode the Featured screen and several summary figures — we will not).
- Every read goes through a repository protocol. The Phase 1 implementation reads the bundle; a later implementation calls an API. Views never know which.

The backend, when it exists, owns: the route catalog and its publishing/verification workflow, user accounts and follows, the feed, likes, comments, and photo storage. The client keeps owning: the local save/offline flags, walk recording, drafts, and the language setting. Nothing in Phases 1–8 requires a network call, which is why they can all be built and verified in the simulator.

---

## 5. Phased roadmap

Eight phases. Each one ends with something you can run in the simulator and click through.

### Phase 1 — Scaffolding and the look
**Scope.** Xcode project (SwiftUI lifecycle, iOS 18 target). Folder structure by feature. `Theme` with every colour, spacing, radius and shadow token from `styles.css`, plus the system-font text styles; shared components listed in §4.4 built and exercised on a preview screen. No fonts are bundled — type is SF Pro with automatic PingFang SC substitution. The four-tab `TabView` with the correct icons and labels, each tab a `NavigationStack` with a placeholder screen. `AppSettings` with the language switch and `\.locale` plumbing; `Localizable.xcstrings` with `en` and `zh-Hans`; the `LocalizedText` type and `L10n` helper. `SampleData.json` produced from the mockup's script data, plus the decoding models and the bundle-backed repositories. The Onboarding screen built for real, since it is static and proves the type, tokens, and language switch end to end — and **designed natively from the tokens**, not ported from the mockup's layout.

**Excluded.** Any map. SwiftData. Any screen other than Onboarding. Location permissions.

**Acceptance.** In the simulator: the app opens on Onboarding in the system language; both buttons navigate to placeholder screens; the four tabs switch; a temporary debug toggle flips the app between English and Chinese and every visible string, including the Chinese line height and the tabular figures, changes correctly; a unit test decodes `SampleData.json` and asserts 5 routes, 4 comments, 3 posts, 2 collections.

---

### Phase 2 — Map and route discovery (screen 2)
**Scope.** The `RouteMapView` wrapper with its `discover` mode: all five route polylines with the ink-casing-under-gold-line treatment, numbered circular pins, camera fitted to the routes, and the paper tint overlay. The bottom sheet with peek and full heights and its animated transition. The routes-in-view list with live count. The Featured / Nearby / Saved filter (Saved filters both the list and the pins; Nearby returns everything for now, matching the mockup). The REC button, positioned relative to the sheet. The search field, presented but inert, matching the mockup.

**Excluded.** Route detail (pins and rows navigate to a stub). Real location. The Nearby filter's actual distance logic. Search behaviour.

**Acceptance.** In the simulator: the Map tab shows five gold route lines over a paper-toned Shanghai; dragging the sheet handle expands and collapses it and the REC button moves with it; the count matches the visible rows; tapping Saved reduces both the list and the pins to three routes; tapping a pin and tapping a row both reach the same stub with the right route id; the whole screen reads correctly in Chinese.

---

### Phase 3 — Route detail, Featured, and save/offline state (screens 3 and 4)
**Scope.** Route detail with the `detail` map mode fitted to the route. Kicker, title, three tags, figure strip, note, author credit. SwiftData enters here: a `RouteUserState` model holding `saved` and `offline` per route id, seeded to match the mockup, driving the bookmark toggle and the Download / Offline-ready toggle. The Featured screen, driven by a `featured` flag on the route rather than hardcoded, with its photo, figure strip, editorial text, curator credit, and "Open the route".

**Excluded.** Tracking (the button is present but stubbed). Comments (button present, shows the count, stubbed). Share. Any real download — the offline toggle only writes a flag in this phase.

**Acceptance.** In the simulator: from the map, opening any of the five routes shows its own map line, figures, tags, and note in both languages; the bookmark toggle fills and empties and survives a relaunch; the download toggle's label flips between "Download" and "Offline ready" and survives a relaunch; switching to the Saved filter on the map immediately reflects a bookmark you just toggled; the Featured screen shows Wukang Road and its button opens that route.

---

### Phase 4 — Walk tracking (screen 6)
**Scope.** `TrackingSession` as an observable model: start, pause, resume, end; elapsed timer; distance from real `CLLocationManager` updates; pace; progress along the route line; remaining distance. Location permission request and its Info.plist strings, in both languages. Background location capability so the timer and track survive the screen locking. The `track` map mode: dashed route, solid walked portion, pulsing walker dot, camera following. The full bottom panel and top bar. Pause/Resume and End walk.

**Excluded.** The Summary screen (End walk goes to a stub). Dead-end warnings — "ends ahead" stays a static "none", as in the mockup, until routes carry break points as data. Route snapping and GPS smoothing.

**Acceptance.** In the simulator: starting a walk from Route detail or from the REC button opens tracking with the timer at 00:00 and running; with a GPX route played through the simulator's location feature, the walked portion of the line grows, the walker dot moves, km and pace and remaining update, and the progress bar fills; Pause stops the clock and the label reads "Paused"; Resume continues; backgrounding the app and returning shows the clock has kept running.

---

### Phase 5 — Walk summary and route builder (screens 7 and 8)
**Scope.** Summary: the 2×2 figure grid fed by the finished `TrackingSession`, date and time range, photo picker into the photo slot, note field, "Post to feed" and "Keep it private". Walks are saved to SwiftData either way; the choice sets a flag. "Km over your best" computed against the user's stored walks rather than hardcoded. Builder: `build` map mode with tap-to-add-point, the dotted draft line, filled first point and hollow rest, running point count and distance, name field, four tag toggles, Undo point, and Save route — which writes a user-created route into SwiftData and shows it on the map.

**Excluded.** Actually posting anywhere (the feed does not exist yet; the flag is stored and honoured in Phase 6). Editing or deleting a saved draft route. Snapping drawn points to streets. Publishing a route to other users.

**Acceptance.** In the simulator: finishing a tracked walk lands on Summary showing that walk's real figures; attaching a photo and a note and choosing either button returns you to the app with the walk stored, visible after relaunch; from Onboarding or Profile, the builder opens, five taps on the map draw a dotted line with five dots and show "5 points · N km", Undo removes the last one, and saving a named, tagged route makes it appear in the map's route list.

---

### Phase 6 — Community feed and comments (screens 9 and 5)
**Scope.** Feed with the sticky header and the Friends/Creators segmented control. Friends: post cards from sample data plus the user's own posted walks from Phase 5, with the route link, photo, note, figures, like toggle (persisted, adjusting the count by one), and reply count opening that route's comments. Creators: collection blocks with computed route-count and total-km meta, tappable member routes, and a Follow button (local state only). Comments: the thread with optional pinned-place rows, the compose box, prepending your comment with "Just now", persisted to SwiftData, ignoring empty input.

**Excluded.** Real friends, real following, any network. Threaded replies — the mockup shows a reply *count* but only a flat list. Comment likes, editing, deletion, or moderation. Attaching a pinned place to your own comment (the mockup always posts an empty pin).

**Acceptance.** In the simulator: the Community tab shows three sample posts plus any walk you posted in Phase 5; liking a post increments the count and survives relaunch; tapping a post's route name opens that route; tapping the reply count opens that route's comments; the Creators tab shows two collections with correct route counts and summed kilometres, and its rows open routes; posting a comment inserts it at the top of the thread and it is still there after relaunch; both tabs read correctly in Chinese.

---

### Phase 7 — Saved and offline (screen 10)
**Scope.** The Saved screen with its live count and two sections, both fed by the SwiftData state from Phase 3 and both opening route detail. Then the real work: making "offline" mean something. Decide and implement one of — (a) offline means route data, notes, and a pre-rendered static map image only, with the map view falling back to that image without a network; or (b) replace MapKit behind the wrapper with MapLibre plus an offline tile pack, which makes the download size figure real. Recommendation is to build (a) first because it is a day of work and covers the honest case, and to treat (b) as its own decision with the tile-hosting question answered first.

**Excluded.** Background or automatic downloads. Sync of any kind — the closing note's promise that "saved routes sync when you are back on data" needs a backend and stays copy-only for now.

**Acceptance.** In the simulator: the Saved tab lists offline routes with size and saved routes with area, counts match the toggles set on route detail, and every row opens the right route; with the simulator in airplane mode, opening a route marked offline still shows its line, figures, and walker notes.

---

### Phase 8 — Profile, settings, and polish (screen 11)
**Scope.** Profile with the avatar, joined line, the 2×2 stats grid computed from stored walks and user-created routes rather than hardcoded, and the "Walk range" chart driven by the real monthly longest walk (Swift Charts, styled to the tokens — gold top rule, faint fill, hairline baseline). Settings: the Language switch moved here from the Phase 1 debug toggle, "Routes you added" with its real count → builder, "Offline downloads" with its real count → Saved, and "About Walkable Shanghai" → Onboarding. Then a pass over the whole app: Dynamic Type behaviour, VoiceOver labels on the icon-only buttons (back, save, REC, like), the 44pt tap-target minimum the mockup already respects, empty states for every list, and a check that the back-stack behaviour matches §2.

**Excluded.** Editing your profile, avatar upload, sign-in, other users' profiles — none exist in the mockup. Dark mode: the design system defines one paper palette only, so this is a product decision, not a polish item.

**Acceptance.** In the simulator: the Profile tab shows stats that change after you record a walk or add a route; the chart shows six months with your real longest walks; switching to 中文 changes the entire app including the month labels, and the choice survives relaunch; all three settings rows navigate correctly; VoiceOver announces every icon-only control; the app is navigable at the largest accessibility text size without clipped figures.

---

## 6. Risks and open questions

- **China map data and coordinates.** Mainland China requires licensed map data, and coordinates there are published in GCJ-02 rather than the WGS-84 that GPS reports. Plotting raw GPS on a China basemap produces a visible offset. MapKit handles the licensing and, on-device in China, the shift — but our stored route points came from OSM (WGS-84) and will need checking against the basemap early, on a real device, not just the simulator. Shipping in mainland China additionally needs an ICP filing and a domestic map provider; that is a business decision, not a code one.
- **Background location.** Tracking a 50-minute walk with the screen off needs the background location mode and "Always" permission, which Apple reviews and asks users to confirm again after a few days. Expect battery and permission-fatigue work, and plan a graceful degradation when only "While Using" is granted.
- **Offline tiles.** MapKit has no supported offline tile API, so "Offline ready · 18 MB" cannot be literally true on MapKit. Phase 7 forces the choice between a downgraded but honest offline mode and a MapLibre swap with its own tile-hosting cost.
- ~~**Chinese type.**~~ **Resolved by the sans-serif amendment.** The serif pairing is retired, so there is no missing-glyph problem: iOS substitutes PingFang SC for Chinese inside the same system-font stack, and the two languages sit together as one family. The remaining care needed is leading, which the shared text styles handle.
- **Nothing social works without a backend.** Likes, comments, follows, the feed itself, and cross-device continuity are all local-only through Phase 8. That is fine for building and demoing, but it means the app cannot be usefully released to a second user until a backend exists. Worth deciding now whether Phase 9 is a backend or a TestFlight of the single-user app.
- **The product claim is an editorial process, not a feature.** "Every route was walked end to end before it was published" needs a review workflow, and the builder currently lets anyone save any line. There is also no sign-in anywhere in the mockup, so authorship is unverifiable. Both need answers before routes are public.

### Details the mockup shows but does not drive

These are decisions to make, not bugs to copy. Each is already handled in the phase noted.

| Shown in the mockup | Reality | Where it is resolved |
|---|---|---|
| Search field on the map | a static label, not an input | deferred; not in any phase |
| "Nearby" filter | returns all five routes | Phase 2 keeps it, logic deferred |
| Featured screen content | hardcoded to Wukang Road | Phase 3, via a `featured` flag |
| "Ends ahead: none" while tracking | hardcoded | Phase 4 keeps it; needs break points as route data |
| "+0.6 km over your best" | hardcoded | Phase 5, computed from stored walks |
| Summary date "16 August 2026 · 07:12 – 08:04" | hardcoded | Phase 5, from the real session |
| Profile stats and bar chart | hardcoded numbers and bar heights | Phase 8, computed |
| Download size "18 MB" | a display string on the route | Phase 7, real or clearly labelled |
| Share button on route detail | not wired | Phase 3 or later; trivial with `ShareLink` |
| Follow button on collections | navigates to the feed, does nothing | Phase 6, local state only |
| Map "grade" (Paper / Neutral / Ink) | a design-canvas control, not an app setting | not built; Paper is the app's look |
