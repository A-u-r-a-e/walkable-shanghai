# JWalk

JWalk ("Just Walk") is an iPhone app for finding and sharing walks in Shanghai
that hold together for their whole length: streets under a continuous canopy
of plane trees, quiet lanes that connect, routes that do not end at an arterial
road you cannot cross. A walker finds routes near them on a map, follows one
with live tracking, records streets they discover, and shares routes with other
walkers.

It is a native SwiftUI app for iOS 18 and later, in English and Simplified
Chinese, with Apple MapKit for the map and SwiftData for walks, routes and downloads
stored on the phone. There is no server yet; an approved plan for one is in
[`docs/superpowers/plans/2026-10-27-first-server.md`](docs/superpowers/plans/2026-10-27-first-server.md).

## Where the project stands

| Area | State |
|---|---|
| Map with five route lists (Nearby, Popular, Featured, Mine, Saved), search, three map styles | Done |
| Route card, bookmark (which also downloads the route), share | Done |
| Tracking a route, and recording a free walk with REC | Done |
| Walk summary with photo, note, personal best, and saving a recorded walk as a route | Done |
| Route builder (draw a route by tapping the map) | Done |
| Sharing routes person to person as a `jwalk://` link and a `.jwalk` file | Done; file opening not yet tried on a device |
| Me tab: profile and walk statistics, language, downloads, location access | Done |
| English and Chinese, light and dark | Done |
| Public routes from other walkers, accounts, moderation | Planned (CloudKit), not started |
| Live "walking now" counts | Always 0 until a server exists |
| App icon, code signing, TestFlight, privacy policy | Not started |

The full list, with known bugs and the order to tackle them, is in
[`docs/STATUS.md`](docs/STATUS.md).

## Quick start

You need a Mac with Xcode 26 (the project was last built with Xcode 26.6), the
iOS 18 and iOS 26 simulator runtimes, and Python 3.

```sh
cd JWalk
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer   # only if xcode-select points elsewhere
xcodebuild -project JWalk.xcodeproj -scheme JWalk \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Or open `JWalk/JWalk.xcodeproj` in Xcode and run the `JWalk` scheme. Code
signing is switched off, so the app runs in the simulator with no Apple
Developer account. Running on a device needs signing turned on first (see
[`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md#running-on-a-device)).

## Repository map

| Path | What it is |
|---|---|
| `JWalk/` | The app: sources, tests, UI tests, scripts, screenshots, the generated Xcode project |
| `JWalk/README.md` | Build, test and editing reference for the app |
| `JWalk/DESIGN.md` | The design system and the behaviour of every screen |
| `docs/` | Documentation for developers (below), plus specs and plans |
| `docs/superpowers/specs/`, `docs/superpowers/plans/` | The neutral-redesign spec and plan (11 Oct 2026) and the first-server plan (27 Oct 2026) |
| `research/` | Research behind decisions: map providers, design direction, settings structure |
| `PLAN.md` | The original development plan, from when the app was called Walkable Shanghai. Historical: much of it was later removed or redesigned |
| `Walkable Shanghai.dc.html`, `walk-map.js`, `support.js`, `image-slot.js`, `ios-frame.jsx`, `_ds/` | The original HTML mockup and the design-token sheet it was built from. Historical reference; nothing in the app reads them |

## Documentation

Read in this order:

1. [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md): how the code is organised,
   how data flows, and how each feature works.
2. [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md): setting up a machine, the
   project's conventions, step-by-step recipes for common changes, and traps.
3. [`docs/STATUS.md`](docs/STATUS.md): what works, what is verified, known bugs,
   technical debt, what is missing for a release, and the roadmap.
4. [`docs/DECISIONS.md`](docs/DECISIONS.md): every significant decision so far,
   who made it and why, the project's history, and the research behind it.
5. [`JWalk/README.md`](JWalk/README.md) and [`JWalk/DESIGN.md`](JWalk/DESIGN.md):
   detailed references for building and testing, and for the design system.
