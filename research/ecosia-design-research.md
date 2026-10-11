# How Ecosia uses green — research notes

Researched 2026-10-11 against Ecosia's own sources: the live ecosia.org stylesheets, the open-source iOS app (github.com/ecosia/ios-browser), the Ecosia blog theme, and the App Store listing. Each value is labeled **confirmed** (read from a file Ecosia owns) or **inferred** (measured or interpreted). HSL values are computed from the hexes. Contrast ratios are WCAG 2.x relative-luminance ratios, computed for this note.

Sources and the exact files:

- **Web tokens (confirmed)**: `https://www.ecosia.org/static/indexpage/assets/static/onRenderClient.Cgb5FAuy.css`, rules `:root, .light { … }` and `.dark { … }`. Component styles in `index.CnrwLXN_.css` and `pages.LDM2WODu.css` in the same folder. The homepage sits behind a Cloudflare check, so the stylesheet URLs were read from the rendered page in a browser; the CSS files themselves download directly.
- **iOS app (confirmed)**: github.com/ecosia/ios-browser at commit `274e325f` (main, 2026-10-09).
  - Primitives: `firefox-ios/Ecosia/UI/DesignSystem/EcosiaColor.swift` (identical values in `firefox-ios/Client/Ecosia/UI/Theme/EcosiaColor.swift`). The file header says these are Ecosia's "official primitive color tokens" from their Figma "Foundations" file.
  - Semantic tokens: `BrowserKit/Sources/Common/Theming/EcosiaThemeColourPalette.swift` (names), `firefox-ios/Client/Ecosia/UI/Theme/EcosiaLightTheme.swift` and `EcosiaDarkTheme.swift` (values).
  - Radii, spacing, type sizes: `firefox-ios/Ecosia/UI/DesignSystem/CGFloat+DesignSystem.swift`, `EcosiaTypography.swift`, `UIFont+DesignSystem.swift`.
  - Brand-change history: PR #944 "[MOB-3567] AI Brand Update", merged 2025-10-28 (commit `904364c17` on branch `main-133`).
- **Blog (confirmed)**: blog.ecosia.org (Ghost 6.70), theme CSS inlined in the page HTML.
- **App Store (confirmed images, inferred colours)**: Ecosia iOS app id 670881887, version 12.6.0 (released 2026-09-27), six screenshots; pixel samples taken from them.
- **Not reached**: Ecosia's press/brand kit (`ecosia.org/press`, `info.ecosia.org`) returned HTTP 403 to scripted requests, so nothing here comes from a brand PDF. The Android repo (github.com/ecosia/chromium-android-browser) is stale (latest branch commit 2024-04, before the rebrand) and its colour resources are not in the `res_ecosia` folder, so Android colours are **not verified**.

---

## 1. The headline: Ecosia moved its UI off green in October 2025

Until PR #944 (2025-10-28), the iOS app's brand colour was a saturated pure green. The "AI Brand Update" replaced it with neutral ink and introduced one pale yellow-green, which Ecosia's code calls **Grellow** ("green-yellow").

| Token (iOS) | Before 2025-10-28 | After (current) |
|---|---|---|
| `brandPrimary` light | Green50 `#008009` | Gray70 `#333333` |
| `brandPrimary` dark | Green30 `#5DD25E` | White `#FFFFFF` |
| `buttonBackgroundPrimary` light | Green50 `#008009` | Gray70 `#333333` |
| `buttonBackgroundPrimary` dark | Green30 `#5DD25E` | White `#FFFFFF` |
| `iconSecondary` light / dark | `#008009` / `#5DD25E` | removed; icons use Gray70 / White |
| Splash logo tint | `#008009` / `#5DD25E` | logo PDFs are `#333333` / `#FFFFFF` |
| Widget `PrimaryBrand` | `#008009` / `#5DD25E` | `#333333` / `#252525` |
| New | — | `brandFeatured`, `buttonBackgroundFeatured` = Grellow100 `#D7EB80` |

Source: diff of commit `904364c17`, files `EcosiaLightTheme.swift`, `EcosiaDarkTheme.swift`, `splashLogoTint.colorset` (deleted), `WidgetKitAssets.xcassets/Colors/PrimaryBrand.colorset`. **Confirmed.**

