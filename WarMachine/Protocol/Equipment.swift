import Foundation

struct EquipmentSpec: Identifiable, Hashable, Sendable {
    let name: String
    let approxCost: String
    let note: String
    let isMustHave: Bool

    var id: String { name }
}

enum Equipment {

    static let mustHave: [EquipmentSpec] = [
        EquipmentSpec(name: "Rucksack + weight plates", approxCost: "$60–150", note: "GoRuck, 5.11, or surplus pack. Load with plates, sand, or bricks wrapped in towels.", isMustHave: true),
        EquipmentSpec(name: "Doorway pull-up bar", approxCost: "$30", note: "Essential for daily grease-the-groove.", isMustHave: true),
        EquipmentSpec(name: "Jump rope", approxCost: "$15", note: "Best conditioning tool per dollar that exists.", isMustHave: true),
        EquipmentSpec(name: "Heart rate monitor (chest strap)", approxCost: "$50", note: "Makes zone 2 actually work. Without this, most people ride easy days too hard.", isMustHave: true)
    ]

    static let niceToHave: [EquipmentSpec] = [
        EquipmentSpec(name: "Ab wheel", approxCost: "$15", note: "Brutal core work.", isMustHave: false),
        EquipmentSpec(name: "Resistance bands", approxCost: "$20", note: "Warm-ups, mobility, travel workouts.", isMustHave: false),
        EquipmentSpec(name: "Foam roller", approxCost: "$25", note: "Recovery.", isMustHave: false),
        EquipmentSpec(name: "Kettlebell (1 heavy)", approxCost: "$50–80", note: "Swings, goblet squats, carries at home.", isMustHave: false),
        EquipmentSpec(name: "Adjustable dumbbells", approxCost: "$200–400", note: "Travel/home days. Big unlock.", isMustHave: false),
        EquipmentSpec(name: "Weighted vest (20–40 lb)", approxCost: "$80–150", note: "Progression for pull-ups and push-ups.", isMustHave: false),
        EquipmentSpec(name: "Sandbag", approxCost: "$40–100", note: "Loading variety for rucking prep and carries.", isMustHave: false)
    ]

    static let all: [EquipmentSpec] = mustHave + niceToHave
}
