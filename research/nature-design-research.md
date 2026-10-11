# How nature-themed apps actually use green — research notes

Researched 2026-08-31 against primary sources (brand PDFs, live first-party site CSS, official color references). Each hex is labeled **confirmed** (pulled from a source the brand owns) or **inferred** (secondary source / measured). HSL hues are computed from the hexes.

---

## 1. Real palettes of nature/outdoors apps

### AllTrails — confirmed (official Style Guide PDF + live site design tokens)

Brand PDF (hosted by AllTrails, © 2023 AllTrails LLC): https://assets-global.website-files.com/650d0d523ce1729e6e4e0626/650d47c95f79fc1f3665097c_AllTrails%20Style%20Guide.pdf

- Primary: `#142800` (near-black green), `#2C5601` (dark forest/olive), `#5DE372` (neon green, logo mountain), `#FFFFFF`
- Secondary: `#C1C1C1`, `#ACC3FF`, `#C2CC9D` (sage), `#F6F5E8` (warm cream)
- PDF states: "`#142800` is used for text on light backgrounds. `#FFFFFF` is used for text on dark backgrounds."

Live product tokens (alltrails.com CSS bundles, fetched 2026-08-31) — **confirmed**:

- Green ramp: `#EEF7ED` (100) → `#4DA330` (500, H=105°) → `#293E23` (800)
- Brand names: pine `#1B2818`, onyx `#161F13` (the body-text ink), moss `#7D867C`, fog `#DCE1DB`, birch `#F2EEE7` (warm off-white), neon `#94F477` / neon-dark `#6ADD36`
- **Neutrals are green-tinted, not gray**: `#F4F5F4`, `#E6EAE6`, `#D0D6CE`, `#8B958A`, `#535B52`, `#222621`, `#151915`, `#0E110E` (neutral-1000)
- `<meta name="theme-color" content="#2b381f">` — dark olive, not black

### Komoot — confirmed (live komoot.com design tokens, 2026)

Source: komoot.com homepage inline CSS (theme-ui tokens), fetched 2026-08-31. Media kits at https://newsroom.komoot.com/media_kits/

- Primary interactive: `#4F6814` (olive/moss, H=78° — strongly yellow-green); `primaryOnDark: #889753`
- Green ramp: `#F3F3E7` (25) → `#E7E8D1` (50) → `#B0BA89` (100) → `#889753` (300) → `#4F6814` (400) → `#404823` (600)
- "Acid green" accent ramp: `#ECEBB4` → `#C1C056` → `#9E9D23`
- Page ground: `#FAF9F4` (warm paper); dark inks: `#1C1A18` and `#2B3117` (olive-black, H=74°, S=36%)
- CTA color is **orange** `#EE6B17` — green is the environment, orange does the shouting

### Gaia GPS — confirmed (live gaiagps.com design-system CSS, 2026)

Source: https://www-static.gaiagps.com/assets/29797903-9b5aec54/Footer-g1_yXY-J.css (and Homepage CSS)

- Two named green families:
  - **conifer** (muted forest): `#184023` → `#276338` (conifer3, used as `--clr-primary-main`) → `#69C083` → `#E0F5E7`
  - **spring** (saturated grass): `#1A4E18` → `#3CC537` (spring6 = `--clr-accent-primary`, H=118°) → `#BEF7BC`
- Neutrals are a separate "granite" gray family; **`--clr-txt-primary` = granite2 `#38383B`** — plain neutral gray ink, no green tint
- Seasonal accent families: fall (orange), summer (red), winter (cyan) — nature-named token system throughout

### iNaturalist — confirmed (official logo SVG on their static server)

- Brand green `#74AC00` (H=80°, S=100% — vivid yellow-green) extracted from https://static.inaturalist.org/sites/1-logo.svg
- Brandfetch (secondary, **inferred**) lists companions `#EBF2E1` (pale sage) and `#001E04` (near-black green): https://brandfetch.com/inaturalist.org
- Brand-refresh discussion: https://www.inaturalist.org/blog/28630-inaturalist-brand-refresh (page blocks fetch; not verified this session)

### Forest — confirmed (live forestapp.cc site CSS, 2026)

Source: https://www.forestapp.cc homepage (Seekrtech's official site)

- Deep greens: `#114836` (H=160° — teal-leaning), `#19634B`, and very dark grounds `#0B372B`, `#041B13` (H=159°, near-black green)
- Grounds/creams: `#FDF9EC`, `#F4EAD0` (warm paper)
- Accents: `#E7FF6A` (acid yellow-green), `#47EBB3` (mint)
- Note: Forest is a *focus timer* with a tree metaphor, not an outdoors app — its calmer teal-forest lean fits that; the actual map/trail apps all sit yellow of it.

