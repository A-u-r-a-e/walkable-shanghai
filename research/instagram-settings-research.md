# Instagram's "Settings and activity" screen and iOS settings-list conventions

Research notes for redesigning the **You** tab of Walkable Shanghai as a settings list, with the profile reached through one row. Researched 2026-10-11.

## Source labels

Every claim carries one of these labels.

| Label | Meaning |
|---|---|
| **[IG]** | Instagram Help Center, iPhone version of the article (`?cms_platform=iphone-app`), rendered and read on 2026-10-11. Each article gives a path such as "Below *Section*, tap *Row*". |
| **[IG-web]** | Same Help Center article, computer (instagram.com) version. Section names match the app, but the web layout can differ. |
| **[Meta]** | Meta Newsroom (about.fb.com). |
| **[Apple]** | Apple Human Interface Guidelines, Apple developer documentation, Apple Support, or the App Review Guidelines. |
| **[S]** | Secondary source: a third party describing Instagram. Named inline. |
| **[O]** | Not confirmed by any source read for these notes. It comes from general knowledge of the app. Treat it as likely, and check it on a device before relying on it. |

### What could not be found

- **No Meta announcement of a 2023 "Settings and activity" redesign turned up.** Searches of Meta's newsroom and the tech press found only the January 2023 and October 2023 Accounts Center posts and the January 2023 navigation change (Shop tab removed). The redesign itself is undocumented by Meta in what could be found.
- **Meta publishes no full map of the screen.** Section membership below is pieced together from about 25 Help Center articles. Those articles never state the order of sections, except that **Login** is at the bottom. The section order shown is **[O]**.
- **The screen's title is not stable in sources.** Current iPhone Help Center articles skip the screen name entirely ("Tap Menu in the top right", then "Below *Section*…"). Third-party guides use both "Settings and activity" and "Settings and privacy" **[S]**.
- **Icons are not documented.** The Help Center shows icons as inline glyphs without names. Every icon listed below is **[O]**.

---

## 1. Section structure and rows

