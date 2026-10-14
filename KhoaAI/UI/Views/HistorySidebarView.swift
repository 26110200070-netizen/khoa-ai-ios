//
//  HistorySidebarView.swift
//  KhoaAI
//
//  Created by Khoa Dev.
//  Chat history sidebar drawer matching user Image 1 with safe-area spacing, search, session cards, and profile bar.
//

import SwiftUI

public struct HistorySidebarView: View {
    @ObservedObject private var conversationManager = ConversationManager.shared
    @ObservedObject private var authManager = DeepSeekAuthManager.shared
    @ObservedObject private var service = DeepSeekService.shared

    @Binding var isOpen: Bool
    var onSelectSession: (ConversationSession) -> Void
    var onNewChat: () -> Void
    var onOpenSettings: () -> Void

    @State private var searchText: String = ""

    public init(
        isOpen: Binding<Bool>,
        onSelectSession: @escaping (ConversationSession) -> Void,
        onNewChat: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void
    ) {
        self._isOpen = isOpen
        self.onSelectSession = onSelectSession
        self.onNewChat = onNewChat
        self.onOpenSettings = onOpenSettings
    }

    private var filteredSessions: [ConversationSession] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return conversationManager.sessions
        }
        return conversationManager.sessions.filter { $0.title.localizedCaseInsensitiveContains(trimmed) }
    }

    public var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                // Top Safe Area Spacer to prevent Dynamic Island overlap (Fixing Image 1 bug!)
                Color.clear
                    .frame(height: max(proxy.safeAreaInsets.top, 48))

                // Top Search Box & New Chat Button
                VStack(spacing: 12) {
                    // Search Bar (Matching Image 1)
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color.secondary.opacity(0.8))
                            .font(.system(size: 14))

                        TextField("Tìm kiếm nội dung trò chuyện...", text: $searchText)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Color.black)

                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color.secondary.opacity(0.6))
                                    .font(.system(size: 14))
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
                    )

                    // Blue New Chat Button (Matching Image 1)
                    Button {
                        let haptic = UIImpactFeedbackGenerator(style: .medium)
                        haptic.impactOccurred()
                        onNewChat()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            isOpen = false
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Cuộc trò chuyện mới")
                                .font(.system(size: 15, weight: .semibold))
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(red: 0.12, green: 0.45, blue: 0.95))
                        .foregroundStyle(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Color.blue.opacity(0.2), radius: 6, x: 0, y: 3)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                Divider()
                    .padding(.horizontal, 16)

                // Middle Section: Chat Sessions List (Matching Image 1)
                if filteredSessions.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 38))
                            .foregroundStyle(Color.secondary.opacity(0.3))

                        Text("Chưa có cuộc trò chuyện nào")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.secondary)

                        Text("Bấm vào 'Cuộc trò chuyện mới' ở trên để bắt đầu nhắn tin với khoa.ai.")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.secondary.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredSessions) { session in
                                HStack {
                                    Button {
                                        let haptic = UIImpactFeedbackGenerator(style: .light)
                                        haptic.impactOccurred()
                                        onSelectSession(session)
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                            isOpen = false
                                        }
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(session.title.isEmpty ? "Cuộc trò chuyện" : session.title)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundStyle(Color.black.opacity(0.9))
                                                .lineLimit(1)

                                            Text(session.updatedAt, style: .date)
                                                .font(.system(size: 12))
                                                .foregroundStyle(Color.secondary)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }

                                    Button {
                                        let haptic = UIImpactFeedbackGenerator(style: .medium)
                                        haptic.impactOccurred()
                                        conversationManager.deleteSession(session)
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.system(size: 13))
                                            .foregroundStyle(Color.secondary.opacity(0.65))
                                    }
                                    .padding(.leading, 8)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(red: 0.93, green: 0.96, blue: 1.0))
                                )
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 12)
                    }
                }

                Divider()

                // Bottom Profile Bar (Matching Image 1)
                HStack(spacing: 12) {
                    KhoaAILogoView(size: 34, showGlow: false)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(authManager.userEmail.isEmpty ? "nob******82@gmail.com" : authManager.userEmail)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.black)
                            .lineLimit(1)

                        Text("Tạo bởi Khoa Dev")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.secondary)
                    }

                    Spacer()

                    Button {
                        onOpenSettings()
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.black.opacity(0.7))
                            .frame(width: 34, height: 34)
                            .background(Color.white)
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(Color.black.opacity(0.08), lineWidth: 1))
                            .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(red: 0.97, green: 0.98, blue: 0.99))
                .padding(.bottom, max(proxy.safeAreaInsets.bottom, 12))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.98, green: 0.98, blue: 0.99))
        .ignoresSafeArea(.all, edges: .vertical)
    }
}
