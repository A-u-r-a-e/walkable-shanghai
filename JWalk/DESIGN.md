# JWalk — design system

Neutral grounds in both appearances, near-neutral text, and green kept for the
few things it marks. The app has two tabs, **Map** and **Me**, and follows
Apple's shape and material language: continuous rounded corners, Liquid Glass on
iOS 26 with system materials on iOS 18, and full dark mode that follows the
system setting.

Every colour is a token in `Sources/DesignSystem/Theme.swift`, and every token's
numbers live in `Sources/DesignSystem/Palette.swift`. Screens never use a literal
colour. If a screen needs a colour the palette lacks, add a role to both files.

---

## 0. Research basis

Two notes in `research/` decided this system.

- [`research/ecosia-design-research.md`](../research/ecosia-design-research.md)
  reads Ecosia's own tokens: its iOS app, its web stylesheets and its blog
  theme. In October 2025 Ecosia moved its interface off green. Grounds and
  primary controls became neutral ink, and green stayed in a few deliberate
  roles. That is the model here: green is a marker, never a ground.
- [`research/instagram-settings-research.md`](../research/instagram-settings-research.md)
  records the structure of Instagram's "Settings and activity" screen and
  Apple's guidance on settings lists. The Me tab follows it: an inset grouped
  list, the profile reached through its first row.

---

## 1. Palette

The values are read from `Palette.swift`. Each role has one light and one dark
value.

| Role | Token | Light | Dark |
|---|---|---|---|
| Background | `bg` | `#F8F8F6` | `#1A1A1A` |
| Surface (cards, list groups) | `surface` | `#FFFFFF` | `#242424` |
| Raised surface | `surfaceRaised` | `#FFFFFF` + shadow | `#2F2F2E` |
| Fill (quiet controls, neutral tags, segmented track) | `fill` | `#F0F0EB` | `#333333` |
| Separator | `separator` | `#DEDED9` | `#42423F` |
| Primary text | `label` | `#2B2B29` | `#F4F4F1` |
| Secondary text | `labelSecondary` | `#63635D` | `#B5B5AE` |
| Tertiary text | `labelTertiary` | `#6B6B65` | `#A3A39C` |
| Accent (route line, selected states, filled bookmark, links) | `accent` | `#3F6B23` | `#A9D27E` |
| Primary button fill | `primaryFill` | `#3F6B23` | `#A9D27E` |
| Primary button label | `onPrimaryFill` | `#FFFFFF` | `#1A1A1A` |
| Featured tag fill | `featuredFill` | `#D6E89A` | `#D6E89A` |
| Featured tag label | `onFeaturedFill` | `#2B2B29` | `#1A1A1A` |

`Theme.swift` adds one alpha colour, the sheet's grab handle: `#2B2B29` at 24%
in light, `#FFFFFF` at 30% in dark.

The grounds — `bg`, `surface`, `surfaceRaised`, `fill` and `separator` — are
grey. `PaletteContrastTests.testGroundsAreNeutral` holds each of their ten values
to a spread of at most 16 between the largest and smallest RGB channel, so a
ground cannot drift towards a tint.

Shadows are drawn in light mode only (`Theme.Shadow`). Dark mode separates
surfaces by lightness, and a shadow on a dark ground does not show.

---

## 2. Where green may appear

Green appears in these places and nowhere else:

- **Primary buttons**: Begin route, New route, Done, End walk, Save route, and
  the onboarding's first button. `primaryFill` with an `onPrimaryFill` label.
- **The route line** on every map: the listed routes, the walked half of a route
  while tracking, the dashed half still ahead, and the builder's dotted draft.
  A route's pin belongs to its line: a `surface` disc with an `accent` ring and
  an `accent` centre. So do the walker dot while tracking and the builder's
  draft points, `accent` rings with the first one filled.
- **Selected states**: the selected segment of a segmented control (Popular's
  period selector, the onboarding language switch) and the selected tab item.
  While tracking, the Recording dot and the progress bar's filled part are
  `accent`; both mark the walk in progress.
