import SwiftUI
import Combine

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var rippleScale: CGFloat = 0
    @State private var particlesOpacity: Double = 0
    @State private var particles: [FishParticle] = []
    
    var body: some View {
        GeometryReader { g in
            ZStack {
                AnimatedGradientBackground()
                
                Image(g.size.width > g.size.height ? "main_l" : "main")
                    .resizable()
                    .scaledToFill()
                    .frame(width: g.size.width, height: g.size.height)
                    .ignoresSafeArea()
                    .opacity(0.5)
                
                // Ripple effect
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .scaleEffect(rippleScale)
                    .opacity(1 - Double(rippleScale) / 3)
                
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    .scaleEffect(rippleScale * 0.7)
                    .opacity(1 - Double(rippleScale) / 2)
                
                // Fish particles
                ForEach(particles) { particle in
                    FishParticleView(particle: particle)
                        .opacity(particlesOpacity)
                }
                
                // Logo
                VStack(spacing: 16) {
                    Spacer()
                    
                    Text("Daily Notes Plus")
                        .font(.custom("PaytoneOne-Regular", size: 32))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("Loading...")
                        .font(.custom("PaytoneOne-Regular", size: 18))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.bottom, 24)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
            }
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                initializeParticles()
                startAnimations()
            }
        }
        .ignoresSafeArea()
    }
    
    private func initializeParticles() {
        for _ in 0..<8 {
            particles.append(FishParticle())
        }
    }
    
    private func startAnimations() {
        // Logo animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Ripple animation
        withAnimation(.easeOut(duration: 2.0)) {
            rippleScale = 3.0
        }
        
        // Particles fade in
        withAnimation(.easeIn(duration: 0.5).delay(0.3)) {
            particlesOpacity = 1.0
        }
    }
}

struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: [
                Color(hex: "1E88E5"),
                Color(hex: "0D47A1"),
                Color(hex: "01579B")
            ],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

struct FishParticle: Identifiable {
    let id = UUID()
    let startX: CGFloat = CGFloat.random(in: -50...UIScreen.main.bounds.width + 50)
    let startY: CGFloat = CGFloat.random(in: 0...UIScreen.main.bounds.height)
    let speed: Double = Double.random(in: 3...6)
    let size: CGFloat = CGFloat.random(in: 20...40)
    let opacity: Double = Double.random(in: 0.1...0.3)
}

struct FishParticleView: View {
    let particle: FishParticle
    @State private var offsetX: CGFloat = 0
    
    var body: some View {
        Image(systemName: "fish.fill")
            .font(.system(size: particle.size))
            .foregroundColor(.white.opacity(particle.opacity))
            .position(x: particle.startX + offsetX, y: particle.startY)
            .onAppear {
                withAnimation(.linear(duration: particle.speed).repeatForever(autoreverses: false)) {
                    offsetX = UIScreen.main.bounds.width + 100
                }
            }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct NotesApplicationView: View {
    
    @StateObject private var coordinator = ApplicationCoordinator()
    @State private var eventObservers: Set<AnyCancellable> = []
    
    var body: some View {
        ZStack {
            primaryContent
            
            if coordinator.requestingPermission {
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
        switch coordinator.presentationState {
        case .initializing:
            SplashScreenView()
            
        case .active:
            if coordinator.endpoint != nil {
                NotesDisplayView()
            } else {
                ContentView()
            }
            
        case .standby:
            ContentView()
            
        case .disconnected:
            ConnectionErrorView()
        }
    }
    
    private func observeEvents() {
        NotificationCenter.default
            .publisher(for: Notification.Name("ConversionDataReceived"))
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { data in
                coordinator.ingest(attribution: data)
            }
            .store(in: &eventObservers)
        
        NotificationCenter.default
            .publisher(for: Notification.Name("deeplink_values"))
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { data in
                coordinator.ingest(deeplink: data)
            }
            .store(in: &eventObservers)
    }
}



#Preview {
    SplashScreenView()
}
