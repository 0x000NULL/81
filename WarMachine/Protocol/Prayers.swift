import Foundation

struct Prayer: Identifiable, Hashable, Sendable {
    let kind: PrayerKind
    let title: String
    let anchorReference: String?
    let body: String

    var id: PrayerKind { kind }
}

enum Prayers {

    static let morning = Prayer(
        kind: .morning,
        title: "Morning Prayer",
        anchorReference: "Lamentations 3:22–23",
        body: """
        Heavenly Father,
        Thank You for this day. You made it; You give me breath to live it.
        Before I pick up my phone, before I touch my coffee, I give this day to You.
        Strengthen me to keep my promise. Give me eyes to see the hard thing You would have me do today, and the will to do it.
        Whatever I build today, let it be for Your glory, not mine.
        In Jesus' name,
        Amen.
        """
    )

    static let preWorkout = Prayer(
        kind: .preWorkout,
        title: "Pre-Workout Prayer",
        anchorReference: "Psalm 144:1",
        body: """
        Lord,
        You train my hands for battle and my fingers for war.
        This body is Yours — bought at a price, a temple of Your Spirit.
        Guard me from injury. Steady me under the weight. Push me past where I would stop alone.
        Let this work honor You.
        In Jesus' name,
        Amen.
        """
    )

    static let postWorkout = Prayer(
        kind: .postWorkout,
        title: "Post-Workout Prayer",
        anchorReference: "Colossians 3:23–24",
        body: """
        Father, thank You.
        Strength given, strength received.
        All for Your glory.
        Amen.
        """
    )

    static let evening = Prayer(
        kind: .evening,
        title: "Evening Prayer",
        anchorReference: "Psalm 127:2",
        body: """
        Father,
        The day is done. I bring it to You as it was, not as I wish it had been.
        Where I kept my word: thank You for the grace that let me do it.
        Where I broke: forgive me, and teach me.
        Where I was tempted to quit: thank You for not quitting on me.
        I trust tomorrow to You.
        Grant me real rest — the kind that restores both body and soul.
        Into Your hands I commit my sleep.
        In Jesus' name,
        Amen.
        """
    )

    static let sabbath = Prayer(
        kind: .sabbath,
        title: "Sabbath Prayer",
        anchorReference: "Mark 2:27",
        body: """
        Lord of the Sabbath,
        Today I rest because You rested. Not because I earned it, and not because the work is done.
        The work will never be done. But You are sovereign over it.
        Quiet my mind. Slow my body. Remind me I am Your child before I am anything I do.
        Prepare me in Your strength, not mine, for the week ahead.
        In Jesus' name,
        Amen.
        """
    )

    static let afterFailure = Prayer(
        kind: .afterFailure,
        title: "Prayer After Failure",
        anchorReference: "Lamentations 3:22–23",
        body: """
        Father,
        I fell. You knew I would.
        Your mercies are new this morning. I receive them.
        I am not the sum of my broken promises. I am Yours.
        Pick me up. Set my feet on solid ground. Let us begin again.
        In Jesus' name,
        Amen.
        """
    )

    static let beforeHardThing = Prayer(
        kind: .beforeHardThing,
        title: "Prayer Before the Hard Thing",
        anchorReference: nil,
        body: """
        Lord,
        This is uncomfortable. I would rather not. But You call me to die to self daily.
        Meet me in the discomfort. Let me not waste it.
        In Jesus' name,
        Amen.
        """
    )

    static let all: [Prayer] = [morning, preWorkout, postWorkout, evening, sabbath, afterFailure, beforeHardThing]

    static func of(_ kind: PrayerKind) -> Prayer {
        all.first { $0.kind == kind } ?? morning
    }
}
