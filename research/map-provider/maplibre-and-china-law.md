# MapLibre Native for iOS, and the legal position of maps in mainland China

Research date: 2026-10-11. Sources are first-party: MapLibre's GitHub repositories and DocC documentation, tile providers' own terms and pricing pages, Chinese law and regulation texts on npc.gov.cn and gov.cn, Apple's developer documentation and feature pages. Each claim carries its URL. Labels used:

- **Unconfirmed**: no primary source states it outright.
- **Inferred**: a conclusion drawn from a primary source that does not say it in so many words.
- **Observed locally**: read from this Mac on 2026-10-11 (DNS lookups, HTTP headers, Overpass queries). The Mac is outside mainland China, so these observations say nothing direct about reachability from inside China.
- **Anecdotal**: a user report (forum post, GitHub issue), not a provider or regulator statement.

Terms used below:

- **GCJ-02**: the obfuscated coordinate system used by maps published in mainland China. Points are shifted from their true position by a non-linear offset.
- **WGS-84**: the coordinate system GPS reports and OpenStreetMap stores. Walkable Shanghai's route data uses it.
- **审图号 (map review number)**: the approval number the Ministry of Natural Resources (MNR, 自然资源部) or a provincial department issues after reviewing a map. It looks like `GS(2026)1234号` for national approvals.
- **互联网地图服务 (internet map service)**: the regulated activity of serving maps over the internet, which covers apps.
- **ICP filing (ICP备案)**: the registration with the Ministry of Industry and Information Technology (MIIT) that websites and apps serving mainland China need.
- **Vector tiles**: map data cut into square tiles and drawn on the device, so the app controls the styling and the label language.
- **PMTiles**: a single-file archive of map tiles that can be read over HTTP range requests or from local disk, with no tile server.

---

# Part 1 — MapLibre Native for iOS

## 1. Installation

### Swift Package

