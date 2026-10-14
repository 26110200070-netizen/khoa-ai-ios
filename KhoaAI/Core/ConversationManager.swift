//
//  ConversationManager.swift
//  KhoaAI
//
//  Created by Khoa Dev.
//  Manages persistent conversation history, sessions, and date grouping.
//

import Foundation
import Combine

public struct ConversationSession: Identifiable, Codable, Equatable {
    public let id: String
    public var title: String
    public var updatedAt: Date
    public var messages: [SavedMessage]
    public var model: String

    public init(
        id: String = UUID().uuidString,
        title: String,
        updatedAt: Date = Date(),
        messages: [SavedMessage] = [],
        model: String = "expert"
    ) {
        self.id = id
        self.title = title
        self.updatedAt = updatedAt
        self.messages = messages
        self.model = model
    }
}

public struct SavedMessage: Identifiable, Codable, Equatable {
    public let id: String
    public let isUser: Bool
    public let text: String
    public let thinkingText: String
    public let date: Date
}

@MainActor
public class ConversationManager: ObservableObject {
    public static let shared = ConversationManager()

    private let storageKey = "khoa_ai_saved_sessions_v1"

    @Published public var sessions: [ConversationSession] = []
    @Published public var activeSessionId: String?

    public init() {
        loadSessions()
    }

    public func loadSessions() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([ConversationSession].self, from: data) else {
            self.sessions = []
            return
        }
        self.sessions = decoded.sorted { $0.updatedAt > $1.updatedAt }
    }

    public func saveCurrentChat(messages: [ChatMessage], model: String) {
        guard !messages.isEmpty else { return }

        // Determine title from first user message
        let firstUser = messages.first(where: { $0.isUser })?.text ?? "Đoạn chat mới"
        let title = String(firstUser.prefix(40))

        let savedMsgs = messages.map {
            SavedMessage(id: $0.id, isUser: $0.isUser, text: $0.text, thinkingText: $0.thinkingText, date: $0.date)
        }

        let sid = activeSessionId ?? UUID().uuidString
        self.activeSessionId = sid

        if let index = sessions.firstIndex(where: { $0.id == sid }) {
            sessions[index].title = title
            sessions[index].updatedAt = Date()
            sessions[index].messages = savedMsgs
            sessions[index].model = model
        } else {
            let newSession = ConversationSession(id: sid, title: title, updatedAt: Date(), messages: savedMsgs, model: model)
            sessions.insert(newSession, at: 0)
        }

        persist()
    }

    public func deleteSession(_ session: ConversationSession) {
        sessions.removeAll { $0.id == session.id }
        if activeSessionId == session.id {
            activeSessionId = nil
        }
        persist()
    }

    public func clearAll() {
        sessions.removeAll()
        activeSessionId = nil
        persist()
    }

    private func persist() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
}