- **The filled bookmark** on a saved route's card.
- **The Featured tag.** `featuredFill` with an `onFeaturedFill` label. Every
  other tag is neutral (`fill` with `label`).

Green does not appear on grounds, cards, list rows, secondary buttons, icons,
navigation bar buttons, section headers or body text. No text is set in green
except links and the label of a selected state. The Me list's current-value
text (the chosen language, the downloads total) is `labelSecondary`, and back
buttons are `label`: they are chrome, not selections.

Destructive actions, such as Remove all downloads, use the system red.

---

## 3. Contrast, measured

Every text and background pair the app draws must meet WCAG AA: 4.5:1 for body
text, 3:1 for large text and controls. `PaletteContrastTests` checks the pairs
below against the numbers in `Palette.swift`, so the test and the screens cannot
disagree. The ratios are WCAG 2.x relative-luminance ratios computed from those
numbers.

Text on each ground (light / dark):

| Text | on `bg` | on `surface` | on `surfaceRaised` | on `fill` |
|---|---|---|---|---|
| `label` | 13.34 / 15.79 | 14.19 / 14.09 | 14.19 / 12.16 | 12.41 / 11.47 |
| `labelSecondary` | 5.69 / 8.44 | 6.05 / 7.53 | 6.05 / 6.50 | 5.29 / 6.13 |
| `labelTertiary` | 5.04 / 6.86 | 5.36 / 6.12 | 5.36 / 5.28 | 4.69 / 4.98 |
| `accent` | 5.92 / 10.12 | 6.29 / 9.02 | 6.29 / 7.79 | 5.50 / 7.34 |

Labels on filled controls (light / dark):

| Pair | Ratio |
|---|---|
| `onPrimaryFill` on `primaryFill` | 6.29 / 10.12 |
| `onFeaturedFill` on `featuredFill` | 10.72 / 13.15 |

The lowest result is `labelTertiary` on `fill` in light mode, 4.69:1. Any change
to a ground or a label colour must keep every cell above 4.5.

---

## 4. Structure

### Two tabs

The tab bar has **Map** and **Me** (地图 and 我). The tab and navigation bars are
the system's own: Liquid Glass on iOS 26, the standard translucent bar on iOS 18.
`Appearance.apply()` in `JWalkApp.swift` sets two things: the
selected tab item takes `accent`, and navigation bar buttons take `label`.

### Map tab

Over the map, from the top:

- **Search field.** Filters the current route list by route name, in both
  languages, ignoring case. Clearing it restores the list.
- **Map-style button**, round, at the top right. Its menu offers **Map**,
  **Satellite** and **Traffic**. Map is MapKit's standard style with muted
  emphasis and Apple's points of interest hidden. Satellite is imagery with
  labels. Traffic is the standard style with traffic shown. The choice persists
  across launches.
- **REC button.** Starts a free walk at once: it records wherever the walker
  goes, following no route, for a street the app does not know yet. The
  tracker shows the clock, distance and pace, with no remaining distance or
  progress bar, and the map draws the line walked so far. On the walk summary,
  **Save as a route** takes a name; Done then keeps the walked line as a route
  in Mine. Left blank, only the walk is kept. The button rides above the sheet.

### The Routes sheet

A hand-built sheet with two heights: peeking (at most 300pt, or 42% of the
screen) and raised (at most 540pt, or 74%). Its header reads **Routes**,
followed by a dropdown with five options.

| Option | Contents and order |
|---|---|
| **Nearby** (default) | All routes, nearest first by distance from the walker to the route's pin. Without location permission, distance is measured from People's Square. |
| **Popular** | Routes walked in the chosen period, most walks first. A segmented control under the header offers Today, This week, This month and All time; This week is the default. |
| **Featured** | Routes carrying the `featured` tag. |
| **Mine** | Routes the walker recorded with REC or drew in the builder, with a **New route** button at the top that opens the builder. |
| **Saved** | Two sections: **Mine** first, with the New route button, then **Saved**, the bookmarked routes. |

