# AMap (高德) iOS 3D Map SDK as a MapKit replacement

Research date: 2026-10-11. Sources are AMap's own pages (lbs.amap.com, a.amap.com API reference), AMap's podspecs in the CocoaPods trunk, and AMap's GitHub organisation. Each claim carries its URL. **Unconfirmed** marks anything no primary source states outright. **Inferred** marks a conclusion drawn from a primary source that does not say it in so many words. **Observed locally** marks facts read from this Mac.

Terms used below:

- **GCJ-02**: the obfuscated coordinate system that Chinese law requires for published maps. AMap tiles, overlays and callbacks all use it.
- **WGS-84**: the GPS coordinate system. Walkable Shanghai's route data uses it.
- **Simulator slice**: the part of a binary framework built for the iOS Simulator. Apple Silicon simulators need an `arm64` simulator slice. An `x86_64` slice runs only under Rosetta (Apple's Intel translation layer).

## 1. Installation

### Latest version

| Component | Version | Date | Source |
|---|---|---|---|
| 3D Map SDK (`MAMapKit`) | **V11.3.100** | 2026-09-22 | Changelog: https://lbs.amap.com/api/ios-sdk/changelog/3d ; download page: https://lbs.amap.com/api/ios-sdk/download/ |
| Foundation SDK (`AMapFoundationKit`, required) | V1.9.4 (IDFA and NO-IDFA builds) | 2026-09-22 | https://lbs.amap.com/api/ios-sdk/changelog/foundation |
| Search SDK (optional) | V9.8.1 | — | https://lbs.amap.com/api/ios-sdk/download/ |

The 3D map zip is `https://a.amap.com/lbs/static/zip/AMap_iOS_3DMap_Lib_V11.3.100.zip`, 79,993,950 bytes, `Last-Modified: 22 Sep 2026` (HTTP HEAD request, not downloaded). The online API reference still reports V11.2.000 (https://a.amap.com/lbs/static/unzip/iOS_Map_Doc/AMap_iOS_API_Doc_3D/index.html).

The old changelog URL https://lbs.amap.com/api/ios-sdk/changelog stops at V9.7.0 (last updated 2023-05-29). The current changelog lives at `/changelog/3d`.

### Swift Package Manager

AMap publishes no Swift package. No AMap page mentions SPM. The `amap-demo` GitHub organisation (https://github.com/amap-demo) has no `Package.swift` (GitHub code search, 0 results). Its iOS demo repositories were last pushed in 2017–2020.

### CocoaPods

Pod names (https://lbs.amap.com/api/ios-sdk/guide/create-project/cocoapods, page dated 2024-03-18): `AMap3DMap` / `AMap3DMap-NO-IDFA`, `AMapSearch` / `AMapSearch-NO-IDFA`, `AMapLocation` / `AMapLocation-NO-IDFA`, `AMapNavi` / `AMapNavi-NO-IDFA` (navigation includes the 3D map). `AMapFoundation` comes in as a dependency.

**The CocoaPods route is stale for the map itself.** The CocoaPods trunk API shows:

| Pod | Latest on trunk | Published | Source |
|---|---|---|---|
| `AMap3DMap` | 9.7.0 | 2023-05-30 | https://trunk.cocoapods.org/api/v1/pods/AMap3DMap |
| `AMap3DMap-NO-IDFA` | 9.7.0 | 2023-05-30 | https://trunk.cocoapods.org/api/v1/pods/AMap3DMap-NO-IDFA |
| `AMapFoundation` | 1.9.1 | 2026-08-10 | https://trunk.cocoapods.org/api/v1/pods/AMapFoundation |
| `AMapSearch` | 9.8.1 | 2026-08-10 | https://trunk.cocoapods.org/api/v1/pods/AMapSearch |

The 10.x and 11.x map SDKs (2024–2026) exist only as manual downloads. The project has no CocoaPods anyway, so this changes little.

### Manual install

From https://lbs.amap.com/api/ios-sdk/guide/create-project/manual-configuration (page dated 2021-01-22):

- Add `MAMapKit.framework` and `AMapFoundationKit.framework`.
- Copy `AMap.bundle` out of `MAMapKit.framework` into the app as a resource.
- Add `-ObjC` to Other Linker Flags.
- Link the system libraries. The 9.7.0 podspec lists QuartzCore, CoreLocation, SystemConfiguration, CoreTelephony, Security, OpenGLES, CoreText, CoreGraphics, GLKit, plus `libz` and `libc++` (https://raw.githubusercontent.com/CocoaPods/Specs/master/Specs/5/f/c/AMap3DMap/9.7.0/AMap3DMap.podspec.json).

The guide and every podspec ship `.framework` bundles, not `.xcframework`. Whether the V11.3.100 zip contains `.framework` or `.xcframework` is **unconfirmed**: the zip was not downloaded.

Privacy manifests (`MAMapKit.xcprivacy`, `AMapFoundationKit-NO-IDFA.xcprivacy`) are separate downloads on the download page, dated 2024-3-27 (https://lbs.amap.com/api/ios-sdk/download/). The frameworks may therefore not carry their own manifests (**unconfirmed**).

### arm64 iOS Simulator slice: probably absent

**Inferred: the current SDK has no arm64 simulator slice.** Evidence:

1. Every recent `AMapFoundation` podspec (1.8.2, 1.8.6, 1.9.0, 1.9.1, the last published 2026-08-10) sets `"EXCLUDED_ARCHS[sdk=iphonesimulator*]": "arm64"` on both the pod and the user target (https://raw.githubusercontent.com/CocoaPods/Specs/master/Specs/8/f/f/AMapFoundation/1.9.1/AMapFoundation.podspec.json). AMap would only exclude arm64 for simulator builds if the binary lacked that slice. A single fat `.framework` cannot hold both arm64-device and arm64-simulator code.
2. The 3D map V11.2.000 changelog entry (2026-06-01) reads "恢复支持苹果x86_64模拟器" ("restored support for the Apple x86_64 simulator") (https://lbs.amap.com/api/ios-sdk/changelog/3d). The changelog never mentions an arm64 simulator.
3. No AMap page mentions Apple Silicon, M1, or arm64 simulators (the iOS map FAQ index at https://lbs.amap.com/faq/ios/ios-map has no such entry).

What this means on this Mac (**observed locally**, Xcode 26.6 build 17F113, arm64, Rosetta installed, via `xcrun simctl list runtimes -j`):

- The installed **iOS 18.6** simulator runtime supports `x86_64` and `arm64`. An x86_64-only SDK can run there under Rosetta.
- The installed **iOS 26.5** simulator runtime supports **`arm64` only**. An x86_64-only SDK cannot run on it. Running on iOS 26 would need the universal runtime variant (for example `xcodebuild -downloadPlatform iOS -architectureVariant universal`). Whether Xcode 26.6 still offers that variant for 26.5 is **unconfirmed**.
- Every simulator build and UI test would then be an x86_64 build under Rosetta: slower, and dependent on Rosetta. Apple has announced that Rosetta is being phased out after macOS 27; that date is not from an AMap source.

To settle this, download the zip (about 80 MB, needs the user's approval) and run `lipo -info MAMapKit.framework/MAMapKit` or list the `.xcframework` slice folders.

## 2. API shape

MAMapView mirrors MKMapView closely. Most MapKit names have an `MA` twin. Sources: API reference (Doxygen, V11.2.000) at https://a.amap.com/lbs/static/unzip/iOS_Map_Doc/AMap_iOS_API_Doc_3D/ , class pages `interface_m_a_map_view.html`, `protocol_m_a_map_view_delegate-p.html`, `interface_m_a_overlay_path_renderer.html`, `interface_m_a_polyline_renderer.html`, `interface_m_a_polygon_renderer.html`.

| Walkable Shanghai uses (MapKit) | AMap equivalent | Notes |
|---|---|---|
| `MKMapView`, `MKMapViewDelegate` | `MAMapView`, `MAMapViewDelegate` | Delegate has `mapView:rendererForOverlay:`, `mapView:viewForAnnotation:`, `mapView:didSelectAnnotationView:`, `mapView:regionDidChangeAnimated:`, `mapInitComplete:` |
| `MKPolyline` + `MKPolylineRenderer` | `MAPolyline` + `MAPolylineRenderer` | `strokeColor`, `lineWidth`, `lineJoinType` (`kMALineJoinRound`…), `lineCapType` (`kMALineCapRound`…), `alpha`, `strokeImage` (texture) |
| `lineDashPattern = [2, 6]` / `[1, 5]` | `lineDashType` (since 5.5.0) | **Only three values: `kMALineDashTypeNone`, `kMALineDashTypeSquare`, `kMALineDashTypeDot`.** No custom dash lengths. A texture through `strokeImage` might imitate a pattern (**unconfirmed**). |
| `MKPolygon` + `MKPolygonRenderer` (translucent wash) | `MAPolygon` + `MAPolygonRenderer` | `fillColor`, `strokeColor`, `lineWidth`. Holes supported since 5.5.0 (changelog). |
| Three `MKAnnotationView` subclasses | Subclass `MAAnnotationView` | `centerOffset`, `canShowCallout`, `dequeueReusableAnnotationViewWithIdentifier:` (https://lbs.amap.com/api/ios-sdk/guide/draw-on-map/draw-marker). Whether a `register(_:forAnnotationViewWithReuseIdentifier:)` equivalent exists is **unconfirmed**. Use the dequeue-or-create pattern. |
| `setVisibleMapRect(_:edgePadding:animated:)` | `setVisibleMapRect:edgePadding:animated:` (also a `duration:` variant) | Takes `MAMapRect`. Build it with `MAMapPointForCoordinate` and `MAMapRectForCoordinateRegion` (method-interaction guide). There is also `showAnnotations:edgePadding:animated:` (SDK summary page). |
| `convert(_:toCoordinateFrom:)` | `convertPoint:toCoordinateFromView:` | Returns a **GCJ-02** coordinate. A built-in `mapView:didSingleTappedAtCoordinate:` delegate callback can replace the custom tap gesture. |
| `showsUserLocation` | `showsUserLocation` | Same name. A custom blue dot is set through `MAUserLocationRepresentation`. |
| `setRegion`, `setCenter` | `setRegion:animated:`, `setCenterCoordinate:animated:`, `setZoomLevel:animated:` (zoom 3–19) | https://lbs.amap.com/api/ios-sdk/guide/interaction-with-map/method-interaction |
| `isRotateEnabled`, `isPitchEnabled`, `showsCompass`, `showsScale` | Present under the same or similar names (gesture-interaction and control-interaction guides) | Exact Swift spellings **unconfirmed**. Check the headers. |
| `MKStandardMapConfiguration(emphasisStyle: .muted)`, `pointOfInterestFilter = .excludingAll` | No equivalent. Use a custom style (section 3). `showsLabels`, `showsBuildings`, `touchPOIEnabled` exist on MAMapView. | |

Other differences:

- **Rendering engine.** MAMapView renders with OpenGL ES by default. `metalEnabled` exists but defaults to NO (MAMapView reference). The podspec links OpenGLES and GLKit. Apple deprecated OpenGL ES in iOS 12.
- **SwiftUI.** AMap has no SwiftUI view. Keep the existing `UIViewRepresentable` pattern. AMap's Swift guide (https://lbs.amap.com/api/ios-sdk/guide/map-tool/swift) dates from 2021-01-22, targets Swift 2.2, and uses a bridging header. The Foundation changelog says modules were enabled "方便swift引入" ("for easier Swift import") from V1.4.3 onward (https://lbs.amap.com/api/ios-sdk/changelog/foundation). Whether `import MAMapKit` works without a bridging header is **unconfirmed**. The show-map guide still tells Swift users to import through the bridging header (https://lbs.amap.com/api/ios-sdk/guide/create-map/show-map).
- **Privacy calls.** MAMapView returns nil unless the privacy calls in section 7 run first.

## 3. Map types, traffic, custom styles

Map types in V11.2.000 (enum list in the API reference: https://a.amap.com/lbs/static/unzip/iOS_Map_Doc/AMap_iOS_API_Doc_3D/globals_eval.html):

- `MAMapTypeStandard`
- `MAMapTypeSatellite`
- `MAMapTypeStandardNight` (dark)
- `MAMapTypeNavi`
- `MAMapTypeNaviNight`
- `MAMapTypeBus`

The guide at https://lbs.amap.com/api/ios-sdk/guide/create-map/set-maptype lists the first four.

Traffic: `mapView.showTraffic` (Swift `isShowTraffic` in the guide), same page.

**No built-in muted mode.** To get a neutral look you need a custom style (自定义地图). Source: https://lbs.amap.com/api/ios-sdk/guide/create-map/custom (page dated 2026-10-11).

- Build the style in AMap's web style editor. Publish it, download the iOS offline files (`style.data`, `style_extra.data`, `textures.zip`), and apply them with `setCustomMapStyleOptions:` plus `customMapStyleEnabled = YES`.
- Style files are tied to SDK versions. V7.0.0 broke older styles (changelog).
- A custom style overrides `mapType` (MAMapView reference, `mapType`).
- Online styles (by style ID) and textures "需要开通相关权限" ("require enabling the relevant permission").

Pricing for custom styles (https://lbs.amap.com/home/package?active=mapstyle):

| Tier | Price | Styles | Mobile SDK features |
|---|---|---|---|
| 免费版 (Free) | ¥0/month | 1 | Offline style files only. No online loading, no textures. |
| 专业版 (Pro) | ¥399/month | 20 | Adds online loading and textures |
| 旗舰版 (Flagship) | Contact sales | 30 | Adds 3D models |

So **one muted style is free if bundled as files.** Light and dark muted styles together would take two styles, which means the Pro tier. The other option is `MAMapTypeStandardNight` for dark mode, which you cannot restyle without a second style (**inferred**).

## 4. English labels

There are two APIs.

1. **`mapLanguage`** (NSNumber; `@0` Chinese, `@1` English). The MAMapView reference says English "不能和自定义地图样式同时使用" (**cannot be used together with a custom map style**) and works "只在MAMapTypeStandard生效" (**only with MAMapTypeStandard**) (https://a.amap.com/lbs/static/unzip/iOS_Map_Doc/AMap_iOS_API_Doc_3D/interface_m_a_map_view.html). Chinese/English switching for the domestic map arrived in V5.6.0 (changelog). There is no `MAMapLanguage` enum. The property is a plain NSNumber.
2. **`regionLanguageType`** (multi-language, V11.1.000+). In V11.2.000 it moved from `MAMapView.regionLanguageType` to `[AMapServices sharedServices].regionLanguageType` (type `AMapRegionLanguageType`, e.g. `AMapRegionLanguageTypeEnglish`) (changelog: https://lbs.amap.com/api/ios-sdk/changelog/3d ; Foundation reference: https://a.amap.com/lbs/static/unzip/iOS_Map_Doc/AMap_iOS_API_Doc_Foundation/interface_a_map_services.html). The world-map guide lists 17 codes: 0 简体中文, 1 繁体中文, 2 English, 3 Spanish, 4 Portuguese, 5 French, 6 German, 7 Thai, 8 Japanese, 9 Korean, 10 Turkish, 11 Hebrew, 12 Italian, 13 Russian, 14 Malay, 15 Indonesian, 16 Vietnamese (https://lbs.amap.com/api/ios-sdk/guide/create-map/world-map). Related additions: V11.1.200 made the scale bar multilingual with imperial units, and V11.2.100 added a switch for showing POIs in their local language (changelog).

**Unconfirmed:**

- Whether `regionLanguageType` English needs the paid world-map service. The guide puts "切换英文地图" ("switch to English map") on the world-map page, which says "世界地图相关服务为高级服务" ("world map services are an advanced service").
- Whether `regionLanguageType` can be combined with a custom style.
- How complete English labelling is for Shanghai streets and POIs. No AMap page states coverage.

**The documented rule blocks the app's current design.** It needs both a muted look and English labels, and `mapLanguage` English cannot combine with a custom style.

## 5. Offline maps

The 3D SDK still has `MAOfflineMap` and the drop-in `MAOfflineMapViewController`. Items include `MAOfflineItemMunicipality` (直辖市, municipalities; Shanghai is one) (https://lbs.amap.com/api/ios-sdk/guide/create-map/use-offlinemap, page dated 2026-09-24).

For current SDK versions, though, offline maps are paid. The guide says: "11.0 及以上版本的离线地图属于高阶服务，如需使用请联系商务咨询" ("offline maps in 11.0 and later are an advanced service; contact business consulting"). The changelog shows V11.1.000 "暂不支持离线地图功能" ("offline maps not supported for now"), then V11.1.200 (2026-04-24) "离线地图下载" ("offline map download").

Shanghai downloads are **inferred** from the municipality class and **unconfirmed** for 11.x without the paid service. V9.7.0 (2023) probably has free offline maps (**unconfirmed**), but it predates the multi-language engine.

## 6. Coordinates (GCJ-02)

- **WGS-84 → GCJ-02: provided.** Use `AMapCoordinateConvert(coordinate, AMapCoordinateTypeGPS)` in AMapFoundationKit. It "转换目标经纬度为高德坐标系，不在枚举范围内的经纬度将直接返回" ("converts to AMap coordinates; coordinates outside the enum range are returned unchanged") (https://a.amap.com/lbs/static/unzip/iOS_Map_Doc/AMap_iOS_API_Doc_Foundation/_a_map_utility_8h.html ; guide: https://lbs.amap.com/api/ios-sdk/guide/computing-equipment/amap-calculate-tool). Since Foundation V1.2.0 it only converts points where `AMapDataAvailableForCoordinate` returns YES, meaning points inside China (Foundation changelog).
- **GCJ-02 → WGS-84: not provided.** The only conversion function targets the AMap system. This matters for build mode: `convertPoint:toCoordinateFromView:` and `didSingleTappedAtCoordinate` return GCJ-02, and the app stores WGS-84, so the app needs its own approximate inverse. The usual method is iterating the forward transform, accurate to about 1 m (**unconfirmed**; this is common practice, not an AMap source).
- **Offset if WGS-84 is drawn unconverted.** No AMap page states it. **Computed** with the widely published GCJ-02 forward formula: at People's Square, the Bund, Xujiahui, Lujiazui and Hongqiao, the GCJ-02 point sits about 420–440 m east and 210–225 m south of the WGS-84 input, about **480 m** in total. Unconverted routes would therefore draw roughly 480 m to the north-west of the streets they follow, about four or five city blocks.

## 7. Account, key, privacy compliance

**Key.** In the console, create an app, add a key for the "iOS平台SDK" service, and enter the Bundle ID. "1个KEY只能用于一个应用" ("one key works for one app only") (https://lbs.amap.com/api/ios-sdk/guide/create-project/get-key, page dated 2026-10-11). Set it with `AMapServices.shared().apiKey = "…"` before using the SDK (https://lbs.amap.com/api/ios-sdk/guide/create-project/note).

**Verification.** Developer verification is a condition of service. Terms 4.8: "您使用本服务需要注册账号，并且应当根据平台网站提示完成相应的开发者认证，这是您使用本服务的前提" ("you must register and complete developer verification; this is a precondition of the service") (https://lbs.amap.com/pages/terms/, updated 2025-12-03).

- Individuals: terms 8.4(7) say the platform collects "姓名、身份证号" (name, ID card number) and passes them to **Alipay**, which verifies identity "根据您的人像信息" (by face/portrait) (same URL).
- Since 2021, unverified individuals cannot create new keys or buy quota (https://lbs.amap.com/news/developer-certify).
- Individual verification collects name, phone and email (https://lbs.amap.com/faq/account/certification/39670).
- Enterprises verify with a business license (营业执照) and unified social credit code (terms 8.5), and must register with a company phone number (terms 4.8.2).

**Unconfirmed:** whether a non-mainland phone number, a passport, or a non-mainland Alipay account can complete individual verification. No AMap page mentions foreign nationals, 港澳台 (Hong Kong, Macao, Taiwan) documents, or passports (checked: terms, https://lbs.amap.com/pages/Account-authentication-protocol, https://lbs.amap.com/faq/account/certification/40594). **Inferred:** in practice it needs a mainland ID card and Alipay.

**Privacy compliance.** These calls became mandatory in V8.1.0 (changelog; https://lbs.amap.com/api/ios-sdk/guide/create-project/note):

```swift
MAMapView.updatePrivacyShow(.didShow, privacyInfo: .didContain)
MAMapView.updatePrivacyAgree(.didAgree)
```

(The doc shows Objective-C, `AMapPrivacyShowStatusDidShow` etc. The Swift spellings above are **unconfirmed**.)

- **When:** before constructing `MAMapView`, `MAOfflineMap`, `MAOfflineMapViewController` or `MATraceManager`. The app must first show the user a privacy prompt that includes AMap's SDK privacy terms and get consent. "否则MAMapView构造失败返回nil" ("otherwise MAMapView construction fails and returns nil").
- Search has its own pair on `AMapSearchAPI`.
- Foundation 1.8.7 added `AMapServices.securityAgree` (default YES) (Foundation reference).

**IDFA.** Use the NO-IDFA Foundation build. The download page offers `AMap_iOS_Foundation_NO_IDFA_Lib_V1.9.4.zip`, and https://lbs.amap.com/api/ios-sdk/guide/create-project/idfa-guide covers App Store answers if the IDFA build is kept. Foundation also uploads crash logs by default (`crashReportEnabled`, default YES) through `NSUncaughtExceptionHandler` (Foundation reference).

## 8. Pricing, quota, terms for global App Store distribution

**Territory.** Terms clause 14.1: "本服务原则上仅面向中华人民共和国大陆地区且服务器在中国大陆地区的开发者提供，且仅面向中华人民共和国大陆地区的最终用户" ("the service is in principle offered only to developers in mainland China with servers in mainland China, and only to end users in mainland China"). The same clause covers use outside the mainland without prior written permission, at the developer's risk (https://lbs.amap.com/pages/terms/). An app on non-China App Store storefronts, used by foreign tourists, sits outside this scope unless AMap gives written permission.

**License.** The iOS SDK overview (https://lbs.amap.com/api/ios-sdk/summary, updated 2025-12-03) states:

- Organisations must buy a 技术服务许可 (technical service license).
- "若您未购买技术服务许可，平台向您提供的KEY和服务配额仅供您用于短期、少量的测试目的" ("without a license, keys and quota are only for short-term, small-scale testing").
- Exceeding that is unlicensed use. The examples given include "您的应用在应用程序分发平台上架或已经可以被公众获取使用" ("your app is listed on an app distribution platform or publicly available") and an app that earns money or shows ads.

**Individual developers.** Terms 3.1 grant a free monthly quota to individuals using the service "以个人研究学习目的" ("for personal research and study"). Terms 3.2.1 defines commercial purpose broadly, including charging users and any direct or indirect benefit, and requires a license. Terms 3.2.5 lets organisations file a ticket for non-commercial evaluation. **Unconfirmed:** whether a free, ad-free App Store app by an individual counts as "personal study". The overview's wording suggests public App Store listing needs a license.

**Prices** (https://lbs.amap.com/upgrade):

- Technical service license: 基础版 (Basic) ¥50,000 per year (372 days); 高级版 (Advanced) listed at ¥100,000 / contact sales. The column-to-tier mapping on the page is ambiguous.
- Free monthly quota for verified individuals lasts one year from verification, for non-commercial use.
- "基础地图定位服务" ("basic map and location service") is listed at ¥3 per 10,000 calls, with a monthly quota of 1,500,000 for verified individuals. That item names JS map initialisation and online location. **Unconfirmed:** whether native iOS map loads count against it.

**Attribution.** Terms 7.7 forbid removing or hiding the 审图号 (map approval number) and copyright marks, and require showing that the map comes from "高德地图".

**Overseas option.** MAMapView has `logoEnable` and `logoLanguage` that apply to an "海外包" ("overseas package"), and V11.3.100 added switching between domestic and overseas domains. AMap also markets a 世界地图 (world map) service at https://lbs.amap.com/solution/abroad. Who may use the overseas package, and whether it covers mainland China for foreign developers, is **unconfirmed**: the page renders no details without JavaScript, and the world map is an "高级服务" ("advanced service") sold through sales.

## 9. Known issues: Xcode 16+, iOS 18+/26, Swift 6, simulator

- **Simulator.** See section 1: probably x86_64 only (inferred). The x86_64 simulator was missing for at least part of 11.x until V11.2.000 restored it. The installed iOS 26.5 runtime here is arm64-only (observed locally).
- **iOS 26 / Xcode 26.** No changelog entry from V10.0.600 (2024-03) to V11.3.100 (2026-09) mentions iOS 18, iOS 26, Xcode 16 or Xcode 26. Most entries say only "修复已知问题" ("fixed known issues"). The API reference is generated by Doxygen 1.9.1 and the overview page still says iOS 8.0+. **Unconfirmed** whether the SDK is tested against iOS 26.
- **Swift 6 strict concurrency.** The project builds with `SWIFT_VERSION = 6.0` (observed in `WalkableShanghai.xcodeproj`). AMap documents nothing about Swift concurrency. Whether its Objective-C headers mark `MAMapView` and its delegate as main-actor-isolated (`NS_SWIFT_UI_ACTOR`) is **unconfirmed**. If they do not, the coordinator likely needs `@preconcurrency` conformance to `MAMapViewDelegate`, plus `MainActor.assumeIsolated` in callbacks.
- **Privacy manifest.** Shipped as separate `.xcprivacy` files (download page). You must add them to the app yourself if the frameworks lack them (**unconfirmed** which applies).
- **Mixing 2D and 3D.** Do not put 2D and 3D map SDKs in one project (download page, CocoaPods guide).

The AMap FAQ pages on CocoaPods updates (`/faq/ios/map-sdk/create-project/46710`) and the overseas map FAQ (`/faq/overseas/map`) were not read for this note.

## Fit for Walkable Shanghai

**Integration effort.** The current wrapper (`WalkableShanghai/Sources/Features/Map/RouteMapView.swift`, 624 lines, one `UIViewRepresentable` with a coordinator, `RoutePolyline`, `BasemapGradeOverlay`, `RoutePinView`, `WalkerView`, `DraftPointView`) maps almost one-to-one onto MAMapView. Estimate, **unconfirmed** until a spike builds:

- **Port the wrapper (2–4 days).** Rename types (`MKMapRect` → `MAMapRect` and so on), rebuild the three annotation views on `MAAnnotationView`, and use dequeue-or-create in place of `register`.
- **Add a coordinate layer (1 day).** Convert WGS-84 → GCJ-02 for everything drawn and for framing. Write a GCJ-02 → WGS-84 inverse for build-mode taps.
- **Redo the look (1–3 days).** Build one muted custom style in AMap's editor. Replace the `[2, 6]` and `[1, 5]` dashes with `Square` or `Dot` types, or textures (textures need the paid tier). Decide on dark mode.
- **Integrate the build (2–4 days).** Vendor two frameworks, `AMap.bundle`, `-ObjC`, system libraries and privacy manifests through the Python `.pbxproj` generator. Set `EXCLUDED_ARCHS` for simulator arm64. Move simulator runs and UI tests to Rosetta x86_64 destinations on a universal runtime.
- **Add a privacy-consent screen before the first map (½–1 day).**

Total: roughly **1.5–2.5 weeks** of engineering, before the account and legal steps.

**Top risks**, highest first:

1. **Terms and licensing block global distribution.** Clause 14.1 limits the service to mainland developers and mainland end users. The SDK overview says that without a ¥50,000/year technical service license, a key is for short-term testing only, and that listing on an app store exceeds that. Use outside the mainland needs AMap's written permission.
2. **The account may be unobtainable.** Individual verification runs through Alipay with a Chinese ID number and face check. Enterprise verification needs a Chinese business license. No documented path exists for a foreign individual (unconfirmed).
3. **No arm64 simulator slice (inferred).** Development and UI tests would run under Rosetta on an x86_64 build and could not use the installed arm64-only iOS 26.5 runtime. The project would depend on Rosetta, which Apple is phasing out.
4. **Muted style and English labels conflict.** English via `mapLanguage` is documented as incompatible with custom styles. The newer `regionLanguageType` path may sit behind the paid world-map service (unconfirmed). Custom dash patterns are not supported.
5. **Smaller items:**
   - Offline maps are a paid advanced service from 11.0.
   - Free custom styles allow 1 style, offline only.
   - GCJ-02 must be handled both ways, and AMap has no reverse conversion.
   - Rendering defaults to OpenGL ES.
   - Swift 6 concurrency behaviour of the Objective-C headers is unknown.
   - CocoaPods has had no map release since 2023, so every update is a manual download.