### PictureThis — confirmed (live picturethisai.com CSS, 2026)

Source: https://www.picturethisai.com CSS (`home.css`, `header_v2.css`)

- Primary `#00A362` (H=156°, teal-leaning green), darker `#009557`/`#00834B`, mints `#3ECCA8`, tints `#F0F9F5`, `#DAF0E5`
- The one big plant app that went teal — reads more "clean tech/health" than "foliage."

---

## 2. Authoritative color references

- **Pantone Greenery 15-0343** = `#88B04B` (H=84°, yellow-green family). Pantone (2017 Color of the Year) describes it as evoking "the first days of spring when nature's greens revive, restore and renew" and "illustrative of flourishing foliage." Pantone's own page: https://www.pantone.com/color-finder/15-0343-TCX and https://www.pantone.com/articles/color-of-the-year/color-of-the-year-2017 (description quoted via search snippets; hex is the standard published TCX value — confirmed).
- **Material Design green** 500 = `#4CAF50` (H=122°). Dark-theme guidance (Material 2, confirmed via Google's own design library article https://design.google/library/material-design-dark-theme and the M2 spec): recommended dark surface is `#121212` dark gray, **not pure black** — "rendered in a dark gray rather than pure black" for contrast with bright content; use **desaturated, lighter tones (200–50 range)** of your color on dark surfaces; high-emphasis text on dark = white at 87% opacity. (Exact tone/opacity numbers are from the M2 spec, corroborated by secondary writeups — the m2.material.io page is JS-only and could not be scraped this session; treat the specific "200–50 / 87%" numbers as well-corroborated rather than freshly verified.)
- **Apple HIG / systemGreen**: light mode RGB(52, 199, 89) = `#34C759`, dark mode RGB(48, 209, 88) = `#30D158` — the dark variant is *brighter*, per Apple's pattern of boosting accents on dark grounds. Values are the community-measured renderings of Apple's semantic color (Apple publishes tokens, not guaranteed hexes — **inferred but stable**). https://developer.apple.com/design/human-interface-guidelines/color

---

## 3. Hue ranges: "trees/foliage" vs "mint/corporate"

Empirical result from the palettes above (computed HSL hues):

| App / reference | Accent hue | Reads as |
|---|---|---|
| Komoot `#4F6814` | 78° | foliage/olive |
| iNaturalist `#74AC00` | 80° | foliage |
| Pantone Greenery `#88B04B` | 84° | foliage (Pantone's own words) |
| AllTrails green-500 `#4DA330` | 105° | foliage/grass |
| Gaia spring `#3CC537` | 118° | grass |
| Material green `#4CAF50` | 122° | generic green |
| Apple systemGreen `#34C759` | 135° | UI green |
| Spotify `#1DB954` | 141° | tech |
| PictureThis `#00A362` | 156° | teal/clean-tech |
| Mint `#3EB489` | 158° | mint |
| Forest `#114836` | 160° | calm/teal-forest |

- Every dedicated *outdoors/trail/nature-ID* brand (AllTrails, Komoot, Gaia, iNaturalist) sits at **H ≈ 78–137°**, and the core "this is a plant" accents cluster at **78–120°** — yellow-green. Teal-side greens (150°+) belong to focus/health/tech products.
- Pantone's own language supports the split: Greenery (84°) is "flourishing foliage"; their 2026 teal pick is framed as a bridge to the *digital* world.
- Design-literature support (secondary, directional): yellow-undertone greens read warm/fresh/natural; blue-undertone greens (teal/mint) read calm, modern, corporate/tech — e.g. https://www.kimp.io/green-in-marketing/ , https://thecreativeaccent.com/brand-colors-psychology-and-the-meaning-behind-each-color/ . **Inferred/soft** — the strongest evidence is the empirical clustering above.

## 4. Dark mode: green-tinted grounds, not true black

- **AllTrails (confirmed, live tokens)**: dark `background-primary` = neutral-1000 `#0E110E` and `background-elevated` = `#1D211D` — both **green-tinted near-blacks** (H=120°, S=6–10%), never `#000000` or neutral `#121212`. The whole neutral ramp carries the green cast, so dark surfaces stay "in the forest."
- **Komoot (confirmed)**: dark ink/ground colors `#1C1A18` (warm black) and `#2B3117` (olive-black, S=36%) — again tinted, not neutral.
- **Forest (confirmed)**: page sections use `#041B13`, `#0B372B`, `#114836` — deep green grounds as the dark environment.
- **Material (authoritative)**: dark surface should be dark gray `#121212`, not pure black; brand tint on dark surfaces comes via desaturated/lighter tones of the brand color.
- **Apple (authoritative pattern)**: accents get *lighter/brighter* in dark mode (`#34C759` → `#30D158`).
- Takeaway: nature apps go one step past Material — they tint the dark ground itself with the brand hue at low saturation (~5–15%), and lighten/brighten the accent.

## 5. Text on green-tinted grounds

- **AllTrails (confirmed)**: `--color-text-primary` = brand **onyx `#161F13`** — a green-cast near-black (S≈25%) on light grounds; dark mode text-primary = neutral-100 `#F4F5F4` (faint green cast). Saturated greens are used for fills, icons, and links — not body text. The brand PDF is explicit: dark `#142800` text on light, white text on dark.
- **Gaia (confirmed)**: text-primary is **granite2 `#38383B`** — a *pure neutral gray*, even though the brand runs two green families. Text ink and brand color are kept in separate token families.
- **Komoot (confirmed)**: body ink `#1C1A18` / `#2B3117` on warm paper `#FAF9F4`; the saturated `#4F6814` is reserved for links/buttons (it's dark enough to pass AA on white, ~7:1).
- Pattern: **ink is near-neutral (0–25% saturation), grounds carry the tint, accents carry the saturation.** Nobody sets paragraphs in mid-saturation green.
- Contrast practice: brand inks are extremely dark (AllTrails `#142800`, onyx `#161F13` — 15:1+ on their creams), so the tint costs nothing in legibility; mid greens like `#4DA330`/`#3CC537` appear only at large sizes or as fills under white text.

---

## Recommended palette — Shanghai plane-tree-canopy walking app

Plane-tree (London plane / 法国梧桐) foliage is a warm yellow-green; the research says: accent at H≈95–115°, warm paper light ground, green-tinted near-black dark ground, neutral inks.

### Light mode

| Token | Hex | Why |
|---|---|---|
| ground | `#F7F6F1` | Warm paper, precedent: Komoot `#FAF9F4`, AllTrails birch `#F2EEE7` — feels like sun through leaves, not clinical white |
| surface (cards) | `#FFFFFF` | Lift off the warm ground |
| surface-tint / fills | `#EDF2E7` → `#DCE5D2` | Pale sage fills, precedent: AllTrails green-100 `#EEF7ED`, iNat `#EBF2E1` |
| accent (interactive) | `#3E7C2B` (H≈102°) | Canopy green; same family as AllTrails `#4DA330` / iNat `#74AC00` but dark enough for 4.7:1 on the ground (AA for UI/large text) |
| accent-deep (headers, map route) | `#2A4A1F` | Forest anchor, precedent: AllTrails `#2C5601` |
| accent-fresh (highlights, badges) | `#7FC95B` | New-leaf pop, use on dark or as fill only (fails AA on white) |
| text-primary | `#1A2116` | Green-cast near-black ink (AllTrails onyx pattern), 15.2:1 on ground |
| text-secondary | `#55604F` | Tinted gray, 6.1:1 on ground |

### Dark mode

| Token | Hex | Why |
|---|---|---|
| ground | `#101410` | Green-tinted near-black (~H120°, S≈11%), precedent: AllTrails `#0E110E`; not `#000`, per Material |
| surface (elevated) | `#1B211A` → `#242C22` | Stepped tinted surfaces, precedent: AllTrails elevated `#1D211D` |
| accent | `#9BD97E` | Lightened, slightly desaturated leaf green — Material's "tone 200" rule + Apple's brighten-in-dark pattern; 11.2:1 on ground, and dark ink on it also hits 11.2:1 for filled buttons |
| accent-deep (fills) | `#3E7C2B` at low alpha, or `#2E4423` | Quiet green fills for selected states |
| text-primary | `#F2F4F0` | Near-white with faint green cast (AllTrails dark text = `#F4F5F4`), 16.8:1 |
| text-secondary | `#A9B3A4` | Tinted gray, 7.6:1 on surface |

Rules of use, straight from the research: ink stays near-neutral, the ground carries the warmth/tint, `#3E7C2B` is the only green that touches text (links/labels, large sizes), and `#7FC95B`/`#9BD97E` never sit under white text. All pairs above verified ≥ 4.5:1 (WCAG AA) this session.