Each row shows the route name, `3.4 km · 52 min`, and
`Last updated: <date> · <N> walking now`, with no route number. Every list has
an empty state: one `labelTertiary` leaf glyph above a sentence, with the glyph
hidden from VoiceOver. The map's pins show the routes in the current list.

### The route card

Tapping a row or a pin selects the route. The map frames its line, and the
sheet's content becomes the route card. The card's close button returns to the
list. The card has two heights:

- **Collapsed**: the title on one line, and `km · min`. The sheet stands 136pt
  plus the tab bar's clearance.
- **Expanded**: the whole card, sized to its content up to 560pt or 78% of the
  screen, whichever is smaller. At the default text size the card fits without
  scrolling on iOS 26.5 and iOS 18.6. Beyond the cap it scrolls.

Top to bottom:

1. The title, with a bookmark toggle and a share button at the right edge, then
   the close button.
2. Distance and time.
3. The description.
4. Tags from the fixed `RouteTag` list. Featured is green; the others are
   neutral.
5. The creator on the left, `<N> walking now` on the right.
6. **Begin route**, the primary button, which starts tracking.

Bookmarking a route also downloads it, and removing the bookmark deletes the
download.

**Sharing.** The share button sends the route itself, two ways at once: a
`.jwalk` file, and a message with the route's name, `km`, `min` and a
`jwalk://route?d=…` link. Messages and Mail make the link tappable; WeChat,
AirDrop and Files carry the file. Opening either in JWalk switches to the Map
tab, past onboarding if it has not been seen, and opens the route's card. A
route JWalk already has opens as itself. A new one shows its sharer as the
creator and carries no tags; it stays in the lists until the app quits, and for
good once bookmarked. A link or file that holds no usable route raises an
alert. There is no server: routes reach only the people they are sent to.

### Me tab

An inset grouped list in the style of iOS Settings. Rows that open a page end
in a chevron; Location access, which leaves the app, ends in an outward arrow.

1. **Profile row**: avatar, name, and `<N> walks · <X> km`. Opens the profile
   page: avatar, joined date, the four-figure grid and the walk-range chart.
2. **Preferences**: Language, English or 简体中文. The app switches immediately.
3. **Storage**: Downloaded routes, with their total size. Opens the list of
   downloaded routes and **Remove all downloads**, which asks first. Removing all
   downloads also removes those bookmarks, because saved and downloaded are one
   state.
4. **Privacy**: Location access, which opens the app's page in iOS Settings.
5. **About**: How JWalk works (opens onboarding), the version, and,
   in debug builds, the design-system gallery.

There is no in-app appearance setting.

---

## 5. Shape

Corners are continuous everywhere: `Theme.shape(_:)` builds
`RoundedRectangle(cornerRadius:style: .continuous)`, so the style cannot be
forgotten.

| Token | Value | Used for |
|---|---|---|
| `xs` | 8 | chips, small inline controls, chart bar tops |
| `sm` | 12 | text fields, small buttons |
| `md` | 16 | buttons, cards |
| `lg` | 22 | grouped cards, floating map controls |
| `xl` | 28 | the sheet's top corners |
| capsule | — | pills, the grab handle, segmented controls, the Routes dropdown |

An inner corner is the outer radius minus the padding between them, and never
less than `xs`.

---

## 6. Materials and Liquid Glass

**Glass is for things that float over the map.** Anything that sits on a page is
opaque.

| Surface | Treatment |
|---|---|
| Search field, map-style button, REC button | `floatingSurface` |
| Routes sheet and route card | `floatingPanel`, `xl` top corners |
| Tab bar, navigation bar | system default |
| Pages (Me, profile, downloads, onboarding, tracking, summary, builder) | opaque `bg` |
| Cards, figure grids, list groups | opaque `surface` |

`Materials.swift` holds the one fork between iOS versions, and views never write
`#available` themselves:

