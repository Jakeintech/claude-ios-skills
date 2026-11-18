import Foundation

/// The one number a card can lead with, and the choices a class offers.
enum ShareCardNumber {
    static let optionID = "number"

    struct Value: Equatable {
        let figure: String
        let unit: String
    }

    /// Only the numbers this class has.
    static func option(for content: ShareCardContent) -> ShareCardOption? {
        var choices: [ShareCardOption.Choice] = []
        if content.minutes != nil {
            choices.append(.init(id: "minutes", title: String(localized: "Minutes", comment: "Share card number choice")))
        }
        if !content.songs.isEmpty {
            choices.append(.init(id: "songs", title: String(localized: "Songs", comment: "Share card number choice")))
        }
        if content.heart != nil {
            choices.append(.init(id: "peak", title: String(localized: "Peak", comment: "Share card number choice: peak heart rate")))
        }
        guard !choices.isEmpty else { return nil }
        return .choice(optionID, String(localized: "Number", comment: "Share card option: which number leads the card"), choices)
    }

    static func value(_ choice: String, in content: ShareCardContent) -> Value? {
        switch choice {
        case "minutes":
            content.minutes.map { Value(figure: "\($0)", unit: String(localized: "min", comment: "Short for minutes, beside a large number")) }
        case "songs":
            content.songs.isEmpty ? nil : Value(
                figure: "\(content.songs.count)",
                unit: content.songs.count == 1
                    ? String(localized: "song", comment: "Unit beside the number 1")
                    : String(localized: "songs", comment: "Unit beside a number of songs"))
        case "peak":
            content.heart.map { Value(figure: "\($0.peakBPM)", unit: String(localized: "peak", comment: "Unit beside a peak heart rate")) }
        default:
            nil
        }
    }
}

extension ShareCardContent {
    /// "75 min", when the class has an end.
    var minutesText: String? {
        minutes.map { String(localized: "\($0) min", comment: "Class length on a share card") }
    }

    /// "10 songs", with the right plural.
    var songsText: String? {
        songs.isEmpty ? nil : String(AttributedString(localized: "^[\(songs.count) song](inflect: true)").characters)
    }
}
