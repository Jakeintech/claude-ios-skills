// Share card prototype: the styles. One small view each.

import SwiftUI

// MARK: - 1. One Number

/// A single large number over a photo. The simplest card there is.
struct OneNumberStyle: ShareCardStyle {
    let id = "one-number", name = "One Number", tagline = "One big number over your photo."
    let symbol = "textformat.123", group = ShareCardGroup.simple
    let backgrounds = ["Photo", "Class colour"]
    let options = ["Number: minutes, songs or peak", "Teacher", "Studio"]

    func body(_ ctx: ShareCardContext) -> AnyView {
        let c = ctx.content
        return AnyView(CardFrame(ctx: ctx) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(c.minutes)")
                        .font(.round(ctx.pick(176, 150, 128)))
                        .tracking(-5)
                    Text("min")
                        .font(.round(ctx.pick(30, 26, 24), .semibold))
                        .opacity(0.86)
                }
                .padding(.bottom, ctx.pick(-10, -8, -8))
                Text(c.title)
                    .font(.round(ctx.pick(24, 22, 21), .semibold))
                HStack(alignment: .firstTextBaseline) {
                    Text(c.placeLine)
                        .font(.round(14, .medium))
                        .opacity(0.8)
                    Spacer(minLength: 8)
                    Wordmark()
                }
                .padding(.top, 5)
            }
        })
    }
}

// MARK: - 2. Quiet

/// Text only. No photo, no chart.
struct QuietStyle: ShareCardStyle {
    let id = "quiet", name = "Quiet", tagline = "Words only, lots of room."
    let symbol = "text.alignleft", group = ShareCardGroup.simple
    let backgrounds = ["Dark", "Paper", "Class colour"]
    let options = ["Teacher", "Studio", "Songs"]

    func body(_ ctx: ShareCardContext) -> AnyView {
        let c = ctx.content
        return AnyView(CardFrame(ctx: ctx, alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                Kicker(text: "\(c.style) · \(c.shortDateText)", color: ctx.ink, dot: true)
                Spacer(minLength: 12)
                Text(c.title)
                    .font(.round(ctx.pick(50, 46, 42)))
                    .tracking(-1)
                    .lineSpacing(-4)
                    .fixedSize(horizontal: false, vertical: true)
                Rectangle()
                    .fill(ctx.ink.opacity(0.18))
                    .frame(height: 1)
                    .padding(.vertical, ctx.pick(22, 18, 16))
                VStack(alignment: .leading, spacing: ctx.pick(7, 6, 5)) {
                    Text("\(c.minutes) minutes")
                    Text("\(c.songs.count) songs")
                    if let studio = c.studio { Text(studio) }
                }
                .font(.round(ctx.pick(18, 17, 16), .medium))
                .opacity(0.86)
                HStack { Spacer(); Wordmark(color: ctx.ink) }
                    .padding(.top, ctx.pick(18, 6, 2))
            }
        })
    }
}

// MARK: - 3. Caption

/// The photo is the card. One thin bar carries the class.
struct CaptionStyle: ShareCardStyle {
    let id = "caption", name = "Caption", tagline = "Your photo, one thin line of class."
    let symbol = "rectangle.bottomthird.inset.filled", group = ShareCardGroup.simple
    let backgrounds = ["Photo"]
    let options = ["Bar: dark or light", "Teacher", "Studio"]
    var light = false

    func body(_ ctx: ShareCardContext) -> AnyView {
        let c = ctx.content
        let fg: Color = light ? Palette.ink : .white
        return AnyView(CardFrame(ctx: ctx, scrim: .none, alignment: .bottom) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(c.title).font(.round(15, .semibold))
                    Text(c.studio ?? c.style).font(.round(12, .medium)).opacity(0.7)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(c.minutes) min").font(.round(15, .semibold))
                    Text("\(c.songs.count) songs").font(.round(12, .medium)).opacity(0.7)
                }
            }
            .lineLimit(1)
            .foregroundStyle(fg)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background((light ? Palette.paper : Palette.ink).opacity(0.94), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, -8)
        })
    }
}

// MARK: - 4. Stickers (transparent, for the person's own Story photo or video)

