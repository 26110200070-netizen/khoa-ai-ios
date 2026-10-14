//
//  DeepSeekLoginSheet.swift
//  KhoaAI
//
//  Created by Khoa Dev.
//  In-app WebKit login sheet for DeepSeek with automatic session, token & cookie capture.
//

import SwiftUI
import WebKit

public struct DeepSeekLoginSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var authManager = DeepSeekAuthManager.shared

    @State private var isLoading: Bool = true
    @State private var statusMessage: String = "Đang tải trang đăng nhập DeepSeek..."
    @State private var isSuccess: Bool = false
    @State private var webView = WKWebView()

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top Info Glass Banner
                    HStack(spacing: 12) {
                        Image(systemName: isSuccess ? "checkmark.circle.fill" : "lock.shield.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(isSuccess ? Color.green : Color.blue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(isSuccess ? "Đăng nhập thành công!" : "Đăng nhập DeepSeek")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))

                            Text(statusMessage)
                                .font(.system(size: 12))
                                .foregroundStyle(Color.secondary)
                                .lineLimit(2)
                        }

                        Spacer()

                        if isLoading && !isSuccess {
                            ProgressView()
                                .scaleEffect(0.85)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .overlay(alignment: .bottom) {
                        Divider()
                    }

                    // Native WebKit View
                    DeepSeekWebViewWrapper(
                        isLoading: $isLoading,
                        statusMessage: $statusMessage,
                        isSuccess: $isSuccess,
                        onSessionCaptured: { token, cookies, userAgent in
                            Task { @MainActor in
                                authManager.saveSession(
                                    token: token,
                                    cookies: cookies,
                                    userAgent: userAgent
                                )
                                statusMessage = "Đã lưu session an toàn. Đang kiểm tra trạng thái tài khoản..."

                                try? await Task.sleep(nanoseconds: 1_200_000_000)
                                if authManager.isMuted {
                                    statusMessage = "⚠️ Tài khoản này đang bị DeepSeek mute. Vui lòng đăng xuất và đăng nhập tài khoản khác!"
                                } else {
                                    statusMessage = "Đã kích hoạt khoa.ai thành công!"
                                    isSuccess = true
                                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                                    dismiss()
                                }
                            }
                        }
                    )
                }
            }
            .navigationTitle("Tài khoản DeepSeek")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        // Reload page
                        NotificationCenter.default.post(name: .deepSeekReloadPage, object: nil)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
            }
        }
    }
}

extension Notification.Name {
    static let deepSeekReloadPage = Notification.Name("deepSeekReloadPage")
}

struct DeepSeekWebViewWrapper: UIViewRepresentable {
    @Binding var isLoading: Bool
    @Binding var statusMessage: String
    @Binding var isSuccess: Bool
    var onSessionCaptured: (String, [String: String], String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.applicationNameForUserAgent = "MobileSafari/604.1"

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView

        // Custom iOS User Agent
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"

        if let url = URL(string: "https://chat.deepseek.com/sign_in") {
            webView.load(URLRequest(url: url))
        }

        NotificationCenter.default.addObserver(
            forName: .deepSeekReloadPage,
            object: nil,
            queue: .main
        ) { _ in
            if let url = URL(string: "https://chat.deepseek.com/sign_in") {
                webView.load(URLRequest(url: url))
            }
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: DeepSeekWebViewWrapper
        weak var webView: WKWebView?
        var timer: Timer?
        var captured: Bool = false

        init(_ parent: DeepSeekWebViewWrapper) {
            self.parent = parent
            super.init()
            startTokenPolling()
        }

        deinit {
            timer?.invalidate()
        }

        func startTokenPolling() {
            timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
                self?.pollSessionToken()
            }
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            parent.statusMessage = "Vui lòng đăng nhập hoặc vượt kiểm tra bảo mật nếu có..."
            pollSessionToken()
        }

        func pollSessionToken() {
            guard !captured, let wv = webView else { return }

            let js = """
            (() => {
                try {
                    const raw = window.localStorage.getItem('userToken');
                    if (!raw) return null;
                    const o = JSON.parse(raw);
                    return (o && o.value) ? o.value : null;
                } catch(e) { return null; }
            })()
            """

            wv.evaluateJavaScript(js) { [weak self] result, error in
                guard let self = self, !self.captured else { return }
                if let token = result as? String, !token.isEmpty {
                    self.captured = true
                    self.parent.statusMessage = "Đã phát hiện token! Đang gom cookies..."

                    // Collect cookies
                    wv.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                        var cookieDict: [String: String] = [:]
                        for c in cookies {
                            if c.domain.contains("deepseek.com") {
                                cookieDict[c.name] = c.value
                            }
                        }

                        wv.evaluateJavaScript("navigator.userAgent") { uaResult, _ in
                            let ua = (uaResult as? String) ?? wv.customUserAgent ?? ""
                            self.parent.onSessionCaptured(token, cookieDict, ua)
                        }
                    }
                }
            }
        }
    }
}
