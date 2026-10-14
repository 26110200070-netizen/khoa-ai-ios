//
//  ChatBubbleView.swift
//  KhoaAI
//
//  Created by Khoa Dev.
//  Message renderer: User has a frosted glass bubble; AI text flows seamlessly without any bounding box frame.
//

import SwiftUI

public struct ChatBubbleView: View {
    public let message: ChatMessage
    @State private var isThinkingExpanded: Bool = false
    @State private var copied: Bool = false

    public init(message: ChatMessage) {
        self.message = message
    }

    public var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
            if message.isUser {
                // User Message: Premium Frosted Glass Bubble
                HStack {
                    Spacer(minLength: 48)

                    Text(message.text)
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(Color.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color(.systemGray6).opacity(0.85))
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: [Color.white.opacity(0.8), Color.white.opacity(0.2)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.0
                                        )
                                }
                                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                        }
                }
            } else {
                // AI Message: NO BOUNDING BOX FRAME - Flows seamlessly across the full canvas!
                VStack(alignment: .leading, spacing: 10) {
                    // DeepThink Reasoning Block (if enabled or present)
                    if !message.thinkingText.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    isThinkingExpanded.toggle()
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color.blue)

                                    Text(message.isThinking ? "Đang suy nghĩ..." : "Đã suy nghĩ xong")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundStyle(Color.secondary)

                                    Image(systemName: isThinkingExpanded ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Color.secondary.opacity(0.7))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background {
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.6), lineWidth: 0.8))
                                }
                            }

                            if isThinkingExpanded {
                                Text(message.thinkingText)
                                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                                    .foregroundStyle(Color.secondary.opacity(0.85))
                                    .padding(.leading, 10)
                                    .padding(.vertical, 4)
                                    .overlay(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color.blue.opacity(0.35))
                                            .frame(width: 2)
                                    }
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }

                    // Main AI Content: Direct text without background container, never overflows screen
                    HStack(alignment: .top, spacing: 0) {
                        Text(LocalizedStringKey(message.text))
                            .font(.system(size: 16.5, weight: .regular, design: .default))
                            .lineSpacing(5)
                            .foregroundStyle(Color.primary)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if message.isStreaming && !message.isThinking {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 7, height: 7)
                                .padding(.top, 7)
                                .padding(.leading, 4)
                                .opacity(0.85)
                        }
                    }

                    // Bottom Action Toolbar (Copy, Share) for AI message
                    if !message.text.isEmpty && !message.isStreaming {
                        HStack(spacing: 14) {
                            Button {
                                UIPasteboard.general.string = message.text
                                let haptic = UIImpactFeedbackGenerator(style: .light)
                                haptic.impactOccurred()
                                withAnimation { copied = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                                    withAnimation { copied = false }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                        .font(.system(size: 12))
                                    if copied {
                                        Text("Đã chép")
                                            .font(.system(size: 11, weight: .medium))
                                    }
                                }
                                .foregroundStyle(copied ? Color.green : Color.secondary.opacity(0.7))
                            }

                            ShareLink(item: message.text) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.secondary.opacity(0.7))
                            }

                            Spacer()
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}