struct PillSticker: ShareCardStyle {
    let id = "sticker-pill", name = "Pill", tagline = "Small. Tuck it in a corner."
    let symbol = "capsule", group = ShareCardGroup.sticker, kind = ShareCardKind.sticker
    let backgrounds = ["Clear"]
    let options = ["Dark or light"]
    var light = false

    func body(_ ctx: ShareCardContext) -> AnyView {
        let c = ctx.content
        return AnyView(
            HStack(spacing: 9) {
                Circle().fill(Palette.saffron).frame(width: 7, height: 7)
                Text(c.title).font(.round(15, .semibold))
                Text("\(c.minutes) min").font(.round(15, .medium)).opacity(0.7)
            }
            .foregroundStyle(light ? Palette.ink : .white)
            .padding(.horizontal, 17)
            .padding(.vertical, 11)
            .background((light ? Palette.paper : Palette.ink).opacity(0.94), in: Capsule())
            .padding(10)
        )
    }
}

struct StackSticker: ShareCardStyle {
    let id = "sticker-stack", name = "Stack", tagline = "Bare type, no box."
    let symbol = "textformat.size", group = ShareCardGroup.sticker, kind = ShareCardKind.sticker
    let backgrounds = ["Clear"]
    let options = ["Number: minutes, songs or peak", "White or dark"]

    func body(_ ctx: ShareCardContext) -> AnyView {
        let c = ctx.content
        return AnyView(
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text("\(c.minutes)").font(.round(104)).tracking(-3)
                    Text("min").font(.round(22, .semibold)).opacity(0.9)
                }
                .padding(.bottom, -8)
                Text(c.title).font(.round(21, .semibold))
                Text([c.studio, "\(c.songs.count) songs"].compactMap { $0 }.joined(separator: " · "))
                    .font(.round(13.5, .medium)).opacity(0.88)
                    .padding(.top, 3)
                Wordmark().padding(.top, 10)
            }
            .foregroundStyle(.white)
            .overPhotoShadow()
            .padding(18)
        )
    }
}

struct LowerThirdSticker: ShareCardStyle {
    let id = "sticker-wide", name = "Lower Third", tagline = "Wide, with the shape of the class."
    let symbol = "rectangle.bottomthird.inset.filled", group = ShareCardGroup.sticker, kind = ShareCardKind.sticker
    let backgrounds = ["Clear"]
    let options = ["Heart-rate line", "Teacher"]

    func body(_ ctx: ShareCardContext) -> AnyView {
        let c = ctx.content
        return AnyView(
            VStack(alignment: .leading, spacing: 10) {
                if let heart = c.heart {
                    TideView(heart: heart, lineWidth: 2.2, fill: false)
                        .frame(height: 30)
                }
                HStack(alignment: .lastTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(c.title).font(.round(17, .semibold))
                        Text(c.studio ?? c.style).font(.round(12.5, .medium)).opacity(0.72)
                    }
                    Spacer(minLength: 10)
                    Text("\(c.minutes) min · \(c.songs.count) songs")
                        .font(.round(12.5, .semibold))
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 15)
            .frame(width: 320)
            .background(Palette.ink.opacity(0.9), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(10)
        )
    }
}

// MARK: - 5. Setlist

/// The playlist from class, in the order it was played.
struct SetlistStyle: ShareCardStyle {
    let id = "setlist", name = "Setlist", tagline = "Every song, in the order it played."
    let symbol = "music.note.list", group = ShareCardGroup.classCard
    let backgrounds = ["Class colour", "Photo", "Dark"]
    let options = ["Times", "Teacher"]

