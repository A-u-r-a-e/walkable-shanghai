# Tencent, Baidu and Mapbox as MapKit replacements

Researched 2026-10-11 for Walkable Shanghai: a SwiftUI iOS app (iOS 18.0 target, Xcode 26.6, arm64 Mac, no CocoaPods or SPM yet) that wraps `MKMapView` in `UIViewRepresentable` with polyline overlay renderers, a polygon tint, custom annotation views, a muted map style, rect framing with edge padding, and tap-to-coordinate. Route data is WGS-84 (the GPS coordinate system).

Sources are the vendors' own docs, download and changelog pages, CocoaPods specs, GitHub, pricing pages and terms, plus the PRC State Council's map regulation. Each claim carries its URL. **Confirmed** means read on a primary source. **Inferred** means reasoned from primary sources. **Unconfirmed** means no primary source was found.

Coordinate systems used below:

- **WGS-84**: the GPS system. Walkable Shanghai's route data uses it.
- **GCJ-02**: the obfuscated system that PRC rules require for maps of mainland China. Tencent, AutoNavi and Apple's China map data use it. WGS-84 points drawn on a GCJ-02 map land roughly a few hundred metres off.
- **BD-09**: Baidu's own further offset of GCJ-02.

---

## 1. Tencent Maps iOS SDK (QMapKit)

### Version and install

- Current release: **6.15.0, 2026-10-08**. Earlier: 6.13.0 (2026-07-31), 6.12.1, 6.11.0, 6.9.0, 6.8.0 (2026-01-19). Source: https://lbs.qq.com/mobile/iOSMapSDK/mapDownload/download3D. **Confirmed.**
- **CocoaPods**: from 6.13.0 the SDK is split into per-module xcframework pods: `Tencent-MapFoundation-XC` (≥ 5.2.4), `Tencent-MapSDK-XC`, `Tencent-MapVisualPlugin-XC` and `Tencent-MapUtils-XC`. The older non-XC pods (`Tencent-MapSDK` and others) still exist. Source: https://lbs.qq.com/mobile/iOSMapSDK/mapGuide/introAuto. **Confirmed.**
- CocoaPods trunk lists `Tencent-MapSDK-XC` 6.13.0 and 6.15.0, and `Tencent-MapSDK` up to 6.9.0. The 6.15.0 XC podspec vendors `QMapKit.xcframework`, sets platform iOS 12.0, links `z`, `c++` and `sqlite3.0`, and adds `-ObjC`. Source: https://cdn.jsdelivr.net/cocoa/Specs/5/0/3/Tencent-MapSDK-XC/6.15.0/Tencent-MapSDK-XC.podspec.json. **Confirmed.**
- **Manual install**: download the zip, add `QMapKit.framework` and `QMapFoundation.framework`, copy `QMapKit.bundle` into the app, add `-ObjC`, and link `libsqlite3.tbd` and `libc++.tbd`. Source: https://lbs.qq.com/mobile/iOSMapSDK/mapGuide/introManual. **Confirmed.** That guide still describes `.framework` files. Whether the 6.15.0 website zip contains xcframeworks is **unconfirmed**.
- **SPM**: not offered. No Swift Package is mentioned on the download or install pages. **Confirmed (absence).**
- **arm64 Simulator slice**: **yes, for the XC pods.** The archive behind `Tencent-MapSDK-XC` 6.15.0 contains `QMapKit.xcframework/ios-arm64/` and `QMapKit.xcframework/ios-arm64_x86_64-simulator/`. The `Tencent-MapFoundation-XC` 5.2.4 archive contains `ios-arm64_x86_64-simulator`. This was read from each zip's file directory, with the archive URLs taken from the podspecs. **Confirmed.** For the non-XC pods and the website zip, simulator support is **unconfirmed**.
- CocoaPods trunk stops accepting new podspecs on **2026-12-02**. Source: https://blog.cocoapods.org/CocoaPods-Specs-Repo/. **Confirmed.** Tencent ships no SPM package, so after that date updates would come only from the website zip, unless Tencent publishes pods some other way (**unconfirmed**).

