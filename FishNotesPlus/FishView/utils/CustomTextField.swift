import SwiftUI

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "2C3E50"))
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                )
        }
        .padding(.horizontal, 20)
    }
}

// CustomTextEditor.swift
struct CustomTextEditor: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "2C3E50"))
            
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "7F8C8D").opacity(0.5))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                }
                
                TextEditor(text: $text)
                    .font(.system(size: 16))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(minHeight: 150)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
        .padding(.horizontal, 20)
    }
}

// SeasonButton.swift
//struct SeasonButton: View {
//    let season: FishingNote.Season
//    let isSelected: Bool
//    let action: () -> Void
//    
//    var body: some View {
//        Button(action: action) {
//            VStack(spacing: 6) {
//                Image(systemName: season.icon)
//                    .font(.system(size: 20))
//                    .foregroundColor(isSelected ? .white : season.color)
//                
//                Text(season.rawValue)
//                    .font(.system(size: 12, weight: .medium))
//                    .foregroundColor(isSelected ? .white : Color(hex: "2C3E50"))
//            }
//            .frame(maxWidth: .infinity)
//            .padding(.vertical, 12)
//            .background(
//                RoundedRectangle(cornerRadius: 12)
//                    .fill(isSelected ? season.color : Color.white)
//                    .shadow(color: isSelected ? season.color.opacity(0.3) : Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
//            )
//        }
//        .buttonStyle(ScaleButtonStyle())
//    }
//}

// TagPillView.swift
struct TagPillView: View {
    let tag: String
    var removable: Bool = false
    var compact: Bool = false
    var onRemove: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "tag.fill")
                .font(.system(size: compact ? 10 : 12))
            
            Text(tag)
                .font(.system(size: compact ? 11 : 13, weight: .medium))
            
            if removable, let onRemove = onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                }
            }
        }
        .foregroundColor(Color(hex: "26A69A"))
        .padding(.horizontal, compact ? 8 : 12)
        .padding(.vertical, compact ? 4 : 6)
        .background(Color(hex: "26A69A").opacity(0.15))
        .cornerRadius(compact ? 10 : 12)
    }
}

// SearchBar.swift
struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(hex: "7F8C8D"))
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(hex: "7F8C8D"))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

// FlowLayout.swift
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// ScaleButtonStyle.swift
//struct ScaleButtonStyle: ButtonStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        configuration.label
//            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
//            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
//    }
//}

// ShareSheet.swift
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
