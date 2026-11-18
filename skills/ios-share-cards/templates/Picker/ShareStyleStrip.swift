import SwiftUI

/// The row of style thumbnails under the preview, with the groups above it.
/// Every thumbnail is the person's own class in that style.
struct ShareStyleStrip: View {
    let model: ShareStudioModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var groups: [ShareCardGroup] {
        ShareCardGroup.allCases.filter { group in
            model.styleIDs.contains { model.style($0)?.group == group }
        }
    }

    private var selectedGroup: ShareCardGroup? { model.selectedStyle?.group }

    var body: some View {
        VStack(spacing: 0) {
            if groups.count > 1 { groupRow }
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(spacing: Theme.Spacing.s) {
                        ForEach(model.styleIDs, id: \.self) { id in
                            thumbnail(id).id(id)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, Theme.Spacing.xs)
                }
                .scrollIndicators(.hidden)
                .onChange(of: model.selectedID) { _, id in
                    guard let id else { return }
                    withAnimation(reduceMotion ? nil : .snappy(duration: 0.25)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
    }

    /// Tapping a group jumps to its first style.
    private var groupRow: some View {
        ScrollView(.horizontal) {
            groupButtons.padding(.horizontal)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    private var groupButtons: some View {
        HStack(spacing: Theme.Spacing.s) {
            ForEach(groups) { group in
                Button {
                    if let first = model.styleIDs.first(where: { model.style($0)?.group == group }) {
                        select(first)
                    }
                } label: {
                    Text(group.displayName)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(selectedGroup == group ? .primary : .secondary)
                        .fixedSize()
                        .padding(.horizontal, Theme.Spacing.s)
                        .frame(minHeight: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selectedGroup == group ? .isSelected : [])
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func thumbnail(_ id: String) -> some View {
        let isSelected = model.selectedID == id
        return Button {
            select(id)
        } label: {
            Group {
                if let image = model.thumbnails[id] {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    Theme.surface
                }
            }
            .frame(width: 45, height: 80)
            .clipShape(.rect(cornerRadius: Theme.Radius.control, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.control + 3, style: .continuous)
                    .stroke(.primary, lineWidth: isSelected ? 2 : 0)
                    .padding(-3.5)
            }
            .opacity(isSelected ? 1 : 0.8)
            .padding(.horizontal, 2)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(model.style(id)?.name ?? "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .task(id: model.renderKey(for: id, thumbnail: true)) {
            model.renderThumbnail(id)
        }
    }

    private func select(_ id: String) {
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.25)) {
            model.select(id)
        }
    }
}
