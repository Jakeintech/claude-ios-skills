import Foundation

/// One class, reduced to what a share card draws. Plain values only, so a
/// card never reads SwiftData and a style can be rendered from a fixture.
/// Built once per share screen by `ShareCardContent(session:)`.
struct ShareCardContent: Sendable, Equatable {
    struct Song: Sendable, Equatable, Identifiable {
        let id: Int
        let title: String
        let artist: String
        /// Seconds from the start of class.
        let offset: TimeInterval

        /// "7:19", or "1:01:52" past the hour.
        var clock: String {
            let total = max(0, Int(offset))
            let hours = total / 3600, minutes = (total % 3600) / 60, seconds = total % 60
            return hours > 0
                ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
                : String(format: "%d:%02d", minutes, seconds)
        }
    }

    /// Heart rate from Apple Watch, reduced to a line and two words.
    struct Heart: Sendable, Equatable {
        /// 0…1, evenly spaced over the class, scaled to this class's own range.
        let curve: [Double]
        let peakBPM: Int
        let averageBPM: Int
        /// "Steady", "Balanced": the words the class page uses. Nil when
        /// there were too few beats to say.
        let effortWord: String?
        let easeWord: String?

        var peakIndex: Int { curve.indices.max { curve[$0] < curve[$1] } ?? 0 }

        static let curvePoints = 72

        /// Averages beats into evenly spaced points and scales them to the
        /// class's own range, leaving a little room above and below the line.
        static func curve(
            from beats: [(offset: TimeInterval, bpm: Int)],
            duration: TimeInterval,
            points: Int = curvePoints
        ) -> [Double] {
            guard duration > 0, points > 1, beats.count > 1 else { return [] }
            var sums = [Double](repeating: 0, count: points)
            var counts = [Int](repeating: 0, count: points)
            for beat in beats where beat.bpm > 0 {
                let position = min(max(beat.offset / duration, 0), 1)
                let index = min(points - 1, Int(position * Double(points)))
                sums[index] += Double(beat.bpm)
                counts[index] += 1
            }
            guard counts.contains(where: { $0 > 0 }) else { return [] }
            // Fill empty points from the nearest earlier one (or the first known).
            var averages = [Double](repeating: 0, count: points)
            let firstKnown = counts.firstIndex { $0 > 0 } ?? 0
            var last = sums[firstKnown] / Double(counts[firstKnown])
            for i in 0..<points {
                if counts[i] > 0 { last = sums[i] / Double(counts[i]) }
                averages[i] = last
            }
            let low = averages.min() ?? 0, high = averages.max() ?? 0
            guard high > low else { return averages.map { _ in 0.5 } }
            return averages.map { 0.06 + 0.88 * ($0 - low) / (high - low) }
        }
    }

    var title: String
    /// The class style ("Vinyasa Flow") or type ("Pilates").
    var kicker: String
    /// "Thu 5 Nov"
    var dateText: String
    /// "9:30 AM"
    var startTimeText: String
    var minutes: Int?
    var teacher: String?
    var studio: String?
    /// In the order they played.
    var songs: [Song]
    /// The teacher's saved lines, in the order they were said.
    var lines: [String]
    var heart: Heart?
}

// MARK: - Fixtures

extension ShareCardContent {
    /// The seeded demo class, as the app shows it. Used by previews and tests.
    static let sample: ShareCardContent = {
        let catalog: [(String, String)] = [
            ("You Can't Rush Your Healing", "Trevor Hall"), ("The Lime Tree", "Trevor Hall"),
            ("10 Laws", "East Forest"), ("Ricochet", "East Forest"), ("Awake", "Tycho"),
            ("A Moment Apart", "ODESZA"), ("Line of Sight", "ODESZA"), ("Kerala", "Bonobo"),
            ("Cirrus", "Bonobo"), ("Break Apart", "Bonobo"),
        ]
        let songLength = 4500.0 / 11
        let beats: [(offset: TimeInterval, bpm: Int)] = (0..<300).map { i in
            let t = Double(i) / 299
            let warm = min(t / 0.18, 1)
            let cool = t > 0.72 ? max(0, 1 - (t - 0.72) / 0.2) : 1
            let wave = 9 * sin(t * 21) + 4 * sin(t * 47 + 1)
            let peak = 22 * exp(-pow((t - 0.60) / 0.07, 2))
            return (t * 4500, Int(72 + (48 * warm + wave * warm + peak) * (0.2 + 0.8 * cool)))
        }
        return ShareCardContent(
            title: "Vinyasa with Maya", kicker: "Vinyasa Flow",
            dateText: "Thu 5 Nov", startTimeText: "9:30 AM", minutes: 75,
            teacher: "Maya", studio: "Sunrise Yoga Loft",
            songs: catalog.enumerated().map { i, song in
                Song(id: i, title: song.0, artist: song.1, offset: Double(i) * songLength + 30)
            },
            lines: ["If you lose the breath, you've left the pose.", "Inhale to lengthen, exhale to deepen."],
            heart: Heart(curve: Heart.curve(from: beats, duration: 4500), peakBPM: 150, averageBPM: 118,
                         effortWord: "Steady", easeWord: "Balanced")
        )
    }()

    /// A class with almost nothing: no Watch, no teacher, no studio, one song.
    static let sparse = ShareCardContent(
        title: "Yoga", kicker: "Yoga", dateText: "Mon 2 Nov", startTimeText: "6:00 AM", minutes: nil,
        teacher: nil, studio: nil,
        songs: [Song(id: 0, title: "Awake", artist: "Tycho", offset: 30)],
        lines: [], heart: nil
    )

    /// The longest strings a card should survive.
    static let long: ShareCardContent = {
        var content = sample
        content.title = "Sunday Morning Slow Flow and Sound Bath with Alejandra"
        content.kicker = "Restorative Yin and Yoga Nidra"
        content.teacher = "Alejandra Fernández-Castellanos"
        content.studio = "The Harbour Collective Yoga and Movement Studio"
        content.minutes = 120
        content.songs = (0..<24).map { i in
            Song(id: i, title: "A Very Long Song Title That Goes On and On, Part \(i + 1)",
                 artist: "An Artist With a Long Name and the Orchestra", offset: Double(i) * 300 + 30)
        }
        content.lines = [
            "You don't have to fix anything for the next ninety minutes, you only have to stay, and breathe, and notice what is already here without needing it to be different.",
        ]
        return content
    }()
}
