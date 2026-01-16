import SwiftUI

struct NoteDetailsView: View {
    @EnvironmentObject var notesManager: NotesManager
    let note: Note
    @State private var showingEdit = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(note.title)
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)
                    
                    Text(note.date, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(note.text)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    if let fish = note.relatedFish {
                        Text("Related Fish: \(fish)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let loc = note.location {
                        Text("Location: \(loc)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Season: \(note.season.rawValue.capitalized)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if !note.tags.isEmpty {
                        HStack(spacing: 8) {
                            Text("Tags:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            ForEach(note.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(20)
                                    .foregroundColor(accentBlue)
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Note Details")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Edit") {
                        showingEdit = true
                    }
                    Button(note.isFavorite ? "Remove from Favorites" : "Add to Favorites") {
                        toggleFavorite()
                    }
                    Button("Delete", role: .destructive) {
                        showingDeleteAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(accentBlue)
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            CreateEditNoteView(note: note)
        }
        .alert("Delete Note", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteNote()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this note?")
        }
    }
    
    func toggleFavorite() {
        if let index = notesManager.notes.firstIndex(where: { $0.id == note.id }) {
            notesManager.notes[index].isFavorite.toggle()
        }
    }
    
    func deleteNote() {
        if let index = notesManager.notes.firstIndex(where: { $0.id == note.id }) {
            notesManager.notes.remove(at: index)
        }
    }
}

