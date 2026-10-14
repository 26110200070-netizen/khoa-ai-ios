//
//  HistorySidebarView.swift
//  KhoaAI
//
//  Created by Khoa Dev.
//  Chat history sidebar drawer matching reference video with search, session switching, and new chat actions.
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
        VStack(spacing: 0) {
            // Top Section: Search Bar & New Chat Button
            VStack(spacing: 12) {
                // Search Input
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.secondary)
                        .font(.system(size: 14))

                    TextField("Tìm kiếm nội dung trò chuyện...", text: $searchText)
                        .font(.system(size: 14))

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.secondary)
                                .font(.system(size: 14))
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.black.opacity(0.06), lineWidth: 1))

                // New Chat Button
                Button {
                    let haptic = UIImpactFeedbackGenerator(style: .medium)
                    haptic.impactOccurred()
                    onNewChat()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        isOpen = false
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Cuộc trò chuyện mới")
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(red: 0.12, green: 0.45, blue: 0.95))
                    .foregroundStyle(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.blue.opacity(0.2), radius: 6, x: 0, y: 3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()

            // Middle: Conversations List or Empty State (Matching Video Frame 1)
            if filteredSessions.isEmpty {
                Spacer()
                VStack(spacing: 14) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.secondary.opacity(0.45))

                    Text("Chưa có cuộc trò chuyện nào")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.primary)

                    Text("Các cuộc trò chuyện của bạn với khoa.ai sẽ hiển thị tại đây.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
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
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(session.title)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(Color.primary)
                                            .lineLimit(1)

                                        Text(session.updatedAt, style: .date)
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color.secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }

                                Button {
                                    conversationManager.deleteSession(session)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.secondary.opacity(0.6))
                                }
                                .padding(.leading, 6)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(conversationManager.activeSessionId == session.id ? Color.blue.opacity(0.08) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 8)
                }
            }

            Divider()

            // Bottom Section: Account info & Settings
            HStack(spacing: 12) {
                KhoaAILogoView(size: 34, showGlow: false)

                VStack(alignment: .leading, spacing: 2) {
                    Text(authManager.userEmail.isEmpty ? "khoa.ai DeepSeek" : authManager.userEmail)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)

                    Text("Tạo bởi Khoa Dev")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)
                }

                Spacer()

                Button {
                    onOpenSettings()
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.primary.opacity(0.75))
                        .frame(width: 34, height: 34)
                        .background(Color(.systemBackground))
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(Color.black.opacity(0.08), lineWidth: 1))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6).opacity(0.8))
        }
        .frame(maxWidth: 300)
        .background(Color(red: 0.96, green: 0.97, blue: 0.98))
        .ignoresSafeArea(.all, edges: .vertical)
    }
}
