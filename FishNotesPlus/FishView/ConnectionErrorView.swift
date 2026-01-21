import SwiftUI

struct ConnectionErrorView: View {
    var body: some View {
        GeometryReader { g in
            
            ZStack {
                Image(g.size.width > g.size.height ? "second_l" : "second")
                    .resizable()
                    .scaledToFill()
                    .frame(width: g.size.width, height: g.size.height)
                    .ignoresSafeArea()
                
                if g.size.width > g.size.height {
                    Image("second_alert")
                        .resizable()
                        .frame(width: 250, height: 200)
                } else {
                    Image("second_alert")
                        .resizable()
                        .frame(width: 250, height: 200)
                }
            }
        }
        .ignoresSafeArea()
    }
}
