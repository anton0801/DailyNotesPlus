import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var notesManager: NotesManager
    
    var favoriteNotes: [Note] {
        notesManager.notes.filter { $0.isFavorite }.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                List {
                    ForEach(favoriteNotes) { note in
                        NavigationLink(destination: NoteDetailsView(note: note)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(note.title)
                                    .font(.headline)
                                
                                Text(note.date, style: .date)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete { indices in
                        deleteNotes(at: indices)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Favorites")
        }
    }
    
    func deleteNotes(at indices: IndexSet) {
        let sortedNotes = favoriteNotes
        for index in indices {
            if let originalIndex = notesManager.notes.firstIndex(where: { $0.id == sortedNotes[index].id }) {
                notesManager.notes.remove(at: originalIndex)
            }
        }
    }
}

#Preview {
    FavoritesView()
}
