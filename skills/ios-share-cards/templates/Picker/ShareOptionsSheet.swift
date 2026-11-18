import SwiftUI

/// The few things that can be changed about one style: its own options (at
/// most three), what it sits on, and the photo.
struct ShareOptionsSheet<PhotoMenu: View>: View {
    let model: ShareStudioModel
    let styleID: String
    @ViewBuilder var photoMenu: () -> PhotoMenu
    let onOlderDesigns: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var kinds: [ShareCardBackgroundKind] { model.backgroundKinds(for: styleID) }

    var body: some View {
        NavigationStack {
            Form {
                let options = model.options(for: styleID)
                if !options.isEmpty {
                    Section {
                        ForEach(options) { option in row(option) }
                    }
                }
                if kinds.count > 1 || model.usesPhoto(styleID) {
                    Section("Background") { background }
                }
                Section {
                    NavigationLink {
                        ShareCardFontSettingsView(content: model.content)
                    } label: {
                        LabeledContent("Font", value: model.typeface.displayName)
                    }
                } footer: {
                    Text("One font for all your cards.")
                }
                Section {
                    Button("Older Card Designs", action: onOlderDesigns)
                } footer: {
                    Text("The earlier cards, with their own options, are still here.")
                }
            }
            .navigationTitle(model.style(styleID)?.name ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(Theme.accent)
    }

    // MARK: Options

    @ViewBuilder private func row(_ option: ShareCardOption) -> some View {
        let values = model.values(for: styleID)
        switch option.kind {
        case .toggle:
            Toggle(option.title, isOn: Binding(
                get: { values.isOn(option) },
                set: { model.setToggle(option.id, $0, for: styleID) }
            ))
        case .choice(let choices, _):
            let selection = Binding(
                get: { values.choice(option) },
                set: { model.setChoice(option.id, $0, for: styleID) }
            )
            // Short choices sit side by side; sentences get a list of their own.
            if choices.count <= 3, choices.allSatisfy({ $0.title.count <= 10 }) {
                LabeledContent(option.title) {
                    Picker(option.title, selection: selection) {
                        ForEach(choices) { Text($0.title).tag($0.id) }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(maxWidth: 220)
                }
            } else {
                Picker(option.title, selection: selection) {
                    ForEach(choices) { Text($0.title).tag($0.id) }
                }
                .pickerStyle(.navigationLink)
            }
        }
    }

    // MARK: Background

    @ViewBuilder private var background: some View {
        let kind = model.backgroundKind(for: styleID)
        if kinds.count > 1 {
            Picker("Background", selection: Binding(
                get: { kind ?? kinds[0] },
                set: { model.setBackground($0, for: styleID) }
            )) {
                ForEach(kinds) { Text($0.displayName).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        if kind == .colour || (model.style(styleID)?.kind == .sticker && model.photo == nil) {
            colours
        }
        if model.usesPhoto(styleID) {
            Menu {
                photoMenu()
            } label: {
                Label(model.photo == nil ? "Add Photo" : "Change Photo", systemImage: "photo.on.rectangle")
            }
            .menuOrder(.fixed)
            .accessibilityHint("The photo is used only for this class")
        }
    }

    private var colours: some View {
        LabeledContent("Colour") {
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(ShareCardField.allCases) { field in
                    let isSelected = model.prefs.field == field
                    Button {
                        model.prefs.field = field
                    } label: {
                        ShareCardFieldView(field: field)
                            .frame(width: 28, height: 28)
                            .clipShape(Circle())
                            .overlay {
                                Circle().stroke(.primary, lineWidth: isSelected ? 2 : 0).padding(-3.5)
                            }
                            .frame(width: 44, height: 44)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(field.displayName)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }
}