    func body(_ ctx: ShareCardContext) -> AnyView {
        let c = ctx.content
        let limit = ctx.pick(10, 7, 5)
        let shown = Array(c.songs.prefix(limit))
        let rest = c.songs.count - shown.count
        return AnyView(CardFrame(ctx: ctx, scrim: .haze, alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                Kicker(text: "Played in class", dot: true)
                Text(c.title)
                    .font(.round(ctx.pick(28, 26, 24)))
                    .padding(.top, 6)
                Spacer(minLength: ctx.pick(18, 12, 10))
                VStack(alignment: .leading, spacing: ctx.pick(13, 11.5, 10.5)) {
                    ForEach(shown) { song in
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text(song.clock)
                                .font(.clock(11))
                                .foregroundStyle(Palette.music)
                                .fixedSize()
                                .frame(width: 50, alignment: .leading)
                            ViewThatFits(in: .horizontal) {
                                HStack(alignment: .firstTextBaseline, spacing: 10) {
                                    Text(song.title).font(.round(15.5, .semibold))
                                    Text(song.artist).font(.round(12.5, .medium)).opacity(0.66)
                                }
                                .fixedSize()
                                Text(song.title).font(.round(15.5, .semibold))
                            }
                            Spacer(minLength: 0)
                        }
                        .lineLimit(1)
                    }
                    if rest > 0 {
                        Text("and \(rest) more")
                            .font(.round(12.5, .medium))
                            .opacity(0.66)
                            .padding(.leading, 62)
                    }
                }
                Spacer(minLength: ctx.pick(18, 12, 10))
                HStack(alignment: .firstTextBaseline) {
                    Text("\(c.songs.count) songs · \(c.minutes) min" + (c.teacher.map { " · with \($0)" } ?? ""))
                        .font(.round(12.5, .medium))
                        .opacity(0.8)
                    Spacer(minLength: 8)
                    Wordmark()
                }
            }
        })
    }
}

// MARK: - 6. Teacher's Line

/// One thing the teacher said, set large.
struct TeacherLineStyle: ShareCardStyle {
    let id = "teacher-line", name = "Teacher's Line", tagline = "One line worth keeping, set large."
    let symbol = "quote.opening", group = ShareCardGroup.classCard
    let backgrounds = ["Class colour", "Photo", "Paper"]
    let options = ["Which line", "Teacher's name"]

    func isAvailable(for content: ShareCardContent) -> Bool { content.line != nil }

    func body(_ ctx: ShareCardContext) -> AnyView {
        let c = ctx.content
        return AnyView(CardFrame(ctx: ctx, scrim: .haze, alignment: .leading) {
            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 0)
                Image(systemName: "quote.opening")
                    .font(.system(size: ctx.pick(26, 24, 22), weight: .bold))
                    .foregroundStyle(Palette.saffron)
                    .padding(.bottom, ctx.pick(16, 14, 12))
                Text(c.line?.text ?? "")
                    .font(.words(ctx.pick(40, 37, 33)))
                    .lineSpacing(1)
                    .fixedSize(horizontal: false, vertical: true)
                VStack(alignment: .leading, spacing: 3) {
                    if let speaker = c.line?.speaker {
                        Text(speaker).font(.round(17, .semibold))
                    }
                    Text([c.style, c.studio].compactMap { $0 }.joined(separator: " · "))
                        .font(.round(13, .medium)).opacity(0.76)
                }
                .padding(.top, ctx.pick(24, 20, 16))
                Spacer(minLength: 0)
                HStack { Spacer(); Wordmark(color: ctx.ink) }
            }
        })
    }
}

// MARK: - 7. Tide

/// The heart-rate line as the hero. Words by default, numbers by choice.
struct TideStyle: ShareCardStyle {
    let id = "tide", name = "Tide", tagline = "The shape of your effort, start to savasana."
    let symbol = "water.waves", group = ShareCardGroup.classCard
    let backgrounds = ["Class colour", "Dark", "Photo"]
    let options = ["Show beats per minute", "Teacher"]
    var showsBPM = false

    func isAvailable(for content: ShareCardContent) -> Bool { content.heart != nil }

