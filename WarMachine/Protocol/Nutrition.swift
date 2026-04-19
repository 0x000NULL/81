import Foundation

struct Meal: Identifiable, Hashable, Sendable {
    let name: String
    let items: String

    var id: String { name }
}

struct NutritionGuidance: Sendable {
    let proteinGrams: Int
    let waterOunces: Int
    let carbsNote: String
    let fatsNote: String
    let electrolytesNote: String
    let sampleMealPlan: [Meal]

    static func compute(bodyweightLb: Double) -> NutritionGuidance {
        NutritionGuidance(
            proteinGrams: Int((bodyweightLb).rounded()),
            waterOunces: Int((bodyweightLb * 0.5).rounded()),
            carbsNote: "Moderate–high on training days. Sources: rice, oats, potatoes, fruit, pasta, bread.",
            fatsNote: "~25–30% of calories. Sources: olive oil, avocado, eggs, fatty fish, nuts.",
            electrolytesNote: "On long conditioning days: LMNT-style mix or salt food + potassium.",
            sampleMealPlan: [
                Meal(name: "Breakfast", items: "4 eggs, 1 cup oats, banana, coffee"),
                Meal(name: "Lunch", items: "8 oz chicken, 1.5 cups rice, vegetables, olive oil"),
                Meal(name: "Pre-workout", items: "Apple + whey shake"),
                Meal(name: "Post-workout", items: "Whey + rice cakes or banana"),
                Meal(name: "Dinner", items: "8 oz beef or salmon, potato, vegetables"),
                Meal(name: "Before bed", items: "Greek yogurt + nuts")
            ]
        )
    }

    static let sampleReferenceCalories = "Sample training day at 200 lb is ~3500 cal. Scale portions to your calorie target."
}