| | iOS 26 | iOS 18 |
|---|---|---|
| `floatingSurface` | `.glassEffect(.regular, in:)`, or `.regular.interactive()` for buttons | `.ultraThinMaterial` |
| `floatingPanel` | `.glassEffect(.regular, in:)` | `.regularMaterial` |

Because the sheet is glass, the basemap shows through it: it reads warm grey
over the light map and blue-grey over MapKit's dark map. The cards and pages
behind it stay on the neutral palette.

`.card()` is the opaque card: `surface`, a hairline `separator` border, and a
small shadow in light mode.

---

## 7. Typography

The system font only: SF Pro for Latin text, with iOS substituting PingFang SC
for Chinese in the same stack. No font is bundled. Every style in
`Typography.swift` is built on a Dynamic Type text style, and every figure uses
tabular digits so columns line up and a running clock does not jitter.

| Style | Built on | Used for |
|---|---|---|
| `display` | large title, medium | screen-opening statements |
| `title` | title, medium | screen titles, the route card's title |
| `heading` | title 3, semibold | the Routes header, section headings |
| `rowTitle` | body, semibold | route names in rows, button labels |
| `body` | body | prose |
| `secondary` | subheadline | supporting text, segmented labels |
| `meta` | footnote | distances, dates, tags |
| `label` | caption, semibold | section headers, via `.sectionLabel()` |

Section headers are sentence case in `labelSecondary`, as iOS sets them.

---

## 8. Components

**Primary button.** `primaryFill`, `onPrimaryFill` label, radius `md`, at least
50pt tall.

**Secondary button.** `fill`, `label` text, radius `md`, no border. Neutral, so
the second action of a pair reads as the lesser one.

**Segmented control** (`SegmentedRing`). A capsule track in `fill`; the selected
segment is a `primaryFill` capsule with an `onPrimaryFill` semibold label, the
others `labelSecondary`.

**Tag chip.** Featured: `featuredFill` / `onFeaturedFill`. Every other tag:
`fill` / `label`. Radius `xs`. Tags wrap onto a new line through `FlowRow` rather
than shrinking.

**Separators.** `separator`, only inside a card or list group, inset to the
content.

**Figures.** `FigureStrip` (tracking) and `FigureGrid` (profile, walk summary)
sit on one card with separators between the cells. When a walk goes farther
than every earlier one, the walk summary shows a neutral **Personal best** tag
chip above the grid; the figures themselves stay `label`.

**Route thumbnails.** Each downloaded route's row draws the route line live on a
`fill` well, with the map's casing for the current appearance and an `accent`
line, so it follows light and dark. The PNG stored with the download is drawn
in the light palette and appears only when the route cannot be decoded.

**Chart.** The profile's walk-range bars are `labelSecondary` with `xs` tops.
Month labels are `labelTertiary`.

**Progress.** A capsule track in `fill` with an `accent` fill.

**Avatars.** A `fill` disc with the walker's single character in
`labelSecondary`. The signed-in walker's avatar takes `label` ink and a
`separator` ring.

**Circular icon button.** A back or dismiss control on an opaque page: a `fill`
disc, no stroke. Controls over the map use `floatingSurface` instead.

---

## 9. The map

`Theme.Map` holds every colour and width the map draws; `RouteMapView` reads it
and invents nothing.

| Element | Treatment |
|---|---|
| Route line | `accent` at 95%, 2.6pt |
| Casing under every line | light: black at 14%; dark: white at 20%; 7pt |
| Walked line (tracking) | `accent`, 4.5pt |
| Route ahead (tracking) | `accent` at 85%, 2.4pt, dashed 2/6 |
| Draft line (builder) | `accent` at 85%, 2.2pt, dotted 1/5 |
| Walker dot | `accent`, with an `accent` halo at 18% |
| Pin | 34pt `surface` disc, 1.5pt `accent` ring, 12pt `accent` centre, soft shadow |

The basemap is MapKit's own and follows the system appearance. MapKit offers no
tile filter, and the app does not tint the basemap.
