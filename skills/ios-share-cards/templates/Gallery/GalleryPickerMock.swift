// Gallery only: a drawn mock of the proposed picker. Not app code: the
// glass here is faked with translucent fills because ImageRenderer cannot
// draw Liquid Glass. The real screen uses system glass button styles.

import SwiftUI

struct PickerMock: View {
    enum Mode { case browse, options, sticker }

    let mode: Mode
    let current: CGImage
    let previous: CGImage
    let next: CGImage
    /// Thumbnails for the style strip, in registry order, with names.
    let strip: [(name: String, image: CGImage)]
    let selectedIndex: Int
    let title: String
    let tagline: String

    private let screen = CGSize(width: 393, height: 852)

    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: 0x131216)
            VStack(spacing: 0) {
                topBar.padding(.top, 62)
                preview.padding(.top, 22)
                VStack(spacing: 3) {
                    Text(title).font(.round(17, .semibold)).foregroundStyle(.white)
                    Text(tagline).font(.round(13, .medium)).foregroundStyle(.white.opacity(0.55))
                }
                .padding(.top, 16)
                styleStrip.padding(.top, 18)
                Spacer(minLength: 0)
                actionBar.padding(.bottom, 34)
            }
            if mode == .options { optionsSheet }
        }
        .frame(width: screen.width, height: screen.height)
        .clipShape(RoundedRectangle(cornerRadius: 54, style: .continuous))
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack {
            glassCircle("xmark")
            Spacer()
            if mode == .sticker {
                Text("Sticker").font(.round(15, .semibold)).foregroundStyle(.white)
                    .padding(.horizontal, 18).frame(height: 40)
                    .background(.white.opacity(0.10), in: Capsule())
            } else {
                HStack(spacing: 0) {
                    segment("Story", selected: true)
                    segment("Post", selected: false)
                    segment("Square", selected: false)
                }
                .padding(3)
                .background(.white.opacity(0.10), in: Capsule())
            }
            Spacer()
            glassCircle("slider.horizontal.3")
        }
        .padding(.horizontal, 18)
    }

    private func segment(_ label: String, selected: Bool) -> some View {
        Text(label)
            .font(.round(13.5, .semibold))
            .foregroundStyle(.white.opacity(selected ? 1 : 0.62))
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(selected ? Color.white.opacity(0.18) : .clear, in: Capsule())
    }

    private func glassCircle(_ symbol: String, size: CGFloat = 44) -> some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.38, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(.white.opacity(0.12), in: Circle())
            .overlay(Circle().stroke(.white.opacity(0.14), lineWidth: 1))
    }

    // MARK: Preview pager

    private var preview: some View {
        let w: CGFloat = 236, h: CGFloat = 236 * 16 / 9
        return ZStack {
            page(previous, w: w, h: h).scaleEffect(0.88).offset(x: -(w * 0.94 + 14)).opacity(0.55)
            page(next, w: w, h: h).scaleEffect(0.88).offset(x: w * 0.94 + 14).opacity(0.55)
            page(current, w: w, h: h)
                .shadow(color: .black.opacity(0.5), radius: 24, y: 14)
                .overlay(alignment: .top) {
                    if mode == .sticker {
                        Label("Choose photo or video", systemImage: "photo.on.rectangle")
                            .font(.round(12.5, .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12).frame(height: 32)
                            .background(.black.opacity(0.55), in: Capsule())
                            .padding(.top, 14)
                    }
                }
        }
        .frame(width: screen.width, height: h)
    }

    private func page(_ image: CGImage, w: CGFloat, h: CGFloat) -> some View {
        Image(decorative: image, scale: 1)
            .resizable()
            .interpolation(.high)
            .frame(width: w, height: h)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    // MARK: Style strip

    private var styleStrip: some View {
        VStack(spacing: 10) {
            HStack(spacing: 18) {
                ForEach(ShareCardGroup.allCases, id: \.self) { group in
                    let on = (mode == .sticker) ? group == .sticker : group == .classCard
                    Text(group.rawValue)
                        .font(.round(12.5, .semibold))
                        .foregroundStyle(.white.opacity(on ? 1 : 0.45))
                }
            }
            HStack(spacing: 9) {
                ForEach(strip.indices, id: \.self) { i in
                    Image(decorative: strip[i].image, scale: 1)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 43, height: 76)
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(.white, lineWidth: i == selectedIndex ? 2 : 0)
                                .padding(-3.5)
                        }
                        .opacity(i == selectedIndex ? 1 : 0.8)
                }
            }
            .frame(width: screen.width, alignment: .leading)
            .offset(x: stripOffset)
        }
    }

    /// Centres the selected thumbnail, as the real strip would scroll to it.
    private var stripOffset: CGFloat {
        let slot: CGFloat = 43 + 9
        return screen.width / 2 - (CGFloat(selectedIndex) * slot + 43 / 2)
    }

    // MARK: Actions

    private var actionBar: some View {
        HStack(spacing: 10) {
            Label("Add to Story", systemImage: "plus.circle.fill")
                .font(.round(17, .semibold))
                .foregroundStyle(Color(hex: 0x1B1408))
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Palette.saffron, in: Capsule())
            if mode == .sticker { glassCircle("doc.on.doc", size: 54) }
            glassCircle("arrow.down.to.line", size: 54)
            glassCircle("square.and.arrow.up", size: 54)
        }
        .padding(.horizontal, 18)
    }

    // MARK: Options sheet

    private var optionsSheet: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.35)
            VStack(alignment: .leading, spacing: 0) {
                Capsule().fill(.white.opacity(0.3)).frame(width: 36, height: 5)
                    .frame(maxWidth: .infinity).padding(.top, 8)
                HStack {
                    Text(title).font(.round(20, .bold)).foregroundStyle(.white)
                    Spacer()
                    Text("Done").font(.round(15, .semibold)).foregroundStyle(Color(hex: 0x1B1408))
                        .padding(.horizontal, 16).frame(height: 36)
                        .background(Palette.saffron, in: Capsule())
                }
                .padding(.top, 16)

                VStack(spacing: 0) {
                    row("Line") {
                        HStack(spacing: 6) {
                            Text("If you lose the breath…").font(.round(15, .medium)).foregroundStyle(.white.opacity(0.6))
                            Image(systemName: "chevron.up.chevron.down").font(.system(size: 12, weight: .semibold)).foregroundStyle(.white.opacity(0.45))
                        }
                    }
                    divider
                    row("Background") {
                        HStack(spacing: 0) {
                            segment("Colour", selected: true)
                            segment("Photo", selected: false)
                            segment("Paper", selected: false)
                        }
                        .padding(3)
                        .background(.white.opacity(0.08), in: Capsule())
                    }
                    divider
                    row("Teacher's name") {
                        Capsule().fill(Palette.saffron).frame(width: 51, height: 31)
                            .overlay(alignment: .trailing) { Circle().fill(.white).frame(width: 27, height: 27).padding(2) }
                    }
                }
                .padding(.horizontal, 16)
                .background(Color(hex: 0x2A2830), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                .padding(.top, 18)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .frame(width: screen.width, height: 330)
            .background(Color(hex: 0x1C1A21), in: UnevenRoundedRectangle(topLeadingRadius: 38, topTrailingRadius: 38, style: .continuous))
        }
    }

    private var divider: some View { Rectangle().fill(.white.opacity(0.1)).frame(height: 1) }

    private func row<Trailing: View>(_ label: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack {
            Text(label).font(.round(16, .medium)).foregroundStyle(.white)
            Spacer()
            trailing()
        }
        .frame(height: 54)
    }
}
