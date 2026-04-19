import SwiftUI

struct LibraryTabView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Scripture") {
                    NavigationLink { BibleVersesView() } label: {
                        Label("Bible Verses", systemImage: "text.book.closed.fill")
                    }
                    NavigationLink { FavoriteVersesView() } label: {
                        Label("Favorite Verses", systemImage: "heart.fill")
                    }
                }
                Section("Prayer") {
                    NavigationLink { PrayersView() } label: {
                        Label("Prayers", systemImage: "hands.sparkles")
                    }
                    NavigationLink { MeditationsView() } label: {
                        Label("Meditations", systemImage: "moon.stars")
                    }
                    NavigationLink { PrayerJournalView() } label: {
                        Label("Prayer Journal", systemImage: "book")
                    }
                }
                Section("Training") {
                    NavigationLink { ScriptsView() } label: {
                        Label("Scripts", systemImage: "shield.lefthalf.filled")
                    }
                    NavigationLink { HardThingsView() } label: {
                        Label("Hard Things", systemImage: "flame")
                    }
                    NavigationLink { NutritionView() } label: {
                        Label("Nutrition", systemImage: "fork.knife")
                    }
                    NavigationLink { BooksView() } label: {
                        Label("Books", systemImage: "books.vertical")
                    }
                    NavigationLink { EquipmentView() } label: {
                        Label("Equipment", systemImage: "shippingbox")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Library")
        }
    }
}
