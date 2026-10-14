//
//  KhoaAILogoView.swift
//  KhoaAI
//
//  Created by Khoa Dev.
//  Desert & AI Logo for khoa.ai combining golden desert dunes and neural cybernetic whale fin.
//

import SwiftUI

public struct KhoaAILogoView: View {
    public var size: CGFloat
    public var showGlow: Bool

    @State private var pulse: Bool = false

    public init(size: CGFloat = 80, showGlow: Bool = true) {
        self.size = size
        self.showGlow = showGlow
    }

    public var body: some View {
        ZStack {
            // Ambient Desert Horizon Glow
            if showGlow {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.98, green: 0.65, blue: 0.15).opacity(pulse ? 0.35 : 0.18),
                                Color(red: 0.05, green: 0.75, blue: 0.95).opacity(pulse ? 0.20 : 0.08),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: size * 0.2,
                            endRadius: size * 0.75
                        )
                    )
                    .frame(width: size * 1.5, height: size * 1.5)
                    .blur(radius: 12)
            }

            // Outer Liquid Glass Ring
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.72, blue: 0.25).opacity(0.8),
                            Color(red: 0.05, green: 0.85, blue: 0.95).opacity(0.5),
                            Color.white.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: size, height: size)
                .shadow(color: Color(red: 0.98, green: 0.65, blue: 0.15).opacity(0.3), radius: 8, x: 0, y: 4)

            // Inner Desert Disk with Dunes & AI Whale Fin
            ZStack {
                // Background Desert Sunset Gradient
                Circle()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color(red: 0.98, green: 0.62, blue: 0.15), location: 0.0), // Amber sun
                                .init(color: Color(red: 0.88, green: 0.40, blue: 0.12), location: 0.55), // Warm sand
                                .init(color: Color(red: 0.18, green: 0.12, blue: 0.32), location: 1.0)  // Twilight dune base
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size - 4, height: size - 4)

                // Back Dune
                DesertDuneShape(offsetFactor: 0.25, amplitude: 8)
                    .fill(Color(red: 0.82, green: 0.33, blue: 0.10).opacity(0.85))
                    .frame(width: size - 4, height: size - 4)
                    .clipShape(Circle())

                // Fore Dune
                DesertDuneShape(offsetFactor: 0.6, amplitude: 12)
                    .fill(Color(red: 0.96, green: 0.55, blue: 0.12))
                    .frame(width: size - 4, height: size - 4)
                    .clipShape(Circle())

                // Soaring Cyber AI Whale Fin / Neural Crest
                WhaleFinNeuralShape()
                    .fill(
                        LinearGradient(
                            colors: [Color.white, Color(red: 0.85, green: 0.95, blue: 1.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size * 0.52, height: size * 0.48)
                    .offset(y: -size * 0.04)
                    .shadow(color: Color.black.opacity(0.18), radius: 4, x: 0, y: 3)

                // Glowing Cyan Neural Circuits inside Whale Fin
                WhaleNeuralLines()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.05, green: 0.90, blue: 0.98),
                                Color(red: 0.20, green: 0.60, blue: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        style: StrokeStyle(lineWidth: 1.6, lineCap: .round)
                    )
                    .frame(width: size * 0.52, height: size * 0.48)
                    .offset(y: -size * 0.04)

                // Specular Light Glint on Glass
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.85), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .center
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: size - 4, height: size - 4)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// Dune Shape
struct DesertDuneShape: Shape {
    var offsetFactor: CGFloat
    var amplitude: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let startY = rect.height * (0.55 + offsetFactor * 0.25)
        path.move(to: CGPoint(x: 0, y: startY))

        path.addCurve(
            to: CGPoint(x: rect.width * 0.55, y: startY - amplitude),
            control1: CGPoint(x: rect.width * 0.25, y: startY + amplitude * 0.8),
            control2: CGPoint(x: rect.width * 0.45, y: startY - amplitude * 1.2)
        )

        path.addCurve(
            to: CGPoint(x: rect.width, y: startY + amplitude * 0.5),
            control1: CGPoint(x: rect.width * 0.75, y: startY - amplitude * 0.6),
            control2: CGPoint(x: rect.width * 0.88, y: startY + amplitude * 0.4)
        )

        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

// Whale Fin / Soaring AI Form
struct WhaleFinNeuralShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Tail apex
        path.move(to: CGPoint(x: w * 0.5, y: 0))

        // Right wing flare
        path.addQuadCurve(
            to: CGPoint(x: w, y: h * 0.38),
            control: CGPoint(x: w * 0.72, y: h * 0.05)
        )
        // Right wing bottom
        path.addQuadCurve(
            to: CGPoint(x: w * 0.62, y: h * 0.58),
            control: CGPoint(x: w * 0.82, y: h * 0.52)
        )
        // Right flank to peduncle
        path.addQuadCurve(
            to: CGPoint(x: w * 0.56, y: h),
            control: CGPoint(x: w * 0.58, y: h * 0.80)
        )
        // Notch
        path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.84))
        // Left peduncle
        path.addLine(to: CGPoint(x: w * 0.44, y: h))

        // Left flank
        path.addQuadCurve(
            to: CGPoint(x: w * 0.38, y: h * 0.58),
            control: CGPoint(x: w * 0.42, y: h * 0.80)
        )
        // Left wing bottom
        path.addQuadCurve(
            to: CGPoint(x: 0, y: h * 0.38),
            control: CGPoint(x: w * 0.18, y: h * 0.52)
        )
        // Left wing flare back to apex
        path.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: 0),
            control: CGPoint(x: w * 0.28, y: h * 0.05)
        )

        path.closeSubpath()
        return path
    }
}

// Neural lines connecting nodes
struct WhaleNeuralLines: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Central neural spine
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.08))
        path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.78))

        // Right branch
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.28))
        path.addLine(to: CGPoint(x: w * 0.88, y: h * 0.38))

        // Left branch
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.28))
        path.addLine(to: CGPoint(x: w * 0.12, y: h * 0.38))

        // Lower branches
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.52))
        path.addLine(to: CGPoint(x: w * 0.62, y: h * 0.60))

        path.move(to: CGPoint(x: w * 0.5, y: h * 0.52))
        path.addLine(to: CGPoint(x: w * 0.38, y: h * 0.60))

        return path
    }
}
