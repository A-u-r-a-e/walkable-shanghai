# JWalk decisions and history

Why JWalk is the way it is. Each decision says who made it and why, so you can
tell a product choice the project owner holds from a technical choice you are
free to revisit. Changing an owner decision means asking the owner; changing a
technical one means weighing the reason given here.

## How the project has worked

- **Plans before building.** Each stage of work started from a written spec or
  plan that the project owner approved (`docs/superpowers/specs/` and
  `docs/superpowers/plans/`). Decisions the owner had to make were put to them as
  short multiple-choice questions.
- **The owner approves visible copy.** New headings, buttons, labels and helper
  text are shown to the owner before they ship.
- **What the app is for.** JWalk exists to help people find shaded,
  continuous streets to walk with friends, to record the ones they discover, and
  to share them, so that knowledge from walkers across Shanghai adds up. The
  owner wants the app to match that description. Features that serve it (record,
  share, find nearby) take priority over polish elsewhere.

## History

| Date | What happened |
|---|---|
| Before October 2026 | `PLAN.md` written from an HTML mockup (`Walkable Shanghai.dc.html`): eleven screens, four tabs (Map, Community, Saved, You), a "Classical" paper-and-gold look, and eight phases from scaffolding to profile. Two amendments followed: the mockup defines what screens do, not how they look, and all type is sans-serif. |
| From 31 August 2026 | All eight phases built, then a "canopy" redesign: green throughout, green-tinted grounds, a gradient wash, Liquid Glass and dark mode. Research: `research/nature-design-research.md`. |
| 11 October 2026 | Snapshot of the canopy app (`48259fb`). The owner rejected the canopy look as ugly in dark mode and too pervasive, reading as toxic rather than natural. Research into Ecosia's move away from green and into settings screens; map-provider research; the neutral redesign spec and its 14-task plan. |
| 11–12 October 2026 | The neutral redesign on branch `neutral-redesign`: Community, the Saved tab, the Featured page and route notes removed; neutral palette, fixed tags, Routes sheet with five lists, map styles, route card, Me tab. 81 unit and 54 UI tests. |
| 22 October 2026 | The redesign merged into `main`. The owner renamed the app JWalk and asked for the app to match its intended description: REC became a free walk that can be saved as a route, and person-to-person sharing was added. |
| 27 October 2026 | The JWalk work committed (`1fa9d6a`). The first-server plan approved: CloudKit, TestFlight first. |

## Product decisions (the project owner's)

| Decision | When | Why, and what it rules out |
|---|---|---|
| **Native iOS in SwiftUI**, iPhone only, portrait | From the start | A walking app lives on the phone in the hand. No Android, no iPad, no web app. |
| **The name is JWalk** ("Just Walk"), in both languages; the Latin name is used in the Chinese interface too | 22 Oct 2026 | Replaced "Walkable Shanghai" / 可步行的上海. The bundle id changed with it to `com.jwalk.app`. Older documents (`PLAN.md`, `docs/superpowers/`, `research/`, the mockup) keep the old name as history. |
| **English and Simplified Chinese, switched inside the app**, independent of the phone's language | From the start | Bilingual walkers in Shanghai choose the language they read the city in. Apple suggests per-app language in iOS Settings instead; the app keeps its own switch. |
| **The neutral design**: neutral greys in light and dark, near-neutral text, green only on primary buttons, the route line and pins, selected states, the filled bookmark and the Featured tag | 11 Oct 2026 | The earlier all-green canopy design was rejected. `JWalk/DESIGN.md` is the reference. |
| **The system font only** (SF Pro, PingFang SC for Chinese), with Dynamic Type | From the start | The original token sheet's serif fonts were retired. |
| **No in-app appearance setting**: the app follows the phone's light or dark | 11 Oct 2026 | Settings research found an in-app switch unnecessary. |
| **Two tabs, Map and Me** (我). Community (feed, comments, likes, collections), the Saved tab, the monthly Featured page and route notes are removed | 11 Oct 2026 | The app was simplified around the map. "You" was renamed "Me", which also avoided a clash with 我的 ("Mine") in Chinese. |
| **Comments and conversation stay out** | 22 Oct 2026 | Reconfirmed when the server was planned. |
| **Tags are a fixed list owned by the developers** (`featured`, `popular`) | 11 Oct 2026 | Walkers cannot tag routes, which keeps tags trustworthy. |
| **Saving a route downloads it**; there is no separate download control | 11 Oct 2026 | One state is simpler to understand than two. |
| **REC records a free walk**, following no route, and the walker can save it as a route | 22 Oct 2026 | Recording a newly found street with minimal interaction is central to the app. Before, REC tracked the walker against the Featured route and discarded the line. |
| **Share routes person to person now, as a link and a file; a server next** | 22 Oct 2026 | Lets walkers share before a backend exists. Links are not tappable in WeChat, so a file goes too. |
| **Skip marking shaded stretches of a route, and skip directions to a route's start** | 22 Oct 2026 | Considered and declined for now. Both remain possible later. |
| **Onboarding: three promises** (Length, Time, Walker); the body no longer promises that every route was walked end to end before publishing | 22 Oct 2026 | The earlier "dead ends" promise had been cut with its feature, and no publishing check existed to back the old sentence. |
| **The first server** (see below) | 27 Oct 2026 | Approved plan. |

## Technical decisions

