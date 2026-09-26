import SwiftUI

struct LibraryView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView("Библиотека", systemImage: "books.vertical", description: Text("Здесь появятся твои и публичные опросники."))
                .navigationTitle("Библиотека")
        }
    }
}
