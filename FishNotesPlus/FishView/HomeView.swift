import SwiftUI

struct HomeView: View {
    @EnvironmentObject var notesViewModel: NotesViewModel
    @EnvironmentObject var gearViewModel: GearViewModel
    @EnvironmentObject var checklistViewModel: ChecklistViewModel
    
    @State private var selectedMonth = Date()
    @State private var showingAllLocations = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Welcome header
                        welcomeHeader
                        
                        // Quick stats cards
                        quickStatsSection
                        
                        // Activity heatmap
                        activityHeatmapSection
                        
                        // Season statistics
                        seasonStatsSection
                        
                        // Top tags
                        topTagsSection
                        
                        // Favorite locations
                        favoriteLocationsSection
                        
                        // Quick actions
                        quickActionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Welcome Header
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome Back! 👋")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("\(notesThisMonth) notes this month")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
                
                // Profile icon with glow
                ZStack {
                    Circle()
                        .fill(AppTheme.primaryAccent.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .blur(radius: 10)
                    
                    Circle()
                        .fill(AppTheme.surface)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(AppTheme.primaryAccent.opacity(0.5), lineWidth: 2)
                        )
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 22))
                        .foregroundColor(AppTheme.primaryAccent)
                }
            }
        }
    }
    
    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    title: "Total Notes",
                    value: "\(notesViewModel.notes.count)",
                    icon: "note.text",
                    color: AppTheme.primaryAccent
                )
                
                StatCard(
                    title: "Favorites",
                    value: "\(favoriteCount)",
                    icon: "star.fill",
                    color: AppTheme.secondaryAccent
                )
            }
            
            HStack(spacing: 12) {
                StatCard(
                    title: "This Week",
                    value: "\(notesThisWeek)",
                    icon: "calendar",
                    color: AppTheme.success
                )
                
                StatCard(
                    title: "Gear Items",
                    value: "\(gearViewModel.gearItems.count)",
                    icon: "figure.fishing",
                    color: Color(hex: "FF6B35")
                )
            }
        }
    }
    
    // MARK: - Activity Heatmap Section
    private var activityHeatmapSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Activity")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("Your fishing journal timeline")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
            }
            
            ActivityHeatmap(notes: notesViewModel.notes, selectedMonth: $selectedMonth)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.primaryAccent.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Season Stats Section
    private var seasonStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Season Breakdown")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("Notes by season")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
            }
            
            SeasonChart(notes: notesViewModel.notes)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.secondaryAccent.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Top Tags Section
    private var topTagsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Top Tags")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("Most used tags")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
            }
            
            if topTags.isEmpty {
                EmptyStateView(
                    icon: "tag",
                    title: "No tags yet",
                    description: "Tags will appear here as you add them to notes"
                )
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(topTags.prefix(5)), id: \.key) { tag, count in
                        TopTagRow(tag: tag, count: count, maxCount: topTags.first?.value ?? 1)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.success.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Favorite Locations Section
    private var favoriteLocationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Favorite Locations")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("Most visited fishing spots")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
                
                if !favoriteLocations.isEmpty {
                    Button(action: { showingAllLocations.toggle() }) {
                        Text("See All")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.primaryAccent)
                    }
                }
            }
            
            if favoriteLocations.isEmpty {
                EmptyStateView(
                    icon: "map",
                    title: "No locations yet",
                    description: "Add locations to your notes to see them here"
                )
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(favoriteLocations.prefix(showingAllLocations ? favoriteLocations.count : 3)), id: \.key) { location, count in
                        LocationRow(location: location, count: count)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(hex: "FF6B35").opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            QuickActionButton(
                title: "New Note",
                icon: "plus.circle.fill",
                gradient: AppTheme.primaryGradient
            ) {
                // Navigate to create note
            }
            
            HStack(spacing: 12) {
                QuickActionButton(
                    title: "Add Gear",
                    icon: "figure.fishing",
                    gradient: AppTheme.secondaryGradient
                ) {
                    // Navigate to add gear
                }
                
                QuickActionButton(
                    title: "New List",
                    icon: "checklist",
                    gradient: AppTheme.successGradient
                ) {
                    // Navigate to create checklist
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var notesThisMonth: Int {
        let calendar = Calendar.current
        return notesViewModel.notes.filter { calendar.isDate($0.createdAt, equalTo: Date(), toGranularity: .month) }.count
    }
    
    private var notesThisWeek: Int {
        let calendar = Calendar.current
        return notesViewModel.notes.filter { calendar.isDate($0.createdAt, equalTo: Date(), toGranularity: .weekOfYear) }.count
    }
    
    private var favoriteCount: Int {
        notesViewModel.notes.filter { $0.isFavorite }.count
    }
    
    private var topTags: [(key: String, value: Int)] {
        notesViewModel.tagCounts.sorted { $0.value > $1.value }
    }
    
    private var favoriteLocations: [(key: String, value: Int)] {
        var locationCounts: [String: Int] = [:]
        for note in notesViewModel.notes {
            if let location = note.location, !location.isEmpty {
                locationCounts[location, default: 0] += 1
            }
        }
        return locationCounts.sorted { $0.value > $1.value }
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: color.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Activity Heatmap
struct ActivityHeatmap: View {
    let notes: [FishingNote]
    @Binding var selectedMonth: Date
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    
    var body: some View {
        VStack(spacing: 12) {
            // Month selector
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.primaryAccent)
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.primaryAccent)
                }
            }
            
            // Day labels
            HStack(spacing: 4) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(getDaysInMonth(), id: \.self) { date in
                    if let date = date {
                        DayHeatmapCell(
                            date: date,
                            noteCount: notesCount(for: date),
                            isCurrentMonth: calendar.isDate(date, equalTo: selectedMonth, toGranularity: .month)
                        )
                    } else {
                        Color.clear
                            .frame(height: 36)
                    }
                }
            }
            
            // Legend
            HStack(spacing: 12) {
                Text("Less")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                
                HStack(spacing: 4) {
                    ForEach(0..<5) { level in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(heatmapColor(for: level))
                            .frame(width: 16, height: 16)
                    }
                }
                
                Text("More")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }
    
    private func getDaysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start)
        else { return [] }
        
        var days: [Date?] = []
        let monthStart = monthInterval.start
        let monthEnd = monthInterval.end
        
        var current = monthFirstWeek.start
        while current < monthStart {
            days.append(nil)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        
        current = monthStart
        while current < monthEnd {
            days.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    private func notesCount(for date: Date) -> Int {
        notes.filter { calendar.isDate($0.createdAt, inSameDayAs: date) }.count
    }
    
    private func heatmapColor(for level: Int) -> Color {
        switch level {
        case 0: return AppTheme.cardHighlight
        case 1: return AppTheme.primaryAccent.opacity(0.3)
        case 2: return AppTheme.primaryAccent.opacity(0.5)
        case 3: return AppTheme.primaryAccent.opacity(0.7)
        default: return AppTheme.primaryAccent
        }
    }
    
    private func previousMonth() {
        selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
    }
    
    private func nextMonth() {
        selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
    }
}

struct DayHeatmapCell: View {
    let date: Date
    let noteCount: Int
    let isCurrentMonth: Bool
    
    private var heatLevel: Int {
        switch noteCount {
        case 0: return 0
        case 1: return 1
        case 2: return 2
        case 3: return 3
        default: return 4
        }
    }
    
    private var cellColor: Color {
        guard isCurrentMonth else { return AppTheme.cardHighlight.opacity(0.3) }
        
        switch heatLevel {
        case 0: return AppTheme.cardHighlight
        case 1: return AppTheme.primaryAccent.opacity(0.3)
        case 2: return AppTheme.primaryAccent.opacity(0.5)
        case 3: return AppTheme.primaryAccent.opacity(0.7)
        default: return AppTheme.primaryAccent
        }
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(cellColor)
            
            if noteCount > 0 && isCurrentMonth {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(AppTheme.primaryAccent.opacity(0.5), lineWidth: 1)
            }
        }
        .frame(height: 36)
        .shadow(color: noteCount > 0 ? AppTheme.primaryAccent.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
    }
}

// MARK: - Season Chart
struct SeasonChart: View {
    let notes: [FishingNote]
    
    private var seasonCounts: [FishingNote.Season: Int] {
        var counts: [FishingNote.Season: Int] = [:]
        for season in FishingNote.Season.allCases {
            counts[season] = notes.filter { $0.season == season }.count
        }
        return counts
    }
    
    private var maxCount: Int {
        seasonCounts.values.max() ?? 1
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ForEach(FishingNote.Season.allCases, id: \.self) { season in
                VStack(spacing: 8) {
                    ZStack(alignment: .bottom) {
                        // Background bar
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppTheme.cardHighlight)
                            .frame(height: 150)
                        
                        // Actual bar with gradient
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [season.color, season.color.opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: barHeight(for: season))
                            .shadow(color: season.color.opacity(0.5), radius: 8, x: 0, y: 4)
                        
                        // Count label
                        if seasonCounts[season, default: 0] > 0 {
                            Text("\(seasonCounts[season, default: 0])")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                                .padding(.bottom, 8)
                        }
                    }
                    
                    // Season icon and name
                    VStack(spacing: 4) {
                        Image(systemName: season.icon)
                            .font(.system(size: 18))
                            .foregroundColor(season.color)
                        
                        Text(season.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func barHeight(for season: FishingNote.Season) -> CGFloat {
        let count = CGFloat(seasonCounts[season, default: 0])
        let max = CGFloat(maxCount)
        return max > 0 ? (count / max) * 150 : 0
    }
}

// MARK: - Top Tag Row
struct TopTagRow: View {
    let tag: String
    let count: Int
    let maxCount: Int
    
    private var percentage: CGFloat {
        CGFloat(count) / CGFloat(maxCount)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Tag icon
            Image(systemName: "tag.fill")
                .font(.system(size: 16))
                .foregroundColor(AppTheme.success)
                .frame(width: 30)
            
            // Tag name
            Text(tag)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppTheme.textPrimary)
            
            Spacer()
            
            // Progress bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.cardHighlight)
                    .frame(width: 80, height: 8)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.success)
                    .frame(width: 80 * percentage, height: 8)
            }
            
            // Count
            Text("\(count)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppTheme.textSecondary)
                .frame(width: 30, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Location Row
struct LocationRow: View {
    let location: String
    let count: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Location icon
            ZStack {
                Circle()
                    .fill(Color(hex: "FF6B35").opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "FF6B35"))
            }
            
            // Location name
            VStack(alignment: .leading, spacing: 2) {
                Text(location)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("\(count) visit\(count == 1 ? "" : "s")")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            // Arrow
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.cardHighlight)
        )
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let title: String
    let icon: String
    let gradient: LinearGradient
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                
                Spacer()
            }
            .foregroundColor(AppTheme.background)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(gradient)
                    .shadow(color: AppTheme.primaryAccent.opacity(0.4), radius: 12, x: 0, y: 6)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(AppTheme.textSecondary.opacity(0.5))
            
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.textSecondary)
            
            Text(description)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textDisabled)
                .multilineTextAlignment(.center)
        }
    }
}
