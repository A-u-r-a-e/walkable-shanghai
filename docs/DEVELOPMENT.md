# Developing JWalk

Setting up a machine, the conventions the code follows, step-by-step recipes
for common changes, and the traps that have cost time before. Paths are
relative to `JWalk/` unless they start with `docs/`. Build, test and screenshot
commands are in full in `JWalk/README.md`.

## Setting up a machine

You need:

- macOS with **Xcode 26**. The project was last built with Xcode 26.6. It uses
  the iOS 26 SDK (Liquid Glass), so Xcode 16 or older cannot build it.
- The **iOS 26** and **iOS 18** simulator runtimes, from Xcode → Settings →
  Components. The deployment target is iOS 18.0, and the test suite is kept
  green on both an iOS 26 and an iOS 18 simulator.
- **Python 3**, for the three scripts in `Scripts/`.

Nothing else: there are no package dependencies, no CocoaPods and no
Swift packages.

If `xcode-select -p` prints the Command Line Tools path instead of Xcode's,
either point it at Xcode once (`sudo xcode-select -s
/Applications/Xcode.app/Contents/Developer`) or prefix every `xcodebuild` and
`xcrun` command with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.

Check the simulators you have and their ids:

```sh
xcrun simctl list devices available
```

A destination by name (`name=iPhone 17 Pro`) usually works. If `xcodebuild`
exits with code 70 ("Unable to find a device matching"), address the simulator
by its id instead: `-destination 'platform=iOS Simulator,id=<id>'`.

### The map needs a network path to Apple's China servers

Because the camera starts on Shanghai, MapKit fetches the basemap from Apple's
China endpoints, which AutoNavi runs. From some networks they time out, and the
map then draws the routes over an empty grid. That does not break anything:
the tests check routes and pins, not scenery. If you want to see the basemap
and it is blank, try another network or a VPN. Traffic colouring has never
appeared in the simulator.

### Running on a device

Code signing is switched off in `Scripts/generate_project.py`
(`CODE_SIGNING_ALLOWED = NO`, `CODE_SIGNING_REQUIRED = NO`,
`CODE_SIGN_IDENTITY = "-"` in `PROJECT_COMMON`), so the simulator needs no
Apple account. To run on an iPhone:

1. In `PROJECT_COMMON`, replace those three settings with
   `("CODE_SIGN_STYLE", "Automatic")` and `("DEVELOPMENT_TEAM", "<your team id>")`.
2. Run `python3 Scripts/generate_project.py`.
3. Select your phone in Xcode and run. A free Apple account can run the app on
   your own phone; TestFlight and CloudKit need the paid Apple Developer
   Program.

The bundle id is `com.jwalk.app`. If it is already registered to someone else's
team, change `BUNDLE_ID` in the script. Task 2 of the server plan describes
turning signing on for good, with an entitlements file.

## Everyday commands

From `JWalk/`:

