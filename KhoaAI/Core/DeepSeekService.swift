//
//  DeepSeekService.swift
//  KhoaAI
//
//  Created by Khoa Dev.
//  Core DeepSeek reverse-engineered API integration service for khoa.ai.
//  Supports DeepSeek-R1 (Expert) and DeepSeek-V3 with SSE streaming, PoW challenge solver,
//  multi-turn session resumption, robust SSE chunk ingestion preventing any dropped characters,
//  and system knowledge learned from dulieukhoaai.md while strictly preserving khoa.ai identity.
//

import Foundation
import UIKit
import Combine

public struct ChatMessage: Identifiable, Codable, Equatable {
    public let id: String
    public var text: String
    public var thinkingText: String
    public let isUser: Bool
    public var isThinking: Bool
    public var isStreaming: Bool
    public var date: Date
    public var timestamp: Date { date }
    public var imageData: Data?

    public init(
        id: String = UUID().uuidString,
        text: String,
        thinkingText: String = "",
        isUser: Bool,
        isThinking: Bool = false,
        isStreaming: Bool = false,
        date: Date = Date(),
        image: UIImage? = nil
    ) {
        self.id = id
        self.text = text
        self.thinkingText = thinkingText
        self.isUser = isUser
        self.isThinking = isThinking
        self.isStreaming = isStreaming
        self.date = date
        self.imageData = image?.jpegData(compressionQuality: 0.8)
    }

    public var image: UIImage? {
        guard let data = imageData else { return nil }
        return UIImage(data: data)
    }
}

@MainActor
public final class DeepSeekService: ObservableObject {
    public static let shared = DeepSeekService()

    @Published public var messages: [ChatMessage] = []
    @Published public var isGenerating: Bool = false
    @Published public var selectedModel: String = "expert" // "expert" (DeepSeek-R1) or "default" (DeepSeek-V3)
    @Published public var isThinkingEnabled: Bool = false  // Default FALSE per user requirement 1!
    @Published public var isSearchEnabled: Bool = true     // Default ALWAYS ON per user requirement 1!
    @Published public var errorMessage: String? = nil

    public var activeChatSessionId: String? = nil
    public var activeParentMessageId: Int? = nil
    public var messagesInCurrentSession: Int = 0

    private let baseUrl = "https://chat.deepseek.com"
    private var lastRequestTime: TimeInterval = 0

    private init() {}

    public func resetConversation() {
        self.messages.removeAll()
        self.activeChatSessionId = nil
        self.activeParentMessageId = nil
        self.messagesInCurrentSession = 0
        self.errorMessage = nil
        self.isGenerating = false
        self.isThinkingEnabled = false // default false
        self.isSearchEnabled = true    // default true
    }

    public func loadSessionMessages(_ session: ConversationSession) {
        self.activeChatSessionId = session.id
        self.messages = session.messages.map { saved in
            ChatMessage(
                id: saved.id,
                text: saved.text,
                thinkingText: saved.thinkingText,
                isUser: saved.isUser,
                date: saved.date
            )
        }
        self.selectedModel = session.model
        self.messagesInCurrentSession = session.messages.count
        self.errorMessage = nil
        self.isGenerating = false
        self.isThinkingEnabled = false
        self.isSearchEnabled = true
    }

    public func stopStreaming() {
        self.isGenerating = false
        if let lastIdx = messages.indices.last, !messages[lastIdx].isUser {
            messages[lastIdx].isStreaming = false
            messages[lastIdx].isThinking = false
        }
    }

