# Walkable Shanghai — iOS app

Native SwiftUI app. See `../PLAN.md` for the original development plan and
`../docs/superpowers/specs/2026-10-11-ecosia-redesign-design.md` for the current
design; this file covers how to build, test and change what exists.

**The app has two tabs, Map and Me, on a neutral design system.** The Map tab
holds the route map, search, three map styles and the Routes sheet with its five
lists (Nearby, Popular, Featured, Mine, Saved). Choosing a route opens its card
in the sheet, and Begin route starts tracking, which ends in the walk summary.
Mine leads to the route builder. The Me tab is a settings list: the profile,
language, downloaded routes, location access, and how the app works.
Everything the app shows is either bundled catalogue data or computed from what
the walker has actually done — no screen carries a hardcoded figure.

## Build and run

There is no `xcodegen` or `tuist` on this machine, and the system's
`xcode-select` points at the Command Line Tools rather than at Xcode. So every
command below sets `DEVELOPER_DIR` explicitly rather than changing a machine-wide
setting:

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

# Build
xcodebuild -project WalkableShanghai.xcodeproj -scheme WalkableShanghai \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Test (80 unit + 53 UI). The UI half drives the simulator, so budget ~15 min.
xcodebuild -project WalkableShanghai.xcodeproj -scheme WalkableShanghai \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

If you'd rather not prefix every command, run this once — it needs your password,
which is why it was not done for you:

```sh
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

## How the Xcode project is generated

`WalkableShanghai.xcodeproj` is produced by `Scripts/generate_project.py`. That
was the simplest reliable option here: neither xcodegen nor tuist was installed,
and a two-target project did not justify adding a global tool dependency.

The generated project uses Xcode 16+ **file system synchronized groups**, which
matters day to day: the project file does not list source files. It points at
`Sources/`, `Tests/` and `UITests/` and Xcode picks up whatever is in them.

**So you almost never re-run the script.** Adding, renaming, moving or deleting a
`.swift` file needs no project change at all — just create the file. Re-run
`python3 Scripts/generate_project.py` only to change targets, build settings, or
the deployment target. It is deterministic, so regenerating produces an identical
file.

## Layout

```
Sources/
  App/            entry point, root view, UIKit chrome
  DesignSystem/   Palette (the numbers), Theme (tokens), Typography,
                  Materials, shared components
  Localization/   AppLanguage, AppSettings, LocalizedText, L10n
  Data/           models, repositories, RouteStore, route tags, walker
                  activity, and the SwiftData stores (saved routes and their
                  downloads, walks, drawn routes)
  Features/       Map (route map, Routes sheet, route card, map styles),
                  Me (settings list, downloaded routes), Profile, Tracking,
                  Builder, Onboarding, Offline (the route-image renderer),
                  Shell (tabs, design-system gallery)
  Resources/      SampleData.json, Localizable.xcstrings, Assets.xcassets
Tests/            unit tests over the catalogue, lists, activity, stores,
                  palette contrast and map styles
UITests/          one file per feature, plus screenshot capture
  Support/        AppLaunch.swift, the launch and query helpers every test uses
Scripts/          generate_project.py, strings.py (String Catalog edits),
                  name_attachments.py (names exported screenshots)
Screenshots/
  neutral/        every screen in light and dark on iOS 26.5, and in light on
                  iOS 18.6 — the current app
  (top level), ios18/
                  captures of the app before the neutral redesign