MapLibre's getting-started guide installs the package from `https://github.com/maplibre/maplibre-gl-native-distribution` via Xcode's "Add Package Dependencies…", then `import MapLibre` (https://maplibre.org/maplibre-native/ios/latest/documentation/maplibre-native-for-ios/gettingstarted). The distribution repository exists only to ship the binary; issues go to `maplibre/maplibre-native` (https://github.com/maplibre/maplibre-gl-native-distribution).

The package is a `binaryTarget` that downloads `MapLibre.dynamic.xcframework.zip` from the `maplibre-native` releases, with product name `MapLibre` (https://raw.githubusercontent.com/maplibre/maplibre-gl-native-distribution/6.31.0/Package.swift).

**Pin a version tag; do not track `main`.** On 2026-10-11, `main` of the distribution repo points at `ios-v7.0.0-pre-globe.0`, a prerelease (https://raw.githubusercontent.com/maplibre/maplibre-gl-native-distribution/main/Package.swift). Xcode's default "Up to Next Major Version" rule uses tags, so it resolves to 6.31.0, but a branch-based dependency would pick up the prerelease.

### Current version

| Release | Date | Status | Source |
|---|---|---|---|
| **6.31.0** | 2026-09-11 | latest stable | https://github.com/maplibre/maplibre-native/releases/tag/ios-v6.31.0 |
| 6.30.0 | 2026-09-10 | stable | GitHub releases API, `maplibre/maplibre-native` |
| 7.0.0-pre0, 7.0.0-pre1, 7.0.0-pre-globe.0 | 2026-10-05 to 10-08 | prereleases | same |

6.31.0 release notes: removes the `CustomDrawableLayer` API and adds a `semiliteral` expression (https://github.com/maplibre/maplibre-native/releases/tag/ios-v6.31.0). Assets: `MapLibre.dynamic.xcframework.zip`, `MapLibre.static.xcframework.zip`, and a dSYM zip (GitHub releases API).

The `7.0.0-pre1` notes say that build ships only the plugin-enabled XCFramework and is not published to CocoaPods or to `maplibre-gl-native-distribution` (https://github.com/maplibre/maplibre-native/releases/tag/ios-v7.0.0-pre1).

### Minimum iOS and simulator support

| | 6.31.0 (stable) | `main` (7.0 line) |
|---|---|---|
| Minimum iOS | **12.0** | **15.5** |
| Simulator slices | `x86_64` and **`arm64`** | `x86_64` and `arm64` |
| Device slice | `arm64` | `arm64` |
| Source | https://github.com/maplibre/maplibre-native/blob/ios-v6.31.0/platform/ios/BUILD.bazel (both `MapLibre.static` and `MapLibre.dynamic` targets) and `platform/ios/MapLibre.podspec` at the same tag (`s.ios.deployment_target = '12.0'`) | https://github.com/maplibre/maplibre-native/blob/main/platform/ios/BUILD.bazel and `platform/ios/MapLibre.podspec` (`15.5`) |

The `arm64` simulator slice means it runs natively on Apple Silicon simulators without Rosetta. Walkable Shanghai targets iOS 18, so both the 6.x and the coming 7.x minimums are below it.

## 2. API shape

The SDK is UIKit, Objective-C based, with an `MLN` prefix. The main types from the DocC index (https://maplibre.org/maplibre-native/ios/latest/documentation/maplibre/):

| Concern | Types |
|---|---|
| Map | `MLNMapView`, `MLNMapViewDelegate`, `MLNMapCamera`, `MLNUserTrackingMode`, `MLNStyle` |
| Sources | `MLNShapeSource` (GeoJSON / shapes), `MLNVectorTileSource`, `MLNRasterTileSource`, `MLNRasterDEMSource`, `MLNImageSource`, `MLNComputedShapeSource` |
| Style layers | `MLNLineStyleLayer`, `MLNSymbolStyleLayer`, `MLNCircleStyleLayer`, `MLNFillStyleLayer`, `MLNRasterStyleLayer`, `MLNHeatmapStyleLayer`, `MLNHillshadeStyleLayer`, `MLNFillExtrusionStyleLayer`, `MLNBackgroundStyleLayer` |
| Shapes | `MLNPolyline`, `MLNPolylineFeature`, `MLNMultiPolyline`, `MLNPolygon`, `MLNPointAnnotation`, `MLNPointFeature`, `MLNShapeCollectionFeature` |
| Annotations | `MLNAnnotation` protocol, `MLNAnnotationView`, `MLNAnnotationImage`, `MLNUserLocationAnnotationView` |
| Offline | `MLNOfflineStorage`, `MLNOfflinePack`, `MLNTilePyramidOfflineRegion`, `MLNShapeOfflineRegion` |
| Snapshots | `MLNMapSnapshotter`, `MLNMapSnapshotOptions` |

Delegate methods relevant to the four map modes (https://maplibre.org/maplibre-native/ios/latest/documentation/maplibre/mlnmapviewdelegate): `mapView(_:didFinishLoading:)` (style loaded, the place to add sources and layers), `mapView(_:didSelect:)` for annotation taps, `mapView(_:viewFor:)` / `mapView(_:imageFor:)` for custom pins, `mapView(_:strokeColorForShapeAnnotation:)` and `mapView(_:lineWidthForPolylineAnnotation:)` for annotation-style polylines, `mapView(_:didUpdate:)` for the user location, `mapView(_:regionDidChangeWith:animated:)` for camera changes.

There are two ways to draw a route line:

1. **Annotation route**: add an `MLNPolyline` with `mapView.addAnnotation(_:)` and colour it through the delegate. Simple, but one style per line.
2. **Style route** (what MapLibre's own examples use): put the route in an `MLNShapeSource` and draw it with one or more `MLNLineStyleLayer`s. Styling uses `NSExpression`, so a casing line under an accent line, dashes, and a solid "walked" portion are each one layer (https://maplibre.org/maplibre-native/ios/latest/documentation/maplibre-native-for-ios/linestylelayerexample, https://maplibre.org/maplibre-native/ios/latest/documentation/maplibre-native-for-ios/animatedlineexample). This matches the two-pass route line in PLAN.md §4.1 (wide low-opacity ink casing, thin accent line on top).

Tap-to-add-point for the builder mode needs a `UITapGestureRecognizer` on the map view plus `mapView.convert(_:toCoordinateFrom:)`. MapLibre's "LineOnUserTap" example shows the pattern (https://maplibre.org/maplibre-native/ios/latest/documentation/maplibre-native-for-ios/lineonusertap).

### SwiftUI options

- **Wrap it yourself.** MapLibre's guide uses a `UIViewRepresentable` whose `makeUIView` returns an `MLNMapView` (https://maplibre.org/maplibre-native/ios/latest/documentation/maplibre-native-for-ios/gettingstarted). The delegate goes on a `Coordinator`. This is the route PLAN.md's `RouteMapView` wrapper already assumes.
- **MapLibreSwiftUI** (`https://github.com/maplibre/swiftui-dsl`). A declarative SwiftUI layer, moved from Stadia Maps to the MapLibre organisation. Latest release **v0.25.0** (2026-04-07). It is pre-1.0 and says the API is not yet stable. Requires iOS 15 and depends on `maplibre-gl-native-distribution` `from: "6.21.2"`. Goals listed: markers, polylines, gestures, clustering, camera control (https://github.com/maplibre/swiftui-dsl, `Package.swift` and README on `main`).

**Inferred:** with only four map modes behind one wrapper, a hand-written `UIViewRepresentable` keeps the dependency count at one and avoids a pre-1.0 API. MapLibreSwiftUI saves code but adds an unstable dependency.

## 3. Offline packs

`MLNOfflineStorage` is a singleton that manages offline packs and the ambient cache. All its methods are asynchronous because offline resources live in a database (https://maplibre.org/maplibre-native/ios/latest/documentation/maplibre/mlnofflinestorage).

How it works (https://maplibre.org/maplibre-native/ios/latest/documentation/maplibre-native-for-ios/offlinepackexample, https://maplibre.org/maplibre-native/ios/latest/documentation/maplibre/mlntilepyramidofflineregion):

1. Define a region. `MLNTilePyramidOfflineRegion(styleURL:bounds:fromZoomLevel:toZoomLevel:)` takes a style URL, a bounding box and a zoom range. `MLNShapeOfflineRegion` takes a polygon or line instead, which downloads fewer tiles for an irregular area, such as a corridor around one walking route.
2. `MLNOfflineStorage.shared.addPack(for:withContext:completionHandler:)` registers a pack. `context` is arbitrary `Data`, such as the route id.
3. `pack.resume()` starts the download. Progress arrives through `MLNOfflinePackProgressChanged`, errors through `MLNOfflinePackError`. `pack.progress` reports resources and bytes completed.
4. The pack holds tiles, the style, glyphs and sprites. The map then renders the region with no network.

Other storage methods: `removePack`, `invalidatePack`, `setMaximumAmbientCacheSize`, `clearAmbientCache`, and `addContentsOfFile:` / `addContentsOfURL:` to merge a pre-built offline database (https://maplibre.org/maplibre-native/ios/latest/documentation/maplibre/mlnofflinestorage). The documentation warns that tile count grows exponentially with the top zoom level and suggests a prepared bundle for large areas.

`MLNOfflinePackMaximumMapboxTilesReached` is described in MapLibre's own example as "a historical artifact"; your tile provider may not limit tile counts.

**PMTiles exception.** Since MapLibre iOS 6.10.0, a source URL prefixed `pmtiles://https://…` or `pmtiles://file://…` reads a PMTiles archive, including one shipped in the app bundle. But "PMTiles sources do not support offline pack downloads or caching" (https://maplibre.org/maplibre-native/ios/latest/documentation/maplibre-native-for-ios/pmtiles). So the two offline strategies are:

- **Offline packs** against an XYZ/TileJSON tile server, for per-route downloads.
- **A bundled or downloaded `.pmtiles` file** read with `pmtiles://file://`. Offline by construction, with no pack API involved.

## 4. Tile sources for Shanghai

### Vector basemaps

| Provider | Cost for a small free app | Key / account | Offline and caching rules | Source |
|---|---|---|---|---|
| **OpenFreeMap** | Free public instance, "no limits on the number of map views or requests"; commercial use allowed; attribution required | None: "no registration, no user database, no API keys" | ToS does not address caching or offline packs. It forbids collecting data "in automated ways without permission". Weekly full-planet downloads (MBTiles) are offered for self-hosting. No SLA; may be discontinued without notice | https://openfreemap.org/ ; https://openfreemap.org/tos/ |
| **Protomaps, self-hosted** | Free data; you pay only for your own hosting (or ship the file in the app) | None | ODbL "Produced Work", OpenStreetMap attribution required. `pmtiles extract INPUT OUTPUT --bbox=MIN_LON,MIN_LAT,MAX_LON,MAX_LAT --maxzoom=N` cuts a city extract from the daily planet build | https://docs.protomaps.com/basemaps/downloads ; https://docs.protomaps.com/pmtiles/cli |
| **Protomaps hosted API** | "free for non-commercial use"; commercial use via GitHub Sponsors | API key required | Encourages self-hosting | https://protomaps.com/api |
| **MapTiler Cloud** | Free plan: 5k map sessions and 100k requests per month, limited to "non-commercial use and research & development". Flex plan from $30/month | API key | Client-side "temporary personal cache (browser cache, mobile app cache, etc.)" allowed. Server-side caching and exporting map content outside the service are prohibited | https://www.maptiler.com/cloud/pricing/ ; https://www.maptiler.com/terms/cloud/ |
| **Stadia Maps** | Free tier 200,000 credits/month, "Commercial use not allowed". Starter $20/month, commercial allowed | API key (domain auth does not work for native apps; Stadia advises against shipping the key in the binary) | Caching "small amounts of data for offline use in a mobile application" allowed, "not to exceed 100MB cached at a time per device"; otherwise client cache only, ≤ HTTP cache lifetime or 7 days | https://stadiamaps.com/pricing/ ; https://stadiamaps.com/terms-of-service/ ; https://docs.stadiamaps.com/authentication/ |

OpenFreeMap style URLs: `https://tiles.openfreemap.org/styles/liberty` (also `bright`, `positron`), TileJSON at `https://tiles.openfreemap.org/planet`, OpenMapTiles schema, max zoom 14, current build `20261004` (https://openfreemap.org/quick_start/; TileJSON fetched 2026-10-11).

Stadia's ToS also contains a China-specific clause: customers "agree not to export map data covering China from within China" (https://stadiamaps.com/terms-of-service/, section 9).

### Satellite imagery

| Source | Terms for a small free app | Source |
|---|---|---|
| **MapTiler Satellite** | "Cloudless global coverage at 2m per pixel", aerial imagery down to 8 cm per pixel in some areas (areas not named). Same Cloud plans as above, so the free plan is non-commercial only. Whether satellite counts against the free plan is not stated on the pricing page (**Unconfirmed**) | https://www.maptiler.com/maps/satellite/ ; https://www.maptiler.com/cloud/pricing/ |
| **Stadia Alidade Satellite** | Not in Free or Starter. Included from Standard ($80/month); 4 credits per tile | https://stadiamaps.com/pricing/ |
| **Esri World Imagery** | Licensed under the Esri Master License Agreement. The layer "is not intended to be used to export tiles for offline". Metered access through ArcGIS Location Platform: 2M basemap tiles/month free, then $0.15 per 1,000; or 1k basemap sessions free, then $4 per 1,000. Whether the free tier allows a commercial app is not stated (**Unconfirmed**). The public `server.arcgisonline.com` endpoint answers without a key, but its terms point to the licence above (**Inferred:** unmetered use of that URL in a shipped app is outside the intended terms) | https://www.arcgis.com/sharing/rest/content/items/10df2279f9684e4a9f6a7f08febac2a9?f=json ; https://location.arcgis.com/pricing/ ; https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer |

For maps shown in China, imagery sharper than 0.5 m per pixel is not allowed on public maps (see §8). Both MapTiler's aerial imagery and Esri's "one meter or better" imagery can exceed that.

### Traffic

No non-Chinese traffic source for mainland China was found:

- **TomTom**: mainland China is absent from the Traffic API market coverage table, and "If a market is missing from the following tables, it is not currently supported." Hong Kong and Taiwan are listed (https://docs.tomtom.com/intermediate-traffic-service/documentation/product-information/market-coverage).
- **HERE**: the traffic coverage page returned HTTP 403. HERE lists China at "Entry Maps" level for map rendering and excludes China from Tour Planning (https://docs.here.com/map-rendering/docs/coverage-info-map-image-api, https://docs.here.com/tour-planning/docs/country-support). Traffic coverage for China is **Unconfirmed**.
- OpenFreeMap, Protomaps, MapTiler and Stadia publish no traffic layer.
- **Apple Maps** lists "Maps: Traffic" as available in China mainland (https://www.apple.com/ios/feature-availability/). That data comes through Apple's China map supplier, so it is a Chinese-provider source in practice.

## 5. English and Chinese labels

**OpenMapTiles schema (OpenFreeMap, MapTiler).** The `transportation_name` and `place` layers in OpenFreeMap's live tiles carry `name`, `name:en`, `name:zh`, `name:zh-Hans`, `name:zh-Hant`, `name:latin`, `name:nonlatin`, plus the deprecated `name_en`, `name_de`, `name_int` (**Observed locally**, TileJSON `vector_layers` at https://tiles.openfreemap.org/planet). The schema defines `name_en` as "`name:en` if available, otherwise `name`" and marks it for removal in favour of `name:en` (https://github.com/openmaptiles/openmaptiles/blob/master/layers/transportation_name/transportation_name.yaml).

OpenFreeMap's Liberty style ships labels as `name:latin` plus `name:nonlatin`, or `coalesce(name_en, name)` (**Observed locally**, https://tiles.openfreemap.org/styles/liberty). The app can override `text-field` per symbol layer with an `NSExpression` to show `name:en` in English mode and `name` (which holds Chinese in China) in Chinese mode.

**Protomaps basemap.** Translated names are stored as `name:{code}`, including `name:en`, `name:zh-Hans` and `name:zh-Hant`. Protomaps publishes one localised style per language. If the target language is missing, non-Latin local names fall back to `name:en` (https://docs.protomaps.com/basemaps/localization).

**OSM convention for China.** "Most names in China are written with Simplified Han characters"; examples put the Chinese name in `name` and `name:zh`, and English in `name:en` (https://wiki.openstreetmap.org/wiki/Multilingual_names#China). WikiProject China says `name:en` should translate generic terms ("Square", "Road") rather than leave them as pinyin (https://wiki.openstreetmap.org/wiki/WikiProject_China).

**Inferred:** for Chinese mode, use `name` (or `name:zh-Hans`, then `name`), because `name:zh` is filled on only about a third of Shanghai streets (see §6) while `name` is Chinese by convention.

## 6. OSM coverage of central Shanghai

No OSM wiki page or OSM statistics page gives a completeness figure for Shanghai streets. The numbers below come from an Overpass API query over all `highway=*` ways inside Huangpu District (`黄浦区`, admin_level 6), OSM data as of 2026-10-11T09:18:57Z (**Observed locally**, https://overpass-api.de/api/interpreter).

| Measure | Count |
|---|---|
| All `highway` ways | 4,099 |
| Street ways (primary, secondary, tertiary, trunk, residential, unclassified, living_street, pedestrian) | 1,694 |
| … with `name` | 1,437 (85%) |
| … named and with `name:en` | 1,395 (97% of named streets) |
| … named and with `name:zh` | 486 (34% of named streets) |
| `highway=service` ways | 1,377 |
| Foot-type ways (footway, path, pedestrian, steps, living_street) | 993 (footway 667, pedestrian 154, steps 92, path 63, living_street 17) |
| Ways whose `name` contains 弄 (lane) | 42 |

What this shows: the named street grid and its English names are well covered in Huangpu. Lanes (弄, the lilong alleys) are thin: only 42 named lane ways in the district. Unnamed alleys may be among the 1,377 `service` ways, but this query does not prove it (**Unconfirmed**). PLAN.md's dead-end counts depend on walked routes, not on OSM, so thin lane data matters for the map picture rather than for route figures.

Legal caveat on improving the data: WikiProject China says private surveying and mapping without authorisation is illegal in mainland China, asks contributors not to add GCJ-02-shifted data, and says Tianditu imagery may not be traced (https://wiki.openstreetmap.org/wiki/WikiProject_China). The law behind this is in §7.

## 7. Reachability from mainland China

No provider publishes a statement that its tile hosts work, or are blocked, in mainland China. What exists:

| Host | What serves it | Evidence about China |
|---|---|---|
| `tiles.openfreemap.org` | Cloudflare (`server: cloudflare`) — **Observed locally**; ToS: "We may use Cloudflare as a CDN" (https://openfreemap.org/tos/) | None from the provider |
| `api.maptiler.com` | Cloudflare — **Observed locally** | None from the provider; Cloud terms name no territory restrictions (https://www.maptiler.com/terms/cloud/) |
| `api.protomaps.com` | Cloudflare — **Observed locally** | None |
| `tiles.stadiamaps.com` | No CDN header seen — **Observed locally** | ToS clause on exporting China map data only (https://stadiamaps.com/terms-of-service/) |
| `server.arcgisonline.com` | Esri — **Observed locally** | None |
| `api.mapbox.com` | Amazon CloudFront — **Observed locally** | `www.mapbox.cn`, `mapbox.cn` and `api.mapbox.cn` returned no DNS records on 2026-10-11 (**Observed locally**). Mapbox's 2017 announcement of an in-China service is linked from search results but its current status is **Unconfirmed**. A 2025 GitHub issue titled "Mapbox is not available in mainland China" (**Anecdotal**, https://github.com/yihong0618/running_page/issues/812) |
| `openstreetmap.org` | OSMF | GitHub issue "The domain is blocked in China", 2022-10-30, closed (**Anecdotal**, https://github.com/openstreetmap/openstreetmap-website/issues/3777) |

The one first-party statement that applies is Cloudflare's. Its China Network runs on in-country data centres (operated by JD Cloud) for Enterprise customers with an ICP filing, and Cloudflare says traffic routed through servers outside the country faces "significant latency and reliability issues" (https://developers.cloudflare.com/china-network/). OpenFreeMap, MapTiler and Protomaps' API are on Cloudflare's global network, not its China Network (**Inferred**: the China Network needs an ICP-filed apex domain, which none of these foreign providers is known to hold).

**Inferred:** any foreign tile host should be treated as slow and unreliable inside mainland China, with outright blocking possible and unannounced. A PMTiles file shipped in the app bundle, or downloaded once before travel, is the only MapLibre setup that does not depend on cross-border requests during a walk.

---

# Part 2 — Legal position in mainland China

## 8. The rules

### 测绘法 (Surveying and Mapping Law), 2017 revision, in force since 2017-07-01

Text: http://www.npc.gov.cn/zgrdw/npc/xinwen/2017-04/27/content_2020927.htm. A later revision was not found in this research (**Unconfirmed** that none exists).

- **Art. 8**: foreign organisations or individuals doing surveying and mapping in China need approval from the State Council's surveying department together with the military surveying department, must work with a Chinese partner, and must not touch state secrets.
- **Art. 10**: the state sets unified national coordinate systems.
- **Art. 27**: units doing surveying and mapping need a 测绘资质证书 (surveying qualification certificate) and must be legal persons.
- **Art. 38**: compiling, publishing, displaying, carrying and updating maps must follow national map-compilation standards, content rules and map review rules. Internet map service providers must "使用经依法审核批准的地图" (use maps approved by law), keep map-data security systems, and check newly added content.
- **Art. 47**: internet map service providers collecting users' personal information must follow personal-information law.
- **Art. 51**: unapproved surveying by foreigners: confiscation, fines of ¥100,000–500,000, up to ¥1,000,000 and expulsion in serious cases.
- **Art. 62**: maps or internet map services that break map-management rules are punished under the relevant rules.

### 地图管理条例 (Map Management Regulations), State Council Order 664, in force since 2016-01-01

Text: https://www.gov.cn/gongbao/content/2016/content_2979707.htm

- **Art. 2**: applies to maps made public inside China and to internet map services.
- **Art. 7**: units compiling maps need a surveying qualification certificate.
- **Art. 8–10**: maps must not show content harming national unity, sovereignty or territorial integrity, or state secrets; world and national maps must show China's full territory; the national border follows the official standard drawing.
- **Art. 15**: national map review system. Maps made public must be submitted for review, except "景区图、街区图、地铁线路图等内容简单的地图" (simple maps such as scenic-area maps, street-block maps, metro maps).
- **Art. 16**: whoever displays or carries a non-publication map submits it for review.
- **Art. 22**: approved maps must show the 审图号 prominently.
- **Art. 33**: internet map services offering location, user upload and annotation of geographic information, or map-database development need the corresponding surveying qualification.
- **Art. 34**: internet map service units must keep the servers that store map data **inside the People's Republic of China**.
- **Art. 36–37**: map databases must not store content that may not be shown on maps; nobody may upload or annotate such content.
- **Art. 38**: internet map service units must use approved maps, check new content, and file with the surveying department.
- **Art. 49, 53, 54**: fines up to ¥100,000 for not submitting a map for review; warnings and possible suspension for not showing the 审图号; up to ¥200,000 for serving unapproved maps.

### 地图审核管理规定 (Map Review Management Provisions), 2019 amendment

Text: https://www.gov.cn/zhengce/2019-08/13/content_5711407.htm

- **Art. 5**: review is required to publish, display, carry, produce, import or export maps or products bearing maps.
- **Art. 6**: no review needed for (1) public-service maps from the authorities that already carry a 审图号, used directly; (2) simple maps such as scenic-area, street-block and public-transport maps; (3) maps the law says must be public and that show no borders or administrative boundaries.
- **Art. 10**: maps for internet services must also show the reviewer the applicant's map-content checking hardware and software, plus the compiler's surveying qualification.
- **Art. 27**: internet map services show the 审图号 **in the lower-left corner of the map page**.
- **Art. 28**: an internet map service 审图号 is valid for **two years**; new annotation content must be filed every six months.

### 自然资办函〔2024〕972号 — MNR and MIIT notice on maps in apps, 2024-04-24

Text: https://www.gov.cn/zhengce/zhengceku/202405/content_6950568.htm

- App operators providing internet map services must complete map review with the natural-resources department **and** ICP filing with the telecom department; when map content changes or updates, review is redone.
- Apps that carry maps must show China's territory, administrative boundaries and important islands correctly and display the 审图号; when quoting a map, cite its source and 审图号.
- MNR offers standard maps and maps with a 审图号 free through the standard-map service and 天地图 (Tianditu).
- The two ministries will share map-review and app-filing data and act jointly against apps that serve unreviewed maps or omit the 审图号.

### 公开地图内容表示规范 (Public Map Content Rules), 自然资规〔2023〕2号, valid five years from 2023-02

Text: https://www.gov.cn/gongbao/content/2023/content_5752310.htm

- **Item 19**: for places inside China, public maps' planimetric accuracy must be **no better than 10 m**.
- **Item 20–21**: lists of facilities and attributes that may not be shown (military sites, important pipelines, bridge load limits, road surface material and so on).
- **Item 22**: remote-sensing imagery of places inside China must have ground resolution **no finer than 0.5 m**.

### Foreign investment

The 2024 Foreign Investment Negative List (in force 2024-11-01) prohibits foreign investment in, among other surveying activities, compiling 导航电子地图 (navigation electronic maps) and 真三维地图 (true-3D maps) (item 19; https://www.ndrc.gov.cn/xxgk/zcfb/fzggwl/202409/P020240907514493057643.pdf). A later edition was not checked (**Unconfirmed**).

### GCJ-02

- GB 20263-2006 《导航电子地图安全处理技术基本要求》 (Basic requirements for security processing of navigation electronic maps) is an in-force national standard without the `/T` (recommended) suffix, i.e. mandatory, owned by MNR (https://openstd.samr.gov.cn/bzgk/std/newGbInfo?hcno=517545EC0EE59615E0CA8D7EA56B153B). A revision plan exists but is on hold (https://std.samr.gov.cn/gb/search/gbDetailed?id=71F772D76AF6D3A7E05397BE0A0AB82A).
- That GB 20263 is the source of the GCJ-02 offset is widely stated but was **Unconfirmed** here: the standard's text was not read.
- The 2023 rules above cap public-map accuracy inside China at 10 m. **Inferred:** a WGS-84 basemap with metre-level OSM accuracy, shown publicly in China, does not meet that rule whatever its source.
- Apple does not document which coordinate system MapKit uses in mainland China. An Apple engineer's only reply to a June 2025 developer question on exactly this was a request to file a Feedback Assistant enhancement (https://developer.apple.com/forums/thread/787990).

## 9. Is an OSM-based or foreign-provider basemap compliant in China?

**No, for users in mainland China.** The pieces of law above stack up against it:

1. Showing a map to the public in China needs a 审图号, and an app serving a map is an internet map service that must use an approved map (测绘法 Art. 38; 地图管理条例 Art. 15, 38; 2024 notice). OpenFreeMap, Protomaps, MapTiler, Stadia, Esri and Mapbox's global service have no 审图号 for their China data (**Inferred**: none of their terms or documentation mentions one).
2. Map-data servers must be inside China (地图管理条例 Art. 34). These providers serve from outside China.
3. Map content must follow China's border and island depiction, accuracy (≤10 m) and imagery (≥0.5 m) rules (地图管理条例 Art. 8–10; 2023 rules items 19, 22). OSM data is metre-accurate WGS-84 and its borders follow OSM's on-the-ground policy, not China's standard map.
4. A foreign company cannot compile navigation electronic maps in China (2024 negative list), and only qualified units may compile maps (地图管理条例 Art. 7).

**The "street-block map" exemption.** Simple street-block (街区图) and transit maps are exempt from review (地图管理条例 Art. 15; 审核规定 Art. 6). Whether a pannable, zoomable vector basemap limited to Shanghai would count as a simple street-block map is not addressed by any source found. The 2024 notice treats apps that serve maps as internet map services needing review. **Unconfirmed; do not rely on this exemption without Chinese legal advice.**

**Has App Store China rejected apps for this?** No Apple or regulator statement naming a rejection for a missing 审图号 was found. What exists:

- App Store Review Guideline 5: "Apps must comply with all legal requirements in any location where you make them available" (https://developer.apple.com/app-store/review/guidelines/#legal). The guidelines contain no China-specific map rule.
- App Store Connect's "Availability in China mainland" section: MIIT "requires that some apps possess a valid Internet Content Provider (ICP) Filing Number", which must match MIIT's records and is shown on the product page (https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/).
- MIIT's 2023 app-filing notice (工信部信管〔2023〕105号): apps providing internet information services in China must file; distribution platforms must not distribute unfiled apps; existing apps had until March 2024, then enforcement from April 2024 (https://www.miit.gov.cn/zwgk/zcwj/wjfb/tz/art/2023/art_920db564162e4312916a01bed6540ad8.html; this page returned HTTP 403 from outside China, so these points come from its search-indexed text and were not read directly).
- The 2024 MNR/MIIT notice links ICP filing to map review for map apps. **Inferred:** an app with an unreviewed map is exposed at the filing stage and to later takedown, even if App Review passes it.

## 10. How Apple MapKit is compliant in China

- **What Apple states:** Apple Maps features in China mainland include Satellite, Traffic, Turn-by-Turn Navigation, Transit and Cycling; Look Around, Flyover and "Detailed City Experience" are not available there (https://www.apple.com/ios/feature-availability/). These are Maps app features; MapKit parity is **Unconfirmed**.
- **AutoNavi (高德):** that Apple's China map data comes from AutoNavi rests on 2012 press reports and on developers seeing "Amap"/高德 attribution in MapKit maps in mainland China (**Anecdotal**). Apple's global acknowledgements page lists many data providers but not AutoNavi (https://gspe21-ssl.ls.apple.com/html/attribution.html, fetched from outside China). AutoNavi's FY2012 20-F mentions Apple only as an app store (https://www.sec.gov/Archives/edgar/data/0001489895/000110465913033632/a13-4675_120f.htm). No first-party Apple statement naming AutoNavi was found.
- **Coordinates:** Apple does not document whether MapKit renders GCJ-02 in China or how it shifts the user-location dot (https://developer.apple.com/forums/thread/787990). Developer reports say WGS-84 overlays land offset from the base map in mainland China (**Anecdotal**).

**What this implies for staying on MapKit (Inferred):**

- The base map, its review and its in-country servers are Apple's (and its supplier's) responsibility. The app does not have to obtain a 审图号 for Apple's tiles.
- The app's own content is not covered. Route lines, pins, walker notes pinned to corners, and the route builder are user-visible geographic annotations. 地图管理条例 Art. 33 puts "地理信息上传标注" (uploading and annotating geographic information) by the public under the qualification requirement, and Art. 36–37 bar annotations of forbidden content. The builder and pinned notes may therefore count as an internet map service in their own right in China (**Unconfirmed**).
- WGS-84 route points drawn on MapKit in mainland China will likely sit off the streets unless converted, because of the anecdotal GCJ-02 behaviour above. Outside mainland China (including the global storefront used by visitors in Shanghai) the same question arises whenever the device is physically in mainland China, because the tiles change by device location, not by storefront (**Unconfirmed**; test on a device in Shanghai).

## 11. Options: global storefront only vs China storefront

| | Global storefronts only (China mainland unticked in App Store Connect) | China storefront |
|---|---|---|
| App Store requirement | No ICP filing number needed (App Store Connect asks for it only for China mainland availability) | ICP filing number matching MIIT records; filing is with the provincial telecom administration of the operator's domicile (**Inferred**: needs a mainland entity or resident) |
| Map with MapKit | Apple's China tiles when the device is in China | Apple's tiles; app's own route data and user annotations may still need map review and a surveying qualification (§10) |
| Map with MapLibre + foreign tiles | Works outside China. Inside China: slow or blocked hosts (§7). Legally, a foreign basemap reaching users in China is still outside Chinese map law; the App Store channel does not change that (**Inferred**) | Not compliant (§9). Would need a Chinese provider with a 审图号 (AMap, Tianditu, etc.) and in-country servers |
| Offline | MapKit: none. MapLibre: offline packs or PMTiles | Same, plus Art. 34 requires map-data servers in China |
| Practical risk | Low for an app aimed at visitors who download it abroad. The legal exposure inside China belongs to the operator if it is ever enforced, and enforcement against foreign apps on foreign storefronts is not documented (**Unconfirmed**) | High effort: ICP filing, map review, two-year 审图号 renewal, six-monthly filings, user-annotation moderation |

Apps on non-China storefronts remain downloadable by visitors whose Apple Account is from another country, and work in China as far as the network allows (**Inferred**).

---

## Fit for Walkable Shanghai

- **Staying on MapKit is the better default.** It is the only option here that gives a reviewed, in-country China basemap with no work, and it shows traffic and satellite in China mainland. PLAN.md §4.1's recommendation holds.
- **MapLibre is technically ready.** 6.31.0 installs by Swift Package, has an `arm64` simulator slice, needs iOS 12, and has a real offline-pack API. It would make "Offline ready · 18 MB" literally true and allow the paper-graded styling. The cost is a UIKit wrapper and a tile source.
- **No foreign tile source is both usable and lawful inside mainland China.** If MapLibre is adopted, the most robust setup is a Shanghai PMTiles extract from Protomaps or OpenFreeMap's planet build, shipped in the app or downloaded once, because foreign hosts are unreliable in China. Satellite and traffic would be lost there: none of the foreign sources has China traffic, and their imagery exceeds China's 0.5 m limit.
- **Release on global storefronts only, with China mainland unticked.** A China-storefront release needs an ICP filing and probably map review for the app's own routes, pinned notes and route builder. That needs a mainland entity and Chinese legal advice; it is a business decision, not a code task.
- **Test coordinates on a device in Shanghai early, whichever framework is used.** Route points are WGS-84 from OSM. On MapKit in mainland China they may draw offset from the streets. On an OSM-based MapLibre map they will line up, because both are WGS-84. This one test decides how much GCJ-02 conversion work the app needs.