    public func sendMessage(_ prompt: String, image: UIImage? = nil, attachmentContext: String = "") async {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || image != nil || !attachmentContext.isEmpty else { return }

        // User message
        let userMsg = ChatMessage(text: trimmed, isUser: true, image: image)
        self.messages.append(userMsg)

        // Assistant placeholder
        let aiMsgId = UUID().uuidString
        let aiMsg = ChatMessage(
            id: aiMsgId,
            text: "",
            thinkingText: "",
            isUser: false,
            isThinking: isThinkingEnabled,
            isStreaming: true
        )
        self.messages.append(aiMsg)
        self.isGenerating = true
        self.errorMessage = nil

        guard let session = DeepSeekAuthManager.shared.currentSession, session.isValid else {
            if let index = self.messages.firstIndex(where: { $0.id == aiMsgId }) {
                self.messages[index].text = "⚠️ Chưa đăng nhập tài khoản DeepSeek. Vui lòng bấm vào icon góc trên hoặc chạm vào đây để đăng nhập!"
                self.messages[index].isStreaming = false
                self.messages[index].isThinking = false
            }
            self.isGenerating = false
            NotificationCenter.default.post(name: .openDeepSeekLoginSheet, object: nil)
            return
        }

        // Anti-mute pre-check
        if DeepSeekAuthManager.shared.isMuted {
            if let index = self.messages.firstIndex(where: { $0.id == aiMsgId }) {
                self.messages[index].text = "⚠️ Tài khoản DeepSeek này đang bị hạn chế (muted). Vui lòng đăng xuất và đăng nhập tài khoản Google khác!"
                self.messages[index].isStreaming = false
                self.messages[index].isThinking = false
            }
            self.isGenerating = false
            return
        }

        // Anti-ban human pacing
        let now = Date().timeIntervalSince1970
        let elapsed = now - lastRequestTime
        if elapsed < 1.2 {
            try? await Task.sleep(nanoseconds: UInt64((1.2 - elapsed) * 1_000_000_000))
        }
        self.lastRequestTime = Date().timeIntervalSince1970

        do {
            // Step 1: Ensure chat session
            let sessionId = try await ensureChatSession(session: session)

            // Step 2 & 3: Fetch and solve PoW challenge
            let powHeader = try await solvePoWChallenge(session: session)

            // Step 4: System prompt with guidelines learned from dulieukhoaai.md & ChatGPT style
            var fullPromptPayload = ""
            if !attachmentContext.isEmpty {
                fullPromptPayload += "\(attachmentContext)\n\n"
            }
            fullPromptPayload += trimmed

            let finalPrompt: String
            if messagesInCurrentSession == 0 {
                let systemPrompt = """
[Quy chuẩn hệ thống (học từ dulieukhoaai.md & chuẩn mực ChatGPT):
1. Danh tính & Cách chào hỏi:
- Bạn là khoa.ai, được sáng lập và phát triển bởi Khoa Dev.
- TUYỆT ĐỐI LƯU Ý: Khi người dùng chào hỏi (như "chào bạn", "xin chào", "hello", "hi"), hãy chào lại tự nhiên, ấm áp, lịch sự và ngắn gọn như ChatGPT. TUYỆT ĐỐI KHÔNG tự động giới thiệu tên hay nói "tôi là khoa.ai do Khoa Dev tạo ra" trừ khi người dùng chủ động hỏi đích danh "bạn là ai?" hoặc "ai tạo ra bạn?".
- Chỉ khi được hỏi trực tiếp về danh tính, nguồn gốc, bạn mới khẳng định mình là khoa.ai do Khoa Dev sáng lập và phát triển.

2. Phong cách hành văn & Trình bày Markdown (Chuẩn ChatGPT):
- Không lạm dụng gạch đầu dòng (-). Viết thành các đoạn văn tự nhiên, mạch lạc, kết nối ý tưởng uyển chuyển thay vì tách mỗi câu thành một gạch đầu dòng.
- Chỉ sử dụng danh sách ngắn khi người dùng yêu cầu liệt kê các bước, hoặc khi cần trình bày cô đọng tối đa 1 danh sách trong một phản hồi.
- Trình bày Markdown rõ ràng, chuyên nghiệp: Tiêu đề (#, ##, ###) đúng cấp bậc, đoạn văn có độ giãn cách thoáng đãng.
- Khi người dùng cần bảng biểu (lịch trình, so sánh, kế hoạch), BẮT BUỘC dùng bảng Markdown chuẩn:
| Tiêu đề 1 | Tiêu đề 2 | Tiêu đề 3 |
| --- | --- | --- |
| Dòng 1 | Nội dung | Ghi chú |
(Lưu ý: Không bọc dấu ** ** vào từng ô trong bảng, để văn bản trong ô hiển thị tự nhiên, sạch sẽ).
- Khối code luôn đặt trong ```ngôn_ngữ ... ```.

3. Thái độ & Trí tuệ (dulieukhoaai.md):
- Trả lời thẳng vào trọng tâm câu hỏi, không dài dòng giải thích thừa thãi hay nói các câu sáo rỗng.
- Luôn giữ thái độ tôn trọng, tích cực, hữu ích, văn minh và an toàn tối đa cho mọi người dùng.]

Người dùng: \(fullPromptPayload)
"""
                finalPrompt = systemPrompt
            } else {
                finalPrompt = fullPromptPayload
            }

            // Step 5: Stream completion with robust chunk handler
            try await streamCompletion(
                session: session,
                sessionId: sessionId,
                prompt: finalPrompt,
                powHeader: powHeader,
                aiMessageId: aiMsgId
            )

            self.messagesInCurrentSession += 1

            // Persist into ConversationManager
            ConversationManager.shared.saveCurrentChat(messages: self.messages, model: self.selectedModel)
        } catch {
            self.errorMessage = error.localizedDescription
            if let index = self.messages.firstIndex(where: { $0.id == aiMsgId }) {
                self.messages[index].text = "⚠️ Lỗi: \(error.localizedDescription)\n\nVui lòng kiểm tra kết nối mạng hoặc thử đăng nhập lại tài khoản DeepSeek."
                self.messages[index].isStreaming = false
                self.messages[index].isThinking = false
            }
        }

        self.isGenerating = false
    }

