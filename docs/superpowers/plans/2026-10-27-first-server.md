# JWalk's First Server: Public Routes on CloudKit

Status: approved 2026-10-27. No code has been written for it. The contact address in §5 is still to be chosen.

**Goal:** a route a walker publishes appears on the map for every JWalk user, so walkers see strangers' routes, not only the ones sent to them. Person-to-person sharing through `jwalk://` links and `.jwalk` files (`JWalk/Sources/Data/RouteShare.swift`) stays as it is.

**Scope in one paragraph:** the public catalogue lives in Apple's CloudKit public database. The app reaches walkers through TestFlight first. A walker's identity is the iCloud account on the phone plus a display name they choose. A walker may publish a route from Mine once it has been walked end to end: a route recorded with REC, or a drawn route the walker then tracked with Begin route. Before publishing, the walker trims the start and end of the line by hand. A published route is visible at once; walkers can report and block, and the developer hides what breaks the rules. Walking-now stays at zero and Popular keeps its bundled counts. Comments stay removed.

All paths below are relative to `JWalk/` unless they start with `docs/` or `research/`.

---

## Decisions

| Question | Decision |
|---|---|
| Distribution | TestFlight first. The China App Store comes later, with its own filing. |
| Hosting | CloudKit public database, container `iCloud.com.jwalk.app`. |
| Identity | The phone's iCloud account, plus a display name the walker chooses. No sign-in screen. Sign in with Apple was considered and dropped: CloudKit cannot check its token, and deleting an account would need a server to revoke the token. |
| What may be published | Routes in Mine that were walked end to end: REC recordings, and drawn routes after a tracked walk covers them. |
| When a route becomes visible | At once. Walkers can report a route and block an author; the developer hides routes. |
| GPS privacy | The walker trims the start and end of the line by hand before publishing. No automatic cut. |
| Walking now | Stays 0. `OfflineActivityProvider` is kept. |
| Popular | Keeps the bundled counts in `SampleData.json`. |
| Comments | Stay removed. |

---

## 1. Where it runs

### The options compared

| | CloudKit public database | Server in mainland China | Server outside China |
|---|---|---|---|
| Reachable from mainland phones | Yes. iCloud for mainland Apple Accounts is run by Guizhou-Cloud Big Data (GCBD) and stored in China. | Yes. | Slow or blocked without a VPN. Not reliable. |
| Yearly cost at beta size | Apple Developer Program only: ¥688 / $99. CloudKit storage and requests are free within Apple's allowance. | Developer Program, plus a cloud server (Alibaba or Tencent Cloud, about ¥100–600 a year on entry plans), plus a domain (about ¥50 a year), plus SMS if phone login is used. | Developer Program, plus a server. |
| Paperwork | None for the database itself. | ICP filing for the domain: a real-name ID, a server bought from the filing provider first, 1–3 weeks. Then public-security (police) filing within 30 days. | None in China, but the service is unusable there. |
| Who runs it | Apple. No machine to patch. | The developer: operating system updates, database backups, TLS certificates, uptime. | The developer. |
| Server-side code | None. Every check runs in the app or by hand in the CloudKit Console. | Any. | Any. |
| What changes in the project | Code signing on, an iCloud entitlement, a container. | Code signing on (for TestFlight), plus a backend codebase. | Same as mainland. |

**The Apple Developer Program is needed whichever option is chosen**, because TestFlight needs it. So CloudKit's only extra requirement is turning code signing on.

**CloudKit was chosen** because it costs nothing beyond the Developer Program, needs no filing to start, and has no machine to keep running. Its cost is that nothing runs on the server: limits and filters live in the app, where a modified app could skip them (see §5).

### Filing for the China App Store

The MIIT app filing (移动互联网应用程序备案) has been required for apps on the China App Store since 2023–2024, whatever the backend. It is filed through an "internet access provider" such as Alibaba Cloud, under a real person's or company's ID. TestFlight does not appear to need it, but no official source confirms that. Before external TestFlight testing starts, confirm with Apple Developer support that TestFlight distribution in mainland China needs no filing number. The China App Store listing is out of scope for this plan.

