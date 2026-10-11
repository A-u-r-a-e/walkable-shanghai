# Walkable Shanghai — design system

This replaces the Classical print-inspired system the app was built with. Three
things change and nothing else: the app becomes **green all the way through**,
the surface language becomes **Apple's own** (generous rounded corners,
materials, Liquid Glass on iOS 26), and the app gains **full dark mode**.

It is a visual change only. No feature, no data, no navigation, no copy and no
behaviour moves. If a change to this document would require touching a view
model, a store or a test that asserts behaviour, it is out of scope.

---

## 0. Research basis

The palette is not invented. It is drawn from what nature and outdoors apps
actually ship, gathered from first-party sources — brand style guides, live
design tokens, official logo files — and written up in
[`research/nature-design-research.md`](../research/nature-design-research.md).
Four findings decided the values below, and each one overturned a guess:

| Finding | Evidence | What it changed here |
|---|---|---|
| Outdoors greens are **yellow-leaning**, hue 78–120° | Komoot `#4F6814` (78°), iNaturalist `#74AC00` (80°), Pantone Greenery `#88B04B` (84°), AllTrails `#4DA330` (105°); teal-side greens belong to focus/health apps (Forest 160°, PictureThis 156°) | The ramp moved from hue 150° — which reads as corporate mint — to **hue ≈ 100°** |
| Dark grounds are **green-tinted near-blacks**, never pure black | AllTrails ships `#0E110E` / `#1D211D`; Komoot `#2B3117`; Material says dark grey, not `#000` | The dark ground is `#101410`, the value the research recommends |
| **Ink stays near-neutral** even in the greenest brands | AllTrails body text is onyx `#161F13`; Gaia's is a plain granite grey; nobody sets paragraphs in mid-saturation green | `label` is AllTrails' onyx exactly; the supporting weights are neutral greys |
| Light grounds are **warm paper**, and the green comes from *real estate* | Komoot `#FAF9F4`, AllTrails birch `#F2EEE7`, with big soft-green fills doing the work | The ground is warm paper tilted greener than industry-typical, and `accentSoft` is used generously |

We sit deliberately greener than the industry on the light ground, because this
app is asked to be heavily nature-themed. But the *mechanism* is theirs: most of
the green comes from green surfaces, washes and controls, not from dyeing the
page.

---

## 1. Under the canopy

The theme is one image: **walking Shanghai's plane-tree streets with the light
coming through the leaves.** Plane-tree foliage is a warm yellow-green, which is
also where the research lands, so the metaphor and the evidence agree.

### The three working greens

Depth is what stops "green everywhere" from becoming a smear. The system works in
three layers, taken from the ramp at three points, named for what they do rather
than for where they sit — because the two modes enter from opposite ends. Light
goes dark at the front; dark goes bright at the front, which is Apple's and
Material's own lighten-on-dark pattern.

| Layer | Role | Light | Dark |
|---|---|---|---|
| **Mist** (`accentMuted`) | the back: the route still ahead of you, the foot of a chart bar, the start of a progress fill | leaf `#A9CD7F` | canopy `#35661F` |
| **Fresh** (`accentStrong`) | the middle: the far stop of a growing gradient, a drawn draft line | `#74A343` | `#74A343` |
| **Canopy** (`accent`) | the front: route lines, icons, selected state, accent text, the rule capping a bar | `#397225` | `#9BD97E` |

Anything describing an *amount* moves through those layers rather than sitting at
one green: the chart bars, the progress fill, the tracking screen's walked line
against the route ahead of it.

### The canopy wash

The signature. Two overlapping soft radial glows at the top of a screen — light
through leaves, with no hard edge anywhere in it. Radial rather than linear
because a linear ramp has a direction and a canopy does not: the eye reads a band
as a header bar and a glow as light. The two stops are offset from each other so
the overlap is off-centre, which keeps it from reading as a logo.

It appears on **four screens only** — onboarding, featured, the walk summary and
the profile — and it is strong enough on each to be the thing you remember.

### Restraint — the four rules that keep this from becoming a swamp

1. **Type is not green.** `label`, `labelSecondary` and `labelTertiary` are ink
   and near-white. This is the research's clearest single pattern, and it is the
   difference between a theme and a rendering fault.