```

The neutral redesign removed the Community tab (feed, comments, likes), the
Saved tab, the monthly Featured page, the pushed route-detail screen and the
placeholder screen. `Features/Community/`, `Features/Saved/` and
`Features/Route/` are gone; `Features/Me/` is new.

## The visual system

`DESIGN.md` is the design system: **neutral grounds in both appearances,
near-neutral text, and green only on primary buttons, the route line, selected
states, the filled bookmark and the Featured tag.** It records the palette, the
measured contrast of every text pairing, and the structure of both tabs.

**Every colour lives in `Palette.swift` and `Theme.swift` and nowhere else.**
`Palette` holds the raw light and dark numbers; `Theme` turns them into adaptive
colours. That split lets `PaletteContrastTests` check every text pairing against
WCAG AA, and check that the grounds stay grey, from the same numbers the screens
draw with. If you need a new colour, add a role to both files.

Compose from the tokens and helpers: `Theme.label`, `Theme.surface`,
`Theme.fill`, `Theme.accent`, `Theme.primaryFill`, `Theme.shape(_:)`, `.card()`,
`.floatingSurface(in:)`, `.floatingPanel(in:)`, `.primaryClassical` and
`.secondaryClassical` button styles.

The direction comes from `../research/ecosia-design-research.md`, which reads
how Ecosia moved its interface off green in 2025, and the Me tab's structure
from `../research/instagram-settings-research.md`.

## Two things worth knowing before you edit

**Type is the system font, everywhere.** SF Pro covers English and iOS
substitutes PingFang SC for Chinese inside the same stack. No fonts are bundled.
Use the styles in `Typography.swift` rather than `.font(.system(size:))`, so
Dynamic Type keeps working.

**Two kinds of text, two mechanisms.** Interface strings ("Begin route") live
in `Localizable.xcstrings` and are read with `"key".localized(language)`. Add or
change them with `python3 Scripts/strings.py`, which writes both languages at
once. Content strings (route names, descriptions) are *data* — every record
carries both languages at once in a `LocalizedText`. Do not put content in the
String Catalog; it will arrive from a server later, not from a resource file.

## How the UI tests are written

The shared helpers live in `UITests/Support/AppLaunch.swift`.
`launchWalkable(language:resetState:mapStyle:arguments:)` starts past
onboarding, from the seeded state, with the map style pinned, and waits for the
Routes sheet; new tests should launch through it. A few older classes
(`LanguageSwitchUITests`, `ProfileUITests`, `TrackingUITests`, and the
onboarding test in `SummaryAndBuilderUITests`) still build their own
`XCUIApplication`. Most of them set something the helper does not, such as
onboarding shown or a text size; `TrackingUITests` was never moved over. `anyElement`, `revealRow`, `chooseRoutesOption`,
`isSheetPeeking`, `visibleRowOrder` and `attachScreenshot` cover the rest. The
helpers are `@MainActor`, so a test class that uses them is marked `@MainActor`
too.

Four habits, each learned from a test that lied once:

- **Assert `isHittable`, not `exists`, for anything near an edge.** A row under
  the tab bar or below the sheet's fold still "exists". Only `isHittable` says a
  finger would reach it, which is why `revealRow` raises the sheet and scrolls
  the list until the row is hittable.
- **Read a control's number from `.value`, not its label.** Walk counts and the
  elapsed clock are accessibility *values*; matching on a label matches the word
  next to the number instead.
- **To claim something persists, relaunch without the reset.** Every launch
  takes `-uitest.resetUserState`, so a persistence test launches once to write
  and again with `resetState: false` to read back.
- **Screenshots come out of the test run, never a manual capture.** Tests attach
  them with `XCTAttachment`; they are exported from the result bundle afterwards
  (see "Screenshots").

Launch arguments the app understands:

| Argument | Effect |
|---|---|
| `-settings.language english\|chinese` | the app's language |
| `-settings.hasSeenOnboarding YES\|NO` | skip or show onboarding |
| `-settings.mapStyle standard\|satellite\|traffic` | the map style |
| `-uitest.resetUserState` | start from the seeded saved routes, with no walks or drawn routes |
| `-uitest.ignoreLocation` | Nearby measures from People's Square, so its order does not depend on the simulator's location |
| `-uitest.simulateWalk <routeId>` | tracking follows that route instead of CoreLocation |
| `-uitest.forceOffline` | forces `Reachability` offline; no current screen reads it (see "What offline means here") |

## Counting things in two languages

English needs two plural forms and Chinese needs one. Both live in the String
Catalog as `variations.plural`, and are read with a distinct entry point:

```swift
L10n.string("me.walks", language, count: 1)   // "1 walk", not "1 walks"
```

Two things about it are easy to get wrong. Plural variations compile to a format
carrying a plural token, and only `String(format:locale:)` resolves that token —
plain interpolation leaves it in the string. And the locale passed must be the
**app's**, not the phone's, or an app running in Chinese on an English phone
applies English plural rules to Chinese text. `L10n.string(_:_:count:)` handles
both; use it for anything countable.

Where a count sits inside a longer sentence (`"5 points · 0.4 km"` in the
builder), the countable half is its own catalogue key (`builder.points`) and the
sentence (`builder.tally`) takes it as an argument. That keeps every plural on
the simple `variations.plural` shape instead of needing catalogue substitutions.

## Language switching

The app runs in one language at a time, chosen in-app under Me → Preferences →
Language, and it can disagree with the phone's language. Interface strings are
resolved against the explicit `.lproj` bundle for the chosen language (`L10n`)
rather than relying on SwiftUI's environment locale for lookup, because that
follows the bundle's preferred localisation. The environment locale *is* still
set at the root — dates, numbers and measurements need it.

## What "offline" means here

**Saving a route downloads it, and removing the bookmark deletes the download.**
There is no separate download control and no separate offline flag: a route is
offline when it has a stored bundle. `SavedRoutesStore` keeps the two in step,
and at launch `ensureDownloads` downloads any saved route that lacks a bundle
and removes any bundle whose route is no longer saved. Me → Downloaded routes
lists the bundles with their sizes, and **Remove all downloads** deletes every
bundle and the bookmarks with them, because saved and downloaded are one state.

MapKit has no supported way to store map tiles, so a download does **not**
include a map. It stores two things in SwiftData, in `OfflineBundle`:

- the route itself, encoded — a snapshot, not a pointer into the catalogue
- a PNG of the route line, drawn from the route's own coordinates by
  `RouteImageRenderer` — no tiles requested, nothing cached from anyone

Bundles no longer store walker notes; notes were removed with the Community tab.
The size shown is the byte count of exactly those two fields. The seeded routes
land between about 50 and 100 KB each.

The route card reads the live catalogue, which ships inside the app, so it works
with or without a network. The stored snapshot exists for later: once the
catalogue comes from a server, a route you took with you has to keep working
after the server's copy moves on. The Downloads page already draws from the
stored bundles.

`Reachability` still exists and the app still builds it (honouring
`-uitest.forceOffline`), but since the route card replaced the route-detail
screen, no view reads it.

## A picture must never decide the layout's width

`.scaledToFill()` reports the *scaled* size of the image, not the size of the
box. A wide picture in a narrow slot then measures wider than the slot, and
`.frame(maxWidth: .infinity)` does not rein that in — clamping a width to
infinity clamps nothing. The oversized width travels up the layout and centres
the whole column of text off screen.

Use `.fillingBox(height:)` (in `DesignSystem/Components.swift`) for any picture
that fills a slot. It paints the image as an overlay on an empty box, so the box
decides the size and the overflow is clipped rather than measured. The walk
summary's photograph goes through it.

## The profile's figures are computed

Nothing on the profile page is stored as a number. Walks, kilometres on foot,
longest walk and routes added are read off `WalkStore` — the `StoredWalk` and
`DraftRoute` tables — every time the screen draws, and so is the Me list's
`<N> walks · <X> km`. The "Walk range" chart is `WalkRange.lastMonths`, which is
a pure function over stored walks and therefore unit-tested against a fixed date
rather than the real one.

A fresh install shows zeroes, an em dash for the longest walk, and an empty
chart that says why. That is correct: showing somebody else's achievements to a
walker who has not walked yet would be the one dishonesty this app cannot
afford.

## The map

The app stays on **Apple MapKit**. `../research/map-provider/` compares the
alternatives — AMap (`amap.md`), Tencent, Baidu and Mapbox
(`tencent-baidu-mapbox.md`), and MapLibre (`maplibre-and-china-law.md`). MapKit
is the only option that is lawful to show in mainland China with no licence or
account, offers satellite and traffic there, and fits the existing wrapper. AMap,
Tencent and Baidu need commercial licences and Chinese accounts, and lack English
labels or arm64 simulator support; Mapbox and MapLibre are not lawful or
reliable for users inside mainland China.

The map-style button offers three styles, persisted in `settings.mapStyle`:

- **Map**: `MKStandardMapConfiguration`, muted emphasis, Apple's points of
  interest hidden so they do not compete with the route pins.
- **Satellite**: `MKHybridMapConfiguration`, imagery with labels.
- **Traffic**: the standard configuration with `showsTraffic` on.

Because the camera sits on Shanghai, Apple Maps serves the basemap from its
**China** endpoints, which are backed by **AutoNavi (Amap)**. Earlier runs from
this machine timed out against them:

```
https://gspe19-2-cn-ssl.ls.apple.com/poi_update?...   → timed out (-1001)
https://dispatcher.is.autonavi.com/dispatcher          → timed out (-1001)
```

and for a while the iOS 26.5 simulator drew the routes over an empty grid while
iOS 18.6 drew full scenery. **That is no longer what happens.** On 2026-10-12,
from this machine's network, which runs through a VPN, all three styles drew
scenery on both iOS 26.5 and iOS 18.6. The iOS 26.5 basemap carried AutoNavi's
attribution (高德地图); the iOS 18.6 basemap carried Apple Maps' attribution.
Whether the scenery draws depends on the network path to those endpoints, so
expect it to come and go with the VPN.

Three things follow:

- **Tests assert geometry and identity, not scenery.** The map exposes its style
  as the accessibility value of `route-map`, and pins as `route-pin-<routeId>`,
  so the suite is green with or without tiles.
- **Traffic colouring did not appear in the simulator.** On 2026-10-12 the
  Traffic style drew the standard basemap on iOS 26.5, at city zoom, from a
  route card, and pinched in to street zoom over the Inner Ring and Yan'an
  elevated roads, but no congestion colouring showed on any road. The style is
  set (`MapStyleTests` checks `showsTraffic`); whether traffic data reaches the
  simulator is not something the app controls.
- **For the product:** serving Shanghai on MapKit means depending on AutoNavi's
  infrastructure and Apple's China licensing, and on how each iOS release talks
  to them.

## Running on both iOS versions

The deployment target is iOS 18.0, and the suite is green on **iOS 18.6**
(iPhone 16 Pro) as well as **iOS 26.5** (iPhone 17 Pro): TEST_COUNTS_BOTH.

`name=iPhone 16 Pro` does not resolve on this machine (`xcodebuild` exits 70,
"Unable to find a device matching"), so point at the iOS 18.6 simulator by its
id. List ids with `xcrun simctl list devices`:

```sh
xcodebuild -project WalkableShanghai.xcodeproj -scheme WalkableShanghai \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,id=<iPhone 16 Pro id>' test
```

Three differences bite the UI tests:

- **The tab bar.** iOS 26 draws a floating capsule *over* the content; iOS 18
  draws an opaque bar over the foot of the sheet. A row near the bottom of the
  peeking sheet can sit under the bar, so tests reach rows through `revealRow`
  rather than `app.buttons["route-row-…"].tap()`. The same goes for Begin route
  when the card scrolls at the largest text sizes: XCUITest's own scroll stops
  once the button enters the scroll view, still under the iOS 18 bar, so the
  test swipes the card until the button `isHittable`.
- **Titles shared with a tab.** "Map" is both a map style and the first tab, and
  on iOS 18 `app.buttons["Map"]` finds the tab. `MapStyleUITests` picks the
  match outside the tab bar.
- **Menus.** iOS 18 offers a `Menu` label less than its own width, which cut the
  Routes dropdown's "Nearby" to "Near…". The label's text is `.fixedSize()`
  for that reason.

## System bars

The tab and navigation bars are the system's own: Liquid Glass on iOS 26, the
standard translucent bar on iOS 18. `Appearance.apply()` in
`WalkableShanghaiApp.swift` sets two things: the selected tab item takes the
app's green, and navigation bar buttons take the primary text colour, because a
back button is chrome rather than a selection.

## Screenshots

`UITests/ScreenshotUITests.swift` walks every screen and attaches a screenshot of
each: the route list peeking and raised, Popular, Saved, the route card expanded
and collapsed, Me, the profile, downloaded routes, tracking, the walk summary
and the builder. The test only navigates; appearance is switched on the
simulator between runs. From `WalkableShanghai/`:

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
for look in light dark; do
  xcrun simctl boot "iPhone 17 Pro" 2>/dev/null; xcrun simctl ui "iPhone 17 Pro" appearance $look
  rm -rf /tmp/ws-shots-$look.xcresult
  xcodebuild -project WalkableShanghai.xcodeproj -scheme WalkableShanghai -sdk iphonesimulator \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test \
    -only-testing:WalkableShanghaiUITests/ScreenshotUITests \
    -resultBundlePath /tmp/ws-shots-$look.xcresult -quiet
  mkdir -p Screenshots/neutral/$look
  xcrun xcresulttool export attachments --path /tmp/ws-shots-$look.xcresult \
    --output-path Screenshots/neutral/$look
  python3 Scripts/name_attachments.py Screenshots/neutral/$look
done
xcrun simctl ui "iPhone 17 Pro" appearance light
```

`xcresulttool export attachments` names each file by a UUID and writes a
`manifest.json`; `Scripts/name_attachments.py` renames every file to the name
the test gave it and deletes the manifest. `Screenshots/neutral/ios18-light/`
is the same run on the iOS 18.6 simulator in light, with `-destination` set to
its id.
