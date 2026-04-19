import Foundation
import SwiftData
import OSLog

private let log = Logger(subsystem: "app.81", category: "export")

struct ExportPayload: Codable {
    let schemaVersion: String
    let exportedAt: Date
    let profile: ProfileData?
    let workouts: [WorkoutData]
    let exercises: [ExerciseData]
    let sets: [SetData]
    let lifts: [LiftData]
    let daily: [DailyData]
    let gtg: [GtgData]
    let rucks: [RuckData]
    let sundays: [SundayData]
    let baselines: [BaselineData]
    let books: [BookData]
    let equipment: [EquipmentData]
    let prayers: [PrayerData]
    let meditations: [MeditationData]
    let favorites: [FavoriteData]
    let journal: [JournalData]

    static let currentSchemaVersion = "1.2-christian-journal"
}

struct ProfileData: Codable {
    let id: UUID
    let createdAt: Date
    let startDate: Date
    let level: String
    let bodyweightLb: Double
    let waistInches: Double
    let identitySentence: String
    let morningReminderHour: Int
    let morningReminderMinute: Int
    let eveningReminderHour: Int
    let eveningReminderMinute: Int
    let workoutReminderHour: Int
    let injuryFlag: Bool
    let injuryNote: String?
    let rebuildModeRemainingSessions: Int
    let lastUTMilestoneShown: Int?
    let currentMemorizationReference: String?
}

struct WorkoutData: Codable {
    let id: UUID
    let date: Date
    let dayType: String
    let startedAt: Date?
    let completedAt: Date?
    let difficulty: Int?
    let notes: String?
    let isTravelMode: Bool
    let abandoned: Bool
    let prePrayed: Bool
    let postPrayed: Bool
    let appliedRebuildDiscount: Bool
}

struct ExerciseData: Codable {
    let id: UUID
    let sessionID: UUID?
    let orderIndex: Int
    let exerciseKey: String
    let displayName: String
    let targetSets: Int
    let targetRepsMin: Int
    let targetRepsMax: Int
    let targetWeight: Double
    let restSeconds: Int
    let alternativeChosen: String?
    let isSwappedForTravel: Bool
}

struct SetData: Codable {
    let id: UUID
    let exerciseID: UUID?
    let setIndex: Int
    let weightLb: Double
    let reps: Int
    let completedAt: Date
}

struct LiftData: Codable {
    let liftKey: String
    let displayName: String
    let currentWeightLb: Double
    let consecutiveTopSessions: Int
    let lastEvaluatedAt: Date?
    let isMainLift: Bool
}

struct DailyData: Codable {
    let date: Date
    let morningPrayerPrayed: Bool
    let promise: String?
    let hardThingCategory: String?
    let hardThingText: String?
    let eveningPrayerPrayed: Bool
    let examenNotes: String?
    let promiseKept: Bool?
    let whereIBroke: String?
    let triggerNote: String?
    let restingHR: Double?
    let sleepHours: Double?
    let energy: Int?
    let skippedReason: String?
    let skippedNote: String?
    let linkedJournalEntryID: UUID?
    let verseOfDayReference: String?
}

struct GtgData: Codable {
    let date: Date
    let totalReps: Int
    let setsCompleted: Int
    let target: Int
}

struct RuckData: Codable {
    let id: UUID
    let date: Date
    let distanceMi: Double
    let weightLb: Double
    let durationSeconds: Int
    let averageHR: Double?
    let notes: String?
}

struct SundayData: Codable {
    let weekStartDate: Date
    let createdAt: Date
    let pattern: String?
    let win: String?
    let nextWeekFocus: String?
    let whereIsawGod: String?
    let sabbathPrayerPrayed: Bool
    let workoutsCompleted: Int
    let promisesKept: Int
    let hardThingsDone: Int
    let prayersPrayed: Int
    let meditationsLogged: Int
}