    func body(_ ctx: ShareCardContext) -> AnyView {
        let c = ctx.content
        guard let heart = c.heart else { return AnyView(EmptyView()) }
        let tideHeight: CGFloat = ctx.pick(190, 132, 96)
        return AnyView(CardFrame(ctx: ctx, scrim: .haze, alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Kicker(text: "\(c.style) · \(c.shortDateText)", dot: true)
                    Spacer(minLength: 8)
                    Wordmark()
                }
                Text(c.title)
                    .font(.round(ctx.pick(28, 26, 24)))
                    .padding(.top, 6)
                Spacer(minLength: 8)
                VStack(spacing: 6) {
                    TideView(heart: heart, lineWidth: 3)
                        .frame(height: tideHeight)
                    HStack {
                        Text(c.timeText)
                        Spacer()
                        Text("\(c.minutes) min")
                    }
                    .font(.clock(10.5))
                    .opacity(0.66)
                    .padding(.horizontal, ctx.insets.leading)
                }
                // The line runs edge to edge; only the labels keep the margin.
                .padding(.horizontal, -ctx.insets.leading)
                Spacer(minLength: 8)
                HStack(alignment: .lastTextBaseline, spacing: ctx.pick(28, 28, 24)) {
                    if showsBPM {
                        metric("Peak", "\(heart.peakBPM)", size: ctx.pick(40, 36, 32))
                        metric("Average", "\(heart.averageBPM)", size: ctx.pick(40, 36, 32))
                    } else {
                        metric("Effort", heart.effortWord, size: ctx.pick(34, 31, 28))
                        metric("Ease", heart.easeWord, size: ctx.pick(34, 31, 28))
                    }
                    Spacer(minLength: 0)
                }
            }
        })
    }

    private func metric(_ label: String, _ value: String, size: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label).font(.round(12, .medium)).opacity(0.7)
            Text(value).font(.round(size)).tracking(-0.5)
        }
        .fixedSize()
    }
}

// MARK: - 8. Ticket

/// A paper stub from the class.
struct TicketStyle: ShareCardStyle {
    let id = "ticket", name = "Ticket", tagline = "A stub from the class you took."
    let symbol = "ticket", group = ShareCardGroup.classCard
    let backgrounds = ["Class colour", "Photo", "Dark"]
    let options = ["Ticket or receipt", "Teacher", "Studio"]

    func body(_ ctx: ShareCardContext) -> AnyView {
        let c = ctx.content
        let compact = ctx.format == .square
        let width: CGFloat = ctx.pick(288, 280, 268)
        let stubHeight: CGFloat = ctx.pick(86, 72, 62)
        return AnyView(CardFrame(ctx: ctx, scrim: .haze, alignment: .center) {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Wordmark(color: Palette.ink)
                        Spacer()
                        Text(String(format: "No. %03d", c.classNumber)).font(.clock(10)).opacity(0.6)
                    }
                    Text(c.title.uppercased())
                        .font(.round(ctx.pick(30, 27, 23), .heavy))
                        .tracking(-0.3)
                        .lineSpacing(-3)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, ctx.pick(18, 12, 9))
                    Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: ctx.pick(14, 10, 8)) {
                        GridRow {
                            field("Date", c.dateText)
                            field("Time", c.timeText)
                        }
                        GridRow {
                            field("Studio", c.studio ?? "—")
                            field("Teacher", c.teacher ?? "—")
                        }
                        if !compact {
                            GridRow {
                                field("Length", "\(c.minutes) min")
                                field("Songs", "\(c.songs.count)")
                            }
                        }
                    }
                    .padding(.top, ctx.pick(18, 12, 10))
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, ctx.pick(18, 14, 12))

                Line()
                    .stroke(Palette.ink.opacity(0.28), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .frame(height: 1)
                    .padding(.horizontal, 14)

                HStack(alignment: .bottom, spacing: 14) {
                    barcode(c.heart?.curve ?? [])
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(compact ? "\(c.minutes) min" : "ADMIT ONE").font(.clock(9.5, .bold))
                        Text(compact ? "\(c.songs.count) songs" : (c.city ?? "")).font(.clock(9.5)).opacity(0.6)
                    }
                }
                .padding(.horizontal, 20)
                .frame(height: stubHeight)
            }
            .foregroundStyle(Palette.ink)
            .frame(width: width)
            .background(Palette.paper, in: TicketShape(notchFromBottom: stubHeight, notchRadius: 9, cornerRadius: 18))
            .shadow(color: .black.opacity(0.32), radius: 18, y: 10)
            .rotationEffect(.degrees(-2.5))
        })
    }

    private func field(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased()).font(.clock(8.5, .semibold)).tracking(1.2).opacity(0.5)
            Text(value).font(.round(13.5, .semibold)).lineLimit(1).minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The class's heart-rate curve as bar widths: every ticket is different.
    private func barcode(_ curve: [Double]) -> some View {
        GeometryReader { geo in
            let count = 44
            let slot = geo.size.width / CGFloat(count)
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(0..<count, id: \.self) { i in
                    let v = curve.isEmpty ? 0.5 : curve[min(curve.count - 1, i * curve.count / count)]
                    Rectangle()
                        .frame(width: max(1, slot * (0.25 + 0.6 * v)), height: geo.size.height)
                        .frame(width: slot, alignment: .leading)
                }
            }
        }
        .frame(height: 34)
        .padding(.bottom, 0)
    }
}