The website follows the same system today: `--color-brand-primary: #333333` (light) and `#ffffff` (dark).

## 2. Brand greens and their HSL

### Grellow — the current brand green (confirmed, `EcosiaColor.swift`)

| Token | Hex | HSL |
|---|---|---|
| Grellow100 | `#D7EB80` | H71 S73 L71 |
| Grellow200 | `#BBCF65` | H71 S52 L60 |
| Grellow300 | `#A1B353` | H71 S39 L51 |
| Grellow400 | `#889745` | |
| Grellow500 | `#6F7D38` | |
| Grellow600 | `#58632B` | |
| Grellow700 | `#424A1E` | H71 S42 L20 |
| Grellow800 | `#2D3315` | H72 S42 L14 |
| Grellow900 | `#1B1D0F` | |

- The whole ramp holds hue 71°, which is closer to yellow than to leaf green. Saturation falls as the colour darkens.
- **The app icon is two Grellow steps only**: a `#D7EB80` tree containing an "E" on a `#2D3315` ground. Pixel-sampled from `firefox-ios/Client/Assets/Images.xcassets/AppIcon.appiconset/1024.png`. The same pair is in the vector `Common.xcassets/iconLogo.imageset/Type=E + Tree Circle…pdf`. **Confirmed.**
- The blog uses one extra hover step, `#C9E454` (H71 S73 L61), on `.c-financial-report__select:hover`.

### Legacy and semantic greens (confirmed, still defined)

| Token | Hex | HSL | Current role |
|---|---|---|---|
| Green50 / web `--color-success` (light) | `#008009` | H124 S100 L25 | success state, green text buttons (`--color-button-content-tertiary`), leaf-icon top |
| Web leaf-icon bottom (light) | `#005304` | H123 S100 L16 | leaf icon, positive toast background |
| Green30 | `#5DD25E` | H121 S57 L59 | old dark-mode brand, now unused in theme files |
| Web `--color-success` (dark) | `#75DD65` | H112 S64 L63 | success, green text buttons, leaf-icon bottom |
| Web leaf-icon top (dark) | `#A8F598` | H110 S82 L78 | leaf icon |
| DarkGreen50 / web `--color-brand-secondary` (light) | `#275243` | H159 S36 L24 | "brand secondary" surfaces |
| Web `--color-brand-secondary` (dark) | `#519F84` | H159 S32 L47 | same role, lightened |

- In the three homepage stylesheets, `--color-success`, `--color-button-content-tertiary` and the leaf-icon tokens are defined but never referenced. They may be used on other pages or in inline SVG; that was not checked.
- `--color-background-brand-secondary` (`#275243` / `#519F84`) is used by exactly four components: a tooltip variant, the "switch" modal dialog, and the `section-wrapper--variant-tertiary` band. Note that in dark mode `--color-background-brand-secondary-alt` (which the section band uses) becomes neutral `#252525`, so that band loses its green in dark mode.
- In iOS, DarkGreen50 `#275243` appears in one place: the top banner of the "make Ecosia your default browser" screen (`EcosiaSettings.swift:49`).

## 3. Light mode

### Grounds, surfaces, borders (confirmed, web `:root, .light`; iOS `EcosiaLightSemanticColors`)

| Role | Web token | Hex | iOS token → hex |
|---|---|---|---|
| Page background | `--color-background-primary` | `#FFFFFF` | `backgroundPrimary` → White `#FFFFFF` |
| Decorative / secondary ground | `--color-background-primary-decorative`, `--color-background-secondary` | `#F8F8F6` (H60 S12 L97) | `backgroundPrimaryDecorative`, `backgroundSecondary` → Gray10 `#F8F8F6`; also the launch screen |
| Quaternary fill | `--color-background-quaternary` | `#F0F0EB` (H60 S14 L93) | `backgroundTertiary`, `backgroundQuaternary` → Gray20 `#F0F0EB` |
| Elevated surfaces | `--color-background-elevation-1/-2` | `#FFFFFF` | `backgroundElevation1/2` → White |
| Elevation shadows | `--color-elevation-layer-1/-2` | `rgba(26,26,26,.18)`, `rgba(26,26,26,.06)` | — |
| Border | `--color-decorative-border-1` | `#DEDED9` | `borderDecorative` → Gray30 `#DEDED9` |
| Form border | `--color-form-border-default` | `#BEBEB9` | — |

