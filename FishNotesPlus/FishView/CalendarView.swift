// CalendarView.swift
import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var viewModel: NotesViewModel
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var notesForSelectedDate: [FishingNote] {
        viewModel.notes.filter { calendar.isDate($0.createdAt, inSameDayAs: selectedDate) }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "FAFAF8")
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Month header
                    monthHeader
                    
                    // Calendar grid
                    calendarGrid
                    
                    Divider()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    
                    // Notes for selected date
                    if notesForSelectedDate.isEmpty {
                        emptyDateView
                    } else {
                        notesListView
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Calendar")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "2C3E50"))
                }
            }
        }
    }
    
    private var monthHeader: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "1E88E5"))
            }
            
            Spacer()
            
            Text(dateFormatter.string(from: currentMonth))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(hex: "2C3E50"))
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "1E88E5"))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var calendarGrid: some View {
        VStack(spacing: 8) {
            // Day headers
            HStack {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "7F8C8D"))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
            
            // Days grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(getDaysInMonth(), id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            hasNotes: hasNotes(on: date),
                            isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
                        ) {
                            selectedDate = date
                        }
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var notesListView: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("Notes for \(DateFormatter.longFormatter.string(from: selectedDate))")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "2C3E50"))
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                
                LazyVStack(spacing: 12) {
                    ForEach(notesForSelectedDate) { note in
                        NavigationLink(destination: NoteDetailView(note: note).environmentObject(viewModel)) {
                            NoteCardView(note: note)
                                .environmentObject(viewModel)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
        }
    }
    
    private var emptyDateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "7F8C8D").opacity(0.3))
            
            Text("No notes for this day")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "7F8C8D"))
        }
        .frame(maxHeight: .infinity)
    }
    
    private func getDaysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start)
        else { return [] }
        
        var days: [Date?] = []
        let monthStart = monthInterval.start
        let monthEnd = monthInterval.end
        
        // Add days from previous month to fill first week
        var current = monthFirstWeek.start
        while current < monthStart {
            days.append(nil)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        
        // Add all days in month
        current = monthStart
        while current < monthEnd {
            days.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        
        // Fill remaining days to complete grid
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    private func hasNotes(on date: Date) -> Bool {
        viewModel.notes.contains { calendar.isDate($0.createdAt, inSameDayAs: date) }
    }
    
    private func previousMonth() {
        withAnimation {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }
    
    private func nextMonth() {
        withAnimation {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let hasNotes: Bool
    let isCurrentMonth: Bool
    let action: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .white : (isCurrentMonth ? Color(hex: "2C3E50") : Color(hex: "7F8C8D").opacity(0.4)))
                
                if hasNotes {
                    Circle()
                        .fill(isSelected ? .white : Color(hex: "1E88E5"))
                        .frame(width: 4, height: 4)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ?
                          LinearGradient(
                            colors: [Color(hex: "1E88E5"), Color(hex: "0D47A1")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          ) :
                          LinearGradient(
                            colors: [Color.clear, Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
