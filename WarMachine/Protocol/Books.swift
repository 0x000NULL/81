import Foundation

struct Book: Identifiable, Hashable, Sendable {
    let title: String
    let author: String
    let why: String
    let isChristian: Bool

    var id: String { title }
}

enum Books {

    static let secular: [Book] = [
        Book(title: "Atomic Habits", author: "James Clear", why: "Builds the framework. Identity-based change, small wins compound. The foundation.", isChristian: false),
        Book(title: "Can't Hurt Me", author: "David Goggins", why: "Lights the fire. Callused mind, 40% rule. Read once, don't live in it.", isChristian: false),
        Book(title: "The War of Art", author: "Steven Pressfield", why: "Names the enemy. 'Resistance' — the voice that talks you out of hard things.", isChristian: false),
        Book(title: "Discipline Equals Freedom", author: "Jocko Willink", why: "Field manual style. Audiobook is better — Jocko reads it.", isChristian: false),
        Book(title: "Grit", author: "Angela Duckworth", why: "The actual research. Studied West Point cadets and Green Beret selection.", isChristian: false),
        Book(title: "Man's Search for Meaning", author: "Viktor Frankl", why: "Not a fitness book. Deepest thing ever written on enduring suffering with meaning.", isChristian: false),
        Book(title: "The Obstacle Is the Way", author: "Ryan Holiday", why: "Stoic philosophy for modern use. Short, practical.", isChristian: false),
        Book(title: "Deep Work", author: "Cal Newport", why: "Grit for the mind. Focused work as the trainable skill.", isChristian: false),
        Book(title: "Extreme Ownership", author: "Willink & Babin", why: "SEAL leadership principles. Taking responsibility as a discipline.", isChristian: false),
        Book(title: "Starting Strength", author: "Mark Rippetoe", why: "The bible of barbell technique. Read if your squat/deadlift form is shaky.", isChristian: false),
        Book(title: "The Ranger Handbook", author: "US Army", why: "Free PDF. Actual military source document.", isChristian: false),
        Book(title: "Tactical Barbell", author: "K. Black", why: "Programming for hybrid strength + endurance athletes. Closest to this protocol.", isChristian: false)
    ]

    static let christian: [Book] = [
        Book(title: "Mere Christianity", author: "C.S. Lewis", why: "Foundations of the faith, defended with clarity.", isChristian: true),
        Book(title: "The Practice of the Presence of God", author: "Brother Lawrence", why: "Short, profound, on constant awareness of God.", isChristian: true),
        Book(title: "The Pursuit of God", author: "A.W. Tozer", why: "Classic on knowing God personally.", isChristian: true),
        Book(title: "The Ruthless Elimination of Hurry", author: "John Mark Comer", why: "Rest, Sabbath, and modern pace.", isChristian: true),
        Book(title: "Spiritual Disciplines for the Christian Life", author: "Donald Whitney", why: "Disciplines as training.", isChristian: true),
        Book(title: "Celebration of Discipline", author: "Richard Foster", why: "On spiritual formation.", isChristian: true)
    ]

    static let all: [Book] = secular + christian
}