struct BaselineData: Codable {
    let id: UUID
    let date: Date
    let weekNumber: Int
    let oneMileRunSeconds: Int?
    let maxPushUpsTwoMin: Int?
    let maxPullUps: Int?
    let twoMileRuckSeconds: Int?
    let twoMileRuckWeightLb: Double
    let restingHR: Double?
    let bodyweightLb: Double?
    let waistInches: Double?
}

struct BookData: Codable {
    let title: String
    let author: String
    let isChristian: Bool
    let started: Bool
    let completed: Bool
    let notes: String?
}

struct EquipmentData: Codable {
    let name: String
    let isMustHave: Bool
    let owned: Bool
    let approxCost: String?
    let note: String?
}

struct PrayerData: Codable {
    let id: UUID
    let prayedAt: Date
    let kind: String
    let linkedDate: Date?
}

struct MeditationData: Codable {
    let id: UUID
    let completedAt: Date
    let kind: String
    let durationMinutes: Int
    let notes: String?
}

struct FavoriteData: Codable {
    let reference: String
    let savedAt: Date
    let note: String?
}

struct JournalData: Codable {
    let id: UUID
    let createdAt: Date
    let date: Date
    let text: String
    let tag: String?
    let linkedFromDailyLog: Bool
}

@MainActor
enum ExportService {

