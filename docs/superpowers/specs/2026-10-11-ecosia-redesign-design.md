# Walkable Shanghai — neutral redesign and two-tab structure

Date: 2026-10-11. Status: approved design, not yet implemented.

This design replaces the "under the canopy" visual system (green-tinted grounds, soft-green cards, canopy wash) and restructures the app from four tabs to two. The canopy palette read as ugly in dark mode and as too pervasive: green on every surface looked toxic rather than natural.

Research behind the decisions:

- `research/ecosia-design-research.md` — Ecosia moved to neutral grounds and ink controls in October 2025 and kept green for a few deliberate roles.
- `research/instagram-settings-research.md` — structure of Instagram's Settings and activity screen and Apple's guidance on settings lists.

## 1. Structure

The app has two tabs: **Map** and **You**.

Removed entirely, with their screens, models, stores, strings, sample data and tests:

- The Saved tab (`SavedScreen`).
- The Community tab: feed (`FeedScreen`, `FeedModels`), friends' posts, likes, follows, creator collections.
- Route notes / comments (`CommentsScreen`, `RouteComment`, `CommunityStore`).
- The monthly Featured page (`FeaturedScreen`, `FeaturedEdition`) and the "Featured this month" banner.
- `PlaceholderScreen`, if nothing else uses it.

The walk summary no longer offers "Post to feed" / "Keep it private". It has one action, **Done**, which stores the walk. `isPosted` is removed from stored walks; existing stored walks keep loading.

Tracking, the route builder, onboarding and the profile page stay, restyled to the new palette.

## 2. Colour

Neutral grounds in both modes, near-neutral text, green in a few named roles only. Every colour is a token in `Sources/DesignSystem/Theme.swift`; screens never use literal colours.

| Role | Light | Dark |
|---|---|---|
| Background | `#F8F8F6` | `#1A1A1A` |
| Surface (cards, sheet) | `#FFFFFF` | `#242424` |
| Raised surface | `#FFFFFF` + shadow | `#2F2F2E` |
| Fill (quiet controls, neutral tags) | `#F0F0EB` | `#333333` |
| Separator | `#DEDED9` | `#42423F` |
| Primary text | `#2B2B29` | `#F4F4F1` |
| Secondary text | `#63635D` | `#B5B5AE` |
| Accent (route line, selected state, filled bookmark, links) | `#3F6B23` | `#A9D27E` |
| Primary button fill / label | `#3F6B23` / `#FFFFFF` | `#A9D27E` / `#1A1A1A` |
| Featured tag fill / label | `#D6E89A` / `#2B2B29` | `#D6E89A` / `#1A1A1A` |

Rules:

- Green appears only on primary buttons (Begin route, New route, Done and similar), the route line, selected states, the filled bookmark and the Featured tag. Grounds, cards, secondary buttons, icons and body text are neutral.
- Text stays ink or near-white. No text is set in green except links and selected-state labels.
- The canopy-wash gradient and the "sunlight" accent are deleted.
- Liquid Glass (iOS 26) and material fallbacks (iOS 18) stay for controls floating over the map.
- Every text/background pair must meet WCAG AA (4.5:1 for body text, 3:1 for large text and non-text controls). Measured ratios are recorded in `WalkableShanghai/DESIGN.md`, which is rewritten for this system.
- Appearance follows the system light/dark setting. There is no in-app appearance setting.

## 3. Map tab

### Top controls

- **Search field.** Filters the current route list by route name (both languages, case-insensitive). Clearing it restores the list.
- **Map-style button.** A round floating button at the top right. It opens a menu with **Map**, **Satellite** and **Traffic**. Map is MapKit's standard style; Satellite is imagery with labels (hybrid); Traffic is the standard style with traffic shown. The choice persists across launches.
- The old Featured / Nearby / Saved segmented control is removed.
- The record button stays and keeps riding above the sheet.

### Route sheet

The hand-built two-height sheet stays. Its header reads **Routes** followed by a dropdown with five options:

| Option | Contents and order |
|---|---|
| **Nearby** (default) | All routes, nearest first by distance from the walker's location to the route's pin. Without location permission, distance is measured from People's Square. |
| **Popular** | Routes walked in the chosen period, most walks first. A selector under the header offers **Today / This week / This month / All time**; default This week. |
| **Featured** | Routes carrying the `featured` tag. |
| **Mine** | Routes the walker drew in the builder, with a **New route** button at the top that opens the builder. |
| **Saved** | Two sections: **Mine** first (with the New route button), then **Saved** (bookmarked routes). |

