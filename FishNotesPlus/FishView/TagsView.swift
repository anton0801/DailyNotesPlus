import SwiftUI

struct TagsView: View {
    @EnvironmentObject var notesManager: NotesManager
    
    var tags: [String: Int] {
        var tagCounts = [String: Int]()
        for note in notesManager.notes {
            for tag in note.tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        return tagCounts
    }
    
    var sortedTags: [(String, Int)] {
        tags.sorted { $0.value > $1.value }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                List {
                    ForEach(sortedTags, id: \.0) { tag, count in
                        NavigationLink(destination: NotesByTagView(tag: tag)) {
                            HStack {
                                Text(tag)
                                    .font(.headline)
                                    .foregroundColor(accentBlue)
                                
                                Spacer()
                                
                                Text("\(count) notes")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Tags")
        }
    }
}

struct NotesByTagView: View {
    let tag: String
    @EnvironmentObject var notesManager: NotesManager
    
    var filteredNotes: [Note] {
        notesManager.notes.filter { $0.tags.contains(tag) }.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            List {
                ForEach(filteredNotes) { note in
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
        .navigationTitle("Notes with \(tag)")
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
