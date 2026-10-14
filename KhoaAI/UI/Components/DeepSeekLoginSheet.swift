//
//  DeepSeekLoginSheet.swift
//  KhoaAI
//
//  Created by Khoa Dev.
//  In-app WebKit login sheet with Google OAuth popup support and 1-tap manual session loader.
//

import SwiftUI
import WebKit

public struct DeepSeekLoginSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var authManager = DeepSeekAuthManager.shared

    @State private var loginMode: Int = 0 // 0: WebKit, 1: Manual/Preloaded
    @State private var isLoading: Bool = true
    @State private var statusMessage: String = "Đang tải trang đăng nhập DeepSeek..."
    @State private var isSuccess: Bool = false
    @State private var manualTokenInput: String = ""

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented Picker
                Picker("Chế độ đăng nhập", selection: $loginMode) {
                    Text("Trình duyệt WebKit").tag(0)
                    Text("Nạp phiên / Token").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                if loginMode == 0 {
                    // Tab 1: Native WebKit Browser
                    VStack(spacing: 0) {
                        // Info banner
                        HStack(spacing: 12) {
                            Image(systemName: isSuccess ? "checkmark.circle.fill" : "lock.shield.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(isSuccess ? Color.green : Color.blue)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(isSuccess ? "Đăng nhập thành công!" : "Đăng nhập DeepSeek")
                                    .font(.system(size: 14, weight: .semibold))
                                Text(statusMessage)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.secondary)
                                    .lineLimit(2)
                            }
                            Spacer()
                            if isLoading && !isSuccess {
                                ProgressView().scaleEffect(0.8)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6).opacity(0.6))
                        .overlay(alignment: .bottom) { Divider() }

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
                                    statusMessage = "Đã lưu session an toàn! Đang chuyển tiếp..."
                                    isSuccess = true
                                    try? await Task.sleep(nanoseconds: 800_000_000)
                                    dismiss()
                                }
                            }
                        )
                    }
                } else {
                    // Tab 2: 1-Tap Preloaded / Manual Token Import
                    ScrollView {
                        VStack(spacing: 24) {
                            // 1-Tap Load Preloaded Card
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "bolt.fill")
                                        .foregroundStyle(Color.orange)
                                    Text("Nạp phiên sẵn có (1-Chạm)")
                                        .font(.system(size: 16, weight: .bold))
                                }

                                Text("Sử dụng ngay phiên DeepSeek mẫu đã được kiểm chứng hoạt động (kèm đầy đủ token & cookies vượt AWS WAF).")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.secondary)

                                Button {
                                    authManager.loadPreloadedSession()
                                    let haptic = UINotificationFeedbackGenerator()
                                    haptic.notificationOccurred(.success)
                                    dismiss()
                                } label: {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "play.circle.fill")
                                        Text("Kích hoạt phiên mẫu & Chat ngay")
                                            .font(.system(size: 15, weight: .semibold))
                                        Spacer()
                                    }
                                    .padding(.vertical, 12)
                                    .background(Color.blue)
                                    .foregroundStyle(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .padding(16)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                            // Manual Token Paste Card
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "key.fill")
                                        .foregroundStyle(Color.blue)
                                    Text("Nhập Bearer Token thủ công")
                                        .font(.system(size: 16, weight: .bold))
                                }

                                Text("Nếu bạn đã có userToken từ web chat.deepseek.com (localStorage.userToken), hãy dán vào đây:")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.secondary)

                                TextField("Dán mã token vào đây...", text: $manualTokenInput)
                                    .font(.system(size: 14, design: .monospaced))
                                    .padding(12)
                                    .background(Color(.systemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1))

                                Button {
                                    let trimmed = manualTokenInput.trimmingCharacters(in: .whitespacesAndNewlines)
                                    guard !trimmed.isEmpty else { return }
                                    authManager.loginWithManualToken(token: trimmed)
                                    let haptic = UINotificationFeedbackGenerator()
                                    haptic.notificationOccurred(.success)
                                    dismiss()
                                } label: {
                                    HStack {
                                        Spacer()
                                        Text("Lưu Token & Sử dụng")
                                            .font(.system(size: 15, weight: .semibold))
                                        Spacer()
                                    }
                                    .padding(.vertical, 12)
                                    .background(manualTokenInput.isEmpty ? Color.gray.opacity(0.4) : Color.green)
                                    .foregroundStyle(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .disabled(manualTokenInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                            .padding(16)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                            Spacer()
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Tài khoản DeepSeek")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if loginMode == 0 {
                        Button {
                            NotificationCenter.default.post(name: .deepSeekReloadPage, object: nil)
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
        }
    }
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
        config.preferences.javaScriptCanOpenWindowsAutomatically = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        context.coordinator.webView = webView

        // Clean Mobile Safari User-Agent that avoids Google 403 disallowed_useragent
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

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
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
            timer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { [weak self] _ in
                self?.pollSessionToken()
            }
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            parent.statusMessage = "Vui lòng đăng nhập hoặc hoàn thành câu đố nếu có..."
            pollSessionToken()
        }

        // Support Google OAuth popup windows inside the same webview
        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
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
                    self.parent.statusMessage = "Đã bắt được phiên! Đang hoàn tất..."

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