Every list shows an empty state when it has no rows.

Each row shows, without a number:

- the route name;
- `3.4 km · 52 min`;
- `Last updated: <date> · <N> walking now`.

Pins on the map show the routes in the current list, without numbers.

### Route card

Tapping a row or a pin selects the route: the map frames its line and the sheet's content becomes the route card. A close button on the card returns to the list. The card has the same two heights as the sheet:

- **Collapsed:** title and `km · min`.
- **Expanded:** everything below, fitting without scrolling at default text size.

Order, top to bottom:

1. Title, with a bookmark toggle and a small share button at the right edge.
2. Distance and time. No dead-ends figure.
3. Description.
4. Tags from the fixed tag list (section 4). No time-of-day or district tags.
5. Creator name on the left; `<N> walking now` right-aligned.
6. **Begin route** (primary button), which starts tracking.

There is no header line above the title. The share text carries the route name, distance and time.

`RouteDetailScreen` as a pushed screen is removed; the card replaces it everywhere a route was opened from.

## 4. Data

### Route

- Removed: `kicker`, `tag1`, `tag2`, `breaks`, `area`, `number`, `isFeatured`, `downloadSize`.
- Added: `tags: [RouteTag]` and `updatedAt: Date`.
- `RouteTag` is a fixed list owned by the developers. It starts with `featured` and `popular`; each case has a localized label. Adding a tag means adding a case and its two strings.
- A route is featured when its tags contain `featured`.

`SampleData.json` loses posts, comments, collections and the featured edition, and gains `tags`, `updatedAt` and per-period walk counts for each route.

### Walker activity

A protocol, `RouteActivityProvider`, answers:

- `walkingNow(routeId) -> Int`
- `walks(routeId, period) -> Int`, where `period` is today, this week, this month or all time.

The shipped implementation is offline: `walkingNow` returns 0, and `walks` reads the bundled per-period counts. A server-backed implementation replaces it later without changing any view.

### Saved and offline

Saving a route also downloads it (route data and the pre-rendered map image). Removing the bookmark deletes the download. There is no separate download control. The separate offline flag is removed; "offline" means "has a stored bundle". Bundles no longer store notes.

## 5. You tab

An inset grouped list in the style of iOS Settings. Rows open with a chevron.

1. **Profile row:** avatar, name, and `<N> walks · <X> km`. Opens the profile page: avatar, joined date, the stats grid and the walk-range chart.
2. **Preferences:** Language (English / 简体中文), switching immediately as it does today.
3. **Storage:** Downloaded routes, with their total size. Opens a list of downloaded routes and a **Remove all downloads** action that asks for confirmation. Removing all downloads also removes those bookmarks, since saved and downloaded are now one state.
4. **Privacy:** Location access, which opens the app's page in iOS Settings.
5. **About:** How Walkable Shanghai works (opens onboarding), and the app version.

Debug builds also show the design-system gallery under About.

Not included until a backend exists: sign in, log out, delete account, sync. "Send feedback" and "Privacy policy" are not included until an address and a URL exist.

## 6. Testing

- Unit and UI tests for removed screens and models are deleted.
- New or updated tests cover:
  - each dropdown option's contents and order, including Nearby's People's Square fallback;
  - the Popular period selector;
  - search filtering;
  - selecting a route, collapsing and expanding the card, closing it;
  - the card's contents and order, and the absence of the dead-ends figure;
  - map-style switching and persistence;
  - save-then-download and unsave-then-delete;
  - the You list, the profile page, Remove all downloads;
  - the walk summary's single Done action;
  - both languages.
- The full suite runs green on iOS 18.6 (iPhone 16 Pro) and iOS 26.5 (iPhone 17 Pro).
- New light and dark screenshots of every screen replace `Screenshots/redesign/`.

## 7. Known limits

- On the iOS 26.5 simulator the standard basemap is blank because Apple's China map endpoints (AutoNavi) time out from this network. Satellite and Traffic may be blank there too. Map styles are verified visually on the iOS 18.6 simulator; tests assert the selected style, not the scenery.
- Walking-now counts read 0 and walk counts are bundled sample figures until a backend exists.