| Decision | Why | If you want to change it |
|---|---|---|
| **Apple MapKit for the map** | The only option lawful to show in mainland China with no licence or account, with satellite and traffic there, and fitting the existing wrapper. AMap needs a ¥50,000-a-year licence once listed and a Chinese-verified account, and its English labels cannot be combined with a custom style; Tencent and Baidu have similar licensing and label limits; Mapbox and MapLibre have no lawful, reliable tile source inside mainland China. Details in `research/map-provider/`. | Read the research first. The cost is MapKit's dependence on Apple's China (AutoNavi) endpoints and no offline tiles. |
| **SwiftData** for everything stored on the phone | Native, no dependencies, enough for four small models. | Add a versioned schema before any non-trivial model change. |
| **No view models**; `@Observable` stores in the environment, pure functions for logic | Few screens and little shared state; logic that matters is unit-tested directly. | Fine to introduce where a screen grows complex. |
| **The Xcode project is generated by a Python script** with folder-synchronised groups | No xcodegen or tuist was installed; a script with no dependencies is deterministic and adding files needs no project change. | Any generator works if it keeps the same targets and settings. |
| **Interface strings looked up in the chosen language's bundle** (`L10n`) instead of SwiftUI's automatic lookup | SwiftUI's lookup follows the phone's language, not the app's. | Keep it while the in-app language switch exists. |
| **Elapsed time from the wall clock**, the timer only redraws | The clock stays right when the phone locks or the app is suspended. | Do not count ticks. |
| **Raw GPS distance**, no snapping to the route and no smoothing | Kept simple for the first version. Fixes worse than 50 m, older than the walk, or jumping 500 m are ignored. | Smoothing or snapping would improve figures on a real device. |
| **The route card reads the live list, not the stored download** | The catalogue ships in the app, so it works offline. | Needed once the catalogue comes from a server: an offline card should read the download. |
| **Downloads store the route and a drawn PNG of its line, no map tiles** | MapKit has no supported way to store tiles. | Offline tiles need a different map approach. |
| **The sheet on the map is built by hand**, not `.presentationDetents` | The REC button rides on its height and the map frames routes in the visible part. | A system sheet cannot report its height live. |
| **Shared routes carry no distance, time or tags**; the receiver measures the line | A link cannot claim a short walk for a long line, and tags stay the developers'. | Keep for any format version. |
| **A shared route is kept only when bookmarked** | No separate inbox to manage; saving is already how a walker keeps a route. | — |
| **Tests assert identifiers, values and geometry, never map scenery** | The basemap depends on the network path to China. | — |

## The first server

Approved 27 October 2026; `docs/superpowers/plans/2026-10-27-first-server.md`
has the full plan and its reasons.

| Question | Decision |
|---|---|
| Hosting | CloudKit public database, container `iCloud.com.jwalk.app`. No machine to run, no filing to start, nothing beyond the Developer Program to pay. The cost: no server code, so every check runs in the app, where a modified app could skip it. |
| Distribution | TestFlight first; the China App Store and its MIIT filing later. |
| Identity | The phone's iCloud account plus a display name. Sign in with Apple was dropped: CloudKit cannot check its token, and account deletion would need a server to revoke it. |
| What may be published | The walker's own routes walked end to end: REC recordings, and drawn routes after a tracked walk covers them. |
| Privacy of lines | The walker trims the line's ends by hand before publishing; no automatic cut. |
| Visibility | At once; walkers report and block; the developer hides routes. |
| Walking now and Popular | Unchanged: 0, and the bundled counts. |

## Research

| File | Conclusion |
|---|---|
| `research/nature-design-research.md` (31 Aug 2026) | Outdoor apps (AllTrails, Komoot, Gaia, iNaturalist and others) use yellow-leaning greens and keep text neutral. The basis of the canopy design, since rejected. |
| `research/ecosia-design-research.md` (11 Oct 2026) | Ecosia moved its brand off green to neutral ink and one pale accent. Basis of the neutral design: neutral grounds, green for a few roles, let the map carry the nature. The research suggested ink primary buttons; the spec chose green ones. |
| `research/instagram-settings-research.md` (11 Oct 2026) | Basis of the Me tab: Apple's Settings pattern, inset grouped lists, permissions sent to iOS Settings, no appearance switch. |
| `research/map-provider/amap.md`, `tencent-baidu-mapbox.md`, `maplibre-and-china-law.md` (11 Oct 2026) | Stay on MapKit (see the technical decisions above). Also: the app's own drawn routes might count as an internet map service under China's map regulations (unconfirmed), and WGS-84 vs GCJ-02 offsets should be checked on a device in Shanghai early. |

## What the original plan had that the app does not

`PLAN.md` describes the app before the October 2026 redesign. These parts of it
no longer exist:

- The Community tab: friends and creators feeds, likes, following, creator
  collections, posting a walk to the feed.
- Route notes pinned to corners, and comments.
- The monthly Featured page (Featured is now a tag and a list).
- The Saved tab (Saved is now a list; downloads live under Me).
- "Dead ends" as a route figure, while tracking and in onboarding.
- Route numbers, kickers, areas, time-of-day tags, walk counts and download
  sizes on the route model; the builder's four tags.
- An editorial check that every route was walked before publishing.
- The paper-and-gold "Classical" look.

The app has things the plan did not: working search, Popular and Nearby lists,
map styles, dark mode, free-walk recording and person-to-person sharing.
