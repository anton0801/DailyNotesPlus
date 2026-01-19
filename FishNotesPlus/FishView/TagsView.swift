import SwiftUI

struct TagsView: View {
    @EnvironmentObject var viewModel: NotesViewModel
    @State private var selectedTag: String?
    @State private var showingNotes = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "FAFAF8")
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tags")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Color(hex: "2C3E50"))
                            
                            Text("\(viewModel.allTags.count) tags")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "7F8C8D"))
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    if viewModel.allTags.isEmpty {
                        emptyStateView
                    } else {
                        tagsListView
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private var tagsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.allTags, id: \.self) { tag in
                    TagRowView(
                        tag: tag,
                        count: viewModel.tagCounts[tag] ?? 0
                    ) {
                        selectedTag = tag
                        showingNotes = true
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .sheet(isPresented: $showingNotes) {
            if let tag = selectedTag {
                TagNotesView(tag: tag)
                    .environmentObject(viewModel)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tag")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "26A69A").opacity(0.3))
            
            Text("No Tags Yet")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(Color(hex: "2C3E50"))
            
            Text("Tags will appear here when you add them to notes")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "7F8C8D"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct TagRowView: View {
    let tag: String
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "tag.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "26A69A"))
                    .frame(width: 40, height: 40)
                    .background(Color(hex: "26A69A").opacity(0.15))
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(tag)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(hex: "2C3E50"))
                    
                    Text("\(count) note\(count == 1 ? "" : "s")")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "7F8C8D"))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "7F8C8D"))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct TagNotesView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: NotesViewModel
    let tag: String
    
    var filteredNotes: [FishingNote] {
        viewModel.notes.filter { $0.tags.contains(tag) }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "FAFAF8")
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredNotes) { note in
                            NavigationLink(destination: NoteDetailView(note: note).environmentObject(viewModel)) {
                                NoteCardView(note: note)
                                    .environmentObject(viewModel)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Color(hex: "1E88E5"))
                }
                
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundColor(Color(hex: "26A69A"))
                        Text(tag)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "2C3E50"))
                    }
                }
            }
        }
    }
}
