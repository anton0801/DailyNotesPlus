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
            title: "Capture Your Fishing Stories",
            description: "Document every moment with detailed notes, photos, and gear tracking",
            color: AppTheme.primaryAccent,
            animation: "notes"
        ),
        OnboardingPage(
            icon: "chart.bar.fill",
            title: "Track Your Progress",
            description: "Analyze patterns, view statistics, and improve your fishing strategy",
            color: AppTheme.secondaryAccent,
            animation: "stats"
        ),
        OnboardingPage(
            icon: "checklist",
            title: "Stay Organized",
            description: "Manage gear, create checklists, and never forget essential equipment",
            color: AppTheme.success,
            animation: "gear"
        )
    ]
    
    var body: some View {
        ZStack {
            // Dark background
            AppTheme.background
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
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
                
                // Custom page indicator with neon effect
                HStack(spacing: 12) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? pages[index].color : AppTheme.textDisabled)
                            .frame(width: currentPage == index ? 32 : 8, height: 8)
                            .shadow(color: currentPage == index ? pages[index].color.opacity(0.8) : Color.clear, radius: 8, x: 0, y: 0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.bottom, 24)
                
                // Action button with gradient
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            currentPage += 1
                        }
                    } else {
                        completeOnboarding()
                    }
                }) {
                    HStack(spacing: 12) {
                        Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                            .font(.system(size: 18, weight: .bold))
                        
                        if currentPage == pages.count - 1 {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .foregroundColor(AppTheme.background)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(
                                LinearGradient(
                                    colors: [pages[currentPage].color, pages[currentPage].color.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: pages[currentPage].color.opacity(0.6), radius: 15, x: 0, y: 8)
                    )
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
    let animation: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @Binding var currentPage: Int
    let pageIndex: Int
    
    @State private var iconScale: CGFloat = 0.5
    @State private var iconRotation: Double = -180
    @State private var textOpacity: Double = 0
    @State private var particleAnimation = false
    @State private var glowRadius: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 50) {
            Spacer()
            
            // Animated icon with neon glow
            ZStack {
                // Neon glow background
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                page.color.opacity(0.4),
                                page.color.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .blur(radius: glowRadius)
                
                // Background particles
                ForEach(0..<8, id: \.self) { index in
                    Circle()
                        .fill(page.color.opacity(0.3))
                        .frame(width: 12, height: 12)
                        .offset(
                            x: particleAnimation ? cos(Double(index) * .pi / 4) * 100 : 0,
                            y: particleAnimation ? sin(Double(index) * .pi / 4) * 100 : 0
                        )
                        .opacity(particleAnimation ? 0 : 1)
                }
                
                // Main icon circle
                ZStack {
                    Circle()
                        .fill(AppTheme.surface)
                        .frame(width: 180, height: 180)
                        .overlay(
                            Circle()
                                .stroke(page.color.opacity(0.5), lineWidth: 3)
                        )
                        .shadow(color: page.color.opacity(0.4), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: page.icon)
                        .font(.system(size: 70, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [page.color, page.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: page.color.opacity(0.8), radius: 10, x: 0, y: 0)
                }
                .scaleEffect(iconScale)
                .rotationEffect(.degrees(iconRotation))
            }
            .frame(height: 300)
            
            // Text content
            VStack(spacing: 20) {
                Text(page.title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Text(page.description)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
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
        glowRadius = 0
        
        // Animate icon
        withAnimation(.spring(response: 0.9, dampingFraction: 0.6).delay(0.1)) {
            iconScale = 1.0
            iconRotation = 0
        }
        
        // Animate glow
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.2)) {
            glowRadius = 20
        }
        
        // Animate text
        withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
            textOpacity = 1.0
        }
        
        // Animate particles
        withAnimation(.easeOut(duration: 1.8).delay(0.3)) {
            particleAnimation = true
        }
    }
}