```sh
# Build
xcodebuild -project JWalk.xcodeproj -scheme JWalk \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Unit tests only (seconds)
xcodebuild -project JWalk.xcodeproj -scheme JWalk \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:JWalkTests

# One UI test class
xcodebuild -project JWalk.xcodeproj -scheme JWalk \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:JWalkUITests/ShareUITests

# Everything (about 15 minutes per simulator)
xcodebuild -project JWalk.xcodeproj -scheme JWalk \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

Run one `xcodebuild` at a time. Two at once share the simulator and the build
folder and fail in confusing ways. To run both runtimes, run them one after the
other, or give each its own `-derivedDataPath`.

Before a commit that changes behaviour, run the unit tests and the affected UI
test classes on both an iOS 26 and an iOS 18 simulator. Before a release, run
the full suite on both.

## Conventions

These are the conventions the existing code follows. Keeping to them keeps the
codebase consistent; changing one is a decision to make across the whole app,
not in one file.

### Code

- **Match the file you are in**: its comment density, naming and idiom. Doc
  comments explain *why* a thing is the way it is, in plain sentences; most
  types and non-obvious decisions have one.
- One space around `=`. No aligned columns. No formatter has been run on the
  code; do not run one, because it would rewrite every file.
- No view models. State lives in the `@Observable` stores in the environment and
  in each view's `@State`. Logic worth testing goes in a pure function on its
  own type (see `RouteList`, `RouteGeometry`, `WalkRange`, `SharedRoute`).
- Stores never throw to views. They log with `print("[JWalk] …")` and carry on.
- Swift 6 strict concurrency stays clean: no new warnings.

### Colours, type and layout

- **Every colour comes from `Theme`**, which builds adaptive colours from the
  numbers in `Palette`. No colour literals elsewhere. A new colour is a new role
  in both files. `PaletteContrastTests` checks every text pairing against WCAG
  AA from those numbers.
- **Green is reserved** for primary buttons, the route line and pins, selected
  states, the filled bookmark and the Featured tag. Text stays near-neutral.
  `JWalk/DESIGN.md` is the reference.
- **Type is the system font** through the styles in `Typography.swift`, never
  `.font(.system(size:))`, so Dynamic Type works. No fonts are bundled.
- **Pictures that fill a slot** go through `.fillingBox(height:)` so the
  picture never sets the layout's width (`JWalk/README.md` explains why).

### Text

- **Interface strings** live in `Resources/Localizable.xcstrings` with both
  `en` and `zh-Hans`, and are read with `"key".localized(language)`.
  Countable strings use `L10n.string(key, language, count:)`. Never call
  SwiftUI's own localisation (`Text("key")` with a literal), because it follows
  the phone's language, not the app's.
- **Edit the catalogue only with `Scripts/strings.py`.** It writes both
  languages at once and keeps keys sorted, so diffs stay readable.
- **Content** (route names and descriptions) is data in `LocalizedText`, never
  in the String Catalog.
- **New visible copy is approved by the project owner** before it ships:
  headings, buttons, labels, helper text, empty states. Do not add subtitles or
  explanatory lines nobody asked for.

### Accessibility and testability

- Every interactive control has an `accessibilityIdentifier` in kebab-case:
  `route-card-title`, `me-profile-row`, `route-row-<id>`. UI tests find
  controls by these, never by their visible text, except where a test checks
  the text itself.
- Icon-only controls also have an `accessibilityLabel`.
- Numbers that tests read (walk counts, the clock) are exposed as accessibility
  *values*.

### Tests

- Logic gets unit tests that never touch the network, the real location or the
  on-disk store (`UserStateContainer.make(inMemory: true)`).
- UI tests launch through `launchJWalk(...)` in `UITests/Support/AppLaunch.swift`
  unless they need something it does not set. New UI test classes are
  `@MainActor`.
- UI tests assert identity and geometry (identifiers, labels, values), never
  map scenery, which depends on the network.
- A test that claims something persists relaunches the app without
  `-uitest.resetUserState` and reads it back.
- Screenshots are produced by `ScreenshotUITests` and exported from the result
  bundle; `JWalk/README.md` has the commands.

### Commits

- One commit per coherent change, made from the repository root.
- The subject is a plain imperative sentence with no type prefix, such as
  "Fix onboarding promises, Shanghai dates, disabled buttons and map labels".
  The body says what changed and why, and which tests pass.

## Recipes

### Add a screen or a Swift file

Create the file under `Sources/`, `Tests/` or `UITests/`. The project uses
folder-synchronised groups, so Xcode picks it up with no project change. Only
re-run `python3 Scripts/generate_project.py` to change targets, build settings
or Info.plist build keys. Never hand-edit `project.pbxproj`; the script
regenerates it.

### Add or change an interface string

```sh
cd JWalk
python3 Scripts/strings.py set my.key "English text" "中文文本" "Optional note for translators"
python3 Scripts/strings.py plural my.count "%lld walk" "%lld walks" "%lld 次步行"
python3 Scripts/strings.py remove my.key        # or a prefix ending in "." to remove a group
```

Read it with `"my.key".localized(language)`, `"my.key".localized(language, arg1, arg2)`
for `%@` arguments, or `L10n.string("my.count", language, count: n)` for plurals.
No test checks every key: `testBothLanguagesResolveInterfaceStrings` only proves
both language bundles load. Check a new key in both languages yourself, or add
a test that walks the whole catalogue.

### Add a colour

Add a `Pair(light:dark:)` to `Palette`, a role to `Theme` built with
`adaptive(_:)`, and, if text is drawn on it or in it, a pairing to
`PaletteContrastTests`.

### Change a stored model (SwiftData)

The schema is listed in `UserStateContainer.schema`
(`Sources/Data/RouteUserState.swift`). There is no versioned schema yet.

- **Adding an optional property, or one with a default value, is safe.**
  SwiftData migrates the existing store automatically.
- **Anything else** (renaming, changing a type, making a property required,
  removing a model) needs a `VersionedSchema` for the current shape, one for
  the new shape, and a `SchemaMigrationPlan`, passed to the `ModelContainer`.
- **Test the migration on a real old store.** If the store cannot be opened,
  `makeOrFallBack` silently falls back to an in-memory store: the app looks fine
  but loses everything at quit. Install the previous build in a simulator, save
  a route and finish a walk, then install the new build over it and check that
  both are still there.

### Add or edit a bundled route

Routes live in `Resources/SampleData.json`. Each needs `id`, `km`, `minutes`,
`name` and `note` (each `{ "en": …, "zh": … }`), `authorName`,
`authorInitial` (one character), `points` (at least two `{ "lat", "lng" }`),
`pin`, `tags` (from `RouteTag`) and `updatedAt` (`yyyy-MM-dd`, read as Shanghai
time). Add a matching entry to `activity` (`today`, `week`, `month`,
`allTime`) if it should appear in Popular.

Several tests pin the catalogue's current contents:
`SampleDataTests.testCatalogueDecodesWithExpectedCounts` expects five routes,
`testTagsComeFromTheFixedListAndFeaturedIsATag` expects `wukang` to be the only
featured route, `RouteListUITests` checks list orders by id, the UI tests open
`wukang`, `creek`, `fuxing` and `bund` by id, and `wukang`, `creek` and
`century` are the routes saved on a fresh install
(`SavedRoutesStore.seededSaved`). Update them together with the data. Coordinates
are WGS-84, the system MapKit uses.

### Add a route tag

Add a case to `RouteTag`, a `tag.<case>` string in both languages, and decide
in `RouteCard` and `TagChip` whether it is neutral (every tag except Featured is).

### Add a launch argument for tests

Read it from `ProcessInfo.processInfo.arguments` where the behaviour is decided
(most are read in `JWalkApp.init`), add it to `launchJWalk` if most tests need
it, and add it to the table in `JWalk/README.md`. A `-settings.<key> <value>`
argument needs no code: `UserDefaults` reads launch arguments for any key, so it
overrides `AppSettings` for that launch.

### Change the share format

`SharedRoute` (`Sources/Data/RouteShare.swift`) is version 1, and links already
sent stay in people's messages. Adding a field that older apps can ignore needs
no version change: decoders ignore unknown keys. A change older apps would
misread needs `currentVersion` raised; older apps refuse a newer version with
the "does not hold a JWalk route" alert, and newer apps should keep reading
version 1. `RouteShareTests` covers the format.

### Change build settings, the bundle id or Info.plist

Edit `Scripts/generate_project.py` (build settings, bundle id, display name, the
English permission strings) or `Config/Info.plist` (background modes, URL
scheme, document types), then regenerate. The Chinese permission strings are in
`Resources/InfoPlist.xcstrings`.

### Recapture screenshots

`JWalk/README.md` → "Screenshots" has the loop. It produces
`Screenshots/neutral/light`, `dark` and `ios18-light`. Add a capture to
`ScreenshotUITests` for any new screen.

## Traps

Each of these has cost real time before.

- **The route list is lazy.** A row below the visible part of the sheet may not
  exist yet. Reach rows with `revealRow`, which raises the sheet and scrolls
  until the row is tappable, and assert `isHittable`, not `exists`.
- **`XCUIApplication.open(url)` relaunches the app** with the URL. It tests a
  cold launch from a link. To deliver a link to the running app, as tapping it
  in Messages does, use `XCUIDevice.shared.system.open(url)` and accept iOS's
  "Open" prompt if it appears (`ShareUITests.openThroughSystem`).
- **`-settings.*` launch arguments override reads only.** Writes during that
  launch go to the real defaults, and the argument still wins on the next
  launch that passes it. A test that changes a setting and relaunches to check
  it must leave the argument off on the second launch.
- **iOS 18 and iOS 26 differ.** The iOS 26 tab bar floats over content; the iOS
  18 bar is opaque and can cover the bottom of the sheet. "Map" is both a map
  style and a tab. iOS 18 can truncate a `Menu` label. `JWalk/README.md` →
  "Running on both iOS versions" has the details.
- **Time zones in tests.** Route dates are formatted in Shanghai time.
  `RouteFormattingTests` sets `NSTimeZone.default`, `TZ` and calls `tzset()`,
  because `NSTimeZone.default` alone does not move `Date.FormatStyle`.
- **Plural strings need the app's locale.** Plain interpolation leaves the
  plural token in the string, and the phone's locale applies the wrong rules.
  Use `L10n.string(_:_:count:)`.
- **The map re-frames on a language or appearance change**, because both are
  part of the redraw signature (they change how routes are drawn).
- **The camera can frame a search match behind the keyboard**, because the map's
  bottom inset ignores the keyboard. It corrects itself once the keyboard
  closes.