2. **Green text never sits on a green ground.** On `accentSoft` a *label* takes
   `onAccentSoft` or `label`; `accent` is allowed there only for a non-text
   glyph, which needs 3:1 rather than 4.5:1.
3. **One warm colour, spent once.** `sunlight` is reserved exclusively for the
   Featured moment's star. Anywhere else it is noise.
4. **Green carries no meaning it has not earned.** Not "eco", not "success", not
   "safe". Environmental messaging is explicitly out of scope.

Note what is *not* on that list any more: the old "one tinted card per screen"
rule is gone. Soft green is now the app's ordinary surface for cards, sections,
segmented tracks, avatars and secondary buttons — that is the real-estate lever
the research points at, and rationing it was what made the first attempt read
grey.

---

## 2. Palette

### The foliage ramp

Seven steps, hue held near 100°.

| Step | Hex | Used for |
|---|---|---|
| `deep` | `#26430F` | forest anchor; `onAccentSoft` in light |
| `canopy` | `#35661F` | light: `accentFill`; dark: **mist** layer |
| `accent` | `#3E7C2B` | the research's interactive green — tuned before use, see below |
| `fresh` | `#74A343` | **fresh** layer both modes; dark `accentFill` |
| `leaf` | `#A9CD7F` | light: **mist** layer; dark: `onAccentSoft` |
| `mist` | `#D6E5B5` | light pin disc |
| `pale` | `#EAF1D8` | light `accentSoft`, canopy glow, map grade |

### Grounds and surfaces

| Role | Light | Dark |
|---|---|---|
| Background | `#F1F3E3` | `#101410` |
| Surface (card, sheet) | `#F8FAF0` | `#1A1F19` |
| Surface raised | `#FFFFFF` | `#242A22` |
| Fill (inset, track, field, media slot) | `#E2E9CC` | `#2B3323` |
| Mist (card borders, in-card separators) | `#C9D5AB` | `#2F3A26` |
| Pin disc | `#D6E5B5` | `#242A22` |

### Accent roles

| Role | Light | Dark |
|---|---|---|
| `accent` | `#397225` | `#9BD97E` |
| `accentStrong` | `#74A343` | `#74A343` |
| `accentMuted` | `#A9CD7F` | `#35661F` |
| `accentFill` | `#35661F` | `#74A343` |
| `onAccentFill` | `#FFFFFF` | `#182C08` |
| `accentSoft` | `#EAF1D8` | `#223018` |
| `onAccentSoft` | `#26430F` | `#A9CD7F` |
| `sunlight` (Featured only) | `#7E5B0E` | `#E8B84B` |

### Labels — near-neutral, per the research

| Role | Light | Dark |
|---|---|---|
| `label` | `#161F13` | `#F2F4EF` |
| `labelSecondary` | `#4A544A` | `#AAB4A6` |
| `labelTertiary` | `#5C625A` | `#9EA99A` |

`label` in light is AllTrails' onyx exactly.

### Two values tuned, and why

Everything else is the researched value used as-is. Two failed measurement and
were moved the smallest distance that fixed them:

- **`accent` in light: `#3E7C2B` → `#397225`.** The research value clears the
  ground at 4.53 but measures **4.07 on `fill`** and **4.38 on `accentSoft`** —
  and since soft green is now ordinary card and section real estate, the accent
  has to clear it. Two steps darker gives 4.65 and 5.01, still plainly the same
  foliage green.
- **`onAccentFill` in dark: `#26430F` → `#182C08`.** Deep-on-fresh measured
  **3.73** and failed. Darkening the text rather than lightening the button keeps
  the filled control the `fresh` green the research points at.

### Contrast, measured

Twenty-six real pairings in **both** modes — fifty-two results — checked against
WCAG 2.1 with the exact values above. **All fifty-two clear AA (4.5:1)**; the
type pairings clear AAA comfortably. Re-measured from scratch when the palette
moved to foliage, because a tinted ground changes every ratio on the screen.

