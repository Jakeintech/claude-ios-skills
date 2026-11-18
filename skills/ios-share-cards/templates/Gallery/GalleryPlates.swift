// Gallery only: demo class data and drawn stand-in photos.
//
// The photos are drawn, not real: a bright studio (the hard case for white
// text), a candle-lit room (the dark case) and a dusk sky (the busy case).

import SwiftUI

extension ShareCardContent {
    /// "Vinyasa with Maya" from DemoSeedService, as the app shows it.
    static let demo: ShareCardContent = {
        let catalog: [(String, String)] = [
            ("You Can't Rush Your Healing", "Trevor Hall"), ("The Lime Tree", "Trevor Hall"),
            ("10 Laws", "East Forest"), ("Ricochet", "East Forest"), ("Awake", "Tycho"),
            ("A Moment Apart", "ODESZA"), ("Line of Sight", "ODESZA"), ("Kerala", "Bonobo"),
            ("Cirrus", "Bonobo"), ("Break Apart", "Bonobo"),
        ]
        let songLength = 4500.0 / 11
        let songs = catalog.enumerated().map { i, s in
            Song(id: i, title: s.0, artist: s.1, offset: Double(i) * songLength + 30)
        }
        // Warm-up, two waves, a peak near 60%, cool-down, savasana.
        let curve: [Double] = (0..<72).map { i in
            let t = Double(i) / 71
            let warm = min(t / 0.18, 1)
            let cool = t > 0.72 ? max(0, 1 - (t - 0.72) / 0.2) : 1
            let wave = 0.10 * sin(t * 21) + 0.05 * sin(t * 47 + 1)
            let peak = 0.22 * exp(-pow((t - 0.60) / 0.07, 2))
            let v = (0.12 + 0.52 * warm + wave * warm + peak) * (0.25 + 0.75 * cool)
            return min(max(v, 0.05), 0.98)
        }
        return ShareCardContent(
            title: "Vinyasa with Maya", style: "Vinyasa Flow",
            dateText: "Thu 5 Nov 2026", shortDateText: "Thu 5 Nov", timeText: "9:30 AM",
            minutes: 75, classNumber: 6,
            teacher: "Maya", studio: "Sunrise Yoga Loft", city: "SAN FRANCISCO",
            songs: songs,
            line: Line(text: "If you lose the breath, you've left the pose.", speaker: "Maya"),
            heart: Heart(curve: curve, peakBPM: 150, averageBPM: 118, effortWord: "Steady", easeWord: "Balanced"),
            // October 2026 in the seed: 7, 12, 18, 23 and 30 October.
            month: Month(name: "October", year: 2026, dayCount: 31, leadingBlanks: 3,
                         classDays: [7, 12, 18, 23, 30], classes: 5, minutes: 330, songs: 37, studios: 5,
                         topTeacher: "Leo Okafor"),
            withTeacher: TeacherTally(classes: 2, songs: 18),
            mood: .stillHeart
        )
    }()
}

// MARK: - Drawn photos

struct StudioPlate: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let floorY = h * 0.60
            // Wall
            ctx.fill(Path(CGRect(x: 0, y: 0, width: w, height: floorY)),
                     with: .linearGradient(Gradient(colors: [Color(hex: 0xF4ECE0), Color(hex: 0xE6D8C4)]),
                                           startPoint: .zero, endPoint: CGPoint(x: 0, y: floorY)))
            // Floor
            ctx.fill(Path(CGRect(x: 0, y: floorY, width: w, height: h - floorY)),
                     with: .linearGradient(Gradient(colors: [Color(hex: 0xD3AE84), Color(hex: 0xA57C54)]),
                                           startPoint: CGPoint(x: 0, y: floorY), endPoint: CGPoint(x: 0, y: h)))
            // Planks towards a vanishing point
            let vp = CGPoint(x: w * 0.42, y: floorY - h * 0.08)
            for i in -6...14 {
                var p = Path()
                p.move(to: CGPoint(x: vp.x + (CGFloat(i) * w * 0.02), y: floorY))
                p.addLine(to: CGPoint(x: vp.x + (CGFloat(i) - 4) * w * 0.26 + w * 0.9, y: h))
                ctx.stroke(p, with: .color(Color(hex: 0x7A5636).opacity(0.28)), lineWidth: 1)
            }
            // Window: two tall panes, blown out
            let win = CGRect(x: w * 0.10, y: h * 0.09, width: w * 0.52, height: h * 0.41)
            ctx.fill(Path(win), with: .color(Color(hex: 0xFFFDF6)))
            for i in 1..<3 {
                let x = win.minX + win.width * CGFloat(i) / 3
                ctx.fill(Path(CGRect(x: x - 2, y: win.minY, width: 4, height: win.height)), with: .color(Color(hex: 0xD9CBB6)))
            }
            ctx.fill(Path(CGRect(x: win.minX, y: win.midY - 2, width: win.width, height: 4)), with: .color(Color(hex: 0xD9CBB6)))
            // Light on the floor
            var light = Path()
            light.move(to: CGPoint(x: w * 0.12, y: floorY + 4))
            light.addLine(to: CGPoint(x: w * 0.60, y: floorY + 4))
            light.addLine(to: CGPoint(x: w * 0.98, y: h * 0.86))
            light.addLine(to: CGPoint(x: w * 0.28, y: h * 0.86))
            light.closeSubpath()
            ctx.fill(light, with: .color(Color(hex: 0xFFF3D6).opacity(0.55)))
            // Mat
            var mat = Path()
            mat.move(to: CGPoint(x: w * 0.30, y: h * 0.70))
            mat.addLine(to: CGPoint(x: w * 0.56, y: h * 0.70))
            mat.addLine(to: CGPoint(x: w * 0.80, y: h * 0.97))
            mat.addLine(to: CGPoint(x: w * 0.22, y: h * 0.97))
            mat.closeSubpath()
            ctx.fill(mat, with: .color(Color(hex: 0x6E5A94)))
            // Plant
            let pot = CGRect(x: w * 0.76, y: floorY - h * 0.02, width: w * 0.13, height: h * 0.08)
            ctx.fill(Path(roundedRect: pot, cornerRadius: 6), with: .color(Color(hex: 0xB9785A)))
            for (dx, dy, r) in [(0.0, -0.10, 0.11), (-0.06, -0.06, 0.08), (0.07, -0.07, 0.09), (0.02, -0.17, 0.08), (-0.04, -0.14, 0.07)] {
                let c = CGPoint(x: pot.midX + w * dx, y: pot.minY + h * dy)
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - w * r / 2, y: c.y - w * r, width: w * r, height: w * r * 2)),
                         with: .color(Color(hex: 0x4F7A56).opacity(0.92)))
            }
        }
        .blur(radius: 1.6)
        .overlay(RadialGradient(colors: [.clear, .black.opacity(0.16)], center: .center, startRadius: 200, endRadius: 420))
    }
}

