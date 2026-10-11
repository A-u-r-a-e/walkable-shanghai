import SwiftUI
import PhotosUI

/// Screen 7 — what the walk came to.
///
/// Replaces Phase 4's stub. The four figures are the finished session's real
/// numbers, and Done writes the walk to SwiftData before unwinding to the map.
struct WalkSummaryScreen: View {

    @Environment(AppSettings.self) private var settings
    @Environment(WalkStore.self) private var walks
    @Environment(TrackingSession.self) private var session

    let route: Route
    /// Called once the walk is stored, to unwind back to the map.
    let onDone: () -> Void

    @State private var note = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var hasSaved = false

    var body: some View {
        let language = settings.language

        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.s3) {
                Text("summary.complete".localized(language))
                    .sectionLabel()

                Text(route.name(language))
                    .font(Typography.title)
                    .foregroundStyle(Theme.label)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("summary-route-name")

                Text(dateLine(language: language))
                    .font(Typography.meta)
                    .foregroundStyle(Theme.labelTertiary)
                    .accessibilityIdentifier("summary-date-line")

                figureGrid(language: language)

                photograph(language: language)

                noteField(language: language)

                Button("summary.done".localized(language)) {
                    finish()
                }
                .buttonStyle(.primaryClassical)
                .accessibilityIdentifier("summary-done-button")
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.top, Theme.Space.s4)
            .padding(.bottom, Theme.Space.s8 + 72)
        }
        .canopyWash()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                photoData = try? await item.loadTransferable(type: Data.self)
            }
        }
    }

    // MARK: - Figures

    /// The 2×2 grid, in the order the design reads it: what you did, how long
    /// it took, how fast that was, and whether it beat anything.
    ///
    /// The shared `FigureGrid` rather than four figures between rules of its
    /// own: the rules were the print system, and this screen's four figures are
    /// exactly the shape that component exists for. `.title` keeps the numbers
    /// the size they were — these four *are* the screen.
    private func figureGrid(language: AppLanguage) -> some View {
        FigureGrid(
            figures: [
                .init(value: session.distanceText,
                      label: "summary.kmWalked".localized(language)),
                .init(value: session.elapsedText,
                      label: "summary.movingTime".localized(language)),
                .init(value: session.paceText,
                      label: "summary.minPerKm".localized(language)),
                .init(value: overBestText,
                      label: "summary.overBest".localized(language),
                      emphasised: isPersonalBest),
            ],
            textStyle: .title
        )
        .accessibilityIdentifier("summary-figures")
    }

    /// Signed distance past the previous best walk.
    ///
    /// An em dash on the first ever walk. The mockup hardcoded "+0.6"; there is
    /// no honest way to compute an improvement when there is nothing to improve
    /// on, and claiming one would make the app's own figures untrustworthy.
    private var overBestText: String {
        guard let delta = walks.metersOverBest(session.distanceMeters) else { return "—" }
        let km = delta / 1000
        return String(format: "%@%.1f", km >= 0 ? "+" : "−", abs(km))
    }

    private var isPersonalBest: Bool {
        guard let delta = walks.metersOverBest(session.distanceMeters) else { return false }
        return delta > 0
    }

    private func dateLine(language: AppLanguage) -> String {
        let locale = Locale(identifier: language == .chinese ? "zh-Hans" : "en_GB")
        let day = Date.FormatStyle(date: .long, time: .omitted).locale(locale)
        let clock = Date.FormatStyle(date: .omitted, time: .shortened).locale(locale)
        let start = session.startedAt ?? Date()
        let end = session.endedAt ?? Date()
        return "\(end.formatted(day)) · \(start.formatted(clock)) – \(end.formatted(clock))"
    }

    // MARK: - Photo and note

    private func photograph(language: AppLanguage) -> some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            Group {
                if let photoData, let image = UIImage(data: photoData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(Theme.fill)
                        .overlay {
                            VStack(spacing: Theme.Space.s1) {
                                Image(systemName: "camera")
                                    .font(.system(size: 18, weight: .light))
                                Text("summary.addPhoto".localized(language))
                                    .font(Typography.meta)
                            }
                            .foregroundStyle(Theme.labelTertiary)
                        }
                }
            }
            // The same guard the offline map needs: a picked photograph is any
            // shape at all, and `scaledToFill` would otherwise let a wide one
            // set the width of the screen.
            .fillingBox(height: 168)
            // A media slot is a rounded well, not a print mount. The clip is
            // what a chosen photograph gets too, so the empty and filled states
            // are the same shape.
            .clipShape(Theme.shape(Theme.Radius.lg))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("summary-photo-picker")
        .accessibilityLabel("summary.addPhoto".localized(language))
    }

    private func noteField(language: AppLanguage) -> some View {
        TextField(
            "summary.notePlaceholder".localized(language),
            text: $note,
            axis: .vertical
        )
        .lineLimit(3...6)
        .font(Typography.body)
        .foregroundStyle(Theme.label)
        .padding(Theme.Space.s3)
        .background(Theme.fill, in: Theme.shape(Theme.Radius.sm))
        .accessibilityIdentifier("summary-note-field")
    }

    // MARK: - Saving

    private func finish() {
        // Guard against a double tap writing the walk twice.
        guard !hasSaved else { return }
        hasSaved = true

        walks.record(
            routeId: route.id,
            startedAt: session.startedAt ?? Date(),
            endedAt: session.endedAt ?? Date(),
            distanceMeters: session.distanceMeters,
            elapsedSeconds: session.elapsed,
            note: note,
            photo: photoData
        )
        onDone()
    }
}