### What must be proved before building

Two reports on Apple's developer forums describe problems specific to CloudKit in mainland China: newly saved public records taking up to a minute to become queryable, and HTTP 500 errors (CKError 15) for mainland accounts. A second unknown is whether a phone signed in to a mainland Apple Account and a phone signed in to an account from another region read the same public database. Task 1 is a spike (a short throwaway test) that answers all three before any feature work.

### Turning on code signing

`Scripts/generate_project.py` sets `CODE_SIGNING_ALLOWED = NO`, `CODE_SIGNING_REQUIRED = NO` and `CODE_SIGN_IDENTITY = "-"` for every target. CloudKit needs an entitlement, and entitlements need a signed app, in the simulator too. The change:

- The app target: automatic signing, the developer's team ID, and a new `Config/JWalk.entitlements` holding the iCloud container `iCloud.com.jwalk.app` with the CloudKit service.
- The unit and UI test targets: signing stays off where Xcode allows it.
- The team ID is read from one place in the script so it is not repeated per target.
- The script stays deterministic: running it twice produces the same project file.

---

## 2. Accounts and identity

- **Reading needs nothing.** Any phone, signed in to iCloud or not, reads the public routes.
- **Publishing, reporting and blocking need iCloud.** The app checks `CKContainer.accountStatus`. With no iCloud account, the Publish button opens a sheet that explains iCloud is needed, with no other action.
- **The identity is the iCloud user record ID** that CloudKit attaches to every record as its creator. The app never sees the walker's Apple Account email or real name. (Apple removed user discovery from CloudKit in iOS 17, so names cannot be looked up anyway.)
- **Display name.** A `WalkerProfile` record, one per walker, holds a display name (1–60 characters, the limit `SharedRoute.maxAuthorLength` already uses) and its first character for the avatar. The walker sets it the first time they publish, prefilled from the local profile name. They can change it from the profile page. A published route stores the display name as it was at publishing time; renaming updates the walker's own published routes.
- **Deleting.** Me gets **Delete my profile and routes**, which asks first, then deletes every record the walker created: profile, published routes and reports. Their routes stay on their phone in Mine. App Store Review Guideline 5.1.1(v) asks for in-app deletion wherever an app creates an account; the profile record counts.
- **Signing out of iCloud** on the phone does not delete anything. Publishing controls behave as if there were no account until one is back.

---

## 3. What publishing a route means

A published route is **a line the walker has walked end to end**, as the onboarding once promised. Only the walker's own routes in Mine can be published. Catalogue routes and routes received from others cannot.

### Which routes qualify

| Route in Mine | Qualifies when |
|---|---|
| Recorded with REC and saved from the walk summary | Always: the line is the walk. |
| Drawn in the builder | After the walker tracks it with Begin route and the walk covers it end to end. |

**"Covers end to end"** is checked on the phone when the walker taps Done on the walk summary, while `TrackingSession.walkedCoordinates` is still in memory:

- The drawn line is sampled every 20 m (`RouteGeometry.densified`).
- A sample counts as covered when a walked fix lies within 50 m of it. 50 m is `TrackingSession.maximumAccuracyMeters`, the roughest fix the tracker accepts.
- The walk qualifies when at least 90% of the samples are covered, including the first and last 100 m of the line.

The check is a pure function over two coordinate lists, so it is unit-tested apart from any view. The 20 m, 50 m, 90% and 100 m figures are starting values, to be tuned on real walks during the beta.

### What changes in local storage

`DraftRoute` (`Sources/Data/WalkRecords.swift`) does not record where a route came from: the builder and the walk summary both call `WalkStore.saveDraftRoute`. Three optional fields are added, so existing stores migrate without a version step:

