import Foundation
import SwiftData

/// Resolves an `EquipmentItem` row by name. On sync collision, merges
/// by OR'ing `owned` and preferring non-empty notes.
@MainActor
enum EquipmentStore {
    static func findOrCreate(name: String,
                             isMustHave: Bool = true,
                             approxCost: String? = nil,
                             note: String? = nil,
                             in context: ModelContext) -> EquipmentItem {
        let descriptor = FetchDescriptor<EquipmentItem>(
            predicate: #Predicate { $0.name == name }
        )
        let matches = (try? context.fetch(descriptor)) ?? []

        if let canonical = matches.first {
            for sibling in matches.dropFirst() {
                canonical.owned = canonical.owned || sibling.owned
                if canonical.note == nil || canonical.note?.isEmpty == true {
                    canonical.note = sibling.note
                }
                if canonical.approxCost == nil || canonical.approxCost?.isEmpty == true {
                    canonical.approxCost = sibling.approxCost
                }
                context.delete(sibling)
            }
            return canonical
        }

        let fresh = EquipmentItem(name: name, isMustHave: isMustHave,
                                  approxCost: approxCost, note: note)
        context.insert(fresh)
        return fresh
    }
}