### API similarity to MKMapView

Tencent's API is a close copy of MapKit's shape. All names below are from the reference at https://mapapi.qq.com/sdk/map/iOS/doc/interface_q_map_view.html and https://mapapi.qq.com/sdk/map/iOS/doc/protocol_q_map_view_delegate-p.html. **Confirmed.**

| MapKit | Tencent |
|---|---|
| `MKMapView` | `QMapView` |
| `mapView(_:viewFor:)` → `MKAnnotationView` | `mapView:viewForAnnotation:` → `QAnnotationView` |
| `mapView(_:rendererFor:)` → `MKPolylineRenderer` | `mapView:viewForOverlay:` → `QOverlayView` (`QPolylineView`, `QPolygonView`) |
| `setVisibleMapRect(_:edgePadding:animated:)` | `setVisibleMapRect:edgePadding:animated:` |
| `setRegion` / `showAnnotations` | `setRegion:edgePadding:animated:`, `showAnnotations:edgePadding:animated:`, `showOverlays:edgePadding:animated:` |
| `convert(_:toCoordinateFrom:)` | `convertPoint:toCoordinateFromView:` |
| tap via gesture recogniser | delegate `mapView:didTapAtCoordinate:` |
| `MKMapPoint` / `MKMapRect` | `QMapPoint` / `QMapRect`, `QMapPointForCoordinate` (https://lbs.qq.com/mobile/iOSMapSDK/mapGuide/otherTransfer) |

The framing guide shows `setVisibleMapRect:edgePadding:animated:` and `QBoundingCoordinateRegionWithCoordinates` (https://lbs.qq.com/mobile/iOSMapSDK/mapGuide/cameraRect). The SDK is Objective-C, and all map calls must run on the main thread (https://lbs.qq.com/mobile/iOSMapSDK/mapGuide/introBasic). **Confirmed.**

### Map types, traffic, styles

- Map types: `QMapTypeStandard`, `QMapTypeSatellite`, `QMapTypeDark` and `QMapType3DImmersiveMap`. Traffic is `showsTraffic = YES` and works on standard and satellite. Traffic colours can be customised with `QTrafficStyle`. Source: https://lbs.qq.com/mobile/iOSMapSDK/mapGuide/mapType. **Confirmed.**
- Custom styles: templates are built in the web console and chosen with `setMapStyle:` by index (1, 2, 3 …). An offline style resource pack can be copied into `QMapKit.bundle` to avoid a visible style switch. Source: https://lbs.qq.com/mobile/iOSMapSDK/mapGuide/mapStyle. **Confirmed.** A key can bind 3 custom layers. Source: https://lbs.qq.com/faq/customMapFaq. **Confirmed.** "Custom layers" (个性化图层, uploaded tile imagery) are a paid feature not open to individuals in mini-programs (same FAQ). Whether console style templates are free for an individual using the iOS SDK is **unconfirmed**.

### Labels and language

- `setForeignLanguage:` takes `QMapLanguage_zh` or `QMapLanguage_en`. The reference describes it as the preferred language for **overseas map** text, with Chinese as the default. Sources: https://mapapi.qq.com/sdk/map/iOS/doc/interface_q_map_view.html and https://mapapi.qq.com/sdk/map/iOS/doc/_q_types_8h_source.html. **Confirmed.**
- No documented way to show English labels for mainland China, including Shanghai. **Inferred** from the reference wording; not tested.

### Offline maps

`offlineMapEnable = YES`, then `QOfflineMap` lists cities, downloads them, and can cancel or delete a download. Available since 4.3.5. Source: https://lbs.qq.com/mobile/iOSMapSDK/mapGuide/offline. **Confirmed.**

### Coordinates

- Tencent uses **GCJ-02** throughout. It returns WGS-84 only in Taiwan and overseas. Tencent offers no conversion back from GCJ-02 to WGS-84. Sources: https://lbs.qq.com/faq/latlngFaq and https://lbs.qq.com/llms.txt. **Confirmed.**
- WGS-84 → GCJ-02 conversion is a **WebService API**, `/ws/coord/v1/translate` (https://lbs.qq.com/service/webService/webServiceGuide/webServiceTranslate). Its quota for personal developers is 6,000 calls/day at 5 requests/second (https://lbs.qq.com/quotaImprove). The iOS SDK headers contain no on-device converter. `QGeometry` only converts between lat/long and map points (https://lbs.qq.com/mobile/iOSMapSDK/mapGuide/otherTransfer). **Confirmed.**

### Account and key

- Registration binds a QQ, WeChat or phone number (terms §3.1, https://lbs.qq.com/terms.html). The FAQ says binding WeChat is **required** (https://lbs.qq.com/faq/accountQuota/faqAccountOther). **Confirmed.**
- A key is created in the console, with the Map SDK enabled and an optional bundle-ID restriction. It is set with `[QMapServices sharedServices].APIKey`. Source: https://lbs.qq.com/mobile/iOSMapSDK/mapGuide/introKey. **Confirmed.**
- Whether a mainland phone number or real-name verification is needed for a personal account is **unconfirmed**. Enterprise verification and the commercial licence require a company (https://lbs.qq.com/faq/authorizationFaq). **Confirmed.**

### Privacy compliance APIs

- `[[QMapServices sharedServices] setPrivacyAgreement:YES]` must be called before any `QMapView` is created. If it is not set, the map instance returns nil. The SDK collects the IDFV (the per-vendor device ID). Uploading identifier data can be turned off with a `server_protocol.json` file (`privacy_protection: false`). Source: https://lbs.qq.com/mobile/iOSMapSDK/mapGuide/privacyAgreement. **Confirmed.**
- The compliance guide requires the app's privacy policy to disclose the SDK. Data listed: device model, network type, screen size and density, OS version, location, IP and IDFV. Source: https://lbs.qq.com/mobile/iOSMapSDK/compliance. **Confirmed.**
- `QMapCustomLocation` must be given the user's real position before the map initialises, so that Tencent can assign region-specific service (https://lbs.qq.com/mobile/iOSMapSDK/mapGuide/introKey). **Confirmed.**

### Pricing

- The iOS map SDK is **free for non-commercial use**. Enterprises and other non-charity organisations need a commercial licence. Source: https://lbs.qq.com/quotaImprove ("移动端 SDK 配额"). **Confirmed.**
- A "personal developer" is defined as use for personal study and not by a company or organisation (same page). **Confirmed.**
- The commercial licence costs **¥50,000/year** (Basic) or **¥70,000/year** (Advanced), runs 372 days, and is granted only to companies. Source: https://lbs.qq.com/faq/authorizationFaq. **Confirmed.**
- Whether a free App Store app published by an individual counts as "non-commercial" is **unconfirmed**. The wording ties the free tier to personal or learning use.

### Coverage and legality in mainland China

Tencent is a domestic provider with GCJ-02 data. Release 6.8.0 added an API that returns the **map review number** (审图号), which approved maps must display (download page, https://lbs.qq.com/mobile/iOSMapSDK/mapDownload/download3D). The Tencent logo must not be covered (https://lbs.qq.com/faq/accountQuota/faqAccountOther). **Confirmed.**

---

## 2. Baidu Maps iOS SDK (BMKMapView)

### Version and install

- Current release: **7.2.0, 2026-07-27**. Earlier: 7.1.0 (2026-05-29), 7.0.0 (2026-04-16), 6.6.7 (2026-01-22). The 7.2.0 changelog says the base map SDK now supports **xcframework with x86_64 simulator, arm64 simulator and arm64 device** architectures, and adds Xcode 27 / iOS 27 support. Source: https://lbsyun.baidu.com/docs/ios?title=iossdk/theupdatelog. **Confirmed.**
- **Downloads**: the full `BaiduMap_IOSSDK_v7.2.0_Frameworks.zip` (includes navigation), and `BaiduMapKit-XCFrameworkV7.2.0.1.zip`. The xcframework package is the base map only, with **no navigation yet**. Per-module privacy manifests (`.xcprivacy`) are provided. Source: https://lbsyun.baidu.com/docs/ios?title=iossdk/sdkiosdev-download. **Confirmed.**
- **CocoaPods**: `BaiduMapKit` 7.2.0 vendors fat `.framework` files, not xcframeworks. It sets `EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64` and `VALID_ARCHS[sdk=iphonesimulator*] = x86_64`. Source: https://cdn.jsdelivr.net/cocoa/Specs/3/7/9/BaiduMapKit/7.2.0/BaiduMapKit.podspec.json. The pod archive contains only `.framework` directories (read from the zip's file directory). **Confirmed.** The pod therefore builds for the simulator only as x86_64, which needs Rosetta.
- **SPM**: not offered. **Confirmed (absence)** on the download page.
- **arm64 Simulator slice**: **yes, but only in the manual XCFramework download (7.2.0.1)**, per the changelog. The slice list inside that zip was not inspected. **Confirmed from the changelog; not checked in the binary.**
- Manual setup: add `-ObjC`. For Xcode 15+ the guide says to add `-ld_classic`. Keep at least one `.mm` file or compile as Objective-C++. Copy `mapapi.bundle`. Link Accelerate, AVFAudio, CoreLocation, OpenGLES, libc++, libsqlite3, libz and others. Source: https://lbsyun.baidu.com/docs/ios?title=iossdk/guide/create-project/oc. **Confirmed.** Whether `-ld_classic` is still needed with Xcode 26 is **unconfirmed**.
- Swift use goes through a bridging header (https://lbsyun.baidu.com/docs/ios?title=iossdk/guide/create-project/swiftconfig). **Confirmed.**

### API similarity to MKMapView

Baidu's API is also MapKit-shaped. Names below are from https://mapopen-pub-iossdk.bj.bcebos.com/map/v_7_2_0/docs/html/interface_b_m_k_map_view.html and https://mapopen-pub-iossdk.bj.bcebos.com/map/v_7_2_0/docs/html/protocol_b_m_k_map_view_delegate-p.html. **Confirmed.**

- `BMKMapView` has `setVisibleMapRect:edgePadding:…`, `fitVisibleMapRect…` and `convertPoint:toCoordinateFromView:`.
- `BMKMapViewDelegate` has `mapView:viewForAnnotation:` (`BMKAnnotationView`), `mapView:viewForOverlay:` (`BMKOverlayView` subclasses), `mapView:regionDidChangeAnimated:`, and **`mapView:onClickedMapBlank:`** for taps on the map.

### Map types, traffic, styles

- `BMKMapTypeStandard`, `BMKMapTypeSatellite` and `BMKMapTypeNone` (blank, for custom tiles). `setTrafficEnabled:YES` shows traffic on both standard and satellite. Source: https://lbsyun.baidu.com/docs/ios?title=iossdk/guide/create-map/maptype. **Confirmed.** No built-in dark map type is listed.
- Custom styles: `.sty` files made in the online editor. They are applied by online style ID (`setCustomMapStyleWithOption:preLoad:success:failure:`) or from a local file (`setCustomMapStylePath:` plus `setCustomMapStyleEnable:YES`). They cover 51 map elements. Source: https://lbsyun.baidu.com/docs/ios?title=iossdk/guide/create-map/custommap. **Confirmed.** Cost is not stated (**unconfirmed**).

### Labels and language

- `languageType` (since 6.4.0) takes `BMKMapLanguageChinese` or `BMKMapLanguageEnglish`. `showSingleLanguage = NO` shows two languages: the local one plus the chosen one. Since 6.6.2 the English map **does not support custom styles**. Source: https://mapopen-pub-iossdk.bj.bcebos.com/map/v_7_2_0/docs/html/interface_b_m_k_map_view.html. **Confirmed.**
- The English base map **must be applied for separately and is a paid service**. It covers 34 provincial-level regions and 346 cities in China. Overseas areas get no English. Source: https://lbsyun.baidu.com/docs/ios?title=iossdk/guide/create-map/englishmap. **Confirmed.** The price is **unconfirmed**.

### Offline maps

`BMKOfflineMap` provides `searchCity:`, `start:`, `pause:`, `update:` and `remove:`, plus a state delegate. Offline data loads first when present. Source: https://lbsyun.baidu.com/docs/ios?title=iossdk/guide/create-map/offlinemap. **Confirmed.**

### Coordinates

- The map SDK uses **BD-09LL** by default. `[BMKMapManager setCoordinateTypeUsedInBaiduMapSDK:BMK_COORDTYPE_COMMON]` switches the whole app to GCJ-02. WGS-84 (`BMK_COORDTYPE_GPS`) **cannot** be set globally. Sources: https://lbsyun.baidu.com/docs/ios?title=iossdk/guide/tool/coordinate and https://mapopen-pub-iossdk.bj.bcebos.com/map/v_7_2_0/docs/html/interface_b_m_k_map_manager.html. **Confirmed.**
- An on-device converter, `BMKCoordTrans` (in `BaiduMapAPI_Utils`), supports **WGS84 → BD09LL**, GCJ02 → BD09LL and BD09LL → GCJ02. Baidu warns against unofficial conversion methods. Source: https://lbsyun.baidu.com/docs/ios?title=iossdk/guide/tool/coordinate. **Confirmed.**

### Account and key

- A Baidu account is required. The AK (access key) is tied to the app's bundle identifier. Source: https://lbsyun.baidu.com/faq/api?title=iossdk/guide/create-project/ak. **Confirmed.**
- The SDK starts with `BMKMapManager` `start:generalDelegate:` (manager reference above). **Confirmed.**
- Whether a mainland phone number or real-name verification is required is **unconfirmed**. Baidu's verification FAQ (`index.php?title=FAQ/authentication`) redirected to an error page.

### Privacy compliance APIs

- `+[BMKMapManager setAgreePrivacy:]` was added in 6.5.1 and defaults to not agreed. Until it is set, search objects (`BMKSearchBase` subclasses) return nil. Map display and overlays are not affected. Sources: https://lbsyun.baidu.com/docs/ios?title=iossdk/guide/create-project/attention and https://lbsyun.baidu.com/docs/ios?title=iossdk/guide/create-project/oc. **Confirmed.**
- Privacy manifests ship per module (download page). **Confirmed.**

### Pricing

- Android and iOS map SDKs have **no daily quota**. Source: https://lbsyun.baidu.com/faq/details?id=2294&title=2597. **Confirmed.**
- Commercial use that brings revenue, directly or indirectly, needs the "technical service authorization". It was renamed from "commercial authorization" on 2026-07-03. It costs **¥50,000/year** (Basic) or **¥100,000/year** (Premium), for 372 days. **Only companies can apply; individuals are not supported.** Source: https://lbsyun.baidu.com/cashier/auth. **Confirmed.**
- Whether a free, ad-free app by an individual counts as commercial is **unconfirmed**. The page ties the requirement to revenue.

### Coverage and legality in mainland China

Baidu is a domestic provider with full mainland coverage, and its English map covers 346 Chinese cities (englishmap page above). Whether and how the SDK shows the map review number is **unconfirmed**.

---

## 3. Mapbox Maps SDK for iOS (v11)

### Version and install

- Latest stable: **11.32.0, 2026-10-02**. 11.33.0-rc.1 came out 2026-10-07. Patch lines 11.30.5 and 11.29.4 are also maintained. Source: https://github.com/mapbox/mapbox-maps-ios/releases. **Confirmed.**
- **SPM** is recommended. Use `https://github.com/mapbox/mapbox-maps-ios.git` for source, or `mapbox-maps-ios-binary.git` for prebuilt xcframeworks (11.20.0+). CocoaPods `MapboxMaps` 11.32.0 is also published. A direct download of four xcframeworks is available after signing in. **Mapbox ends CocoaPods support in December 2026.** A public token goes in Info.plist as `MBXAccessToken`. Source: https://docs.mapbox.com/ios/maps/guides/install/. **Confirmed.**
- Requirements: iOS 14+, Xcode 16 minimum (26.4 recommended), Swift 5.9+. Source: https://docs.mapbox.com/ios/maps/guides/. **Confirmed.**
- `Package.swift` at tag 11.32.0 depends on `mapbox-common-ios` 24.32.0, `mapbox-core-maps-ios` 11.32.0 (a binary xcframework from `api.mapbox.com/downloads/v2/mobile-maps-core/…`) and `turf-swift` 4.0.0. It bundles `PrivacyInfo.xcprivacy`. Source: https://github.com/mapbox/mapbox-maps-ios/blob/11.32.0/Package.swift. **Confirmed.**
- **arm64 Simulator slice**: **yes.** `MapboxCoreMaps.xcframework` 11.32.0 contains `ios-arm64`, `ios-arm64_x86_64-simulator`, `ios-arm64_x86_64-maccatalyst` and visionOS slices. This was read from the archive's file directory at https://api.mapbox.com/downloads/v2/mobile-maps-core/releases/ios/packages/11.32.0/MapboxCoreMaps.xcframework-dynamic.zip. **Confirmed.**

### API similarity to MKMapView

Mapbox's API differs most from MapKit. It has its own Swift API for both UIKit (`MapView`) and **SwiftUI** (`Map`).

- SwiftUI has `PolygonAnnotation(...).fillColor(...).fillOpacity(...)`, `MapViewAnnotation(coordinate:) { SwiftUI view }`, and `viewport = .overview(geometry:)` for framing. Source: https://docs.mapbox.com/ios/maps/guides/swiftui/. **Confirmed.**
- UIKit has `MapboxMap.camera(for: [CLLocationCoordinate2D], …)` (framing with padding) and `coordinate(for: CGPoint)` (tap-to-coordinate). Source: https://github.com/mapbox/mapbox-maps-ios/blob/main/Sources/MapboxMaps/Foundation/MapboxMap.swift. **Confirmed.**
- Moving the app off `UIViewRepresentable` onto Mapbox's SwiftUI `Map` is possible but means rewriting the overlay and annotation code. **Inferred.**

### Map types, traffic, styles

- Built-in styles: `.streets`, `.outdoors`, `.light`, `.dark`, `.satellite` and `.satelliteStreets` (https://github.com/mapbox/mapbox-maps-ios/blob/main/Sources/MapboxMaps/Style/StyleURI.swift). Standard and Standard Satellite also exist (`Sources/MapboxMaps/Style/Generated/MapStyle+StandardSatellite.swift` in the same repo). **Confirmed.**
- Muted styling: Standard has `theme` (`default`, `faded`, `monochrome`, `custom`), `lightPreset`, label visibility switches, and per-feature colour overrides. Source: https://docs.mapbox.com/map-styles/standard/api/. Full custom styles are made in Mapbox Studio. **Confirmed.**
- Traffic: the `mapbox.mapbox-traffic-v1` vector tileset is added as a layer. Its reference page gives no country coverage list (https://docs.mapbox.com/data/tilesets/reference/mapbox-traffic-v1/). Traffic coverage for Shanghai is **unconfirmed**.

### Labels and language

Label language is set through `SettingsService` with `MapboxCommonSettings.language`, for example `en` or `zh-Hans`. Worldviews include `CN`. Missing translations fall back to the local name. Source: https://docs.mapbox.com/help/dive-deeper/maps-internationalization/. **Confirmed.** English and Simplified Chinese label quality in Shanghai depends on OpenStreetMap-derived data, where a `name_*` field is null when no translation exists (https://docs.mapbox.com/data/tilesets/reference/mapbox-streets-v8/). **Confirmed in general; Shanghai coverage unconfirmed.**

### Offline maps

Offline maps are supported. The cumulative number of unique tile packs cannot exceed **750**. Source: https://docs.mapbox.com/ios/maps/guides/offline/. **Confirmed.** In 11.32.0, `TileStore.loadTileRegion` reports a partly downloaded region as `TileRegionError.partialLoad` (release notes, https://github.com/mapbox/mapbox-maps-ios/releases/tag/11.32.0). **Confirmed.**

### Coordinates

The basemap and SDK use **WGS-84**, so Walkable Shanghai's route data would line up with no conversion. **Inferred**: Mapbox data is OpenStreetMap-based and the SDK documents no China datum. The current docs describe no GCJ-02 converter. An older mapbox.cn "China plugin" page reportedly offered WGS-84 → GCJ-02 conversion. That page could not be loaded, so this is **unconfirmed**.

### Account and key

A Mapbox account and a public access token are needed (install guide above). **Confirmed.** Whether a credit card is required at signup is **unconfirmed**; the pricing page does not say.

### Privacy compliance

A privacy manifest ships in the package (`Package.swift`). Telemetry can be opted out of through the attribution dialog (https://github.com/mapbox/mapbox-maps-ios/blob/main/CHANGELOG.md, entry "Fix telemetry opt-out through attribution dialog"). **Confirmed.** There is no China-specific consent API.

### Pricing

The Maps SDK for mobile is **free up to 25,000 monthly active users**, then $4.00 per 1,000 MAUs up to 125,000. Source: https://www.mapbox.com/pricing. **Confirmed.**

### Mapbox China status in 2025–2026

- On 2026-10-11, `www.mapbox.cn`, `mapbox.cn` and `api.mapbox.cn` **did not resolve** (no A records). The `mapbox.cn` domain itself still has name servers at `hichina.com` (Alibaba Cloud DNS). Checked with `dig` from a non-China network. **Confirmed for that date and network.**
- Current docs.mapbox.com pages for v11 describe no China endpoint, base-URL override, China token or GCJ-02 support. The install, guides, internationalization, styles and offline pages were checked. **Confirmed (absence on the pages read).**
- Mapbox's Streets v8 reference says the `CN` worldview is "not officially approved for use in the PRC". Source: https://docs.mapbox.com/data/tilesets/reference/mapbox-streets-v8/. **Confirmed.**
- Mapbox's public terms (https://www.mapbox.com/legal/tos, https://www.mapbox.com/legal/product-terms, https://www.mapbox.com/legal/service-terms) contain no China clause. **Confirmed (absence).**
- An official Mapbox announcement that mapbox.cn was discontinued was **not found**. The conclusion that **no China product is available today** is **inferred** from the dead hostnames and the docs' silence.

### Coverage and legality in mainland China

The PRC Map Management Regulation (State Council Order 664, effective 2016-01-01) is at https://www.gov.cn/zhengce/content/2015-12/14/content_10403.htm. Whether it has been revised since was not checked. **Confirmed.** It requires:

- review of maps shown to the public (Art. 15);
- a visible review number on approved maps (Art. 22);
- surveying qualifications for providers of location and map services (Art. 33);
- internet map data servers located inside the PRC (Art. 34);
- user consent for collecting personal data (Art. 35).

Mapbox's global service meets none of these as documented. Whether `api.mapbox.com` loads reliably from mainland networks is **unconfirmed** and needs testing there.

---

## Comparison

| | Tencent (QMapKit) | Baidu (BMKMapView) | Mapbox v11 |
|---|---|---|---|
| Current version | 6.15.0 (2026-10-08) | 7.2.0 (2026-07-27) | 11.32.0 (2026-10-02) |
| SPM | No | No | Yes (source or binary) |
| CocoaPods | Yes (`-XC` xcframework pods) | Yes, but pod excludes arm64 sim | Yes, until Dec 2026 |
| Manual xcframework | Zip download (format of 6.15.0 zip unconfirmed) | Yes, 7.2.0.1, base map only | Yes (sign-in) |
| arm64 Simulator | Yes (XC pods, verified in archive) | Yes in XCFramework zip (changelog); no via pod | Yes (verified in archive) |
| MKMapView-like API | Very close (Obj-C) | Very close (Obj-C) | Different; native SwiftUI |
| Standard / satellite / traffic | Yes / yes / yes | Yes / yes / yes | Yes / yes / traffic tileset, China coverage unconfirmed |
| Muted / custom style | Console templates; built-in dark | `.sty` styles; no built-in dark | Standard `faded`/`monochrome` themes; Studio |
| English labels in Shanghai | Not documented (overseas only) | Yes, paid add-on, needs application, no custom style | Yes (`en`), OSM-based quality |
| Offline | Per city | Per city | Tile regions, 750-pack cap |
| Datum | GCJ-02 | BD-09 default, GCJ-02 optional | WGS-84 |
| WGS-84 converter | WebService API only (6,000/day personal) | On device (`BMKCoordTrans`) | Not needed |
| Account | QQ/WeChat/phone; WeChat binding required | Baidu account; AK bound to bundle ID | Mapbox account + token |
| Privacy API | `setPrivacyAgreement:` (map is nil until set) | `setAgreePrivacy:` (search nil until set) | Telemetry opt-out; privacy manifest |
| Cost for small free app | Free for non-commercial; companies ¥50k/yr | Map SDK no quota; commercial ¥50k/yr, companies only | Free ≤ 25k MAU |
| Legal for mainland display | Licensed domestic provider; review-number API | Licensed domestic provider | Not approved; no China product found |

---

## Fit for Walkable Shanghai

**Tencent.** Tencent fits best for a reliable mainland basemap with minimal code change. `QMapView` mirrors `MKMapView` almost method for method: annotation and overlay views, `setVisibleMapRect:edgePadding:animated:`, `didTapAtCoordinate:`. The XC pods ship a verified arm64 simulator slice, and the SDK has standard, satellite, dark and traffic layers plus offline city packs. There are three costs. First, it would bring CocoaPods into the project just as trunk freezes, or a manual zip whose layout was not checked. Second, the WGS-84 route data must be converted to GCJ-02 ahead of time, because Tencent has no on-device converter and its WebService converter is rate-limited. Third, English labels for Shanghai are not documented, which conflicts with the English and Chinese label requirement. Before committing, confirm that a free app by an individual counts as "non-commercial", and confirm the WeChat and real-name signup path.

**Baidu.** Baidu covers every feature on the list: standard, satellite, traffic, styles, offline, English labels and an on-device WGS-84 → BD-09 converter. Its API is equally close to MapKit. The drawbacks are many. Only the manual 7.2.0.1 XCFramework has an arm64 simulator slice; the CocoaPods route forces an x86_64 simulator. That XCFramework is base map only. English labels are a paid add-on that needs an application and cannot be combined with the custom muted style. Commercial authorization is open only to companies. Every coordinate goes through BD-09, a datum used only by Baidu. Baidu is the fallback if English labels must come from a domestic provider and the paid English map is affordable.

**Mapbox.** Mapbox is the easiest to integrate: SPM, a verified arm64 simulator slice, native SwiftUI, WGS-84 data that matches the routes, a `faded`/`monochrome` theme for the muted look, English and Simplified Chinese labels, and a free tier of 25,000 MAU. It fails the core requirement. No Mapbox China product could be found in 2026 (the mapbox.cn hosts do not resolve). Mapbox says its CN worldview is not approved in the PRC. PRC rules require map servers inside China and an approved review number, so reliable and lawful display to users in mainland China cannot be assumed. Mapbox is suitable only if the app accepts an unapproved basemap that may load slowly or not at all in mainland China. It is not suitable as the primary basemap for Walkable Shanghai.
