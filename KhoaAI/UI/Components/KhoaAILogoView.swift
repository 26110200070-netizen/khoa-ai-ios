//
//  KhoaAILogoView.swift
//  KhoaAI
//
//  Created by Khoa Dev.
//  Neural Network & Synapse Logo (Dây thần kinh & Khớp thần kinh AI) for khoa.ai.
//

import SwiftUI

public struct KhoaAILogoView: View {
    public var size: CGFloat
    public var showGlow: Bool

    @State private var pulse: CGFloat = 1.0
    @State private var impulsePhase: CGFloat = 0.0

    public init(size: CGFloat = 88, showGlow: Bool = true) {
        self.size = size
        self.showGlow = showGlow
    }

    // Normalized node coordinates around center (0,0)
    private let nodes: [CGPoint] = [
        CGPoint(x: 0, y: -0.38),
        CGPoint(x: -0.28, y: -0.22),
        CGPoint(x: 0.28, y: -0.22),
        CGPoint(x: -0.42, y: 0.05),
        CGPoint(x: 0, y: 0), // Central node
        CGPoint(x: 0.42, y: 0.05),
        CGPoint(x: -0.26, y: 0.32),
        CGPoint(x: 0.26, y: 0.32),
        CGPoint(x: 0, y: 0.42),
        CGPoint(x: -0.15, y: -0.10),
        CGPoint(x: 0.15, y: -0.10),
        CGPoint(x: -0.15, y: 0.18),
        CGPoint(x: 0.15, y: 0.18)
    ]

    private let edges: [(Int, Int)] = [
        (0, 1), (0, 2), (0, 9), (0, 10),
        (1, 3), (1, 9), (2, 5), (2, 10),
        (3, 6), (3, 11), (5, 7), (5, 12),
        (4, 9), (4, 10), (4, 11), (4, 12),
        (6, 8), (6, 11), (7, 8), (7, 12),
        (8, 4)
    ]

    public var body: some View {
        ZStack {
            // Ambient Neural Synaptic Aura Glow
            if showGlow {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.05, green: 0.70, blue: 0.98).opacity(0.25 * pulse),
                                Color(red: 0.25, green: 0.45, blue: 0.95).opacity(0.12),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: size * 0.1,
                            endRadius: size * 0.85
                        )
                    )
                    .frame(width: size * 1.6, height: size * 1.6)
                    .blur(radius: 14)
            }

            // Outer Liquid Glass Circular Capsule
            Circle()
                .fill(Color.white.opacity(0.92))
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .frame(width: size, height: size)
                .overlay {
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white, location: 0.0),
                                    .init(color: Color(red: 0.05, green: 0.75, blue: 0.98).opacity(0.4), location: 0.5),
                                    .init(color: Color.black.opacity(0.08), location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                }
                .shadow(color: Color(red: 0.05, green: 0.60, blue: 0.95).opacity(0.18), radius: 10, x: 0, y: 5)
                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)

            // Neural Fibers & Axon Lines
            Canvas { context, canvasSize in
                let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                let scale = size

                for (fromIdx, toIdx) in edges {
                    let p1 = CGPoint(
                        x: center.x + nodes[fromIdx].x * scale,
                        y: center.y + nodes[fromIdx].y * scale
                    )
                    let p2 = CGPoint(
                        x: center.x + nodes[toIdx].x * scale,
                        y: center.y + nodes[toIdx].y * scale
                    )

                    var path = Path()
                    path.move(to: p1)
                    path.addLine(to: p2)

                    // Neural fiber base
                    context.stroke(
                        path,
                        with: .color(Color(red: 0.05, green: 0.65, blue: 0.95).opacity(0.35)),
                        lineWidth: 1.6
                    )

                    // Electric nerve impulse moving along the fiber
                    let progress = (impulsePhase + CGFloat(fromIdx + toIdx) * 0.1).truncatingRemainder(dividingBy: 1.0)
                    let sparkX = p1.x + (p2.x - p1.x) * progress
                    let sparkY = p1.y + (p2.y - p1.y) * progress
                    let sparkRect = CGRect(x: sparkX - 2.5, y: sparkY - 2.5, width: 5, height: 5)
                    context.fill(Path(ellipseIn: sparkRect), with: .color(Color(red: 0.20, green: 0.95, blue: 1.0).opacity(0.85)))
                }

                // Synaptic Nodes (Khớp thần kinh)
                for (idx, node) in nodes.enumerated() {
                    let pt = CGPoint(
                        x: center.x + node.x * scale,
                        y: center.y + node.y * scale
                    )

                    let isCentral = (idx == 4)
                    let r: CGFloat = isCentral ? 5.5 : 3.8

                    // Outer halo
                    let haloRect = CGRect(x: pt.x - r * 1.8, y: pt.y - r * 1.8, width: r * 3.6, height: r * 3.6)
                    context.fill(Path(ellipseIn: haloRect), with: .color(Color(red: 0.10, green: 0.65, blue: 0.98).opacity(0.25)))

                    // Node body
                    let bodyRect = CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)
                    context.fill(
                        Path(ellipseIn: bodyRect),
                        with: .color(isCentral ? Color(red: 0.12, green: 0.50, blue: 0.98) : Color(red: 0.05, green: 0.75, blue: 0.95))
                    )

                    // White center point
                    let innerRect = CGRect(x: pt.x - r * 0.45, y: pt.y - r * 0.45, width: r * 0.9, height: r * 0.9)
                    context.fill(Path(ellipseIn: innerRect), with: .color(.white))
                }
            }
            .frame(width: size, height: size)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulse = 1.25
            }
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                impulsePhase = 1.0
            }
        }
    }
}
