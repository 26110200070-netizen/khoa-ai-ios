//
//  DeepSeekAuthManager.swift
//  KhoaAI
//
//  Created by Khoa Dev.
//  Manages DeepSeek authenticated sessions, anti-ban headers, cookie stores, and account health.
//

import Foundation
import WebKit
import Combine

public struct DeepSeekSession: Codable {
    public var token: String
    public var cookies: [String: String]
    public var userAgent: String
    public var capturedAt: TimeInterval
    public var email: String
    public var isMuted: Bool

    public var isExpired: Bool {
        return (Date().timeIntervalSince1970 - capturedAt) > (24 * 3600)
    }

    public var isValid: Bool {
        return !token.isEmpty && !isExpired
    }

    public var cookieHeader: String {
        return cookies.map { "\($0.key)=\($0.value)" }.joined(separator: "; ")
    }
}

@MainActor
public class DeepSeekAuthManager: ObservableObject {
    public static let shared = DeepSeekAuthManager()

    private let storageKey = "khoa_ai_deepseek_session_v2"

    @Published public var session: DeepSeekSession?
    public var currentSession: DeepSeekSession? { session }
    @Published public var isAuthenticated: Bool = false
    @Published public var isMuted: Bool = false
    @Published public var userEmail: String = ""
    @Published public var isCheckingHealth: Bool = false
    @Published public var healthError: String?

    public init() {
        loadSession()
    }

    public func loadSession() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(DeepSeekSession.self, from: data),
           !decoded.token.isEmpty {
            self.session = decoded
            self.isAuthenticated = true
            self.isMuted = decoded.isMuted
            self.userEmail = decoded.email
            syncCookiesToStorage(decoded.cookies)
        } else {
            // Auto-load preloaded session on first install so user can chat immediately
            loadPreloadedSession()
        }

        Task {
            await self.verifyAccountStatus()
        }
    }

    public func loadPreloadedSession() {
        saveSession(
            token: PreloadedSession.token,
            cookies: PreloadedSession.cookies,
            userAgent: PreloadedSession.userAgent,
            email: "Tài khoản mẫu DeepSeek"
        )
    }

    public func saveSession(
        token: String,
        cookies: [String: String],
        userAgent: String,
        email: String = "",
        isMuted: Bool = false
    ) {
        let cleanToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "Bearer ", with: "")

        let ua = userAgent.isEmpty ? "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1" : userAgent

        let newSession = DeepSeekSession(
            token: cleanToken,
            cookies: cookies,
            userAgent: ua,
            capturedAt: Date().timeIntervalSince1970,
            email: email,
            isMuted: isMuted
        )

        if let encoded = try? JSONEncoder().encode(newSession) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }

        self.session = newSession
        self.isAuthenticated = !cleanToken.isEmpty
        self.isMuted = isMuted
        self.userEmail = email
        syncCookiesToStorage(cookies)

        Task {
            await self.verifyAccountStatus()
        }
    }

    public func loginWithManualToken(token: String) {
        saveSession(
            token: token,
            cookies: self.session?.cookies ?? PreloadedSession.cookies,
            userAgent: self.session?.userAgent ?? PreloadedSession.userAgent,
            email: "Token thủ công"
        )
    }

    public func logout() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        self.session = nil
        self.isAuthenticated = false
        self.isMuted = false
        self.userEmail = ""

        WKWebsiteDataStore.default().removeData(
            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
            modifiedSince: Date(timeIntervalSince1970: 0),
            completionHandler: {}
        )
    }

    private func syncCookiesToStorage(_ cookies: [String: String]) {
        for (name, val) in cookies {
            var properties: [HTTPCookiePropertyKey: Any] = [
                .name: name,
                .value: val,
                .domain: ".deepseek.com",
                .path: "/",
                .expires: Date().addingTimeInterval(30 * 86400)
            ]
            if let c = HTTPCookie(properties: properties) {
                HTTPCookieStorage.shared.setCookie(c)
            }
        }
    }

    // Anti-ban check: Verify account is healthy and not muted by DeepSeek
    public func verifyAccountStatus() async {
        guard let session = self.session, !session.token.isEmpty else { return }

        isCheckingHealth = true
        defer { isCheckingHealth = false }

        guard let url = URL(string: "https://chat.deepseek.com/api/v0/users/current") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(session.token)", forHTTPHeaderField: "authorization")
        request.setValue(session.userAgent, forHTTPHeaderField: "user-agent")
        request.setValue("https://chat.deepseek.com", forHTTPHeaderField: "origin")
        request.setValue("https://chat.deepseek.com/", forHTTPHeaderField: "referer")
        request.setValue("*/*", forHTTPHeaderField: "accept")
        request.setValue("vi-VN,vi;q=0.9,en-US;q=0.8,en;q=0.7", forHTTPHeaderField: "accept-language")
        request.setValue("com.deepseek.chat", forHTTPHeaderField: "x-client-bundle-id")
        request.setValue("2.0.0", forHTTPHeaderField: "x-client-version")
        request.setValue("web", forHTTPHeaderField: "x-client-platform")

        if !session.cookies.isEmpty {
            request.setValue(session.cookieHeader, forHTTPHeaderField: "cookie")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let dataObj = json["data"] as? [String: Any],
                   let biz = dataObj["biz_data"] as? [String: Any] {

                    let email = biz["email"] as? String ?? ""
                    let chatInfo = biz["chat"] as? [String: Any] ?? [:]
                    let isMutedInt = chatInfo["is_muted"] as? Int ?? 0
                    let muted = (isMutedInt == 1)

                    if !email.isEmpty {
                        self.userEmail = email
                    }
                    self.isMuted = muted

                    if var current = self.session {
                        if !email.isEmpty { current.email = email }
                        current.isMuted = muted
                        if let encoded = try? JSONEncoder().encode(current) {
                            UserDefaults.standard.set(encoded, forKey: storageKey)
                        }
                        self.session = current
                    }

                    if muted {
                        self.healthError = "Tài khoản (\(email)) đang bị DeepSeek tạm khóa/mute tính năng chat."
                    } else {
                        self.healthError = nil
                    }
                }
            } else if let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 401 {
                self.healthError = "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại."
            }
        } catch {
            print("[AuthManager] verify error: \(error.localizedDescription)")
        }
    }
}
