import Foundation

struct TalkScript: Identifiable, Hashable, Sendable {
    let situation: String
    let script: String
    let anchorReference: String
    let scenario: ScriptScenario

    var id: String { situation }
}

enum ScriptScenario: String, Codable, Sendable {
    case midWorkoutPush        // in the middle of a hard set
    case repCountSaysStop
    case cantStart
    case milesRemaining
    case noMotivation
    case brokenPromise
    case wantToSkip
    case zone2Boring
}

enum Scripts {

    static let all: [TalkScript] = [
        TalkScript(situation: "Rep count says stop", script: "One more. Just one. Then decide.", anchorReference: "Philippians 4:13", scenario: .repCountSaysStop),
        TalkScript(situation: "Workout feels impossible before starting", script: "I don't have to finish it. I just have to start it.", anchorReference: "2 Timothy 1:7", scenario: .cantStart),
        TalkScript(situation: "Mile 6 of 10 with loaded pack", script: "Next pole. Just the next pole.", anchorReference: "Hebrews 12:1–2", scenario: .milesRemaining),
        TalkScript(situation: "Motivation is gone", script: "Motivation isn't coming. Go anyway.", anchorReference: "Galatians 6:9", scenario: .noMotivation),
        TalkScript(situation: "You've broken a promise", script: "That was one. The next one is separate.", anchorReference: "Lamentations 3:22–23", scenario: .brokenPromise),
        TalkScript(situation: "In the middle of a hard set", script: "This is the rep. This one. Right now.", anchorReference: "1 Corinthians 9:24–27", scenario: .midWorkoutPush),
        TalkScript(situation: "Want to skip the workout", script: "The schedule is the training. Go.", anchorReference: "Proverbs 24:16", scenario: .wantToSkip),
        TalkScript(situation: "Zone 2 feels boring", script: "Boring is the work. Do the work.", anchorReference: "Colossians 3:23–24", scenario: .zone2Boring)
    ]

    /// Contextual pick for "Give me one" button.
    static func pick(for context: ScriptContext) -> TalkScript {
        switch context {
        case .preWorkout:
            return all.first { $0.scenario == .cantStart } ?? all[0]
        case .midWorkout:
            return all.first { $0.scenario == .midWorkoutPush } ?? all[0]
        case .struggling:
            return all.first { $0.scenario == .repCountSaysStop } ?? all[0]
        case .brokenPromise:
            return all.first { $0.scenario == .brokenPromise } ?? all[0]
        case .zone2:
            return all.first { $0.scenario == .zone2Boring } ?? all[0]
        case .ruck:
            return all.first { $0.scenario == .milesRemaining } ?? all[0]
        case .wantToSkip:
            return all.first { $0.scenario == .wantToSkip } ?? all[0]
        }
    }
}

enum ScriptContext {
    case preWorkout, midWorkout, struggling, brokenPromise, zone2, ruck, wantToSkip
}
