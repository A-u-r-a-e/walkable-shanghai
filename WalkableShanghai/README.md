# Walkable Shanghai — iOS app

Native SwiftUI app. See `../PLAN.md` for the full development plan; this file
covers only how to build and run what exists.

**All eight phases are complete.** Every screen in the plan is built:
onboarding, map and discovery, featured, route detail, notes, tracking, walk
summary, route builder, community feed, saved/offline, and profile/settings.
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

# Test (72 unit + 63 UI). The UI half drives the simulator, so budget ~25 min.
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
  DesignSystem/   Theme (tokens), Typography, shared components
  Localization/   AppLanguage, AppSettings, LocalizedText, L10n
  Data/           models, repositories, RouteStore, and the SwiftData stores
                  (saved/offline flags, walks, likes and notes, downloads)
  Features/       Onboarding, Map, Route, Tracking, Builder, Community,
                  Saved, Offline, Profile, Shell (tabs, gallery)
  Resources/      SampleData.json, Localizable.xcstrings, Assets.xcassets
Tests/            unit tests over the catalogue, the stores and the renderer
UITests/          one file per feature, plus screenshot capture
Screenshots/      captured by the UI tests, not by hand (iOS 26.5)
  ios18/          the same screens on iOS 18.6, the deployment target
```

## The visual system has been replaced

`DESIGN.md` is the design system: **a foliage-green theme, Apple's shape and
material language, full dark mode.** It replaces the Classical print-inspired
system described in the section below, which is gone from the code entirely.

The rollout is complete. All eleven screens are converted, and the compatibility
aliases that kept the unmigrated ones compiling — `Theme.text`, `Theme.divider`,
the remapped `Gold` and `Neutral` ramps, `paperBackground()` — are deleted. The
compiler proved the migration was total: nothing referenced them by the time they
went.

Read `DESIGN.md` before touching any view, and compose from its tokens
(`Theme.label`, `Theme.surface`, `Theme.accentSoft`, `Theme.accentFill`,
`Theme.shape(_:)`, `.card()`, `.canopyWash()`, `.floatingSurface(in:)`).

**Every colour lives in `Theme.swift` and nowhere else.** That is enforceable by
grep, and worth keeping: the palette was swapped wholesale twice during the
rollout, and each swap was a one-file change because no view had invented a
colour of its own. If you need a new colour, add a token.

The hues are not invented either. `../research/nature-design-research.md` records
what real outdoors apps ship — AllTrails, Komoot, Gaia, iNaturalist — gathered
from their own style guides and live design tokens, and `DESIGN.md §0` says which
four findings decided which values.

Screenshots of all eleven screens in both appearances are in
`Screenshots/redesign/`, captured by `RedesignScreenshotUITests` rather than by
hand.

## Three things worth knowing before you edit

**Type is the system font, everywhere.** The Classical design system this app is
built from pairs Cormorant Garamond with Lora; both are retired by decision. SF
Pro covers English and iOS substitutes PingFang SC for Chinese inside the same
stack. No fonts are bundled. Use the styles in `Typography.swift` rather than
`.font(.system(size:))`, so Dynamic Type keeps working.

**~~Gold is a stroke, not a fill.~~ Retired — see `DESIGN.md`.** The old system
forbade filled buttons, tinted cards and elevated surfaces; the new one uses all
three, because Apple's language does. What survives: list screens still use
`LazyVStack` with explicit separators rather than `List`, so the app controls its
own row chrome.

**Two kinds of text, two mechanisms.** Interface strings ("Start walking") live
in `Localizable.xcstrings` and are read with `"key".localized(language)`. Content
strings (route names, walker notes) are *data* — every record carries both
languages at once in a `LocalizedText`. Do not put content in the String Catalog;
it will arrive from a server later, not from a resource file.

## How the UI tests are written

Four habits, each learned from a test that lied once:

- **Assert `isHittable`, not `exists`, for buttons near an edge.** A control
  under the floating tab bar still "exists". Only `isHittable` says a finger
  would reach it.
- **Read a control's number from `.value`, not its label.** Like counts, walk
  counts and the elapsed clock are accessibility *values*; matching on a label
  matches the word next to the number instead.
- **To claim something persists, relaunch without the reset.** Every launch
  takes `-uitest.resetUserState`, so a persistence test launches once to write
  and again *without* that argument to read back.
- **Screenshots come out of the test run, never a manual capture.** Tests attach
  them with `XCTAttachment`; they are exported from the result bundle into
  `Screenshots/` afterwards.

Launch arguments the app understands: `-settings.language`,
`-settings.hasSeenOnboarding`, `-uitest.resetUserState`, `-uitest.simulateWalk
<routeId>`, `-uitest.forceOffline`.

## Counting things in two languages

English needs two plural forms and Chinese needs one. Both live in the String
Catalog as `variations.plural`, and are read with a distinct entry point:

```swift
"saved.count".localized(language, count: 1)   // "1 route", not "1 routes"
```

Two things about it are easy to get wrong. Plural variations compile to a format
carrying a plural token, and only `String(format:locale:)` resolves that token —
plain interpolation leaves it in the string. And the locale passed must be the
**app's**, not the phone's, or an app running in Chinese on an English phone
applies English plural rules to Chinese text. `L10n.string(_:_:count:)` handles
both; use it for anything countable.

Where a count sits inside a longer sentence (`"1 point · 0.4 km"`, `"Added by
M. Lau · walked 1 time"`), the countable half is its own catalogue key and the
sentence takes it as an argument. That keeps every plural on the simple
`variations.plural` shape instead of needing catalogue substitutions.