private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return p
    }
}

struct TicketShape: Shape {
    let notchFromBottom: CGFloat
    let notchRadius: CGFloat
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path(roundedRect: rect, cornerRadius: cornerRadius, style: .continuous)
        let y = rect.maxY - notchFromBottom
        let notches = Path { p in
            p.addEllipse(in: CGRect(x: rect.minX - notchRadius, y: y - notchRadius, width: notchRadius * 2, height: notchRadius * 2))
            p.addEllipse(in: CGRect(x: rect.maxX - notchRadius, y: y - notchRadius, width: notchRadius * 2, height: notchRadius * 2))
        }
        path = path.subtracting(notches)
        return path
    }
}

// MARK: - 9. Memory (the full card)

/// Everything about the class, without boxes.
struct MemoryStyle: ShareCardStyle {
    let id = "memory", name = "Memory", tagline = "The whole class on one card."
    let symbol = "sparkles.rectangle.stack", group = ShareCardGroup.classCard
    let backgrounds = ["Class colour", "Photo", "Dark"]
    let options = ["Teacher's line", "Songs", "Heart-rate line"]

    func body(_ ctx: ShareCardContext) -> AnyView {
        let c = ctx.content
        let songCount = ctx.pick(3, 3, 0)
        return AnyView(CardFrame(ctx: ctx, scrim: .haze, alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                Kicker(text: "\(c.style) · \(c.shortDateText)", dot: true)
                Text(c.title)
                    .font(.round(ctx.pick(34, 30, 28)))
                    .tracking(-0.5)
                    .padding(.top, 6)
                Text([c.studio, "\(c.minutes) min", "\(c.songs.count) songs"].compactMap { $0 }.joined(separator: " · "))
                    .font(.round(13.5, .medium)).opacity(0.78)
                    .padding(.top, 3)

                Spacer(minLength: 10)
                if let line = c.line {
                    Text("“\(line.text)”")
                        .font(.words(ctx.pick(25, 21, 21)))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 10)
                if let heart = c.heart {
                    VStack(alignment: .leading, spacing: 6) {
                        TideView(heart: heart, lineWidth: 2.2, peakDot: false)
                            .frame(height: ctx.pick(54, 38, 40))
                            .padding(.horizontal, -ctx.insets.leading)
                        Text("\(heart.effortWord) effort · \(heart.easeWord.lowercased()) ease")
                            .font(.round(12.5, .medium)).opacity(0.78)
                    }
                }
                if songCount > 0 {
                    Spacer(minLength: 10)
                    VStack(alignment: .leading, spacing: ctx.pick(9, 7, 7)) {
                        ForEach(c.songs.prefix(songCount)) { song in
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                Image(systemName: "music.note")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Palette.music)
                                Text(song.title).font(.round(14.5, .semibold)).layoutPriority(1)
                                Text(song.artist).font(.round(12.5, .medium)).opacity(0.66)
                            }
                            .lineLimit(1)
                        }
                    }
                }
                Spacer(minLength: 10)
                HStack(alignment: .firstTextBaseline) {
                    if songCount > 0 {
                        Text("and \(c.songs.count - songCount) more songs").font(.round(12.5, .medium)).opacity(0.66)
                    }
                    Spacer()
                    Wordmark()
                }
            }
        })
    }
}

// MARK: - 10. Song

/// One song from the class as the hero.
struct SongStyle: ShareCardStyle {
    let id = "song", name = "Song", tagline = "The one song you want to remember."
    let symbol = "music.note", group = ShareCardGroup.classCard
    let backgrounds = ["Class colour", "Dark"]
    let options = ["Which song", "Teacher"]