    static func buildPayload(context: ModelContext) throws -> ExportPayload {
        let profile = try context.fetch(FetchDescriptor<UserProfile>()).first

        let workouts = try context.fetch(FetchDescriptor<WorkoutSession>())
        let exercises = try context.fetch(FetchDescriptor<ExerciseLog>())
        let sets = try context.fetch(FetchDescriptor<SetLog>())
        let lifts = try context.fetch(FetchDescriptor<LiftProgression>())
        let daily = try context.fetch(FetchDescriptor<DailyLog>())
        let gtg = try context.fetch(FetchDescriptor<GtgLog>())
        let rucks = try context.fetch(FetchDescriptor<RuckLog>())
        let sundays = try context.fetch(FetchDescriptor<SundayReview>())
        let baselines = try context.fetch(FetchDescriptor<BaselineTest>())
        let books = try context.fetch(FetchDescriptor<BookProgress>())
        let equipment = try context.fetch(FetchDescriptor<EquipmentItem>())
        let prayers = try context.fetch(FetchDescriptor<PrayerLog>())
        let meditations = try context.fetch(FetchDescriptor<MeditationLog>())
        let favorites = try context.fetch(FetchDescriptor<FavoriteVerse>())
        let journal = try context.fetch(FetchDescriptor<PrayerJournalEntry>())

        return ExportPayload(
            schemaVersion: ExportPayload.currentSchemaVersion,
            exportedAt: .now,
            profile: profile.map {
                ProfileData(id: $0.id, createdAt: $0.createdAt, startDate: $0.startDate,
                            level: $0.levelRaw, bodyweightLb: $0.bodyweightLb,
                            waistInches: $0.waistInches, identitySentence: $0.identitySentence,
                            morningReminderHour: $0.morningReminderHour,
                            morningReminderMinute: $0.morningReminderMinute,
                            eveningReminderHour: $0.eveningReminderHour,
                            eveningReminderMinute: $0.eveningReminderMinute,
                            workoutReminderHour: $0.workoutReminderHour,
                            injuryFlag: $0.injuryFlag,
                            injuryNote: $0.injuryNote,
                            rebuildModeRemainingSessions: $0.rebuildModeRemainingSessions,
                            lastUTMilestoneShown: $0.lastUTMilestoneShown,
                            currentMemorizationReference: $0.currentMemorizationReference)
            },
            workouts: workouts.map {
                WorkoutData(id: $0.id, date: $0.date, dayType: $0.dayTypeRaw,
                            startedAt: $0.startedAt, completedAt: $0.completedAt,
                            difficulty: $0.difficulty, notes: $0.notes,
                            isTravelMode: $0.isTravelMode, abandoned: $0.abandoned,
                            prePrayed: $0.prePrayed, postPrayed: $0.postPrayed,
                            appliedRebuildDiscount: $0.appliedRebuildDiscount)
            },
            exercises: exercises.map {
                ExerciseData(id: $0.id, sessionID: $0.session?.id,
                             orderIndex: $0.orderIndex, exerciseKey: $0.exerciseKey,
                             displayName: $0.displayName, targetSets: $0.targetSets,
                             targetRepsMin: $0.targetRepsMin, targetRepsMax: $0.targetRepsMax,
                             targetWeight: $0.targetWeight, restSeconds: $0.restSeconds,
                             alternativeChosen: $0.alternativeChosen,
                             isSwappedForTravel: $0.isSwappedForTravel)
            },
            sets: sets.map {
                SetData(id: $0.id, exerciseID: $0.exercise?.id,
                        setIndex: $0.setIndex, weightLb: $0.weightLb,
                        reps: $0.reps, completedAt: $0.completedAt)
            },
            lifts: lifts.map {
                LiftData(liftKey: $0.liftKey, displayName: $0.displayName,
                         currentWeightLb: $0.currentWeightLb,
                         consecutiveTopSessions: $0.consecutiveTopSessions,
                         lastEvaluatedAt: $0.lastEvaluatedAt,
                         isMainLift: $0.isMainLift)
            },
            daily: daily.map {
                DailyData(date: $0.date,
                          morningPrayerPrayed: $0.morningPrayerPrayed,
                          promise: $0.promise,
                          hardThingCategory: $0.hardThingCategoryRaw,
                          hardThingText: $0.hardThingText,
                          eveningPrayerPrayed: $0.eveningPrayerPrayed,
                          examenNotes: $0.examenNotes,
                          promiseKept: $0.promiseKept,
                          whereIBroke: $0.whereIBroke,
                          triggerNote: $0.triggerNote,
                          restingHR: $0.restingHR,
                          sleepHours: $0.sleepHours,
                          energy: $0.energy,
                          skippedReason: $0.skippedReasonRaw,
                          skippedNote: $0.skippedNote,
                          linkedJournalEntryID: $0.linkedJournalEntryID,
                          verseOfDayReference: $0.verseOfDayReference)
            },
            gtg: gtg.map { GtgData(date: $0.date, totalReps: $0.totalReps, setsCompleted: $0.setsCompleted, target: $0.target) },
            rucks: rucks.map {
                RuckData(id: $0.id, date: $0.date, distanceMi: $0.distanceMi,
                         weightLb: $0.weightLb, durationSeconds: $0.durationSeconds,
                         averageHR: $0.averageHR, notes: $0.notes)
            },
            sundays: sundays.map {
                SundayData(weekStartDate: $0.weekStartDate,
                           createdAt: $0.createdAt,
                           pattern: $0.pattern,
                           win: $0.win,
                           nextWeekFocus: $0.nextWeekFocus,
                           whereIsawGod: $0.whereIsawGod,
                           sabbathPrayerPrayed: $0.sabbathPrayerPrayed,
                           workoutsCompleted: $0.workoutsCompleted,
                           promisesKept: $0.promisesKept,
                           hardThingsDone: $0.hardThingsDone,
                           prayersPrayed: $0.prayersPrayed,
                           meditationsLogged: $0.meditationsLogged)
            },
            baselines: baselines.map {
                BaselineData(id: $0.id, date: $0.date, weekNumber: $0.weekNumber,
                             oneMileRunSeconds: $0.oneMileRunSeconds,
                             maxPushUpsTwoMin: $0.maxPushUpsTwoMin,
                             maxPullUps: $0.maxPullUps,
                             twoMileRuckSeconds: $0.twoMileRuckSeconds,
                             twoMileRuckWeightLb: $0.twoMileRuckWeightLb,
                             restingHR: $0.restingHR,
                             bodyweightLb: $0.bodyweightLb,
                             waistInches: $0.waistInches)
            },
            books: books.map {
                BookData(title: $0.title, author: $0.author, isChristian: $0.isChristian,
                         started: $0.started, completed: $0.completed, notes: $0.notes)
            },
            equipment: equipment.map {
                EquipmentData(name: $0.name, isMustHave: $0.isMustHave, owned: $0.owned,
                              approxCost: $0.approxCost, note: $0.note)
            },
            prayers: prayers.map {
                PrayerData(id: $0.id, prayedAt: $0.prayedAt, kind: $0.kindRaw, linkedDate: $0.linkedDate)
            },
            meditations: meditations.map {
                MeditationData(id: $0.id, completedAt: $0.completedAt, kind: $0.kindRaw,
                               durationMinutes: $0.durationMinutes, notes: $0.notes)
            },
            favorites: favorites.map {
                FavoriteData(reference: $0.reference, savedAt: $0.savedAt, note: $0.note)
            },
            journal: journal.map {
                JournalData(id: $0.id, createdAt: $0.createdAt, date: $0.date,
                            text: $0.text, tag: $0.tag, linkedFromDailyLog: $0.linkedFromDailyLog)
            }
        )
    }