## Language switching

The app runs in one language at a time, chosen in-app under the You tab, and it
can disagree with the phone's language. Interface strings are resolved against
the explicit `.lproj` bundle for the chosen language (`L10n`) rather than relying
on SwiftUI's environment locale for lookup, because that follows the bundle's
preferred localisation. The environment locale *is* still set at the root — dates,
numbers and measurements need it.

## What "offline" means here

MapKit has no supported way to store map tiles, and the tiles for Shanghai come
from Apple's China endpoints anyway (see the next section). So downloading a
route does **not** download a map. It stores three things in SwiftData, in
`OfflineBundle`:

- the route itself, encoded — a snapshot, not a pointer into the catalogue
- its walker notes as they stood at download time
- a PNG of the route line, drawn from the route's own coordinates by
  `RouteImageRenderer` — no tiles requested, nothing cached from anyone

The size shown to the walker is the byte count of exactly those three fields.
The mockup printed a flat "18 MB" for every route; that figure was invented, and
a storage number a walker cannot check is worse than none. Real routes land
around 100–140 KB.

With no network *and* a download in hand, `RouteDetailScreen` and
`CommentsScreen` read the snapshot rather than the catalogue, and the map slot
draws the stored PNG instead of building a `RouteMapView` at all. Today the
snapshot and the catalogue agree, because the catalogue ships inside the app —
but the catalogue is meant to come from a server later, and a route you took
with you has to keep working after the server's copy moves on. That is the whole
reason the snapshot is stored rather than just the picture.

The `Reachability` type is the only thing that decides online versus offline, and
it has exactly one consumer. The simulator has no airplane mode `simctl` can
reach, so the UI tests force the flag with `-uitest.forceOffline`; everything
below the flag is the real path.

## A picture must never decide the layout's width

`.scaledToFill()` reports the *scaled* size of the image, not the size of the
box. A 900×560 route drawing in a 393×290 slot measures 466 points across, and
`.frame(maxWidth: .infinity)` does not rein that in — clamping a width to
infinity clamps nothing. The oversized width then travels up the layout and
centres the whole column of text off screen.

Use `.fillingBox(height:)` (in `DesignSystem/Components.swift`) for any picture
that fills a slot. It paints the image as an overlay on an empty box, so the box
decides the size and the overflow is clipped rather than measured. Both the
offline map and the walk-summary photograph go through it, and
`SavedUITests.testTheStoredMapDoesNotShiftTheLayoutSideways` pins the behaviour.

