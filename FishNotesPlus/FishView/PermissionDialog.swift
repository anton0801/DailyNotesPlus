import SwiftUI

struct PermissionDialog: View {
    
    @EnvironmentObject var coordinator: AppViewModel
    @State private var pulsing = false
    
    var body: some View {
        GeometryReader { g in
            ZStack {
                Image(g.size.width > g.size.height ? "alter_l" : "alter")
                    .resizable()
                    .scaledToFill()
                    .frame(width: g.size.width, height: g.size.height)
                    .ignoresSafeArea()
                
                if g.size.width > g.size.height {
                    horizontalContent
                } else {
                    verticalContent
                }
            }
        }
        .ignoresSafeArea()
    }
    
    private var visualElement: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.purple.opacity(0.2), Color.purple.opacity(0.05)],
                        center: .center,
                        startRadius: 20,
                        endRadius: 70
                    )
                )
                .frame(width: 140, height: 140)
                .scaleEffect(pulsing ? 1.2 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: pulsing
                )
            
            Image(systemName: "app.badge")
                .font(.system(size: 64))
                .foregroundColor(.purple)
        }
        .onAppear { pulsing = true }
    }
    
    private var verticalContent: some View {
        VStack(spacing: 12) {
            Spacer()
            
            Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
                .font(.custom("PaytoneOne-Regular", size: 20))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .multilineTextAlignment(.center)
            
            Text("STAY TUNED WITH BEST OFFERS FROM\nOUR CASINO")
                .font(.custom("PaytoneOne-Regular", size: 16))
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 12)
                .multilineTextAlignment(.center)
            
            actionButtons
        }
        .padding(.bottom, 24)
    }
    
    private var horizontalContent: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                VStack(alignment: .leading, spacing: 12) {
                    Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
                        .font(.custom("PaytoneOne-Regular", size: 20))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .multilineTextAlignment(.leading)
                    
                    Text("STAY TUNED WITH BEST OFFERS FROM OUR CASINO")
                        .font(.custom("PaytoneOne-Regular", size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 12)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                actionButtons
                Spacer()
            }
        }
        .padding(.bottom, 24)
    }
    
    private var messageContent: some View {
        VStack(spacing: 18) {
            Text("Stay Informed")
                .font(.largeTitle.bold())
            
            Text("Get instant updates about your daily notes and important reminders")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 52)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 20) {
            Button {
                coordinator.grantPermission()
            } label: {
                Image("alter_btn")
                    .resizable()
                    .frame(width: 320, height: 60)
            }
            
            Button {
                coordinator.denyPermission()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.white.opacity(0.17))
                    
                    Text("SKIP")
                        .font(.custom("PaytoneOne-Regular", size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(width: 300, height: 35)
        }
        .padding(.horizontal, 48)
    }
}