    func isAvailable(for content: ShareCardContent) -> Bool { !content.songs.isEmpty }

    func body(_ ctx: ShareCardContext) -> AnyView {
        let c = ctx.content
        guard let song = c.songs.last else { return AnyView(EmptyView()) }
        let art: CGFloat = ctx.pick(236, 196, 132)
        let artwork = ArtworkPlaceholder(seed: song.id)
            .frame(width: art, height: art)
            .clipShape(RoundedRectangle(cornerRadius: art * 0.1, style: .continuous))
            .shadow(color: .black.opacity(0.35), radius: 20, y: 12)
        let words = VStack(alignment: .leading, spacing: 0) {
            Kicker(text: "The savasana song")
            Text(song.title)
                .font(.round(ctx.pick(32, 29, 27)))
                .tracking(-0.5)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 5)
            Text(song.artist)
                .font(.round(ctx.pick(18, 17, 16), .medium)).opacity(0.82)
        }
        return AnyView(CardFrame(ctx: ctx, scrim: .haze, alignment: .leading) {
            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 0)
                if ctx.format == .square {
                    HStack(alignment: .center, spacing: 18) { artwork; words }
                } else {
                    artwork
                    words.padding(.top, ctx.pick(24, 18, 0))
                }
                Spacer(minLength: 0)
                HStack(alignment: .firstTextBaseline) {
                    Text("\(song.clock) into \(c.title)")
                        .font(.round(12.5, .medium)).opacity(0.72)
                    Spacer(minLength: 8)
                    Wordmark()
                }
            }
        })
    }
}

/// Stand-in for album artwork (the gallery has no real artwork).
struct ArtworkPlaceholder: View {
    let seed: Int
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x2B2A4A), Color(hex: 0x0F1020)], startPoint: .top, endPoint: .bottom)
            GeometryReader { geo in
                let s = geo.size.width
                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .stroke(Color(hex: 0xF2C9A0).opacity(0.75 - Double(i) * 0.11), lineWidth: s * 0.012)
                        .frame(width: s * (0.2 + CGFloat(i) * 0.19), height: s * (0.2 + CGFloat(i) * 0.19))
                        .position(x: s * 0.5, y: s * 0.86)
                }
                Circle().fill(Color(hex: 0xF2C9A0)).frame(width: s * 0.1, height: s * 0.1).position(x: s * 0.5, y: s * 0.86)
            }
        }
    }
}

// MARK: - 11. Month

/// The month on the mat.
struct MonthStyle: ShareCardStyle {
    let id = "month", name = "Month", tagline = "Your month on the mat."
    let symbol = "calendar", group = ShareCardGroup.recap, tier = ShareCardTier.pro
    let backgrounds = ["Class colour", "Dark", "Paper"]
    let options = ["Which month", "Teacher you saw most"]

    func isAvailable(for content: ShareCardContent) -> Bool { content.month != nil }