The light neutrals are not pure gray. Gray10–Gray40 (`#F8F8F6`, `#F0F0EB`, `#DEDED9`, `#BEBEB9`) carry a faint warm yellow cast (H60, S4–14%). The darker grays (`#6C6C6C` and below) are pure neutral. The page itself is plain white.

### Text and links (confirmed)

| Role | Hex | Contrast |
|---|---|---|
| Primary text (`--color-text-primary`, iOS `textPrimary` Gray70) | `#333333` | 12.63 on white, 11.88 on `#F8F8F6` |
| Secondary text (`--color-text-secondary`, iOS Gray50) | `#6C6C6C` | 5.25 on white, 4.94 on `#F8F8F6` |
| Links (`--color-link-primary`, iOS `linkPrimary`) | `#333333` | links are ink, not green |
| Search-result links | `#1A0DAB`, visited `#681DA8` | conventional search-engine blue and purple |
| Focus ring (`--color-focused`) | `#0094C7` (H195) | blue, in both modes |

### Buttons and controls (confirmed)

- **Primary button**: `#333333` fill, `#FFFFFF` label; hover `#4C4C4C`, pressed `#6C6C6C`.
- **Secondary button**: white fill, `#333333` label and border.
- **Featured button** (`--color-button-background-featured`, CSS class `base-button--variant-solid-grellow`): `#D7EB80` fill with a `#333333` label; hover `#BBCF65`, pressed `#A1B353`. Ink on Grellow is 9.68:1. White on Grellow would be 1.31:1, and Ecosia never pairs them.
- iOS switches, segmented controls and the selected-checkmark colour are all `#333333` in light mode.

### Where green appears in light mode

Confirmed from CSS selectors and Swift call sites:

1. **Homepage hero**: `.above-fold-section` has `background-color: #d7eb80` and `border-radius: 20px`, filling the first viewport. An image (`.above-fold-section__background`, `object-fit: cover`) is drawn over it, and the headline is white Founders Grotesk on top of the image. So Grellow is the card colour behind the hero photo.
2. **Search submit button**: transparent with a gray border at rest. It turns `#D7EB80` with a dark glyph only on hover or when the search field has focus (`.search-form:focus-within .search-form__submit`). The iOS new-tab search bar does the same (`NTPSearchBarView.swift:682–702`).
3. **Featured CTAs on iOS**, all `buttonBackgroundFeatured` = `#D7EB80`: sign-in on the account screen, the welcome/onboarding CTA, the upload sign-in, and "invite friends" (`MultiplyImpact.swift:379`).
4. **Featured badges, popovers, and the featured section band** (`--color-background-featured`).
5. **Text highlight**: `--color-highlighter` = Grellow at 32% alpha.
6. **Blog**: the current nav item pill, the app-install banner, the newsletter hero band, tree-report pills, "native trees" labels, and dark `#333` buttons with Grellow text (`.c-braze-signup__form button`).
7. **Brand mark**: the app icon (Grellow100 on Grellow800).
8. **Success state and the leaf icon** (`#008009`), as defined tokens.

Where green deliberately does **not** appear (confirmed):

- body text, headings, links, URLs
- primary buttons, switches, segmented controls, checkmarks, focus rings
- page grounds, cards, borders
- the in-app wordmark (`#333333`, or white in dark mode)
- icons: `iconDecorative` is `#6C6C6C`

### How much of the screen is green (inferred)

A pixel-area measurement of the live homepage DOM was not completed, so these are estimates.