    private func ensureChatSession(session: DeepSeekSession) async throws -> String {
        if let existing = activeChatSessionId, messagesInCurrentSession < 30 {
            return existing
        }

        guard let url = URL(string: "\(baseUrl)/api/v0/chat_session/create") else {
            throw NSError(domain: "DeepSeekService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(session.token)", forHTTPHeaderField: "authorization")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(session.userAgent, forHTTPHeaderField: "user-agent")
        request.setValue(baseUrl, forHTTPHeaderField: "origin")
        request.setValue("\(baseUrl)/", forHTTPHeaderField: "referer")
        request.setValue(session.cookieHeader, forHTTPHeaderField: "cookie")
        request.setValue("vi-VN,vi;q=0.9", forHTTPHeaderField: "accept-language")
        request.setValue("com.deepseek.chat", forHTTPHeaderField: "x-client-bundle-id")
        request.setValue("2.0.0", forHTTPHeaderField: "x-client-version")
        request.setValue("web", forHTTPHeaderField: "x-client-platform")

        let bodyObj: [String: Any] = [:]
        request.httpBody = try JSONSerialization.data(withJSONObject: bodyObj)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "DeepSeekService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Không nhận được phản hồi"])
        }

        if http.statusCode != 200 {
            let msg = parseErrorMessage(data) ?? "Tạo phiên chat thất bại (HTTP \(http.statusCode))"
            throw NSError(domain: "DeepSeekService", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "DeepSeekService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Phản hồi phiên chat không phải JSON hợp lệ"])
        }

        if let code = json["code"] as? Int, code != 0 {
            let msg = json["msg"] as? String ?? "Lỗi API DeepSeek (mã \(code))"
            throw NSError(domain: "DeepSeekService", code: code, userInfo: [NSLocalizedDescriptionKey: msg])
        }

        let dataObj = json["data"] as? [String: Any]
        let biz = dataObj?["biz_data"] as? [String: Any]
        let chatSession = (biz?["chat_session"] as? [String: Any]) ?? (dataObj?["chat_session"] as? [String: Any])

        let foundId = (chatSession?["id"] as? String)
            ?? (biz?["id"] as? String)
            ?? (dataObj?["id"] as? String)

        guard let id = foundId, !id.isEmpty else {
            throw NSError(domain: "DeepSeekService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Định dạng phiên không hợp lệ"])
        }

        self.activeChatSessionId = id
        self.activeParentMessageId = nil
        self.messagesInCurrentSession = 0
        return id
    }

    private func solvePoWChallenge(session: DeepSeekSession) async throws -> String {
        guard let url = URL(string: "\(baseUrl)/api/v0/chat/create_pow_challenge") else {
            throw NSError(domain: "DeepSeekService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Invalid PoW URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(session.token)", forHTTPHeaderField: "authorization")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(session.userAgent, forHTTPHeaderField: "user-agent")
        request.setValue(baseUrl, forHTTPHeaderField: "origin")
        request.setValue("\(baseUrl)/", forHTTPHeaderField: "referer")
        request.setValue(session.cookieHeader, forHTTPHeaderField: "cookie")
        request.setValue("vi-VN,vi;q=0.9", forHTTPHeaderField: "accept-language")
        request.setValue("com.deepseek.chat", forHTTPHeaderField: "x-client-bundle-id")
        request.setValue("2.0.0", forHTTPHeaderField: "x-client-version")
        request.setValue("web", forHTTPHeaderField: "x-client-platform")

        let bodyObj = ["target_path": "/api/v0/chat/completion"]
        request.httpBody = try JSONSerialization.data(withJSONObject: bodyObj)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "DeepSeekService", code: -5, userInfo: [NSLocalizedDescriptionKey: "Không nhận được phản hồi PoW"])
        }

        if http.statusCode != 200 {
            let msg = parseErrorMessage(data) ?? "Lỗi tải PoW (HTTP \(http.statusCode))"
            throw NSError(domain: "DeepSeekService", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "DeepSeekService", code: -6, userInfo: [NSLocalizedDescriptionKey: "Định dạng JSON PoW không hợp lệ."])
        }

        if let code = json["code"] as? Int, code != 0 {
            let msg = json["msg"] as? String ?? "Lỗi API PoW (mã \(code))"
            throw NSError(domain: "DeepSeekService", code: code, userInfo: [NSLocalizedDescriptionKey: msg])
        }

        let dataObj = json["data"] as? [String: Any]
        let biz = dataObj?["biz_data"] as? [String: Any]
        let challenge = (biz?["challenge"] as? [String: Any]) ?? (dataObj?["challenge"] as? [String: Any])

        guard let chal = challenge else {
            throw NSError(domain: "DeepSeekService", code: -6, userInfo: [NSLocalizedDescriptionKey: "Định dạng PoW không hợp lệ."])
        }

        return try await DeepSeekPowSolver.shared.makeHeader(challenge: chal)
    }

    private func streamCompletion(
        session: DeepSeekSession,
        sessionId: String,
        prompt: String,
        powHeader: String,
        aiMessageId: String
    ) async throws {
        guard let url = URL(string: "\(baseUrl)/api/v0/chat/completion") else {
            throw NSError(domain: "DeepSeekService", code: -7, userInfo: [NSLocalizedDescriptionKey: "Invalid completion URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(session.token)", forHTTPHeaderField: "authorization")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(session.userAgent, forHTTPHeaderField: "user-agent")
        request.setValue(baseUrl, forHTTPHeaderField: "origin")
        request.setValue("\(baseUrl)/", forHTTPHeaderField: "referer")
        request.setValue(session.cookieHeader, forHTTPHeaderField: "cookie")
        request.setValue("vi-VN,vi;q=0.9", forHTTPHeaderField: "accept-language")
        request.setValue("com.deepseek.chat", forHTTPHeaderField: "x-client-bundle-id")
        request.setValue("2.0.0", forHTTPHeaderField: "x-client-version")
        request.setValue("web", forHTTPHeaderField: "x-client-platform")
        request.setValue(powHeader, forHTTPHeaderField: "x-ds-pow-response")

        var bodyObj: [String: Any] = [
            "chat_session_id": sessionId,
            "parent_message_id": activeParentMessageId as Any,
            "prompt": prompt,
            "ref_file_ids": [],
            "thinking_enabled": isThinkingEnabled,
            "search_enabled": isSearchEnabled,
            "action": NSNull(),
            "preempt": false
        ]

        if messagesInCurrentSession == 0 {
            bodyObj["model_type"] = selectedModel
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: bodyObj)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "DeepSeekService", code: -8, userInfo: [NSLocalizedDescriptionKey: "Lỗi kết nối máy chủ"])
        }

        if http.statusCode != 200 {
            throw NSError(domain: "DeepSeekService", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Lỗi phản hồi HTTP \(http.statusCode)"])
        }

        var activePath: String = "response/fragments/-1/content"

        for try await line in bytes.lines {
            var trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.hasPrefix("data:") else { continue }
            
            // Remove "data:" prefix and optional leading whitespace
            trimmed.removeFirst(5)
            if trimmed.hasPrefix(" ") {
                trimmed.removeFirst()
            }
            if trimmed.isEmpty || trimmed == "[DONE]" { continue }

            guard let jsonData = trimmed.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                continue
            }

            // Path tracking
            if let p = obj["p"] as? String {
                activePath = p
                if let msgId = obj["v"] as? Int, p.hasSuffix("message_id") {
                    self.activeParentMessageId = msgId
                }
            }

            // Filter out status updates (prevents FINISHED / COMPLETED from leaking into chat)
            if activePath.contains("status") || activePath.contains("finish_reason") {
                continue
            }

            // Case A: v is a snapshot dictionary or new fragment dictionary
            if let vDict = obj["v"] as? [String: Any] {
                // If it contains "response", extract message_id and any initial fragments
                if let resp = vDict["response"] as? [String: Any] {
                    if let mid = resp["message_id"] as? Int ?? resp["id"] as? Int {
                        self.activeParentMessageId = mid
                    }
                    if let frags = resp["fragments"] as? [[String: Any]] {
                        for frag in frags {
                            let type = (frag["type"] as? String ?? "").uppercased()
                            let content = frag["content"] as? String ?? ""
                            guard !content.isEmpty else { continue }
                            if type.contains("THINK") {
                                appendToThinking(content, for: aiMessageId)
                            } else {
                                appendToResponse(content, for: aiMessageId)
                            }
                        }
                    }
                }

                // If vDict has its own "content" (e.g. {"type": "RESPONSE", "content": "..."})
                // This is where DeepSeek sends the FIRST character(s) of a fragment!
                if let content = vDict["content"] as? String, !content.isEmpty {
                    let type = (vDict["type"] as? String ?? "").uppercased()
                    if type.contains("THINK") || activePath.contains("/0/") || activePath.contains("think") {
                        appendToThinking(content, for: aiMessageId)
                    } else {
                        appendToResponse(content, for: aiMessageId)
                    }
                }
            }

            // Case B: v is a direct string append
            if let vStr = obj["v"] as? String, !vStr.isEmpty {
                // Filter out any status values accidentally received as vStr
                let upper = vStr.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
                if upper == "FINISHED" || upper == "COMPLETED" || upper == "STOPPED" || upper == "DONE" {
                    continue
                }

                if activePath.contains("think") || activePath.contains("/0/content") {
                    appendToThinking(vStr, for: aiMessageId)
                } else if activePath.contains("content") || activePath.contains("response") {
                    appendToResponse(vStr, for: aiMessageId)
                }
            }
        }

        if let index = self.messages.firstIndex(where: { $0.id == aiMessageId }) {
            self.messages[index].isStreaming = false
            self.messages[index].isThinking = false
        }
    }

    private func appendToThinking(_ text: String, for messageId: String) {
        if let idx = self.messages.firstIndex(where: { $0.id == messageId }) {
            self.messages[idx].thinkingText += text
            self.messages[idx].isThinking = true
        }
    }

    private func appendToResponse(_ text: String, for messageId: String) {
        if let idx = self.messages.firstIndex(where: { $0.id == messageId }) {
            self.messages[idx].text += text
            self.messages[idx].isThinking = false
        }
    }

    public func loadSession(_ session: ConversationSession) {
        loadSessionMessages(session)
    }

    private func parseErrorMessage(_ data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        if let msg = json["msg"] as? String, !msg.isEmpty {
            return msg
        }
        return nil
    }
}

public extension Notification.Name {
    static let openDeepSeekLoginSheet = Notification.Name("openDeepSeekLoginSheet")
}
