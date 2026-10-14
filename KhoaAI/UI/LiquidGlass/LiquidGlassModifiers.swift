//
//  LiquidGlassModifiers.swift
//  KhoaAI
//
//  Created by Khoa Dev.
//  Liquid Glass Design System with adaptive depth, specular gloss, and tactile micro-interactions.
//

import SwiftUI

public struct LiquidGlassStyle: ViewModifier {
    public var cornerRadius: CGFloat
    public var tint: Color
    public var opacity: Double
    public var blurRadius: CGFloat
    public var hasRimGlow: Bool

    public init(
        cornerRadius: CGFloat = 20,
        tint: Color = .white,
        opacity: Double = 0.65,
        blurRadius: CGFloat = 20,
        hasRimGlow: Bool = true
    ) {
        self.cornerRadius = cornerRadius
        self.tint = tint
        self.opacity = opacity
        self.blurRadius = blurRadius
        self.hasRimGlow = hasRimGlow
    }

    public func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    // Base Ultra Thin Material for dynamic backdrop blur
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(0.95)

                    // Glass tint overlay
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(tint.opacity(opacity * 0.12))

                    // Specular gloss reflection
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.35),
                                    Color.white.opacity(0.08),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Subtle refractive rim glow
                    if hasRimGlow {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color.white.opacity(0.75), location: 0.0),
                                        .init(color: Color.white.opacity(0.30), location: 0.4),
                                        .init(color: Color.white.opacity(0.05), location: 0.7),
                                        .init(color: Color.white.opacity(0.40), location: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.0
                            )
                    }
                }
                .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
                .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
            }
    }
}

public struct LiquidGlassButtonModifier: ViewModifier {
    public var diameter: CGFloat
    public var tint: Color
    public var active: Bool

    @State private var isPressed: Bool = false

    public init(diameter: CGFloat = 46, tint: Color = .primary, active: Bool = false) {
        self.diameter = diameter
        self.tint = tint
        self.active = active
    }

    public func body(content: Content) -> some View {
        content
            .font(.system(size: diameter * 0.42, weight: .semibold, design: .rounded))
            .foregroundStyle(active ? Color.white : tint)
            .frame(width: diameter, height: diameter)
            .background {
                ZStack {
                    if active {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.blue.opacity(0.45), radius: 8, x: 0, y: 4)
                    } else {
                        Circle()
                            .fill(.ultraThinMaterial)

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.45),
                                        Color.white.opacity(0.10)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.8), Color.white.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.0
                            )
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                    }
                }
            }
            .contentShape(Circle())
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

public struct LiquidGlassPillModifier: ViewModifier {
    public var active: Bool
    public var accentColor: Color

    public init(active: Bool = false, accentColor: Color = Color.blue) {
        self.active = active
        self.accentColor = accentColor
    }

    public func body(content: Content) -> some View {
        content
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(active ? accentColor : Color.primary.opacity(0.85))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background {
                Capsule()
                    .fill(active ? accentColor.opacity(0.12) : Color(.systemGray6).opacity(0.55))
                    .background(active ? AnyShapeStyle(accentColor.opacity(0.06)) : AnyShapeStyle(.ultraThinMaterial))
                    .clipShape(Capsule())
                    .overlay {
                        Capsule()
                            .strokeBorder(
                                active ? accentColor.opacity(0.4) : Color.white.opacity(0.6),
                                lineWidth: active ? 1.2 : 0.8
                            )
                    }
                    .shadow(color: active ? accentColor.opacity(0.2) : Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
            }
    }
}

public extension View {
    func liquidGlass(
        cornerRadius: CGFloat = 24,
        tint: Color = .white,
        opacity: Double = 0.65
    ) -> some View {
        modifier(LiquidGlassStyle(cornerRadius: cornerRadius, tint: tint, opacity: opacity))
    }

    func glassCircleButton(diameter: CGFloat = 46, tint: Color = .primary, active: Bool = false) -> some View {
        modifier(LiquidGlassButtonModifier(diameter: diameter, tint: tint, active: active))
    }

    func glassPill(active: Bool = false, accentColor: Color = Color.blue) -> some View {
        modifier(LiquidGlassPillModifier(active: active, accentColor: accentColor))
    }

    // Compatibility shim matching LiquidGlassSwiftUI repo
    func glassEffect(_ style: Color = .clear) -> some View {
        modifier(LiquidGlassStyle(cornerRadius: 24, tint: style))
    }

    func glassEffectID(_ id: String, in namespace: Namespace.ID) -> some View {
        self.matchedGeometryEffect(id: id, in: namespace)
    }
}

public struct GlassEffectContainer<Content: View>: View {
    public var spacing: CGFloat
    @ViewBuilder public var content: () -> Content

    public init(spacing: CGFloat = 16, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    public var body: some View {
        VStack(spacing: spacing) {
            content()
        }
    }
}
