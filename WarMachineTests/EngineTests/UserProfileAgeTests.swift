import Testing
import Foundation
import SwiftData
@testable import WarMachine

@Suite("UserProfile age math")
@MainActor
struct UserProfileAgeTests {

    @Test("nil birthDate returns nil")
    func nilBirthday() throws {
        let ctx = try Self.makeContext()
        let p = UserProfile()
        ctx.insert(p)
        #expect(p.ageYears(on: .now) == nil)
        #expect(p.zone2MaxHR(on: .now) == nil)
    }

    @Test("standard birthday: age and 180-age computed")
    func standard() throws {
        let ctx = try Self.makeContext()
        let p = UserProfile()
        let dob = Calendar.current.date(from: DateComponents(year: 1990, month: 3, day: 14))!
        let now = Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 19))!
        p.birthDate = dob
        ctx.insert(p)
        #expect(p.ageYears(on: now) == 36)
        #expect(p.zone2MaxHR(on: now) == 144)
    }

    @Test("birthday hasn't occurred yet this year")
    func birthdayNotYet() throws {
        let ctx = try Self.makeContext()
        let p = UserProfile()
        let dob = Calendar.current.date(from: DateComponents(year: 1990, month: 12, day: 25))!
        let now = Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 19))!
        p.birthDate = dob
        ctx.insert(p)
        #expect(p.ageYears(on: now) == 35)
        #expect(p.zone2MaxHR(on: now) == 145)
    }

    @Test("leap-day birthday on non-leap year")
    func leapDay() throws {
        let ctx = try Self.makeContext()
        let p = UserProfile()
        let dob = Calendar.current.date(from: DateComponents(year: 1992, month: 2, day: 29))!
        let now = Calendar.current.date(from: DateComponents(year: 2025, month: 3, day: 1))!
        p.birthDate = dob
        ctx.insert(p)
        #expect(p.ageYears(on: now) == 33)
    }

    @MainActor
    private static func makeContext() throws -> ModelContext {
        let schema = Schema(versionedSchema: SchemaV2.self)
        let container = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
        return ModelContext(container)
    }
}
