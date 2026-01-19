import SwiftUI

#Preview {
    OnboardingView()
}

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0
    
    let pages = [
        OnboardingPage(
            icon: "square.and.pencil",
            title: "Write Fishing Notes Freely",
            description: "Capture your fishing experiences, observations, and insights in your personal journal",
            color: Color(hex: "1E88E5")
        ),
        OnboardingPage(
            icon: "tag.fill",
            title: "Organize by Tags & Favorites",
            description: "Structure your knowledge with custom tags and mark important notes as favorites",
            color: Color(hex: "26A69A")
        ),
        OnboardingPage(
            icon: "book.closed.fill",
            title: "Build Your Fishing Knowledge",
            description: "Create a comprehensive personal database of fishing wisdom and techniques",
            color: Color(hex: "FF6F00")
        )
    ]
    
    var body: some View {
        ZStack {
            Color(hex: "FAFAF8")
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "7F8C8D"))
                    .padding()
                }
                
                // Pages
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(
                            page: pages[index],
                            currentPage: $currentPage,
                            pageIndex: index
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Custom page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? pages[index].color : Color.gray.opacity(0.3))
                            .frame(width: currentPage == index ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.bottom, 20)
                
                // Action button
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            currentPage += 1
                        }
                    } else {
                        completeOnboarding()
                    }
                }) {
                    HStack {
                        Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                            .font(.system(size: 18, weight: .semibold))
                        
                        if currentPage == pages.count - 1 {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [pages[currentPage].color, pages[currentPage].color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(28)
                    .shadow(color: pages[currentPage].color.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func completeOnboarding() {
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @Binding var currentPage: Int
    let pageIndex: Int
    @State private var iconScale: CGFloat = 0.5
    @State private var iconRotation: Double = -180
    @State private var textOpacity: Double = 0
    @State private var particleAnimation = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Animated icon with particles
            ZStack {
                // Background particles
                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .fill(page.color.opacity(0.2))
                        .frame(width: 20, height: 20)
                        .offset(
                            x: particleAnimation ? CGFloat.random(in: -100...100) : 0,
                            y: particleAnimation ? CGFloat.random(in: -100...100) : 0
                        )
                        .opacity(particleAnimation ? 0 : 1)
                }
                
                // Main icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [page.color.opacity(0.2), page.color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 200, height: 200)
                    
                    Image(systemName: page.icon)
                        .font(.system(size: 80, weight: .light))
                        .foregroundColor(page.color)
                }
                .scaleEffect(iconScale)
                .rotationEffect(.degrees(iconRotation))
            }
            .frame(height: 250)
            
            // Text content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "2C3E50"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Text(page.description)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(Color(hex: "7F8C8D"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
            }
            .opacity(textOpacity)
            
            Spacer()
        }
        .onChange(of: currentPage) { newValue in
            if newValue == pageIndex {
                animateContent()
            }
        }
        .onAppear {
            if currentPage == pageIndex {
                animateContent()
            }
        }
    }
    
    private func animateContent() {
        // Reset states
        iconScale = 0.5
        iconRotation = -180
        textOpacity = 0
        particleAnimation = false
        
        // Animate icon
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1)) {
            iconScale = 1.0
            iconRotation = 0
        }
        
        // Animate text
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            textOpacity = 1.0
        }
        
        // Animate particles
        withAnimation(.easeOut(duration: 1.5).delay(0.2)) {
            particleAnimation = true
        }
    }
}