## The profile's figures are computed

Nothing on the You tab is stored as a number. Walks, kilometres on foot, longest
walk and routes added are read off `WalkStore` — the `StoredWalk` and
`DraftRoute` tables — every time the screen draws. The "Walk range" chart is
`WalkRange.lastMonths`, which is a pure function over stored walks and therefore
unit-tested against a fixed date rather than the real one.

A fresh install shows zeroes, an em dash for the longest walk, and an empty
chart that says why. That is correct: the source design hardcoded six bar
heights and four statistics, and showing somebody else's achievements to a
walker who has not walked yet would be the one dishonesty this app cannot
afford.

## The basemap draws on iOS 18, not on iOS 26

This one changed once we finally ran on the deployment target. On the **iOS 18.6**
simulator the Shanghai basemap renders in full — streets, water, parks, labels —
under our routes and paper wash. On **iOS 26.5** the same build shows the routes
over an empty grid. Same machine, same network, same binary: the difference is
the runtime.

So the earlier diagnosis below was too broad. It is not "this machine cannot
reach the map backends" — iOS 18 reaches them fine. Something about how iOS 26's
MapKit resolves the China endpoints is what fails here. The original evidence,
kept because the endpoints named are still the ones in play:

```
https://gspe19-2-cn-ssl.ls.apple.com/poi_update?...   → timed out (-1001)
https://dispatcher.is.autonavi.com/dispatcher          → timed out (-1001)
```

Because the camera sits on Shanghai, Apple Maps serves the basemap from its
**China** endpoints, which are backed by **AutoNavi (Amap)**. That much is
confirmed — the iOS 18 screenshots in `Screenshots/ios18/` carry AutoNavi's
attribution.

Three things follow:

- **For development:** on iOS 26 expect a blank basemap and verify geometry
  (pins, lines, framing) rather than scenery. Every map test is written to
  assert geometry and identity, so the suite is green with or without tiles —
  which is why this never showed up as a failure.
- **When a map change needs to be seen:** run it on the iOS 18.6 simulator,
  where the scenery actually draws.
- **For the product:** serving Shanghai on MapKit means depending on AutoNavi's
  infrastructure and Apple's China licensing, and evidently on how a given iOS
  release talks to them. That is a real input to the MapKit-vs-MapLibre
  question, not a detail.

## Running on both iOS versions

The deployment target is iOS 18.0, and the suite is green on **iOS 18.6**
(iPhone 16 Pro) as well as **iOS 26.5** (iPhone 17 Pro). Point `-destination` at
whichever you want; both were run at the end of Phase 8.

One difference bites the UI tests. iOS 26 draws its tab bar as a floating
capsule *over* the content; iOS 18 draws an opaque bar that takes layout space.
So the map's peeking sheet fits two route rows on iOS 18 and four on iOS 26. A
row below the fold still "exists" to XCUITest, and tapping it lands on whatever
covers it. Tests therefore go through `revealRouteRow`, which expands the sheet
when the row is not hittable rather than trusting the fold. Reach for that
helper rather than `app.buttons["route-row-…"].tap()` for anything past the
first two routes.

## ~~Known cosmetic deviation~~ — resolved by the redesign

There used to be a note here about the tab bar. The old system repainted the tab
and navigation bars in paper so they sat flush with a print-inspired ground, and
on iOS 26 that override was largely ignored by the system's new floating capsule
— so the bar read slightly lighter than the page, and the deviation had to be
flagged rather than fixed.

The redesign hands the bars back to the system entirely. On iOS 26 that means
Liquid Glass, on iOS 18 the standard translucent bar, and on both it means the
app's chrome matches every other app on the phone. `Appearance.apply()` in
`WalkableShanghaiApp.swift` now sets exactly one thing — the selected item takes
the app's green rather than the system blue — and there is nothing left to
deviate. That was the point of moving to Apple's language, and it retired the
problem instead of working around it.
