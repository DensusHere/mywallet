// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import SwiftUI

struct ButtonProgressViewStyle: ProgressViewStyle {

    @State private var angle: Angle = .degrees(-90)

    let railColor: Color
    let trackColor: Color

    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            let lineWidth: CGFloat = geometry.size.width / 6.0
            ZStack {
                let style = StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .butt
                )
                Circle()
                    .stroke(trackColor, style: style)
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(railColor, style: style)
                    .rotationEffect(angle)
                    .onAppear {
                        // Dispatch in order to fix a bug where being a child of `NavigationView`
                        // causes the animation to affect things other than the angle.
                        DispatchQueue.main.async {
                            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                                angle = .degrees(angle.degrees + 360)
                            }
                        }
                    }
            }
            .padding(lineWidth / 2)
        }
        .scaledToFit()
    }
}

struct ButtonProgressView_Previews: PreviewProvider {

    static var previews: some View {
        ProgressView()
            .progressViewStyle(
                ButtonProgressViewStyle(
                    railColor: Color.semantic.primary,
                    trackColor: Color.semantic.light
                )
            )
            .frame(width: 70, height: 70)
    }
}