- `origin`: recorded or drawn. Routes saved before this change count as drawn.
- `walkedEndToEndAt`: the date a covering walk finished. Set at save time for a recording.
- `publishedId`: the public record's name once published.

### The publishing flow

On a route card for a qualifying route in Mine, a **Publish** button sits beside Share. A route that does not qualify yet shows no Publish button. The flow:

1. **Trim.** The line on a map, with a handle at each end. The walker drags each handle along the line; the part being cut is drawn as the dashed "route ahead" style, and the kept part as the route line. The figures update as they drag. A route must keep at least 500 m.
2. **Details.** Name (prefilled, 1–120 characters) and an optional description (up to 2000 characters), the limits `SharedRoute` already uses. One language: the text goes into both halves of `LocalizedText`, as drawn routes do now.
3. **Confirm.** The kept line, name, description and display name exactly as others will see them, and **Publish**.

After publishing, the card shows **Unpublish** in place of Publish. Unpublishing deletes the public record. Editing a published route is out of scope: to change the line, unpublish and publish again.

### What the public record holds

A `PublicRoute` record:

| Field | Content |
|---|---|
| record name | `pub-<UUID>`. A new id, because drawn-route ids (`draft-` plus 8 hex characters) are too short to stay unique across every walker. |
| `name`, `note` | The walker's text. |
| `authorName`, `authorInitial` | From `WalkerProfile` at publishing time. |
| `line` | The trimmed line in the `SharedRoute` integer format (1e-5 degrees), 2–5000 points. |
| `publishedOn` | The publishing day, Shanghai time, with no time of day. |
| creator | CloudKit's own creator field: the walker's iCloud user record ID. |

Distance, time and the pin are not stored. The app computes them from the line, as `SharedRoute.route` does, so a record cannot claim a short walk for a long line. Public routes carry no tags; tags stay the developers' fixed list.

### Limits of an app-side check

CloudKit runs no code on the server, so the walked-end-to-end rule, the length limits and the rate limit in §5 are enforced by the app. A modified app could publish a line nobody walked. For a TestFlight beta of about a hundred walkers that is accepted. A later server plan can move the checks onto the server before the App Store listing.

---

## 4. Networked routes, and activity

### `RouteRepository`

The protocol (`Sources/Data/Repositories.swift`) is synchronous today: `allRoutes()`, `route(id:)`, `featuredRoute()`. Views must not wait on the network, so a networked repository serves a cache synchronously and refreshes it in the background.

- **`CloudRouteRepository`** conforms to `RouteRepository` over its cached list and adds `refresh() async throws`.
- **The cache** is the last fetched list, encoded to a file in Caches. At launch the app shows the cache at once, then refreshes. With no network, the cache is what shows; with no cache and no network, only the bundled catalogue and the walker's own routes show.
- **The query** fetches every `PublicRoute`, newest first, following CloudKit's cursor to the end. At beta size that is a few hundred records. Paging by map area is a later concern.
- **Refresh** runs at launch, when the app returns to the foreground after more than 10 minutes, and after the walker publishes or unpublishes.
- **`featuredRoute()`** keeps returning the bundled featured route. Public routes cannot be featured in this plan.

### `RouteStore`

`RouteStore` merges four lists into one: bundled catalogue, the walker's drawn and recorded routes, **public routes** (new), and received routes, in that order. Its rules:

- A public route whose id matches one of the walker's own `publishedId` values is dropped: the walker sees their own route once, as the Mine copy.
- Hidden, auto-hidden and blocked routes (§5) are dropped.
- A received route whose id matches a public route opens as the public route, the same way a route the app already has opens as itself now.
- A public route the walker bookmarks is downloaded like any other route. Its `OfflineBundle` snapshot keeps working after the author unpublishes it.

Nearby, Mine and Saved need no change: Nearby lists every route in the merged list, so public routes appear there. Featured shows only bundled routes, which carry the tag.

### `RouteActivityProvider`

No change in this plan. `OfflineActivityProvider` stays, so:

- **Walking now** reads 0 on every route, public or bundled.
- **Popular** ranks by the bundled counts. A public route has no counts, so it never appears in Popular. That follows from keeping the bundled counts, and a later plan with server-side walk counts would change it.

The protocol remains the place a networked provider plugs in later, with no view changes.

---

## 5. Moderation and abuse limits

Routes are visible as soon as they are published, so the safeguards act afterwards. Apple's App Store Review Guideline 1.2 asks apps with user-generated content for four things: a filter for objectionable material, a way to report it, a way to block abusive users, and published contact information. Beta App Review for external TestFlight applies the same guidelines.

### Reporting and blocking

- **Report.** A route card for someone else's public route gets a Report action with three reasons: offensive text, not a walkable route, and shows a private place. Reporting creates a `Report` record (route id, reason, creator). One report per walker per route.
- **Automatic hiding.** The app hides a public route once three different walkers have reported it, until the developer reviews it.
- **Block.** The same menu offers Block author. The app stores the author's creator ID on the phone and hides every route by that author. Blocking sends nothing to the server. Me → Privacy gets a Blocked authors list to undo it.
- **Contact.** Me → About gets a contact row. **The contact address is missing:** the developer needs to choose one (an email address is enough) before external testing.

### Developer tools

- The developer's iCloud account gets a custom **Moderator** security role in the CloudKit Console.
- A `Hidden` record (route id, reason) hides a route for everyone. A `Cleared` record overrides automatic hiding for a route that was reported but is fine. Only the Moderator role can create either; everyone can read them.
- Reports are reviewed in the CloudKit Console. A moderation screen inside the app is out of scope; it could later sit in debug builds beside the design-system gallery.

### Security roles

| Record type | Everyone | Signed-in walkers | Creator | Moderator |
|---|---|---|---|---|
| `PublicRoute` | read | create | write, delete | delete |
| `WalkerProfile` | read | create | write, delete | delete |
| `Report` | read (to count) | create | delete | read, delete |
| `Hidden`, `Cleared` | read | — | — | create, delete |

A `Report` is readable so the app can count reports. It shows a creator's pseudonymous record ID, never a name.

### Limits the app enforces before uploading

- Name 1–120 characters, description up to 2000, display name 1–60, a line of 2–5000 points.
- A kept line from 0.5 to 30 km long, with every point inside Shanghai municipality (latitude 30.67–31.88, longitude 120.85–122.20).
- At most 5 publishes per walker per day.
- Name, description and display name checked against a bundled word list in English and Chinese. A match blocks publishing with a message.

As §3 says, a modified app could skip these. CloudKit's own limit is 1 MB per record, which caps the damage of one record.

### Storage

A 5000-point line in the integer format is about 60 KB, so a thousand public routes take about 60 MB. Apple does not publish a current free allowance for the public database; older figures give a base allowance that grows with each active user. Watch actual use in the CloudKit Console during the beta.

---

## 6. Privacy of GPS lines

A recorded line usually starts and ends near where the walker lives or works. A drawn line can too.

- **What becomes public:** the kept part of the line, the name, the description, the display name, its initial, and the publishing day.
- **What never leaves the phone:** the untrimmed line, walks (`StoredWalk`), their times, distances, notes and photographs, which route a walker tracked, and the walker's location.
- **No timestamps on the line.** The line holds coordinates only, and the record holds the day without the time, so a recording published straight after the walk does not reveal when the walker passed each point.
- **Trimming is by hand** (§3). Nothing is cut automatically. The trim screen opens with both handles at the very ends, and the confirm step shows the exact public line.
- **Unpublishing** removes the route from every phone at its next refresh. Copies other walkers already saved stay on their phones, because a saved route is a downloaded snapshot. The confirm step says so before the walker publishes.
- **Where data lives:** for mainland Apple Accounts, iCloud data is operated by GCBD under its terms. A privacy policy covering what is published, where it is stored and how to delete it is needed before the App Store listing, and should be ready for external TestFlight testing.