- **Website**: the hero is one large Grellow-backed card, but a photo covers it. Below the hero the page is white and `#F8F8F6`, with Grellow only on small featured elements.
- **App**: in the App Store screenshots the app UI itself is white or `#F8F8F6` with `#333333` text. Green shows up only in the yellow seed/progress accents and the financial-report donut chart.
- The surrounding marketing frames are the opposite: Grellow grounds (sampled `#D8EB80`, the JPEG rendering of `#D7EB80`) or full-bleed forest and leaf photography, with headlines in Founders Grotesk. Green carries the store listing and the brand moments, and the product UI stays neutral.
- The iOS new-tab page uses a nature-photo wallpaper behind "glass" tiles: `buttonBgGlassStatic` = `#1A1A1A` at 32% alpha, with a white border at 24% alpha. The nature feeling comes from photography, not from tinting the UI.

## 4. Dark mode

### Grounds and surfaces (confirmed, web `.dark`; iOS `EcosiaDarkSemanticColors`)

| Role | Hex | Notes |
|---|---|---|
| Background | `#1A1A1A` (Gray90) | pure neutral; also the dark launch screen |
| Secondary / elevation-1 | `#252525` (Gray80) | |
| Elevation-2 / quaternary | `#333333` (Gray70) | |
| Border | `#4C4C4C` (Gray60) | |
| Form border | `#6C6C6C` | |

- **Dark grounds are pure neutral gray (S=0), with no green tint.** Before the rebrand the dark launch background was `#333333`; it is now `#1A1A1A`.
- Elevation is shown by stepping lighter (`#1A1A1A` → `#252525` → `#333333`), with no shadows.

### Text (confirmed)

| Role | Hex | Contrast |
|---|---|---|
| Primary | `#FFFFFF` | 17.40 on `#1A1A1A` |
| Secondary | `#DEDED9` (web and iOS Gray30) | 12.89 on `#1A1A1A`, 11.35 on `#252525` |
| Links | `#FFFFFF`; search results `#99C3FF`, visited `#CA94F9` | |
| Decorative icon | `#BEBEB9` | |

### How the greens shift in dark mode (confirmed)

- **Grellow stays the same for buttons.** `buttonBackgroundFeatured` is `#D7EB80` in both modes, and the label stays dark. iOS has a separate "static" token for this, with an explicit comment in `NTPSearchBarView.swift`: "The featured background is grellow in both themes, so the icon must stay dark in both."
- **Large Grellow surfaces go dark and desaturated.** `--color-background-featured` and the iOS `backgroundFeatured` change from `#D7EB80` to Grellow700 `#424A1E` (H71 S42 L20). White text on it is 9.42:1. The positive alert background in dark mode is also `#424A1E`, with a `#58632B` border. The October 2025 commit first set the iOS dark featured background to `#D7EB80`; it is `#424A1E` at the current commit.
- **Saturated legacy greens get lighter.** Success and leaf colours go from `#008009` (L25) to `#75DD65` / `#A8F598` (L63–78). Brand-secondary goes from `#275243` (L24) to `#519F84` (L47), keeping its hue and slightly dropping saturation. This matches Apple's and Material's practice of lightening accent colours on dark grounds.
- **Primary actions invert.** The dark primary button is white with `#333333` text on the web. (On iOS, `buttonContentPrimary` is White in both modes, which would put white on white if a screen used it on the primary fill. This looks like an unused or inconsistent token; it was not traced further.)

## 5. Supporting colours (confirmed)

| Colour | Hex | Role |
|---|---|---|
| Yellow40 | `#F7BC00` | iOS `brandImpact`: account progress bar and level badge (the "seeds" impact system) |
| Web accent yellow | `#F8C856` | `badge--variant-accent-yellow`, circular progress stroke, warning alert border |
| Blue | `#0094C7` | focus ring, both modes |
| Search-result blue/purple | `#1A0DAB` / `#681DA8` (light), `#99C3FF` / `#CA94F9` (dark) | result links only |
| Peach | `#FCDBCC` with `#77300A` text | iOS balance-increment chip; light negative alert |
| Red / claret | `#B90A32`, `#8E0624` (light); `#FD8786`, `#FCB3AF` (dark); claret `#4C232D` | errors and negative states |
| Alert grounds (light) | positive `#E9F8A2`, warning `#F8DEB0`, info `#C9E7FB`, negative `#FCDBCC` | pale fills under `#000000` text |
| Alert grounds (dark) | positive `#424A1E`, warning `#574310`, info `#03354A`, negative `#4C232D` | dark fills under `#FFFFFF` text |

