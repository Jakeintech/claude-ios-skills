import SwiftUI
import SwiftData

/// Chooses the font share cards are set in. Tall is everyone's; choosing
/// another is part of Pro. Anyone can try a font on the preview first.
///
/// Reached from Settings and from the share screen's Options.
struct ShareCardFontSettingsView: View {
    /// The class to preview with. Settings passes nil and the most recent
    /// class is used.
    var content: ShareCardContent?

    @State private var settings = UserSettings.shared
    @State private var trying: ShareCardTypeface?
    @State private var previewContent: ShareCardContent?
    @State private var isExample = false
    @State private var previews: [UIImage] = []
    @State private var showPaywall = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The font in use now.
    private var current: ShareCardTypeface {
        ShareCardTypeface.effective(raw: settings.shareCardTypefaceRaw, isPro: settings.isProUser)
    }

    /// The font on the preview: the one being tried, else the one in use.
    private var shown: ShareCardTypeface { trying ?? current }

    private func canUse(_ typeface: ShareCardTypeface) -> Bool {
        typeface.isFree || settings.isProUser
    }

    var body: some View {
        List {
            Section {
                preview
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            } footer: {
                if isExample {
                    Text("An example class. Your own classes appear here once you have one.")
                }
            }

            if !canUse(shown) {
                Section {
                    Button {
                        showPaywall = true
                    } label: {
                        Text("Use \(shown.displayName) with Pro")
                            .frame(maxWidth: .infinity)
                    }
                    .listRowBackground(Theme.surface)
                } footer: {
                    Text("Your cards stay in \(current.displayName) until then.")
                }
            }

            Section {
                ForEach(ShareCardTypeface.allCases) { typeface in
                    row(typeface)
                }
            } footer: {
                Text("\(ShareCardTypeface.standard.displayName) is the standard font. With Pro you can choose any of these.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Card Font")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.selection, trigger: shown)
        .task { loadContent() }
        .task(id: PreviewKey(typeface: shown, content: previewContent)) { renderPreviews() }
        .sheet(isPresented: $showPaywall) {
            PaywallView(reason: String(localized: "Pro lets you choose the font on your share cards."))
        }
    }

    // MARK: Preview

    private struct PreviewKey: Equatable {
        let typeface: ShareCardTypeface
        let content: ShareCardContent?
    }

    private var preview: some View {
        HStack(spacing: Theme.Spacing.m) {
            ForEach(Array(previews.enumerated()), id: \.offset) { _, image in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(.rect(cornerRadius: Theme.Radius.card, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .padding(.vertical, Theme.Spacing.s)
        .animation(reduceMotion ? nil : .smooth(duration: 0.2), value: shown)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Share cards set in \(shown.displayName)"))
    }

    /// The class passed in, else the most recent class, else an example.
    private func loadContent() {
        guard previewContent == nil else { return }
        if let content {
            previewContent = content
            return
        }
        var latest = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isProcessingComplete },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        latest.fetchLimit = 1
        if let session = try? modelContext.fetch(latest).first {
            previewContent = ShareCardContent(session: session)
        } else {
            previewContent = .sample
            isExample = true
        }
    }

    /// Two cards that show a font best: a hero number and the teacher's line
    /// (or the song list when the class has no saved line).
    private func renderPreviews() {
        guard let previewContent else { return }
        let wanted = ["one-number", "teacher-line", "setlist", "caption"]
        let styles = wanted.compactMap(ShareCardRegistry.style(id:))
            .filter { $0.isAvailable(for: previewContent) }
            .prefix(2)
        previews = styles.compactMap { style in
            ShareCardRenderer.image(
                style,
                ShareCardRenderer.defaultContext(for: style, content: previewContent, typeface: shown),
                scale: 2
            )
        }
    }

    // MARK: Rows

    private func row(_ typeface: ShareCardTypeface) -> some View {
        let isCurrent = typeface == current
        let locked = !canUse(typeface)
        return Button {
            if locked {
                // Anyone can see a font on their own class before deciding.
                trying = typeface
            } else {
                trying = nil
                settings.shareCardTypefaceRaw = typeface.rawValue
            }
        } label: {
            HStack(spacing: Theme.Spacing.m) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(typeface.displayName)
                        .foregroundStyle(.primary)
                    Text(typeface.character)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: Theme.Spacing.s)
                if isCurrent {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                } else if locked {
                    Text("Pro", comment: "Badge on a share card font that needs Pro")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, Theme.Spacing.s)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(Theme.background, in: Capsule())
                }
            }
            .frame(minHeight: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .listRowBackground(typeface == shown && !isCurrent ? Theme.accent.opacity(0.12) : Theme.surface)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
        .accessibilityHint(locked ? Text("Shows this font on the preview. Using it needs Pro.") : Text(""))
    }
}
