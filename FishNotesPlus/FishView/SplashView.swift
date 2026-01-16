import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 20) {
                ZStack {
                    Image(systemName: "book.fill")
                        .font(.system(size: 120))
                        .foregroundColor(accentBlue)
                    
                    Image(systemName: "fish.fill")
                        .font(.system(size: 60))
                        .foregroundColor(accentGreen)
                        .offset(x: 40, y: -20)
                }
                
                Text("Fish Notes Plus")
                    .font(.system(.largeTitle, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        }
    }
}

#Preview {
    SplashView()
}