The warm accent, yellow, is reserved for impact and progress (seeds, levels). Green is used for brand moments and the main call to action. Blue marks focus and search results.

## 6. Typography and shape (confirmed)

- **Fonts**: body and UI text use Inter on the web (variable font, weights 400–700, `font-family: Inter, helvetica, arial, sans-serif`). The iOS app uses the system font for UI (`UIFont.ecosia(size:weight:)` → `systemFont`). Display headings use **Founders Grotesk**: Condensed Semibold on iOS (`FoundersGroteskCond-SmBd`, added in the October 2025 brand update), and Founders Grotesk at weight 400 for the web hero title. The blog loads both fonts from `cdn-static.ecosia.org`.
- **iOS type scale** (`EcosiaTypography`): 10, 12, 14, 16, 18, 20, 24, 36, 48, 54, 72 pt.
- **Corner radii**: iOS `EcosiaBorders` are 4 / 6 / 10 / 20 pt. On the web the most common values are `10px` (25 rules), `20px` (13 rules; hero and mobile search), and `9999px` pills (10 rules). Blog cards use `10px`, and blog pills and buttons use 20–25px.
- **Spacing** (iOS `EcosiaSpacing`): 4, 8, 12, 16, 20, 24, 32, 40, 48, 56, 64, 80, 100.

---

## Implications for Walkable Shanghai

What the Ecosia evidence supports:

1. **Neutral grounds in both modes.** Ecosia keeps its grounds white or faintly warm in light mode and pure neutral gray in dark mode. The current Walkable Shanghai grounds (`#F1F3E3` light, `#101410` dark) are green-tinted everywhere, which is the "poisonous" effect. Ecosia gave up exactly this kind of all-over green in October 2025.
2. **Ink for interaction, green for one featured action.** Ecosia's links, primary buttons and controls are ink. Its green does three jobs: the one featured CTA, highlights or badges, and the brand mark.
3. **Use the pale green as a fill and keep the label dark.** A pale yellow-green with a dark label works in both modes, and a dark olive version takes over for large dark-mode areas.
4. **Let photography and the map carry the nature feeling.** In the app UI, Ecosia's nature imagery is the wallpaper and the store art, not tinted chrome. For a walking app, the map and street imagery can do the same job.

### Proposed palette

The light grounds use Ecosia's warm neutrals. The accent hue (H≈97°) sits closer to plane-tree leaves than Ecosia's H71 Grellow, so the app keeps its own identity. Contrast ratios were computed for this note.

#### Light

| Role | Hex | HSL | Notes |
|---|---|---|---|
| background | `#F8F8F6` | H60 S12 L97 | Ecosia Gray10 |
| surface (cards, sheets) | `#FFFFFF` | — | |
| raised surface | `#FFFFFF` + shadow | — | Same as Ecosia: in light mode, elevation is a shadow (`rgba(26,26,26,.18)` key, `.06` ambient), not a different fill |
| fill (grouped rows, chips at rest) | `#F0F0EB` | H60 S14 L93 | Ecosia Gray20 |
| separator | `#DEDED9` | H60 S7 L86 | Ecosia Gray30; decorative, so no text-contrast requirement |
| primary text | `#2B2B29` | H60 S2 L16 | near-neutral ink |
| secondary text | `#63635D` | H60 S3 L38 | |
| accent (links, selected tab icon, active toggle, route line) | `#3F6B23` | H97 S51 L28 | the only saturated green |
| filled button (primary) | `#2B2B29` fill, `#FFFFFF` label | | follows Ecosia's ink primary |
| featured fill ("Start walk", one per screen; highlights) | `#D6E89A` fill, `#2B2B29` label | H74 S63 L76 | the "Grellow" role, shifted slightly toward leaf |

Light contrast:

