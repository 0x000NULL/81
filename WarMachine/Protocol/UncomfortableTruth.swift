import Foundation

enum UncomfortableTruth {
    static let passage = """
    None of this is secret. None of it is complicated.

    People who seem to have inhuman willpower aren't using different techniques \
    — they've just been doing these boring things consistently for years.

    There's no hack. There's no shortcut. There's just today's rep.
    Do it. Then do tomorrow's.

    The first one is the hardest.
    """

    static let pullQuote = "There's no hack. There's no shortcut. There's just today's rep."

    /// Milestones (in weeks) when the banner should surface on first-open.
    static let milestoneWeeks: [Int] = [4, 8, 12]
}
