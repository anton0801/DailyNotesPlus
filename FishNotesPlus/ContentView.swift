import SwiftUI

struct ContentView: View {
    
    @State private var showSplash = true
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    
    var body: some View {
        if showSplash {
            SplashView()
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showSplash = false
                        }
                    }
                }
        }  else {
            MainTabView()
        }
//        else if showOnboarding {
//                    
//        //            OnboardingView {
//        //                showOnboarding = false
//        //                UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
//        //            }
//                }
    }
    
}

#Preview {
    ContentView()
}
