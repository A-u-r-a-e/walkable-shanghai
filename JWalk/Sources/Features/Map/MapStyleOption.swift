import Foundation

/// The three basemaps the walker can choose between on the map.
enum MapStyleOption: String, CaseIterable, Sendable {
    case standard
    case satellite
    case traffic

    var localizationKey: String { "map.style.\(rawValue)" }

    var systemImage: String {
        switch self {
        case .standard: return "map"
        case .satellite: return "globe.asia.australia"
        case .traffic: return "car"
        }
    }
}
