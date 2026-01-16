import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var notesManager: NotesManager
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                VStack {
                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding()
                    
                    let notesForDay = notesManager.notes.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }.sorted { $0.date > $1.date }
                    
                    List {
                        ForEach(notesForDay) { note in
                            NavigationLink(destination: NoteDetailsView(note: note)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(note.title)
                                        .font(.headline)
                                    
                                    Text(note.date, style: .time)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Calendar")
        }
    }
}

#Preview {
    CalendarView()
}
