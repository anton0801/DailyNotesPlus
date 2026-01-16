import SwiftUI

struct NotesView: View {
    @EnvironmentObject var notesManager: NotesManager
    @State private var searchText = ""
    @State private var showingCreate = false
    
    var filteredNotes: [Note] {
        let sorted = notesManager.notes.sorted { $0.date > $1.date }
        if searchText.isEmpty {
            return sorted
        } else {
            return sorted.filter { $0.title.lowercased().contains(searchText.lowercased()) || $0.text.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                List {
                    ForEach(filteredNotes) { note in
                        NavigationLink(destination: NoteDetailsView(note: note)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(note.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(note.date, style: .date)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text(note.text.prefix(100) + (note.text.count > 100 ? "..." : ""))
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .onDelete { indices in
                        deleteNotes(at: indices)
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search notes")
            }
            .navigationTitle("My Fishing Notes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreate = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(accentBlue)
                    }
                }
            }
            .sheet(isPresented: $showingCreate) {
                CreateEditNoteView(note: nil)
                    .presentationDetents([.large])
            }
        }
    }
    
    func deleteNotes(at indices: IndexSet) {
        let sortedNotes = filteredNotes
        for index in indices {
            if let originalIndex = notesManager.notes.firstIndex(where: { $0.id == sortedNotes[index].id }) {
                notesManager.notes.remove(at: originalIndex)
            }
        }
    }
}

#Preview {
    NotesView()
}