    func body(_ ctx: ShareCardContext) -> AnyView {
        guard let m = ctx.content.month else { return AnyView(EmptyView()) }
        let story = ctx.format == .story
        let gap: CGFloat = ctx.pick(10, 7, 6)
        let width = ctx.size.width - ctx.insets.leading - ctx.insets.trailing
        // Story: the dots span the card. Shorter formats: dots beside the numbers.
        let dot: CGFloat = story ? (width - gap * 6) / 7 : ctx.pick(0, 22, 17)
        return AnyView(CardFrame(ctx: ctx, alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                Kicker(text: "My month on the mat", color: ctx.ink, dot: true)
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(m.name).font(.round(ctx.pick(54, 46, 40))).tracking(-1)
                    Text(String(m.year)).font(.round(ctx.pick(20, 18, 16), .semibold)).opacity(0.6)
                }
                .padding(.top, 4)
                Spacer(minLength: 8)
                if story {
                    dots(m, dot: dot, gap: gap, ink: ctx.ink)
                    Spacer(minLength: 8)
                    HStack(alignment: .lastTextBaseline, spacing: 26) { metrics(m, ctx) }
                } else {
                    HStack(alignment: .center, spacing: 0) {
                        dots(m, dot: dot, gap: gap, ink: ctx.ink)
                        Spacer(minLength: 12)
                        VStack(alignment: .leading, spacing: ctx.pick(0, 8, 4)) { metrics(m, ctx) }
                    }
                }
                Spacer(minLength: story ? 0 : 8)
                HStack(alignment: .firstTextBaseline) {
                    Text([m.topTeacher.map { "Most often with \($0)" }, "\(m.studios) studios"].compactMap { $0 }.joined(separator: " · "))
                        .font(.round(12.5, .medium)).opacity(0.76)
                    Spacer(minLength: 8)
                    Wordmark(color: ctx.ink)
                }
                .padding(.top, story ? 16 : 0)
            }
        })
    }

    private func dots(_ m: ShareCardContent.Month, dot: CGFloat, gap: CGFloat, ink: Color) -> some View {
        let cells = Array(repeating: 0, count: m.leadingBlanks) + Array(1...m.dayCount)
        let rows = stride(from: 0, to: cells.count, by: 7).map { Array(cells[$0..<min($0 + 7, cells.count)]) }
        return Grid(horizontalSpacing: gap, verticalSpacing: gap) {
            ForEach(rows.indices, id: \.self) { r in
                GridRow {
                    ForEach(rows[r].indices, id: \.self) { i in
                        let day = rows[r][i]
                        Group {
                            if day == 0 {
                                Color.clear
                            } else if m.classDays.contains(day) {
                                Circle().fill(ink)
                            } else {
                                Circle().fill(ink.opacity(0.14))
                            }
                        }
                        .frame(width: dot, height: dot)
                    }
                }
            }
        }
    }

    @ViewBuilder private func metrics(_ m: ShareCardContent.Month, _ ctx: ShareCardContext) -> some View {
        metric("\(m.classes)", "classes", ctx)
        metric(m.hoursText, "on the mat", ctx)
        metric("\(m.songs)", "songs", ctx)
    }

    private func metric(_ value: String, _ unit: String, _ ctx: ShareCardContext) -> some View {
        VStack(alignment: .leading, spacing: -2) {
            Text(value).font(.round(ctx.pick(40, 32, 27))).tracking(-0.5)
            Text(unit).font(.round(12.5, .medium)).opacity(0.72)
        }
        .fixedSize()
    }
}

// MARK: - 12. Thank You

/// A card made to be sent to, and reposted by, the teacher.
struct ThanksStyle: ShareCardStyle {
    let id = "thanks", name = "Thank You", tagline = "A card for your teacher to repost."
    let symbol = "person.2", group = ShareCardGroup.recap
    let backgrounds = ["Class colour", "Photo", "Paper"]
    let options = ["Their line", "Classes together"]

    func isAvailable(for content: ShareCardContent) -> Bool { content.teacher != nil }

    func body(_ ctx: ShareCardContext) -> AnyView {
        let c = ctx.content
        return AnyView(CardFrame(ctx: ctx, scrim: .haze, alignment: .leading) {
            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 0)
                Kicker(text: "For my teacher", color: ctx.ink, dot: true)
                Text("Thank you,\n\(c.teacher ?? "").")
                    .font(.round(ctx.pick(60, 54, 48)))
                    .tracking(-1.5)
                    .lineSpacing(-6)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                if let line = c.line {
                    Text("“\(line.text)”")
                        .font(.words(ctx.pick(22, 20, 19)))
                        .opacity(0.92)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, ctx.pick(22, 16, 12))
                }
                Spacer(minLength: 0)
                HStack(alignment: .lastTextBaseline) {
                    VStack(alignment: .leading, spacing: 3) {
                        if let tally = c.withTeacher {
                            Text("\(tally.classes) classes together · \(tally.songs) songs")
                                .font(.round(13.5, .semibold))
                        }
                        Text([c.style, c.studio].compactMap { $0 }.joined(separator: " · "))
                            .font(.round(12.5, .medium)).opacity(0.74)
                    }
                    Spacer(minLength: 8)
                    Wordmark(color: ctx.ink)
                }
            }
        })
    }
}
