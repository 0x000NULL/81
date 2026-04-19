import Foundation
import SwiftData

@Model
final class EquipmentItem {
    @Attribute(.unique) var name: String = ""
    var isMustHave: Bool = true
    var owned: Bool = false
    var approxCost: String?
    var note: String?

    init(name: String, isMustHave: Bool, approxCost: String?, note: String?) {
        self.name = name
        self.isMustHave = isMustHave
        self.approxCost = approxCost
        self.note = note
    }
}