| Pair | Ratio | WCAG |
|---|---|---|
| `#2B2B29` on `#F8F8F6` | 13.34 | AAA |
| `#2B2B29` on `#FFFFFF` | 14.19 | AAA |
| `#2B2B29` on `#F0F0EB` | 12.41 | AAA |
| `#63635D` on `#F8F8F6` | 5.69 | AA |
| `#63635D` on `#FFFFFF` | 6.05 | AA |
| `#63635D` on `#F0F0EB` | 5.29 | AA |
| `#3F6B23` on `#F8F8F6` | 5.92 | AA |
| `#3F6B23` on `#FFFFFF` | 6.29 | AA |
| `#3F6B23` on `#F0F0EB` | 5.50 | AA |
| `#FFFFFF` on `#2B2B29` (primary button) | 14.19 | AAA |
| `#2B2B29` on `#D6E89A` (featured button) | 10.72 | AAA |
| `#FFFFFF` on `#3F6B23` (if a green fill is ever needed) | 6.29 | AA |

#### Dark

| Role | Hex | HSL | Notes |
|---|---|---|---|
| background | `#1A1A1A` | H0 S0 L10 | Ecosia Gray90; neutral, no green tint |
| surface | `#242424` | H0 S0 L14 | near Ecosia `#252525` |
| raised surface | `#2F2F2E` | H60 S1 L18 | step lighter instead of a shadow, like Ecosia |
| separator | `#42423F` | H60 S2 L25 | between Ecosia's `#333333` and `#4C4C4C`; decorative |
| primary text | `#F4F4F1` | H60 S12 L95 | near-white |
| secondary text | `#B5B5AE` | H60 S5 L70 | |
| accent (links, selected, route line) | `#A9D27E` | H89 S48 L66 | lighter and less saturated than the light accent, following Ecosia's `#008009` → `#75DD65` shift |
| filled button (primary) | `#F4F4F1` fill, `#1A1A1A` label | | inverts, like Ecosia |
| featured fill (button) | `#D6E89A` fill, `#1A1A1A` label | | same in both modes, like Ecosia's Grellow button |
| featured surface (large banner or highlight band) | `#3A4220` with `#F4F4F1` text | H74 S35 L19 | the role of Ecosia's Grellow700 `#424A1E`: a large pale-green area would glare in dark mode |

Dark contrast:

| Pair | Ratio | WCAG |
|---|---|---|
| `#F4F4F1` on `#1A1A1A` | 15.79 | AAA |
| `#F4F4F1` on `#242424` | 14.09 | AAA |
| `#F4F4F1` on `#2F2F2E` | 12.16 | AAA |
| `#B5B5AE` on `#1A1A1A` | 8.44 | AAA |
| `#B5B5AE` on `#242424` | 7.53 | AAA |
| `#B5B5AE` on `#2F2F2E` | 6.50 | AA |
| `#A9D27E` on `#1A1A1A` | 10.12 | AAA |
| `#A9D27E` on `#242424` | 9.02 | AAA |
| `#A9D27E` on `#2F2F2E` | 7.79 | AAA |
| `#1A1A1A` on `#F4F4F1` (primary button) | 15.79 | AAA |
| `#1A1A1A` on `#D6E89A` (featured button) | 13.15 | AAA |
| `#F4F4F1` on `#3A4220` (featured surface) | 9.62 | AAA |

### Where green goes, and where it does not

Use green for:

- the one featured action per screen (`#D6E89A` fill, dark label)
- the walked and planned route line on the map, and the current-location or progress accent (`#3F6B23` / `#A9D27E`)
- selected state: the active tab icon, the selected chip outline or check, and the active toggle track if a tint is wanted
- small brand moments: the app icon, the onboarding illustration, and an empty-state leaf
- success confirmation

Do not use green for:

- grounds, cards, sheets, separators or grouped-list fills (all neutral, as in Ecosia since October 2025)
- body text, headings and secondary text (near-neutral ink and white only)
- the primary button (ink in light mode, near-white in dark mode)
- shadows and scrims (neutral `#1A1A1A`-based alpha, not green-black)
- several green fills on one screen: Ecosia shows at most one Grellow element in a given region

Warm accent: if the app needs an "achievement" colour (distance milestones, streaks), Ecosia's split suggests a separate warm yellow such as `#F7BC00` or `#F8C856` for progress and rewards, so green does not have to mean everything.
