import SwiftUI

/// Screen 6 — recording a walk.
///
/// The one screen in the app that is watched rather than read, usually held at
/// arm's length while moving. So the figures are large, the two controls are
/// unmissable, and nothing here needs a second tap to understand.
struct TrackingScreen: View {

    @Environment(AppSettings.self) private var settings
    @Environment(TrackingSession.self) private var session
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss

    let route: Route
    /// Unwinds the whole tracking flow once the walk is stored.
    var onFinished: () -> Void = {}

    @State private var showingSummary = false

    var body: some View {
        let language = settings.language

        VStack(spacing: 0) {
            topBar(language: language)

            RouteMapView(
                mode: .track,
                routes: [route],
                walkedFraction: session.progress,
                walkerCoordinate: session.walkerCoordinate,
                followsWalker: true
            )
            .frame(maxHeight: .infinity)

            panel(language: language)
        }
        .screenBackground()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            if session.state == .idle || session.route?.id != route.id {
                session.start(route: route)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            // Coming back from the background: catch the clock up in one step.
            // It never stopped counting — it is derived from the wall clock —
            // but the ticker that redraws the screen was suspended.
            if phase == .active { session.refreshElapsed() }
        }
        .navigationDestination(isPresented: $showingSummary) {
            WalkSummaryScreen(route: route, onDone: onFinished)
        }
    }

    // MARK: - Top bar

    private func topBar(language: AppLanguage) -> some View {
        HStack(spacing: Theme.Space.s2) {
            // A dot that stops pulsing when paused, so the recording state is
            // legible without reading the word next to it.
            Circle()
                .fill(session.state == .running ? Theme.accent : Theme.labelTertiary)
                .frame(width: 8, height: 8)
                .opacity(session.state == .running ? 1 : 0.5)

            Text((session.state == .running ? "track.recording" : "track.paused").localized(language))
                .font(Typography.label)
                .foregroundStyle(session.state == .running ? Theme.accent : Theme.labelSecondary)
                .accessibilityIdentifier("recording-state")

            Spacer()

            Text(route.name(language))
                .font(Typography.meta)
                .foregroundStyle(Theme.labelTertiary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.horizontal, Theme.Space.screen)
        .padding(.vertical, Theme.Space.s2)
        .background(Theme.bg)
    }

    // MARK: - Panel

    private func panel(language: AppLanguage) -> some View {
        VStack(spacing: Theme.Space.s3) {

            // The clock is the biggest thing on the screen. It is the number a
            // walker actually glances at.
            Text(session.elapsedText)
                .font(Typography.figure(.largeTitle))
                .foregroundStyle(Theme.label)
                .accessibilityIdentifier("elapsed-clock")
                .accessibilityLabel("track.elapsed".localized(language))
                .accessibilityValue(session.elapsedText)

            FigureStrip(figures: [
                (session.distanceText, "unit.km".localized(language), false),
                (session.paceText, "track.pace".localized(language), false),
                (session.remainingText, "track.remaining".localized(language), false),
            ])

            progressBar(language: language)

            deadEndsAhead(language: language)

            HStack(spacing: Theme.Space.s2) {
                Button((session.state == .running ? "track.pause" : "track.resume").localized(language)) {
                    session.state == .running ? session.pause() : session.resume()
                }
                .buttonStyle(.secondaryClassical)
                .accessibilityIdentifier("pause-resume-button")

                Button("track.end".localized(language)) {
                    session.end()
                    showingSummary = true
                }
                .buttonStyle(.primaryClassical)
                .accessibilityIdentifier("end-walk-button")
            }
        }
        .padding(.horizontal, Theme.Space.screen)
        .padding(.top, Theme.Space.s4)
        .padding(.bottom, Theme.Space.s4)
        .background(Theme.bg)
        // The one place a rule still crosses a page: the seam between a live
        // map and the opaque panel under it. That is a boundary between two
        // materials, not a page dividing itself, and iOS draws it too.
        .overlay(alignment: .top) { SeparatorRule() }
    }

    private func progressBar(language: AppLanguage) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.s1 + 1) {
            HStack {
                Text("track.progress".localized(language))
                    .sectionLabel(color: Theme.labelTertiary)
                Spacer()
                Text(session.progressPercentText)
                    .font(Typography.figure(.caption))
                    .foregroundStyle(Theme.accent)
                    .accessibilityIdentifier("progress-percent")
            }

            // A capsule track with a gradient fill, per DESIGN.md §6. The old
            // 3pt ruled bar belonged to the print system; this one says "how far
            // along" with the same two greens the walked line uses.
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.fill)
                        .frame(height: 6)
                    Capsule()
                        .fill(Theme.progressFill)
                        .frame(width: geometry.size.width * session.progress, height: 6)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 6)
            .accessibilityHidden(true)
        }
    }

    /// Static "none" for now. Routes do not carry break points as data yet, and
    /// PLAN.md keeps this honest placeholder rather than inventing a warning
    /// the catalogue cannot support.
    private func deadEndsAhead(language: AppLanguage) -> some View {
        HStack(spacing: Theme.Space.s2) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 13))
                .foregroundStyle(Theme.onAccentSoft)
            Text("track.deadEndsAhead".localized(language))
                .font(Typography.meta)
                .foregroundStyle(Theme.onAccentSoft)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.Space.s3)
        .padding(.vertical, Theme.Space.s2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.accentSoft, in: Theme.shape(Theme.Radius.sm))
    }
}
