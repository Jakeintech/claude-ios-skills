import Foundation

extension ShareCardContent {
    /// Reads a class once into plain values. Call from a `.task`, not from a
    /// view body: it walks the class's songs, lines and heart-rate samples.
    @MainActor
    init(session: WorkoutSession) {
        let style = session.classCategory == .yoga ? session.classification?.resolvedStyle?.info.displayName : nil
        let songs = (session.playlist?.sortedSongs ?? []).enumerated().map { index, song in
            Song(id: index, title: song.title, artist: song.artist, offset: song.startTime)
        }
        let lines = (session.theme?.quotes ?? [])
            .sorted { $0.orderIndex < $1.orderIndex }
            .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        self.init(
            title: session.title,
            kicker: style ?? session.classCategory.localizedName,
            dateText: session.startedAt.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)),
            startTimeText: session.startedAt.formatted(date: .omitted, time: .shortened),
            minutes: session.duration.map { max(1, Int(($0 / 60).rounded())) },
            teacher: session.taggedInstructor?.displayName,
            studio: session.venueName,
            songs: songs,
            lines: lines,
            heart: Heart(session: session)
        )
    }
}

extension ShareCardContent.Heart {
    /// Fewer beats than this do not make a line worth drawing.
    static let minimumBeatsForLine = max(PracticeWordsCalculator.minimumBeats, 24)

    /// Nil when the class has too few beats to draw a line worth showing.
    @MainActor
    init?(session: WorkoutSession) {
        let facts = PracticeBodyFacts(session: session)
        guard facts.beats.count >= Self.minimumBeatsForLine, facts.duration > 0 else { return nil }
        let curve = Self.curve(from: facts.beats.map { (offset: $0.offset, bpm: $0.bpm) }, duration: facts.duration)
        guard curve.count > 2 else { return nil }
        let words = PracticeWordsCalculator.words(for: facts)
        let bpms = facts.beats.map(\.bpm)
        self.init(
            curve: curve,
            peakBPM: bpms.max() ?? 0,
            averageBPM: bpms.reduce(0, +) / max(bpms.count, 1),
            effortWord: words.effort?.title,
            easeWord: words.ease?.title
        )
    }
}