| Pairing | Light | Dark |
|---|---|---|
| accent on background | 5.18 | 11.17 |
| accent on surface | 5.52 | 10.06 |
| accent on surface raised | 5.82 | 8.83 |
| accent on fill | **4.65** | 7.89 |
| accent on accentSoft | 5.01 | 8.39 |
| accent on canopy wash | **4.86** | 6.84 |
| label on background | 15.06 | 16.79 |
| label on surface | 16.07 | 15.12 |
| label on fill | 13.52 | 11.85 |
| label on accentSoft | 14.58 | 12.61 |
| label on canopy wash | 14.15 | 10.27 |
| labelSecondary on background | 7.02 | 8.67 |
| labelSecondary on surface | 7.50 | 7.81 |
| labelSecondary on fill | 6.31 | 6.12 |
| labelSecondary on accentSoft | 6.80 | 6.51 |
| labelSecondary on canopy wash | 6.60 | 5.30 |
| labelTertiary on background | 5.57 | 7.61 |
| labelTertiary on surface | 5.95 | 6.85 |
| labelTertiary on fill | 5.00 | 5.37 |
| labelTertiary on accentSoft | 5.40 | 5.72 |
| labelTertiary on canopy wash | 5.23 | **4.66** |
| onAccentFill on accentFill | 6.84 | **5.04** |
| onAccentSoft on accentSoft | 9.55 | 7.80 |
| sunlight on background | 5.51 | 10.08 |
| sunlight on surface | 5.88 | 9.08 |
| sunlight on canopy wash | 5.17 | 6.17 |

"On canopy wash" is measured against the wash at its strongest point — where both
radial glows overlap — rather than where it has already faded into the ground.
The dark wash's strength was set by that measurement: at the first strengths
tried, `labelTertiary` came out at 3.85, so the two glows dropped to 40% and 42%.

---

## 3. Shape

The old scale (2 / 4 / 7pt) is retired. Apple's shapes are generous and, more
importantly, **continuous** — `RoundedRectangle(cornerRadius:style: .continuous)`
everywhere. A circular-arc corner at these radii reads visibly wrong next to
system chrome.

| Token | Value | Used for |
|---|---|---|
| `xs` | 8 | chips, small inline controls |
| `sm` | 12 | text fields, segmented controls, small buttons |
| `md` | 16 | buttons, list cards, figure cards |
| `lg` | 22 | grouped cards, the map's floating controls |
| `xl` | 28 | bottom sheet top corners, hero surfaces |
| `capsule` | — | pills, the grab handle, filter segments |

Nesting rule: an inner corner is the outer radius minus the padding between
them, floored at `xs`. A 16pt card with 8pt padding holds a 8pt inner shape.

---

## 4. Materials and Liquid Glass

### The rule

**Glass is for things that float over content.** Anything that sits *on* the
page is opaque.

| Surface | Treatment |
|---|---|
| Map search field, filter control, REC button | **Glass** |
| Map bottom sheet | **Glass**, `xl` top corners |
| Floating back / bookmark buttons over a map | **Glass**, circular |
| Tab bar, navigation bar | **System default** — do not restyle |
| Page backgrounds (onboarding, detail body, profile) | Opaque `bg`, or the header wash gradient |
| Cards, figure grids, list rows | Opaque surface colour |
| Long-form reading surfaces | Opaque, always |

Glass over an opaque page is noise: there is nothing behind it to refract. Glass
over the map is the whole point — the map keeps showing through the controls
that sit on it.

### Per-OS behaviour

| | iOS 26+ | iOS 18 (deployment floor) |
|---|---|---|
| Floating controls | `.glassEffect(.regular, in:)` | `.background(.ultraThinMaterial)` |
| Interactive floating controls | `.glassEffect(.regular.interactive(), in:)` | `.background(.ultraThinMaterial)` |
| Bottom sheet | `.glassEffect(.regular, in:)` | `.background(.regularMaterial)` |
| Tab bar | system Liquid Glass | system translucent bar |

One helper carries this — `.floatingSurface(_:in:)` in `Materials.swift`. Views
never write `#available` themselves. Adding a new floating control means calling
the helper, not repeating the fork.

The iOS 18 fallback is a real design, not a degradation to tolerate:
`.ultraThinMaterial` over the map gives the same read — content showing through
a frosted control — without the specular edge. Both were checked on device.

---

## 5. Typography

**Unchanged.** System font throughout: SF Pro for Latin, automatic PingFang SC
substitution for Chinese, Dynamic Type on every style, tabular figures on every
number. `Typography.swift` is not touched by this redesign.

