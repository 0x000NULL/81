import Foundation

struct Meditation: Identifiable, Hashable, Sendable {
    let kind: MeditationKind
    let title: String
    let durationRange: ClosedRange<Int>
    let context: String
    let description: String
    let steps: [String]

    var id: MeditationKind { kind }

    var durationLabel: String {
        if durationRange.lowerBound == durationRange.upperBound {
            return "\(durationRange.lowerBound) min"
        }
        return "\(durationRange.lowerBound)–\(durationRange.upperBound) min"
    }
}

enum Meditations {

    static let lectioDivina = Meditation(
        kind: .lectioDivina,
        title: "Lectio Divina",
        durationRange: 10...20,
        context: "Thursday Zone 2 or Sunday rest",
        description: "A slow, prayerful reading of a short Scripture passage in four movements — an ancient Christian practice of encountering God through His Word.",
        steps: [
            "Lectio (Read) — Read a short passage slowly, aloud if possible. What word or phrase catches you?",
            "Meditatio (Meditate) — Sit with that word. Repeat it. What does it stir in you?",
            "Oratio (Pray) — Respond to God from what's been stirred. Speak honestly.",
            "Contemplatio (Contemplate) — Rest silently in God's presence. No words needed."
        ]
    )

    static let breathPrayer = Meditation(
        kind: .breathPrayer,
        title: "Breath Prayer / Jesus Prayer",
        durationRange: 5...20,
        context: "Zone 2 runs and long rucks",
        description: "The ancient Jesus Prayer synced with breath. A way to pray without ceasing while the body works.",
        steps: [
            "Inhale: \"Lord Jesus Christ, Son of God…\"",
            "Exhale: \"…have mercy on me, a sinner.\"",
            "Continue at a natural breath rhythm. Don't force the pace.",
            "When your mind wanders, return gently to the words."
        ]
    )

    static let examen = Meditation(
        kind: .examen,
        title: "The Examen",
        durationRange: 10...10,
        context: "Evening, before sleep",
        description: "Ignatian daily review. Walk back through the day with God.",
        steps: [
            "Give thanks — What am I grateful for today?",
            "Ask for light — Holy Spirit, show me this day truly.",
            "Review the day — Where did I sense God? Where did I resist Him?",
            "Repent — What needs confession?",
            "Renew — Commit tomorrow to God."
        ]
    )

    static let scriptureMemorization = Meditation(
        kind: .scriptureMemorization,
        title: "Scripture Memorization",
        durationRange: 20...60,
        context: "Thursday Zone 2",
        description: "One verse per week, memorized during the Thursday Zone 2 session through repetition in rhythm with your stride or breath.",
        steps: [
            "Pick one verse Monday morning. Say it out loud three times.",
            "During Thursday Zone 2, repeat it silently in rhythm with breathing.",
            "Break it into phrases. Focus on one phrase per quarter of the session.",
            "By the end of the session, recite the whole verse without looking."
        ]
    )

    static let silentWaiting = Meditation(
        kind: .silentWaiting,
        title: "Silent Waiting",
        durationRange: 10...20,
        context: "Sunday rest",
        description: "Stillness before God. Not prayer, not reading, not thinking. Psalm 46:10 — \"Be still, and know that I am God.\"",
        steps: [
            "Sit comfortably, eyes closed or softly open.",
            "Don't pray. Don't read. Don't plan.",
            "When thoughts come, acknowledge and release. Return to \"Be still.\"",
            "End when the timer does. Resist the urge to extend or cut short."
        ]
    )

    static let attributeOfGod = Meditation(
        kind: .attributeOfGod,
        title: "Meditation on an Attribute of God",
        durationRange: 10...15,
        context: "Morning or any quiet moment",
        description: "Choose one attribute of God and let it reshape how you see Him today.",
        steps: [
            "Pick one: holiness, faithfulness, love, sovereignty, mercy, justice, patience, wisdom.",
            "Read 2–3 verses that reveal it (use the Verses library).",
            "Sit with the attribute. How does it change how you see God right now?",
            "Close with a short prayer acknowledging this truth about God."
        ]
    )

    static let all: [Meditation] = [lectioDivina, breathPrayer, examen, scriptureMemorization, silentWaiting, attributeOfGod]

    static func of(_ kind: MeditationKind) -> Meditation {
        all.first { $0.kind == kind } ?? breathPrayer
    }
}
