import SwiftUI

struct CreateEditNoteView: View {
    @EnvironmentObject var notesManager: NotesManager
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var text = ""
    @State private var relatedFish = ""
    @State private var location = ""
    @State private var season: Season = .summer
    @State private var tagsString = ""
    @State private var isFavorite = false
    
    let note: Note?
    
    init(note: Note?) {
        self.note = note
        if let note {
            _title = State(initialValue: note.title)
            _text = State(initialValue: note.text)
            _relatedFish = State(initialValue: note.relatedFish ?? "")
            _location = State(initialValue: note.location ?? "")
            _season = State(initialValue: note.season)
            _tagsString = State(initialValue: note.tags.joined(separator: ", "))
            _isFavorite = State(initialValue: note.isFavorite)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                Form {
                    Section(header: Text("Note Content").font(.subheadline)) {
                        TextField("Title (e.g., Morning bite observations)", text: $title)
                            .font(.body)
                        
                        TextEditor(text: $text)
                            .frame(minHeight: 200)
                            .font(.body)
                    }
                    
                    Section(header: Text("Details").font(.subheadline)) {
                        TextField("Related Fish (optional)", text: $relatedFish)
                        TextField("Location (optional)", text: $location)
                        Picker("Season", selection: $season) {
                            Text("Spring").tag(Season.spring)
                            Text("Summer").tag(Season.summer)
                            Text("Autumn").tag(Season.autumn)
                            Text("Winter").tag(Season.winter)
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Section(header: Text("Tags").font(.subheadline)) {
                        TextField("Tags (comma separated, e.g., weather, depth, bait)", text: $tagsString)
                    }
                    
                    Toggle("Add to Favorites", isOn: $isFavorite)
                        .tint(accentGreen)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(note == nil ? "New Note" : "Edit Note")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveNote()
                        dismiss()
                    }
                    .foregroundColor(accentBlue)
                    .disabled(title.isEmpty || text.isEmpty)
                }
            }
        }
    }
    
    func saveNote() {
        let tags = tagsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let newNote = Note(title: title, text: text, date: note?.date ?? Date(), relatedFish: relatedFish.isEmpty ? nil : relatedFish, location: location.isEmpty ? nil : location, season: season, tags: tags, isFavorite: isFavorite)
        
        if let note, let index = notesManager.notes.firstIndex(where: { $0.id == note.id }) {
            notesManager.notes[index] = newNote
        } else {
            notesManager.notes.append(newNote)
        }
    }
}
