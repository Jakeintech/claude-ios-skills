import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

/// The share screen: a full-height pager of card styles drawn with this
/// class, a strip of thumbnails, one shape control and one main action.
/// See docs/specs/share-card-styles.md.
struct ShareStudioView: View {
    let session: WorkoutSession

    @State private var model = ShareStudioModel()
    @State private var showingOptions = false
    @State private var showingOlderDesigns = false
    @State private var showingLibrary = false
    @State private var showingCamera = false
    @State private var photoItem: PhotosPickerItem?
    @State private var canOpenInstagram = false
    @State private var isSharing = false
    @State private var pendingShare: PendingShare?
    @State private var failure: Failure?
    @State private var copiedSticker = false
    @State private var afterOptions: FollowUp?

    /// Something to present once the options sheet has finished closing.
    private enum FollowUp { case library, camera, olderDesigns }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Items waiting in the system share sheet.
    private struct PendingShare: Identifiable {
        let id = UUID()
        let items: [Any]
    }

    private struct Failure: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        /// When set, the alert offers the system share sheet for these.
        let fallback: [Any]?
    }

    var body: some View {
        NavigationStack {
            Group {
                if model.content == nil {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    studio
                }
            }
            // Readable width on iPad and the unfolded foldable.
            .frame(maxWidth: horizontalSizeClass == .regular ? 640 : .infinity)
            .frame(maxWidth: .infinity)
            .background(Theme.background)
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .task {
                model.load(session)
                canOpenInstagram = InstagramStorySharer().canShareDirectly
            }
            .onChange(of: model.selectedID) { model.rememberSelection() }
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) { model.setPhoto(data) }
                    photoItem = nil
                }
            }
            .sensoryFeedback(.selection, trigger: model.selectedID)
            .sensoryFeedback(.success, trigger: copiedSticker) { _, copied in copied }
            .photosPicker(isPresented: $showingLibrary, selection: $photoItem, matching: .images, photoLibrary: .shared())
            .fullScreenCover(isPresented: $showingCamera) {
                CameraPicker { data in
                    showingCamera = false
                    if let data { model.setPhoto(data) }
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showingOptions, onDismiss: {
                if let next = afterOptions {
                    afterOptions = nil
                    run(next)
                }
            }) {
                if let id = model.selectedID {
                    ShareOptionsSheet(model: model, styleID: id, photoMenu: { photoMenuItems }) {
                        present(.olderDesigns)
                    }
                    .presentationDetents([.medium, .large])
                }
            }
            .sheet(isPresented: $showingOlderDesigns) {
                ShareSheetView(session: session)
            }
            .sheet(item: $pendingShare) { pending in
                ActivityShareSheet(items: pending.items)
                    .presentationDetents([.medium, .large])
                    .ignoresSafeArea()
            }
            .alert(item: $failure) { failure in
                if let fallback = failure.fallback {
                    Alert(
                        title: Text(failure.title),
                        message: Text(failure.message),
                        primaryButton: .default(Text("Share Another Way")) { pendingShare = PendingShare(items: fallback) },
                        secondaryButton: .cancel()
                    )
                } else {
                    Alert(title: Text(failure.title), message: Text(failure.message), dismissButton: .cancel(Text("OK")))
                }
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .principal) {
            if model.selectedStyle?.kind == .sticker {
                Text("Sticker", comment: "Shown in place of the shape control when a sticker is selected")
                    .font(.headline)
            } else {
                Picker("Shape", selection: Bindable(model).prefs.format) {
                    ForEach(ShareCardFormat.allCases) { format in
                        Text(format.displayName).tag(format)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 240)
                .accessibilityHint("Changes the shape of the card")
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Button {
                showingOptions = true
            } label: {
                Label("Options", systemImage: "slider.horizontal.3")
            }
            .disabled(model.selectedID == nil)
        }
    }

    // MARK: - Layout

    private var studio: some View {
        VStack(spacing: Theme.Spacing.m) {
            pager
            caption
            ShareStyleStrip(model: model)
            actions
                .padding(.horizontal)
        }
        .padding(.top, Theme.Spacing.s)
        .padding(.bottom, Theme.Spacing.s)
    }

    /// A page per style. Neighbours peek at the edges, so it reads as
    /// something to swipe.
    private var pager: some View {
        GeometryReader { geo in
            let pageWidth = max(120, min(geo.size.width * 0.74, geo.size.height * 9 / 16))
            ScrollView(.horizontal) {
                LazyHStack(spacing: Theme.Spacing.m) {
                    ForEach(model.styleIDs, id: \.self) { id in
                        SharePreviewPage(model: model, styleID: id, photoMenu: { photoMenuItems })
                            .frame(width: pageWidth, height: geo.size.height)
                            .id(id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: Bindable(model).selectedID, anchor: .center)
            .contentMargins(.horizontal, max(0, (geo.size.width - pageWidth) / 2), for: .scrollContent)
            .scrollIndicators(.hidden)
        }
        .frame(maxHeight: .infinity)
    }

    private var caption: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(model.selectedStyle?.name ?? "")
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .accessibilityAddTraits(.isHeader)
            // At the largest text sizes the description gives its room to
            // the preview; the copied message still shows.
            if copiedSticker || !dynamicTypeSize.isAccessibilitySize {
                Text(copiedSticker
                     ? String(localized: "Sticker copied. Open your Story in Instagram and paste.")
                     : (model.selectedStyle?.tagline ?? ""))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(.horizontal)
        .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: copiedSticker)
    }

    // MARK: - Actions

    private var isSticker: Bool { model.selectedStyle?.kind == .sticker }

    /// A Story-shaped card or a sticker goes to Instagram. Other shapes are
    /// for a feed, so their main action is the share sheet.
    private var goesToStory: Bool { isSticker || model.prefs.format == .story }

    private var actions: some View {
        GlassEffectContainer(spacing: Theme.Spacing.m) {
            // Side by side when the title fits on one line, stacked when it
            // does not (large text, narrow screens).
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Theme.Spacing.m) {
                    primaryButton(lines: 1)
                    secondaryButtons
                }
                VStack(spacing: Theme.Spacing.s) {
                    primaryButton(lines: 2)
                    HStack(spacing: Theme.Spacing.m) { secondaryButtons }
                }
            }
        }
        // The preview is the point of the screen: very large text stops
        // growing here, and the round buttons show a large-content label.
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    private func primaryButton(lines: Int) -> some View {
        Button {
            Task { await goesToStory ? addToStory() : shareSelected() }
        } label: {
            HStack(spacing: Theme.Spacing.s) {
                if isSharing { ProgressView().controlSize(.small) }
                Text(primaryTitle)
                    .font(.headline)
                    .lineLimit(lines)
                    .fixedSize(horizontal: lines == 1, vertical: true)
            }
            // On brand: never white on saffron.
            .foregroundStyle(Theme.background)
            .frame(maxWidth: .infinity)
        }
        .primaryButtonStyle()
        .disabled(isSharing || model.selectedID == nil)
    }

    @ViewBuilder private var secondaryButtons: some View {
        if isSticker {
            roundButton("Copy sticker", systemImage: "doc.on.doc") { copySticker() }
                .accessibilityHint("Copies the sticker so you can paste it onto a Story")
        }
        if goesToStory {
            roundButton("Share another way", systemImage: "square.and.arrow.up") {
                Task { await shareSelected() }
            }
        }
    }

    private var primaryTitle: String {
        if !goesToStory { return String(localized: "Share") }
        return canOpenInstagram
            ? String(localized: "Add to Story", comment: "Button that opens Instagram's story composer with the card")
            : String(localized: "Share as Story", comment: "Button that shares a story image when Instagram isn't installed")
    }

    private func roundButton(_ title: LocalizedStringKey, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .controlSize(.large)
        .accessibilityLabel(title)
        .accessibilityShowsLargeContentViewer { Label(title, systemImage: systemImage) }
        .disabled(isSharing || model.selectedID == nil)
    }

    /// Presents now, or after the options sheet has closed if it is open:
    /// two sheets cannot change places in one step.
    private func present(_ next: FollowUp) {
        if showingOptions {
            afterOptions = next
            showingOptions = false
        } else {
            run(next)
        }
    }

    private func run(_ next: FollowUp) {
        switch next {
        case .library: showingLibrary = true
        case .camera: showingCamera = true
        case .olderDesigns: showingOlderDesigns = true
        }
    }

    /// The same menu on the preview and in the options sheet.
    @ViewBuilder private var photoMenuItems: some View {
        if CameraPicker.isAvailable {
            Button {
                present(.camera)
            } label: {
                Label("Take Photo", systemImage: "camera")
            }
        }
        Button {
            present(.library)
        } label: {
            Label("Choose from Library", systemImage: "photo.on.rectangle")
        }
        if model.photo != nil {
            Divider()
            Button(role: .destructive) {
                model.removePhoto()
            } label: {
                Label("Remove Photo", systemImage: "trash")
            }
        }
    }

    // MARK: - Sharing

    private func couldNotMake() -> Failure {
        Failure(
            title: String(localized: "This card couldn't be made"),
            message: String(localized: "Try again, or choose another card."),
            fallback: nil
        )
    }

    /// What the share sheet gets: the card as an image, or a sticker as a
    /// PNG file so its transparency survives.
    private func shareItems(for styleID: String) -> [Any]? {
        guard let image = model.exportImage(styleID) else { return nil }
        guard model.style(styleID)?.kind == .sticker else { return [image] }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("sticker.png")
        guard let data = image.pngData(), (try? data.write(to: url, options: .atomic)) != nil else { return [image] }
        return [url]
    }

    private func shareSelected() async {
        guard let id = model.selectedID else { return }
        guard let items = shareItems(for: id) else { failure = couldNotMake(); return }
        pendingShare = PendingShare(items: items)
    }

    private func addToStory() async {
        guard let id = model.selectedID, let style = model.style(id) else { return }
        isSharing = true
        defer { isSharing = false }

        guard let image = model.exportImage(id) else { failure = couldNotMake(); return }
        let outcome: StoryShareOutcome
        let flat: UIImage?
        switch style.kind {
        case .card:
            flat = image
            let colors = model.prefs.field.storyHex
            outcome = await InstagramStorySharer().share(fullFrame: image, topColorHex: colors.top, bottomColorHex: colors.bottom)
        case .sticker:
            flat = model.exportStickerStory(id)
            outcome = await InstagramStorySharer().share(sticker: image, over: model.photo, field: model.prefs.field)
        }

        switch outcome {
        case .openedInstagram:
            break
        case .instagramUnavailable, .notConfigured:
            // No Instagram: hand the finished Story image to the share sheet.
            if let flat { pendingShare = PendingShare(items: [flat]) } else { failure = couldNotMake() }
        case .openFailed:
            failure = Failure(
                title: String(localized: "Instagram didn't open"),
                message: String(localized: "Your story is ready. Share it another way, or try again in a moment."),
                fallback: flat.map { [$0] }
            )
        case .renderFailed:
            failure = couldNotMake()
        }
    }

    private func copySticker() {
        guard let id = model.selectedID, let data = model.exportImage(id)?.pngData() else {
            failure = couldNotMake()
            return
        }
        UIPasteboard.general.setData(data, forPasteboardType: UTType.png.identifier)
        copiedSticker = true
        AccessibilityNotification.Announcement(String(localized: "Sticker copied")).post()
        Task {
            try? await Task.sleep(for: .seconds(4))
            copiedSticker = false
        }
    }
}

// MARK: - Page

/// One style's preview: the exact image that will be shared, fitted to the
/// page. Drawn again only when something it depends on changes.
struct SharePreviewPage<PhotoMenu: View>: View {
    let model: ShareStudioModel
    let styleID: String
    @ViewBuilder var photoMenu: () -> PhotoMenu

    var body: some View {
        ZStack {
            if let image = model.previews[styleID] {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(.rect(cornerRadius: Theme.Radius.sheet, style: .continuous))
                    .shadow(color: .black.opacity(0.45), radius: 18, y: 10)
                    .overlay(alignment: .top) { photoControl }
                    .accessibilityLabel(Text("\(model.style(styleID)?.name ?? "") card preview"))
                    .transition(.opacity)
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: model.renderKey(for: styleID)) {
            model.renderPreview(styleID)
        }
    }

    /// Styles that lead with a photo ask for one right on the preview.
    private var leadsWithPhoto: Bool {
        guard let style = model.style(styleID) else { return false }
        return style.kind == .sticker || style.backgrounds.first == .photo
    }

    @ViewBuilder private var photoControl: some View {
        if leadsWithPhoto {
            Menu {
                photoMenu()
            } label: {
                Label(model.photo == nil ? "Add Photo" : "Change Photo", systemImage: "photo.on.rectangle")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, Theme.Spacing.m)
                    .frame(minHeight: 44)
                    .glassEffect(.clear, in: Capsule())
            }
            .menuOrder(.fixed)
            .padding(.top, Theme.Spacing.m)
            // It sits on the card, so it must not grow over it.
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .accessibilityShowsLargeContentViewer()
            .accessibilityHint("The photo is used only for this class")
        }
    }
}