---

## Implementation order

Each task ends with the unit tests and the affected UI test classes green on iOS 26.5 and iOS 18.6, and a commit.

1. **Enrol and spike.** Join the Apple Developer Program. With a throwaway signed build, create the container, save a public record from a mainland Apple Account and read it from a second account in another region, and time how long a new record takes to become queryable. *Done when* all three results are written down here; if the two regions see different databases, stop and revisit §1.
2. **Signing.** Change `Scripts/generate_project.py` and add `Config/JWalk.entitlements`. *Done when* the signed app builds and runs on both simulators and a device, and the test targets still run.
3. **Schema.** Create `PublicRoute`, `WalkerProfile`, `Report`, `Hidden` and `Cleared` with the security roles in §5 in CloudKit's development environment. *Done when* the schema is in the Console; it is deployed to production just before the first TestFlight build.
4. **Public routes on the map.** `CloudRouteRepository`, its cache, and the merge in `RouteStore`. Public records are created by hand in the Console for this task. *Done when* they appear in Nearby and open their cards, with and without network.
5. **Identity.** Account status, `WalkerProfile`, the display-name step, renaming, and Delete my profile and routes.
6. **Walked end to end.** The new `DraftRoute` fields, the coverage check at Done, and REC recordings marked at save.
7. **Publish and unpublish.** The trim, details and confirm steps, the upload, the in-app limits and the word list.
8. **Report, block and hide.** Report, Block author, Blocked authors, automatic hiding, `Hidden` and `Cleared`, and the contact row.
9. **Docs.** `README.md` and `DESIGN.md` describe the public catalogue, publishing, moderation and signing. The README's "there is no server yet" sentences change.
10. **TestFlight.** Deploy the schema to production, archive, upload, and invite testers.

### Testing

- **Unit tests** cover the coverage check, trimming, the in-app limits, the word list, the merge rules in `RouteStore`, report counting and hiding, and the cache's encoding. They use a fake repository and never touch the network.
- **UI tests** never reach CloudKit. A new launch argument, `-uitest.publicRoutes`, loads a bundled fixture of public routes into the fake repository, and a second one sets the iCloud account status to signed in or signed out. The existing tests keep passing with neither set.
- **By hand, on devices:** publish from one phone and see the route on another, with a mainland Apple Account and with one from another region; unpublish; report from three accounts; block.

---

## Interface copy to approve

The plan adds these strings. Each needs an English and a Chinese value in `Localizable.xcstrings`; the Chinese is drafted with the implementation.

- Publish · Unpublish · Report · Block author · Blocked authors · Delete my profile and routes · Contact
- The three report reasons: Offensive text · Not a walkable route · Shows a private place
- The trim step's title and its one-line instruction
- The confirm step's line about saved copies staying on other phones
- The iCloud-needed sheet's sentence
- The word-list and rate-limit messages

The wording of the last five is drafted with the implementation and shown for approval before it ships.

---

## Out of scope

- Comments, likes or any conversation.
- Live walking-now counts and server-side Popular counts.
- Featuring public routes.
- Editing a published route's line.
- Push notifications for new routes.
- A web page that opens a shared link on phones without JWalk.
- The China App Store listing and its MIIT app filing.
- Moving the app-side checks onto a server.

---

## Concerns that stay open

- **Trimming by hand with no default cut** means a walker who skips past the trim step publishes the line's real ends. The trim screen and the confirm step show those ends, but nothing stops it.
- **Visible at once** means an offensive name can show on every map until three walkers report it or the developer hides it.
- **App-side checks** can be bypassed by a modified app (§3, §5).
- **Public routes never appear in Popular** while Popular uses the bundled counts.
- **CloudKit in mainland China** has the reported index delays and errors the spike in Task 1 checks.
- **TestFlight without a filing number** is likely but unconfirmed (§1).