struct CandlePlate: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x0E0908), Color(hex: 0x24130B)], startPoint: .top, endPoint: .bottom)
            Canvas { ctx, size in
                let w = size.width, h = size.height
                let lights: [(Double, Double, Double)] = [
                    (0.18, 0.78, 0.20), (0.36, 0.84, 0.15), (0.58, 0.80, 0.22), (0.82, 0.86, 0.17),
                    (0.70, 0.66, 0.11), (0.28, 0.62, 0.09), (0.90, 0.58, 0.08), (0.48, 0.70, 0.12), (0.10, 0.92, 0.14),
                ]
                for (x, y, r) in lights {
                    let rect = CGRect(x: w * x - w * r / 2, y: h * y - w * r / 2, width: w * r, height: w * r)
                    ctx.fill(Path(ellipseIn: rect), with: .color(Color(hex: 0xF2A84B).opacity(0.5)))
                }
            }
            .blur(radius: 13)
            Canvas { ctx, size in
                let w = size.width, h = size.height
                for (x, y) in [(0.18, 0.78), (0.58, 0.80), (0.82, 0.86), (0.36, 0.84)] {
                    ctx.fill(Path(ellipseIn: CGRect(x: w * x - 4, y: h * y - 9, width: 8, height: 18)),
                             with: .color(Color(hex: 0xFFE7B0)))
                }
            }
            .blur(radius: 2.5)
        }
    }
}

struct DuskPlate: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let horizon = h * 0.60
            ctx.fill(Path(CGRect(x: 0, y: 0, width: w, height: horizon)),
                     with: .linearGradient(Gradient(stops: [
                        .init(color: Color(hex: 0x1F2362), location: 0),
                        .init(color: Color(hex: 0x5B3C8E), location: 0.45),
                        .init(color: Color(hex: 0xB85C8E), location: 0.78),
                        .init(color: Color(hex: 0xF3B58A), location: 1),
                     ]), startPoint: .zero, endPoint: CGPoint(x: 0, y: horizon)))
            // Sun
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.60, y: horizon - w * 0.13, width: w * 0.16, height: w * 0.16)),
                     with: .color(Color(hex: 0xFFE3BE)))
            // Water
            ctx.fill(Path(CGRect(x: 0, y: horizon, width: w, height: h - horizon)),
                     with: .linearGradient(Gradient(colors: [Color(hex: 0xC98A8E), Color(hex: 0x3A2C6E), Color(hex: 0x17143A)]),
                                           startPoint: CGPoint(x: 0, y: horizon), endPoint: CGPoint(x: 0, y: h)))
            for i in 0..<16 {
                let y = horizon + CGFloat(i * i) * 1.1 + 6
                let half = w * (0.05 + 0.012 * CGFloat(i))
                ctx.fill(Path(roundedRect: CGRect(x: w * 0.68 - half, y: y, width: half * 2, height: 2.4), cornerRadius: 1.2),
                         with: .color(Color(hex: 0xFFE3BE).opacity(0.55 - Double(i) * 0.028)))
            }
            // Hills
            func hill(_ pts: [(Double, Double)], _ color: Color) {
                var p = Path()
                p.move(to: CGPoint(x: 0, y: horizon))
                for (x, y) in pts { p.addLine(to: CGPoint(x: w * x, y: horizon - h * y)) }
                p.addLine(to: CGPoint(x: w, y: horizon))
                p.closeSubpath()
                ctx.fill(p, with: .color(color))
            }
            hill([(0, 0.05), (0.14, 0.09), (0.30, 0.04), (0.46, 0.07), (0.56, 0.02), (0.74, 0.0)], Color(hex: 0x4A3478))
            hill([(0, 0.02), (0.10, 0.045), (0.24, 0.015), (0.38, 0.0)], Color(hex: 0x2B2156))
            hill([(0.80, 0.0), (0.90, 0.03), (1.0, 0.055)], Color(hex: 0x33265F))
        }
        .blur(radius: 1.2)
    }
}