    static func encode(_ payload: ExportPayload) throws -> Data {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try enc.encode(payload)
    }

    static func decode(_ data: Data) throws -> ExportPayload {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return try dec.decode(ExportPayload.self, from: data)
    }

    static func writeToTempFile(_ payload: ExportPayload) throws -> URL {
        let data = try encode(payload)
        let df = ISO8601DateFormatter()
        df.formatOptions = [.withFullDate]
        let name = "81-export-\(df.string(from: .now)).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try data.write(to: url, options: .atomic)
        return url
    }

    // MARK: Import

    /// Wipes existing data then inserts from payload.
    static func importPayload(_ payload: ExportPayload, into context: ModelContext) throws {
        try context.delete(model: UserProfile.self)
        try context.delete(model: WorkoutSession.self)
        try context.delete(model: ExerciseLog.self)
        try context.delete(model: SetLog.self)
        try context.delete(model: LiftProgression.self)
        try context.delete(model: DailyLog.self)
        try context.delete(model: GtgLog.self)
        try context.delete(model: RuckLog.self)
        try context.delete(model: SundayReview.self)
        try context.delete(model: BaselineTest.self)
        try context.delete(model: BookProgress.self)
        try context.delete(model: EquipmentItem.self)
        try context.delete(model: PrayerLog.self)
        try context.delete(model: MeditationLog.self)
        try context.delete(model: FavoriteVerse.self)
        try context.delete(model: PrayerJournalEntry.self)

        if let p = payload.profile {
            let profile = UserProfile()
            profile.id = p.id
            profile.createdAt = p.createdAt
            profile.startDate = p.startDate
            profile.levelRaw = p.level
            profile.bodyweightLb = p.bodyweightLb
            profile.waistInches = p.waistInches
            profile.identitySentence = p.identitySentence
            profile.morningReminderHour = p.morningReminderHour
            profile.morningReminderMinute = p.morningReminderMinute
            profile.eveningReminderHour = p.eveningReminderHour
            profile.eveningReminderMinute = p.eveningReminderMinute
            profile.workoutReminderHour = p.workoutReminderHour
            profile.injuryFlag = p.injuryFlag
            profile.injuryNote = p.injuryNote
            profile.rebuildModeRemainingSessions = p.rebuildModeRemainingSessions
            profile.lastUTMilestoneShown = p.lastUTMilestoneShown
            profile.currentMemorizationReference = p.currentMemorizationReference
            context.insert(profile)
        }

        for f in payload.favorites {
            let fv = FavoriteVerse(reference: f.reference, note: f.note)
            fv.savedAt = f.savedAt
            context.insert(fv)
        }

        for j in payload.journal {
            let e = PrayerJournalEntry(text: j.text, tag: j.tag, linkedFromDailyLog: j.linkedFromDailyLog)
            e.id = j.id
            e.createdAt = j.createdAt
            e.date = j.date
            context.insert(e)
        }

        for d in payload.daily {
            let dl = DailyLog(date: d.date)
            dl.morningPrayerPrayed = d.morningPrayerPrayed
            dl.promise = d.promise
            dl.hardThingCategoryRaw = d.hardThingCategory
            dl.hardThingText = d.hardThingText
            dl.eveningPrayerPrayed = d.eveningPrayerPrayed
            dl.examenNotes = d.examenNotes
            dl.promiseKept = d.promiseKept
            dl.whereIBroke = d.whereIBroke
            dl.triggerNote = d.triggerNote
            dl.restingHR = d.restingHR
            dl.sleepHours = d.sleepHours
            dl.energy = d.energy
            dl.skippedReasonRaw = d.skippedReason
            dl.skippedNote = d.skippedNote
            dl.linkedJournalEntryID = d.linkedJournalEntryID
            dl.verseOfDayReference = d.verseOfDayReference
            context.insert(dl)
        }

        for g in payload.gtg {
            let gl = GtgLog(date: g.date, target: g.target)
            gl.totalReps = g.totalReps
            gl.setsCompleted = g.setsCompleted
            context.insert(gl)
        }

        for l in payload.lifts {
            let lp = LiftProgression(liftKey: l.liftKey, displayName: l.displayName,
                                     currentWeightLb: l.currentWeightLb, isMainLift: l.isMainLift)
            lp.consecutiveTopSessions = l.consecutiveTopSessions
            lp.lastEvaluatedAt = l.lastEvaluatedAt
            context.insert(lp)
        }

        for b in payload.baselines {
            let bt = BaselineTest(date: b.date, weekNumber: b.weekNumber)
            bt.id = b.id
            bt.oneMileRunSeconds = b.oneMileRunSeconds
            bt.maxPushUpsTwoMin = b.maxPushUpsTwoMin
            bt.maxPullUps = b.maxPullUps
            bt.twoMileRuckSeconds = b.twoMileRuckSeconds
            bt.twoMileRuckWeightLb = b.twoMileRuckWeightLb
            bt.restingHR = b.restingHR
            bt.bodyweightLb = b.bodyweightLb
            bt.waistInches = b.waistInches
            context.insert(bt)
        }

        for r in payload.rucks {
            let rl = RuckLog(date: r.date, distanceMi: r.distanceMi,
                             weightLb: r.weightLb, durationSeconds: r.durationSeconds)
            rl.id = r.id
            rl.averageHR = r.averageHR
            rl.notes = r.notes
            context.insert(rl)
        }

        for b in payload.books {
            let bp = BookProgress(title: b.title, author: b.author, isChristian: b.isChristian)
            bp.started = b.started
            bp.completed = b.completed
            bp.notes = b.notes
            context.insert(bp)
        }

        for e in payload.equipment {
            let eq = EquipmentItem(name: e.name, isMustHave: e.isMustHave, approxCost: e.approxCost, note: e.note)
            eq.owned = e.owned
            context.insert(eq)
        }

        for p in payload.prayers {
            if let kind = PrayerKind(rawValue: p.kind) {
                let pl = PrayerLog(kind: kind, prayedAt: p.prayedAt, linkedDate: p.linkedDate)
                pl.id = p.id
                context.insert(pl)
            }
        }

        for m in payload.meditations {
            if let kind = MeditationKind(rawValue: m.kind) {
                let ml = MeditationLog(kind: kind, durationMinutes: m.durationMinutes,
                                       notes: m.notes, completedAt: m.completedAt)
                ml.id = m.id
                context.insert(ml)
            }
        }

        for s in payload.sundays {
            let sr = SundayReview(weekStartDate: s.weekStartDate)
            sr.createdAt = s.createdAt
            sr.pattern = s.pattern
            sr.win = s.win
            sr.nextWeekFocus = s.nextWeekFocus
            sr.whereIsawGod = s.whereIsawGod
            sr.sabbathPrayerPrayed = s.sabbathPrayerPrayed
            sr.workoutsCompleted = s.workoutsCompleted
            sr.promisesKept = s.promisesKept
            sr.hardThingsDone = s.hardThingsDone
            sr.prayersPrayed = s.prayersPrayed
            sr.meditationsLogged = s.meditationsLogged
            context.insert(sr)
        }

        try context.save()
    }
}
