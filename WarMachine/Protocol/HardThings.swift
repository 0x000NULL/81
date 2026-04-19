import Foundation

struct HardThing: Identifiable, Hashable, Sendable {
    let text: String
    let category: HardThingCategory

    var id: String { "\(category.rawValue)-\(text)" }
}

enum HardThings {

    static let physical: [HardThing] = [
        HardThing(text: "Cold shower, 2+ minutes", category: .physical),
        HardThing(text: "Set to true failure (any lift, safely)", category: .physical),
        HardThing(text: "100 burpees for time", category: .physical),
        HardThing(text: "Walk outside in bad weather, 20 min, no phone", category: .physical),
        HardThing(text: "Last mile of a run at threshold pace", category: .physical),
        HardThing(text: "Fast from breakfast to lunch (skip one meal intentionally)", category: .physical),
        HardThing(text: "5 min plank (broken as needed)", category: .physical),
        HardThing(text: "Max push-ups in 2 min", category: .physical)
    ]

    static let mental: [HardThing] = [
        HardThing(text: "20 min focused work, phone in another room", category: .mental),
        HardThing(text: "Read 10 pages of something hard (not fiction, not your field)", category: .mental),
        HardThing(text: "Sit still for 10 min doing nothing — no phone, no music", category: .mental),
        HardThing(text: "Write for 10 min without editing", category: .mental),
        HardThing(text: "Do a task you've been putting off for 2+ weeks", category: .mental),
        HardThing(text: "Learn something you're bad at for 20 min", category: .mental)
    ]

    static let social: [HardThing] = [
        HardThing(text: "Have the conversation you've been avoiding", category: .social),
        HardThing(text: "Send the message you've been drafting", category: .social),
        HardThing(text: "Ask for something you're afraid to ask for", category: .social),
        HardThing(text: "Admit you were wrong about something, out loud, to someone", category: .social),
        HardThing(text: "Give a sincere compliment to someone you don't know well", category: .social),
        HardThing(text: "Sit with an uncomfortable emotion for 10 min without distracting", category: .social)
    ]

    static let spiritual: [HardThing] = [
        HardThing(text: "Read a full chapter of Scripture without checking your phone.", category: .spiritual),
        HardThing(text: "Memorize a single Bible verse today.", category: .spiritual),
        HardThing(text: "Pray for 10 minutes uninterrupted.", category: .spiritual),
        HardThing(text: "Fast from social media for 24 hours.", category: .spiritual),
        HardThing(text: "Skip breakfast and pray through the hour you would have eaten.", category: .spiritual),
        HardThing(text: "Confess a specific sin to a trusted brother.", category: .spiritual),
        HardThing(text: "Forgive someone in a specific, written prayer.", category: .spiritual),
        HardThing(text: "Give something away anonymously today.", category: .spiritual),
        HardThing(text: "Attend church when you do not feel like it.", category: .spiritual),
        HardThing(text: "Pray for someone you resent, by name, for 5 straight days.", category: .spiritual),
        HardThing(text: "Read a Psalm out loud, slowly.", category: .spiritual),
        HardThing(text: "Spend 30 minutes in total silence — no music, no podcasts.", category: .spiritual)
    ]

    static let all: [HardThing] = physical + mental + social + spiritual

    static func byCategory(_ category: HardThingCategory) -> [HardThing] {
        switch category {
        case .physical: return physical
        case .mental: return mental
        case .social: return social
        case .spiritual: return spiritual
        }
    }
}
