import SwiftUI
import Combine

struct SplashScreenView: View {
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var glowRadius: CGFloat = 0
    @State private var waveOffset: CGFloat = 0
    @State private var particlesOpacity: Double = 0
    @State private var particles: [WaterParticle] = []
    @State private var ripples: [Ripple] = []
    
    var body: some View {
        GeometryReader { g in
            ZStack {
                DarkWaterBackground(waveOffset: waveOffset)
                
                Image(g.size.width > g.size.height ? "main_l" : "main")
                    .resizable()
                    .scaledToFill()
                    .frame(width: g.size.width, height: g.size.height)
                    .ignoresSafeArea()
                    .opacity(0.5)
                
                // Ripple effects
                ForEach(ripples) { ripple in
                    RippleView(ripple: ripple)
                }
                
                // Floating particles
                ForEach(particles) { particle in
                    WaterParticleView(particle: particle)
                        .opacity(particlesOpacity)
                }
                
                // Main logo with neon glow
                VStack(spacing: 24) {
                    ZStack {
                        // Neon glow effect
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        AppTheme.primaryAccent.opacity(0.6),
                                        AppTheme.primaryAccent.opacity(0.3),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200)
                            .blur(radius: glowRadius)
                        
                        // Logo icon
                        Image(systemName: "book.fill")
                            .font(.system(size: 90, weight: .thin))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppTheme.primaryAccent, AppTheme.secondaryAccent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Image(systemName: "fish.fill")
                                    .font(.system(size: 35))
                                    .foregroundColor(AppTheme.secondaryAccent)
                                    .offset(x: 40, y: -30)
                            )
                            .shadow(color: AppTheme.primaryAccent.opacity(0.8), radius: 20, x: 0, y: 0)
                            .shadow(color: AppTheme.primaryAccent.opacity(0.4), radius: 40, x: 0, y: 0)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Daily Notes Master")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppTheme.textPrimary, AppTheme.primaryAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: AppTheme.primaryAccent.opacity(0.5), radius: 10, x: 0, y: 5)
                        
                        Text("Dark Waters Edition")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(AppTheme.textSecondary)
                            .tracking(2)
                    }
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
            }
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                initializeEffects()
                startAnimations()
            }
        }
        .ignoresSafeArea()
    }
    
    private func initializeEffects() {
        // Initialize particles
        for _ in 0..<15 {
            particles.append(WaterParticle())
        }
        
        // Initialize ripples
        for i in 0..<3 {
            ripples.append(Ripple(delay: Double(i) * 0.5))
        }
    }
    
    private func startAnimations() {
        // Logo animation
        withAnimation(.spring(response: 1.0, dampingFraction: 0.6, blendDuration: 0).delay(0.2)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Glow pulsing animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowRadius = 30
        }
        
        // Wave animation
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            waveOffset = UIScreen.main.bounds.width
        }
        
        // Particles fade in
        withAnimation(.easeIn(duration: 0.8).delay(0.5)) {
            particlesOpacity = 1.0
        }
    }
}

// MARK: - Background with animated waves
struct DarkWaterBackground: View {
    let waveOffset: CGFloat
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(hex: "0A0E1A"),
                    AppTheme.background,
                    Color(hex: "1A2332")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Animated wave layers
            WaveShape(offset: waveOffset, percent: 0.7)
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.primaryAccent.opacity(0.1),
                            AppTheme.primaryAccent.opacity(0.05)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            WaveShape(offset: waveOffset * 0.8, percent: 0.6)
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.secondaryAccent.opacity(0.08),
                            AppTheme.secondaryAccent.opacity(0.03)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
    }
}

struct WaveShape: Shape {
    var offset: CGFloat
    var percent: Double
    
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let midHeight = height * percent
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / 50
            let sine = sin(relativeX + offset / 50)
            let y = midHeight + sine * 20
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Water Particle
struct WaterParticle: Identifiable {
    let id = UUID()
    let startX: CGFloat = CGFloat.random(in: 0...UIScreen.main.bounds.width)
    let startY: CGFloat = CGFloat.random(in: 0...UIScreen.main.bounds.height)
    let size: CGFloat = CGFloat.random(in: 3...8)
    let duration: Double = Double.random(in: 3...6)
    let opacity: Double = Double.random(in: 0.2...0.5)
    let delay: Double = Double.random(in: 0...2)
}

struct WaterParticleView: View {
    let particle: WaterParticle
    @State private var offsetY: CGFloat = 0
    @State private var opacity: Double = 1
    
    var body: some View {
        Circle()
            .fill(AppTheme.primaryAccent)
            .frame(width: particle.size, height: particle.size)
            .opacity(opacity * particle.opacity)
            .position(x: particle.startX, y: particle.startY + offsetY)
            .blur(radius: 2)
            .onAppear {
                withAnimation(
                    .linear(duration: particle.duration)
                    .repeatForever(autoreverses: false)
                    .delay(particle.delay)
                ) {
                    offsetY = -UIScreen.main.bounds.height - 50
                    opacity = 0
                }
            }
    }
}

// MARK: - Ripple Effect
struct Ripple: Identifiable {
    let id = UUID()
    let delay: Double
}

struct RippleView: View {
    let ripple: Ripple
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 0.8
    
    var body: some View {
        Circle()
            .stroke(AppTheme.primaryAccent.opacity(0.5), lineWidth: 2)
            .frame(width: 300, height: 300)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeOut(duration: 2.5)
                    .repeatForever(autoreverses: false)
                    .delay(ripple.delay)
                ) {
                    scale = 2.0
                    opacity = 0
                }
            }
    }
}

struct NotesApplicationView: View {
    
    @StateObject private var coordinator = AppViewModel()
    @State private var eventObservers: Set<AnyCancellable> = []
    
    var body: some View {
        ZStack {
            primaryContent
            
            if coordinator.showPermissionPrompt {
                PermissionDialog()
                    .environmentObject(coordinator)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .onAppear {
            observeEvents()
        }
    }
    
    @ViewBuilder
    private var primaryContent: some View {
        switch coordinator.state {
        case .idle, .loading, .validating, .validated:
            SplashScreenView()
            
        case .active:
            if coordinator.targetURL != nil {
                NotesDisplayView()
            } else {
                ContentView()
            }
            
        case .inactive:
            ContentView()
            
        case .offline:
            ConnectionErrorView()
        }
    }
    
    private func observeEvents() {
        NotificationCenter.default
            .publisher(for: Notification.Name("ConversionDataReceived"))
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { data in
                coordinator.handleAttribution(data)
            }
            .store(in: &eventObservers)
        
        NotificationCenter.default
            .publisher(for: Notification.Name("deeplink_values"))
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { data in
                coordinator.handleDeeplink(data)
            }
            .store(in: &eventObservers)
    }
}



#Preview {
    SplashScreenView()
}
