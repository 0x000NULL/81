import SwiftUI
import SwiftData

struct NutritionView: View {
    @Query private var profiles: [UserProfile]

    private var guidance: NutritionGuidance {
        NutritionGuidance.compute(bodyweightLb: profiles.first?.bodyweightLb ?? 180)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                targetsCard
                macrosCard
                electrolytesCard
                mealPlanCard
                Text(NutritionGuidance.sampleReferenceCalories)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding()
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Nutrition")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var targetsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Targets (from bodyweight)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                HStack {
                    Text("Protein")
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text("\(guidance.proteinGrams) g / day")
                        .foregroundStyle(Theme.textPrimary)
                }
                HStack {
                    Text("Water")
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text("\(guidance.waterOunces) oz / day")
                        .foregroundStyle(Theme.textPrimary)
                }
            }
        }
    }

    private var macrosCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Text("Carbs")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(guidance.carbsNote).font(.footnote).foregroundStyle(Theme.verseBody)
                Text("Fats")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary).padding(.top, 8)
                Text(guidance.fatsNote).font(.footnote).foregroundStyle(Theme.verseBody)
            }
        }
    }

    private var electrolytesCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Text("Electrolytes")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(guidance.electrolytesNote).font(.footnote).foregroundStyle(Theme.verseBody)
            }
        }
    }

    private var mealPlanCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Sample training day")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                ForEach(guidance.sampleMealPlan) { meal in
                    HStack(alignment: .firstTextBaseline) {
                        Text(meal.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text(meal.items)
                            .font(.footnote)
                            .foregroundStyle(Theme.verseBody)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
        }
    }
}