One treatment changes: the small gold uppercase tracked section label
(`.sectionLabel()`) was a print device. It becomes a plain **secondary-weight
sentence-case label in the secondary label colour**, which is what iOS uses for
section headers. Tracking and uppercasing are dropped.

---

## 6. Components

**Primary button.** Filled `accentFill`, `onAccentFill` text, radius `md`, 50pt
tall. This is the biggest departure from the old system, which forbade filled
buttons entirely. Apple's does not, and a filled foliage button is the clearest
possible "this is the action".

**Secondary button.** `accentSoft` background, `label` text, radius `md`, no
border. Soft green rather than a neutral well: it is the second half of a pair of
actions and belongs to the same family as the primary, one layer back. Its title
stays `label` — restraint rule 2.

**Cards.** `accentSoft` background, radius `md` or `lg`, a **1pt `mist` border**,
and a soft shadow in light mode only.

Soft green, not a near-white panel — this is the single biggest lever on how
green the app reads, because almost everything on almost every screen is in a
card. It is also exactly the mechanism the research describes: AllTrails and
Komoot both run warm, barely-tinted *page* grounds and get their green from large
soft-green surfaces sitting on them. Near-white cards on a cream ground are how
the first attempt ended up looking grey.

`surface` survives as a token — the map's stored offline drawing uses it for the
end marker, and it is the natural value for anything that must read as paper
under the canopy — but no card uses it. A screen full of pale panels was the
problem, not the solution.

**Canopy wash.** Two overlapping radial glows over the ground, applied with
`.canopyWash()`. Light: a wide `fresh` glow at 28% with a `pale` glow at 85%
inside it. Dark: the same geometry as `deep` at 40% and `canopy` at 42%, *lifting*
the forest ground rather than washing it out — a pale glow on a night ground
would read as fog rather than as leaves. It is a ground, so it never carries a
corner, a border or a shadow. Four screens only.

**Separators.** Solid `mist`, and only *inside* a card between rows, inset to the
content. Screens no longer use hairlines to divide the page; cards do that now.
The one exception is the seam between a live map and the opaque panel under it —
that is a boundary between two materials rather than a page dividing itself, and
iOS draws it too.

**Bottom sheet.** Glass, `xl` top corners, a capsule grab handle. Behaviour,
detents and drag logic unchanged.

**Filter control.** A capsule track in `accentSoft`, with the selected segment a
capsule of `accentFill` carrying `onAccentFill` text. The standard iOS segmented
look, tinted foliage — and the track itself is green real estate.

**Tag chips.** `accentSoft` fill / `onAccentSoft` text when set, `fill` /
`labelSecondary` when not. Radius `xs`. A chip may carry an SF Symbol before its
text where the theme genuinely carries the meaning — the "Green" route tag takes
a leaf — and that glyph is hidden from VoiceOver so the chip still announces
exactly the word it always did.

**Circular icon button.** A back or dismiss control that sits *on* a page rather
than floating over a map: an `accentSoft` disc with an `onAccentSoft` glyph, no
stroke. Anything floating over live content calls `.floatingSurface` instead.

**Avatars.** `accentSoft` with an `accent` ring for the signed-in walker or a
curator; the neutral well for everyone else.

**Empty states.** A single `accent` leaf above the sentence, hidden from
VoiceOver. The theme's mark rather than an illustration: the copy and the
announcement are exactly what they were.

**Figure grid.** A card. Figures sit on `surface` with `mist` separators between
cells rather than hairlines on the page. Numbers keep tabular figures and their
emphasis colour.

**Chart.** Bars are a vertical **mist-to-fresh** gradient capped by a 2pt solid
`accent` rule at the value, with radius `xs` on the bar top (Swift Charts'
`cornerRadius`, not a `clipShape` — a clip shape draws correctly but costs the
chart its accessibility element, and three UI tests then cannot find the chart at
all). The gradient is the point: a bar that grows greener as it grows taller says
"further" without a second axis. The baseline is a `mist` separator under the
plot. Month labels in `labelTertiary`. Structure and data unchanged.

**Progress.** A capsule track in `fill` with a capsule fill running the layers
horizontally — `accentMuted` where it started to `accent` where it has reached —
at height 6. The old 3pt ruled bar was a print device.