How to reach the screen on iPhone: tap **Profile** (bottom right), then **Menu** (top right) **[IG]** ([Your Instagram account settings](https://help.instagram.com/131112217071354/?cms_platform=iphone-app)). The menu opens straight onto the settings list. Older layouts showed a bottom sheet with a separate **Settings** item first ([Privacy International guide, July 2025](https://privacyinternational.org/guide-step/5613/guide-instagram-settings-and-good-practices) still says "Settings > See more in Accounts Centre") **[S]**.

### Search field (top of the screen)

A rounded search field with the placeholder "Search" sits above the first section. One source describes it this way: a GitHub pull request that rebuilt the screen from a Mobbin capture ("a real rounded search field with placeholder "Search""; [brandthread PR #413](https://github.com/externaldev21-sketch/brandthread/pull/413)) **[S]**. That it filters the rows as you type is **[O]**. Meta does not document it.

### Sections, in the order they appear on screen [order: O]

Row names are exact Help Center wording where an [IG] source exists.

#### Your account *(section name: O)*

| Row | Evidence | Icon / trailing content |
|---|---|---|
| **Accounts Center** | Steps go "Tap Menu in the top right. Tap Accounts Center, then tap Password and security" with no section to scroll to, so it sits at or near the top **[IG]** ([Securing your Meta Account with two-factor authentication](https://help.instagram.com/566810106808145/?cms_platform=iphone-app)). Meta says Accounts Center "is located in the settings menus for Facebook, Messenger and Instagram" **[Meta]** ([Centralizing Your Apps Settings in Accounts Center, Jan 2023](https://about.fb.com/news/2023/01/centralizing-apps-settings-in-accounts-center/)). | Meta logo, title, subtitle "Password, security, personal details, ad preferences", chevron. A footnote below explains it covers settings shared across Meta apps **[O]**. |

Accounts Center holds the settings shared across Meta apps: personal details, password and security, and ad preferences (Jan 2023) **[Meta]**, plus download and transfer of your information (Oct 2023, [Making It Easier To Manage Your Information Across Meta's Apps](https://about.fb.com/news/2023/10/manage-your-information-across-apps/)) **[Meta]**. Accounts Center is being replaced by **Meta Account** in a gradual rollout "over the next year" from 23 April 2026. Help articles now say "You may see either Accounts Center or Meta Account settings" **[Meta]** ([Meta Account, 23 Apr 2026](https://about.fb.com/news/2026/04/meta-account/)) **[IG]**. Meta's stated split, from the same post, is a useful rule: settings that apply across apps go in the account hub, and settings specific to one app ("whether someone can tag you in a photo on Instagram") stay inside the app **[Meta]**.

#### How you use Instagram

| Row | Evidence | Icon / trailing content [O] |
|---|---|---|
| **Saved** | "Below How you use Instagram, tap Saved." **[IG]** ([Create a collection](https://help.instagram.com/274531543007118/?cms_platform=iphone-app)) | Bookmark |
| **Archive** | "Tap Menu in the top right. Tap Archive." No section is named **[IG]** ([Archive Stories](https://help.instagram.com/1935507879999791/?cms_platform=iphone-app)). The section is **[O]**. | Clock with a counter-clockwise arrow |
| **Your activity** | "Below How you use Instagram, tap Your activity." **[IG]** ([Time spent](https://help.instagram.com/195902884574087/?cms_platform=iphone-app), [Review and export](https://help.instagram.com/181231772500920/?cms_platform=iphone-app)). It holds archived items and account history. | Activity graph |
| **Notifications** | "Below How you use Instagram, tap Notifications." **[IG]** ([Manage push notifications](https://help.instagram.com/546541825361643/?cms_platform=iphone-app)) | Bell |
| **Time management** | "Below How you use Instagram, tap Time management." **[IG]** ([Time spent](https://help.instagram.com/195902884574087/?cms_platform=iphone-app)) | Clock |

#### What you see

| Row | Evidence | Icon / trailing content [O] |
|---|---|---|
| **Like and share counts** | "Below What you see, tap Like and share counts." **[IG]** ([Hide like counts](https://help.instagram.com/113355287252104/?cms_platform=iphone-app)) | Heart with a slash |
| **Content preferences** | "scroll down to What you see. Click Content preferences" **[IG-web]**. The iPhone version confirms the section **[IG]** ([Content Setting for Teen Accounts](https://help.instagram.com/1470609900735343/?cms_platform=iphone-app)). | Content icon |
| Favorites, Muted accounts | **[O]**. The Favorites article now routes through the feed's "Instagram" title menu instead **[IG]** ([Favorites](https://help.instagram.com/664109784733070/?cms_platform=iphone-app)). | Star / bell with a slash, with counts |

#### Who can see your content

| Row | Evidence | Icon / trailing content [O] |
|---|---|---|
| **Account privacy** | "Below Who can see your content, tap Account privacy." **[IG]** ([Make your account private](https://help.instagram.com/448523408565555/?cms_platform=iphone-app)) | Lock; trailing value "Public" or "Private" |
| **Close Friends** | "Below Who can see your content, tap Close Friends." **[IG]** ([Close Friends](https://help.instagram.com/476003390920140/?cms_platform=iphone-app)) | Star in a circle; trailing count |
| **Blocked** | "Below Who can see your content, tap Blocked." **[IG]** ([Blocked](https://help.instagram.com/461525818338125/?cms_platform=iphone-app)) | Circle with a slash; trailing count |
| **Story, live and location** | "Below Who can see your content, tap Story, live and location." **[IG]** ([Hide your story](https://help.instagram.com/1177797265575168/?cms_platform=iphone-app)). Older name: "Hide story and live" **[O]**. | Story ring |
| Crossposting | **[O]** | |

#### How others can interact with you

| Row | Evidence | Icon / trailing content [O] |
|---|---|---|
| **Messages and story replies** | "Below How others can interact with you, tap Messages and story replies." Activity status is inside it **[IG]** ([Story replies](https://help.instagram.com/1133988223332503/?cms_platform=iphone-app), [Activity Status](https://help.instagram.com/1164377657035425/?cms_platform=iphone-app)) | Speech bubble |
| **Tags and mentions** | **[IG]** ([Who can mention or tag you](https://help.instagram.com/345505572238391/?cms_platform=iphone-app)) | @ sign |
| **Comments** | **[IG]** ([Hide comments](https://help.instagram.com/700284123459336/?cms_platform=iphone-app)) | Speech bubble |
| **Sharing and reuse** | "Under How others can interact with you, tap Sharing and reuse." Read through a search excerpt of [Help Center article 329208821595430](https://help.instagram.com/329208821595430); the page itself was not rendered. **[IG]** | Arrows |
| **Restricted** | **[IG]** ([Restrict](https://help.instagram.com/2638385956221960/?cms_platform=iphone-app)) | Person with a minus; count |
| **Limit interactions** | **[IG]** ([Limits](https://help.instagram.com/4106887762741654/?cms_platform=iphone-app)) | |
| **Hidden words** | **[IG]** ([Hide comments](https://help.instagram.com/700284123459336/?cms_platform=iphone-app)) | "Aa" |

#### Your app and media

| Row | Evidence | Icon / trailing content [O] |
|---|---|---|
| **Device permissions** | "Below Your app and media, tap Device permissions." **[IG]** ([Device permissions](https://help.instagram.com/1535234260383659/?cms_platform=iphone-app)). The row lists each device permission and sends you to iOS Settings to change it. | Phone |
| **Archiving and downloading** | "Click Archiving and downloading under Your app and media." **[IG-web]** ([Archive Stories, web](https://help.instagram.com/1935507879999791/?cms_platform=www)). On iPhone the same toggle is reached through Your activity → Archived → Settings **[IG]**. | Download arrow |
| **Media quality** | "Below Your app and media, tap Media quality." It holds "Upload at highest quality" and "Use less cellular data" **[IG]** ([Reel size](https://help.instagram.com/1038071743007909/?cms_platform=iphone-app), [Use less data](https://help.instagram.com/379494505495970/?cms_platform=iphone-app)) | HD badge |
| **Website permissions** | "Below Your app and media, tap Website permissions." **[IG]** ([Apps and websites](https://help.instagram.com/1144624522593085/?cms_platform=iphone-app)) | Globe |
| Accessibility, Language (and translations) | **[O]** | Accessibility figure; globe or "文A" |

**Dark mode has no row on iPhone.** Instagram states that dark mode "cannot be turned on or off in the Instagram app for iPhone" and follows the iPhone's system setting. The website has its own switch **[IG]** ([Dark mode](https://help.instagram.com/897760233943762/?cms_platform=iphone-app)).

#### Family Center

| Row | Evidence |
|---|---|
| **Supervision for Teen Accounts** | "Below Family Center, tap Supervision for Teen Accounts." **[IG]** ([About Family Center](https://help.instagram.com/454886756318459/?cms_platform=iphone-app)). A 2024 parenting blog gives the older section name "For Families" **[S]**. |

#### For professionals; Your orders and fundraisers *(both O)*

These hold account type and tools, Meta Verified, and Orders and payments. They appear for some accounts only **[O]**.

#### More info and support

| Row | Evidence |
|---|---|
| **Help** | "Below More info and support, tap Help." Report a problem lives inside it **[IG]** ([Report a technical problem](https://help.instagram.com/381579045265733/?cms_platform=iphone-app)) |
| **Account Status** | "Below More info and support, tap Account Status" **[IG]** ([Account Status](https://help.instagram.com/338481628002750/?cms_platform=iphone-app)) |
| Privacy Center, About | **[O]** |

#### Also from Meta *(O)*

Rows that promote other Meta apps (Threads, Facebook, WhatsApp, Edits and others) **[O]**.

#### Login (always last)

| Row | Evidence |
|---|---|
| (section) | "Scroll down to Login." **[IG]** ([Add or remove login information](https://help.instagram.com/1020536697967549/?cms_platform=iphone-app)) |
| **Add account** | "Scroll to the bottom and tap Add account." **[IG]** ([Add and switch profiles](https://help.instagram.com/1682672155283228/?cms_platform=iphone-app)) |
| **Log out** | "Scroll to the bottom of the page and tap Log out." Instagram may first offer to save login information, and then asks again to confirm **Log out** **[IG]** ([Log out of Instagram](https://help.instagram.com/623835647655355/?cms_platform=iphone-app)) |
| Log out of all accounts | Shown when several accounts are signed in **[O]** |

---

## 2. How the profile or account entry is presented

- **Instagram has no avatar row at the top of this screen [O].** The profile is the tab you open settings from. The first item under the search field is **Accounts Center**, a row with a logo, title, subtitle and chevron. It is not a personal identity card. The Help Center supports the placement but not the visual details (see the Your account section above).
- **Apple's own Settings app is the model for an avatar row at the top.** Apple's support guides start account tasks with "Settings > [your name]". If your name is missing from the top of Settings, you tap the Apple Account row to sign in **[Apple]** ([Keep your Apple Account secure](https://support.apple.com/guide/iphone/keep-your-apple-account-secure-iph904b71f28/ios), [Set up iCloud](https://support.apple.com/guide/icloud/set-up-icloud-on-your-devices-mmfc0f1e2a/icloud)). That row is a large avatar, the name, a subtitle, and a chevron, in its own group with no header **[O for the visual details]**.
- So the design asked for (settings list with the profile as one tappable row) follows **Apple's Settings** pattern at the top and **Instagram's** pattern for everything below it.

---

## 3. Patterns worth borrowing

1. **Section headers phrased as the user's question.** "How you use Instagram", "Who can see your content", "How others can interact with you" and "What you see" group rows by what the person is trying to do, not by feature names **[IG]**. Only the header wording is sourced. Whether this phrasing helps people find settings is a design judgement.
2. **Row anatomy.** Leading line icon, then title, then an optional trailing value, then a chevron. The trailing value is a state ("Private") or a count (Close Friends, Blocked) **[O]**. Instagram draws flat rows with hairline dividers and grey sentence-case headers, without rounded cards **[S]** ([brandthread PR #413](https://github.com/externaldev21-sketch/brandthread/pull/413)). An iOS-native app would use Apple's inset grouped cards instead (section 4).
3. **Shared or account-wide settings in one row at the top.** Instagram puts everything that spans Meta apps behind the Accounts Center row, and keeps the app's own settings in the list **[Meta]**.
4. **Each count lives in one place.** Saved, Archive and Your activity are rows in settings, not tabs **[IG]**. This supports moving Saved routes and Offline downloads into the You tab.
5. **Log out and Add account sit last**, in their own **Login** section, below Help and About **[IG]**. Log out asks for confirmation **[IG]**. Whether the text is red is **[O]**.
6. **Follow the system for appearance.** Instagram on iPhone has no dark-mode switch **[IG]**. Apple's guidance says the same (section 4).
7. **Device permissions are summarized in the app and changed in iOS Settings.** The Device permissions row lists each permission and sends you to the system Settings app to change it **[IG]**.
8. **Search at the top** only pays off at Instagram's scale, with about 40 rows **[S]/[O]**. With fewer than about 15 rows, search adds clutter. Apple's Settings guidance says to minimize the number of settings (section 4).

---

## 4. Apple HIG guidance for settings-style lists

All **[Apple]**. HIG pages read through their JSON source on 2026-10-11.

### Lists and grouping

- iOS Settings itself "uses a hierarchy of lists to help people choose options." The **grouped** style "uses headers, footers, and additional space to separate groups of data." Pick a row style that fits the information, for example a small leading image followed by a brief label. ([Lists and tables](https://developer.apple.com/design/human-interface-guidelines/lists-and-tables))
- SwiftUI `.insetGrouped`: "a continuous background color that extends from the section header, around both sides of list items in the section, and down to the section footer." ([ListStyle.insetGrouped](https://developer.apple.com/documentation/swiftui/liststyle/insetgrouped)) `Section` takes a header and a footer. ([Section](https://developer.apple.com/documentation/swiftui/section))
- Keep row text succinct. If a row needs a lot of text, show the title only and put the rest in a detail view. ([Lists and tables](https://developer.apple.com/design/human-interface-guidelines/lists-and-tables))
- The HIG does not give a separate rule for footer text. The grouped style simply includes footers. Putting short explanations of a section in its footer is the common iOS Settings practice **[O]**.

### Disclosure indicators and row actions

- To let people drill into a row, use a **disclosure indicator** (the chevron). The **info button** is only for revealing more information and "doesn't support navigation." ([Lists and tables](https://developer.apple.com/design/human-interface-guidelines/lists-and-tables))
- Don't add an alphabet index to a list whose rows end in disclosure indicators, because both sit on the trailing edge. (same page)
- A `NavigationLink` can use `LabeledContent` as its label to show "a summary value for the destination it links to." This gives the "title … value ›" row in SwiftUI. ([LabeledContent](https://developer.apple.com/documentation/swiftui/labeledcontent))
- Selection feedback: a list used for navigation highlights the row along the path. A list of options briefly highlights the row, then shows a **checkmark** on the chosen item. ([Lists and tables](https://developer.apple.com/design/human-interface-guidelines/lists-and-tables))

### Toggles in rows

- "Use the switch toggle style only in a list row. You don't need to supply a label in this situation because the content in the row provides the context." ([Toggles](https://developer.apple.com/design/human-interface-guidelines/toggles))
- Change the switch from its default green only if needed, for example to the app's accent color, and only with enough contrast against the off state. (same page)
- A toggle is for two opposing values. To choose from a list of items, use a different control, such as a pop-up button or a list of options with checkmarks. (same page)

### Row height and touch targets

- Default control size on iOS is **44×44 pt**, and the minimum is **28×28 pt**. Leave about 12 pt of padding around bezeled elements and about 24 pt around unbezeled ones. ([Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility))
- The HIG gives no fixed list-row height. System list rows grow with Dynamic Type, so use the system row instead of a fixed height **[O]**.

### What belongs in an app's settings

From [Settings](https://developer.apple.com/design/human-interface-guidelines/settings):

- "Minimize the number of settings you offer." Too many settings make the app "less approachable" and make each setting harder to find.
- "Respect people's systemwide settings and avoid including redundant versions of them in your custom settings area." Custom copies of global options imply that the system settings may not apply to the app.
- Put general, infrequently changed settings in the settings area. Options that affect one task belong on that task's screen.
- "Avoid using settings to ask for setup information you can get in other ways", for example whether the person is using Dark Mode.
- It can help to provide a button that opens the system Settings app directly. In UIKit, `UIApplication.openSettingsURLString` opens the app's page in iOS Settings ([openSettingsURLString](https://developer.apple.com/documentation/uikit/uiapplication/opensettingsurlstring)). SwiftUI's `openURL` action can open the same URL **[O]**.

### Appearance

- "Avoid offering an app-specific appearance setting." It makes people adjust more than one setting, and "they may think your app is broken because it doesn't respond to their systemwide appearance choice." ([Dark Mode](https://developer.apple.com/design/human-interface-guidelines/dark-mode))

### Language

- iOS 13 added a per-app language setting in iOS Settings. In WWDC19 session 403, Apple recommends that if an app needs an in-app language option, it should "Launch into Settings where users can go in and switch the language of your app." The app then relaunches in the chosen language. ([Creating Great Localized Experiences with Xcode 11, WWDC19](https://developer.apple.com/videos/play/wwdc2019/403/); quote via search excerpt of the transcript)
- An Apple engineer on the Developer Forums says there is no supported way for an app to change its own system language, and that writing `AppleLanguages` to UserDefaults is unsupported ([forum thread](https://developer.apple.com/forums/thread/741550); via search excerpt) **[Apple, forum]**.

### Permissions (location, notifications)

- Request permission only when a feature needs it. Avoid asking at launch unless the app can't work without it. People can review and change each choice in Settings > Privacy. ([Privacy](https://developer.apple.com/design/human-interface-guidelines/privacy))
- Notifications need consent before any are sent. People then manage styles and timing in Settings. ([Notifications](https://developer.apple.com/design/human-interface-guidelines/notifications))

### Destructive actions (Log out, Delete)

- A button can have the **destructive** role, which draws it in system red. "Don't assign the primary role to a button that performs a destructive action." ([Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons))
- Show a confirmation alert for **uncommon destructive actions that can't be undone**, not for common undoable ones. When there is a destructive action, include a button titled exactly "Cancel". Use specific button titles such as "Delete", not "OK". ([Alerts](https://developer.apple.com/design/human-interface-guidelines/alerts))
- For choices tied to an action the person started on purpose, use an **action sheet** (SwiftUI `confirmationDialog`). Put destructive buttons at the top in the destructive style and Cancel at the bottom. Use at most four buttons, including Cancel. ([Action sheets](https://developer.apple.com/design/human-interface-guidelines/action-sheets))
- If an app supports account creation, "you must also offer account deletion within the app." ([App Review Guidelines 5.1.1(v)](https://developer.apple.com/app-store/review/guidelines/#data-collection-and-storage))

### Search

- iOS search can sit in a tab, in a toolbar, or inline. Apple's own Settings app puts search in the bottom toolbar as the only item. An inline search field filtering a single list goes above that list, and may pin to the top toolbar while scrolling. ([Search fields](https://developer.apple.com/design/human-interface-guidelines/search-fields))

---

## 5. Proposed You tab for Walkable Shanghai

### Starting point

The app is local-only, with no backend and no sign-in. The current You tab (`WalkableShanghai/Sources/Features/Profile/ProfileScreen.swift`) is one scroll view with:

- an identity block (initial avatar, name, joined month)
- four figures (walks, total km, longest walk, routes added)
- a "walk range" bar chart of the last six months
- a settings card with Language (an English / 简体中文 segmented control), Routes you added (count → route builder), Offline downloads (count → Saved screen), About Walkable Shanghai (→ onboarding), and Design system (→ token gallery)

The Saved tab is being removed. `SavedRoutesStore` already keeps two separate sets, **saved** and **offline**, and `OfflineStore` knows each download's size. `CommunityStore` keeps liked posts and the walker's own notes locally. `LocationProvider` asks for When In Use location. The app sends no notifications today.

### Layout

A SwiftUI `List` with `.insetGrouped` style. Each row has an SF Symbol in a fixed-width leading slot, a title, an optional trailing value in secondary text, and a chevron from `NavigationLink`. Counts use tabular figures. Section headers are short. Short explanations go in section footers. This follows Apple's grouped list conventions (section 4) and keeps the app's current card look, since inset grouped rows already sit on rounded cards.

Key for the **Needs** column:

- **Local**: can ship now on data the app already stores.
- **Local, new**: can ship now, but needs a new screen or setting.
- **System**: opens or reads iOS Settings.
- **Hosted page**: needs a public web page or email address, but no backend.
- **Backend**: needs a server, accounts, or both. These rows should not be shown until that exists.

#### Profile (no header)

| Row | Content | Destination | Needs |
|---|---|---|---|
| **Profile** | Avatar (initial), name, subtitle such as "12 walks · 48.6 km". Taller than other rows, like the Apple Account row. | Profile screen: identity, the four figures, the walk-range chart, then the walk history list | Local |

The profile screen keeps everything the tab shows today except the settings card. This is Apple's "[your name]" row pattern. Instagram has no equivalent (section 2).

#### Your walks
*(after Instagram's "How you use Instagram")*

| Row | Trailing | Destination | Needs |
|---|---|---|---|
| **Saved routes** | count | List of routes the walker has saved, without downloading them | Local, new (moves from the Saved tab) |
| **Offline downloads** | count | List of downloaded routes, each with its size, plus swipe to delete | Local (moves from the Saved tab) |
| **Routes you added** | count | Drafts list, with a "Draw a new route" button that opens the route builder | Local, new list (today the row opens the builder directly) |
| **Walk history** | count | Recorded walks, newest first (`WalkStore.walksNewestFirst`) | Local, new |

Footer under the section, for example: "Offline downloads work without signal. They use 3.2 MB on this iPhone." The total comes from `OfflineStore.totalBytes`.

**Choice for the user:** Saved routes and Offline downloads could be **one row with two sections inside**, like the current Saved screen. Two rows match Instagram's "each list gets its own row". One row keeps the list shorter, which Apple's "minimize settings" guidance favors.

#### Your activity
*(optional; after Instagram's Your activity)*

| Row | Trailing | Destination | Needs |
|---|---|---|---|
| **Posts you liked** | count | Community posts the walker liked (`PostLike`) | Local, new |
| **Your notes on routes** | count | Notes the walker left on routes | Local, new |

Leave this section out if Community stays a demo. The data is local now, but it means little until other people can see it.

#### Preferences

| Row | Trailing | Control | Needs |
|---|---|---|---|
| **Language** | "English" or "简体中文" | Push to a two-item list with a checkmark on the current language (Apple's "list of options" pattern). Or keep the current segmented control inline. | Local (exists) |
| **Units** | "Kilometers" | Kilometers or miles | Local, new. **Recommendation: leave it out.** iOS has a system measurement setting, and HIG says not to duplicate system settings. Use `Locale.current.measurementSystem` if miles are ever needed. |
| **Appearance** | "System" | System, Light, Dark | Local, new. **Recommendation: leave it out.** The HIG says "Avoid offering an app-specific appearance setting", and Instagram on iPhone has none. If it is added anyway, default to System and list it last. |

On Language: the app's switch re-renders every screen at once in the app's own localization layer (`AppSettings.language`). Apple's guidance is to send people to iOS Settings for per-app language. The in-app switch is the better experience here because it needs no relaunch and covers the bilingual route data. It does mean the app's language can differ from what iOS Settings shows for the app. Keep the in-app switch. Optionally add a footer link to iOS Settings.

#### Privacy and permissions
*(after Instagram's "Who can see your content" and "Your app and media")*

| Row | Trailing | Destination | Needs |
|---|---|---|---|
| **Location** | "While Using" / "Never" / "Ask" | Short explanation of what location is used for (map position and walk tracking), with an "Open Settings" button (`openSettingsURLString`) | System |
| **Notifications** | "Off" | Same pattern | System. **Add only when the app sends something.** Local walk reminders need no backend. Replies to your routes would need one. |
| **Your data** | — | Plain statement that walks, routes, likes and notes are stored only on this iPhone, followed by destructive rows: "Delete all offline downloads" and "Delete walk history". Each confirms with an action sheet, destructive button on top and Cancel at the bottom. | Local, new |

Footer: "Walkable Shanghai has no account. Everything stays on this iPhone." The sentence needs updating once a backend exists.

#### Support and about
*(after Instagram's "More info and support")*

| Row | Trailing | Destination | Needs |
|---|---|---|---|
| **How Walkable Shanghai works** | — | The onboarding, as today's "About Walkable Shanghai" row | Local (exists) |
| **Send feedback** | — | Mail composer to a support address | Hosted page (an email address) |
| **Privacy policy** | — | Web page | Hosted page. The App Store requires a privacy policy link. |
| **Rate on the App Store** | — | App Store review page | Needs the App Store listing |
| **Version** | "1.0 (12)" | No chevron; read-only `LabeledContent` | Local |
| **Design system** | — | Token gallery | Local (exists). Show in debug builds only. |

#### Account (future; show only once a backend exists)
*(after Instagram's Accounts Center at the top and Login at the bottom)*

| Row | Where | Needs |
|---|---|---|
| **Sign in / Create account** | Replaces the profile row's subtitle with a "Sign in to sync your walks" prompt, as Apple's Settings does when signed out | Backend |
| **Sync across devices** | Under Account | Backend |
| **Who can see your routes**, **Comments on your routes**, **Blocked people** | New "Community" section, after Instagram's "Who can see your content" and "How others can interact with you" | Backend |
| **Log out** | Last section, alone. Destructive style, with a confirmation. | Backend |
| **Delete account** | Inside the account screen, not on the main list. Destructive style, with an alert that has a "Cancel" button. Required by App Review Guideline 5.1.1(v) once accounts exist. | Backend |

### Proposed order (today, without a backend)

1. Profile row
2. Your walks: Saved routes · Offline downloads · Routes you added · Walk history
3. Preferences: Language
4. Privacy and permissions: Location · Your data
5. Support and about: How Walkable Shanghai works · Send feedback · Privacy policy · Version · (Design system, debug only)

That comes to 11 or 12 rows. No search field is needed at this size. Rows marked "Hosted page" stay hidden until their URL or address exists. When a backend arrives, Account rows go at the top (inside the profile row and an account screen), Community goes after Privacy, and Log out goes at the very bottom.

### Open questions for the user

- One row or two for Saved routes and Offline downloads.
- Whether to add Units and Appearance despite the HIG guidance against them.
- Whether Walk history lives on the profile screen, as its own row, or both.
- Whether the Your activity section (likes and notes) ships before the community has a backend.
- Language as a pushed list with checkmarks, or the current inline segmented control.