**Route pins.** A `pinDisc` disc — mist green in light so the pin belongs to the
landscape, raised forest in dark so it reads against one — with an `accent`
number and a 1.5pt `accent` ring, and a soft shadow.

---

## 7. The map — a green landscape

The map is where the theme is most visible and most easily ruined, so its
translation is spelled out.

| Element | Old (gold) | New (foliage) |
|---|---|---|
| Route line | `#B68235` @ 90%, 2.4pt | `accent` @ 95%, 2.6pt |
| Line casing | ink @ 10%, 6.5pt | light: ink @ 14%; dark: white @ 20%, 7pt |
| Walked line (tracking) | gold solid, 4pt | `accent` (canopy) solid, 4.5pt |
| Route ahead (tracking) | gold @ 42%, dashed | `accentMuted` (mist) @ 85%, dashed |
| Draft line (builder) | gold @ 75%, dotted | `accentStrong` (fresh) @ 85%, dotted |
| Walker dot | gold core, gold halo | `accent` core, `accent` halo |
| Pin | paper disc, gold ring | `pinDisc` disc, `accent` ring |
| Basemap grade | paper @ 34% | light: pale `#EAF1D8` @ 40%; dark: `#0A0F09` @ 46% |

The grade is what makes the basemap botanical rather than street-atlas grey.
MapKit exposes no tile filter, so it is a translucent sheet drawn across the map
beneath the routes and pins — which therefore keep their full saturation. In
light mode it is the palest step of the foliage ramp, laid on heavily enough that
Apple's greys and beiges go leaf while water stays recognisably blue. Nature
includes water, and a map whose rivers have turned green is a map with a bug, not
a theme. In dark mode the sheet inverts — the night basemap is already dim, so
grading it lighter would flatten the green instead of lifting it — and it is a
near-black *green* rather than pure black, so the map does not fall out of the
palette.

Two things stop the grade from swallowing the route. The casing under each line
was strengthened (14% from 12% in light, 20% from 18% in dark), because a green
line on a green map needs more separation than a green line on grey. And tracking
draws its two halves from **two different layers of the ramp** — canopy behind
you, mist ahead of you — rather than one green at two opacities, so "done" and "to
go" read as two states and not as one line with a rendering problem.

MapKit's own dark map is requested explicitly rather than inherited, so the grade
and the basemap can never disagree about which mode they are in.

---

## 8. What deliberately does not change

- **Layout and structure.** Every screen keeps its composition, its order and
  its information hierarchy. This is a re-skin, not a re-layout.
- **Navigation.** Four tabs, the same stacks, the same covers, the same back
  behaviour.
- **Copy.** No string changes in either language. The String Catalog is not
  touched.
- **Typography.** System font, Dynamic Type, tabular figures — as above.
- **Accessibility conventions.** Every identifier, label and value stays exactly
  as it is. The UI tests assert behaviour and identity, not colour, and they
  must keep passing untouched.
- **Data, stores, models, repositories.** Not touched.
- **The 44pt minimum target** and the largest-text-size behaviour.
- **`Theme.Space`.** The 4.6-based spacing scale is idiosyncratic but it is
  working, it is used everywhere, and rescaling it would be a re-layout. It
  stays.

---

## 9. Rollout

Step one proved the shape, material and dark-mode work on three screens —
**Onboarding**, **Map discovery** (including pins, route lines and the sheet) and
**Route detail** — against a neutral grey palette with a green accent.

Step two does two things at once, because doing them separately would mean
skinning eight screens twice:

1. **The palette becomes the theme** (§1, §2). Green stops being an accent on a
   grey chassis and becomes the light: leaf-cast grounds, the three working
   greens, the canopy wash, one warm colour spent once. Every neutral is
   re-specified and all fifty contrast results are re-measured — four values in
   this document exist because a first choice failed and was tuned until it did
   not. The three step-one screens are re-touched so the whole app lands on one
   system rather than two.
2. **The remaining eight screens are converted** — Featured, Notes, Tracking,
   Summary, Builder, Feed, Saved, Profile — and the compatibility aliases the
   theme layer kept for them (`Theme.text`, `Theme.divider`, the remapped `Gold`
   and `Neutral` ramps, `paperBackground()`) are deleted. The compiler is what
   proves that migration is total: nothing referenced them by the time they went.

What step two does **not** do is change any of §8. It is still a re-skin.
