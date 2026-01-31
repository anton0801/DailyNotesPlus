import SwiftUI
import WebKit
import Combine

struct SettingsView: View {
    @EnvironmentObject var viewModel: NotesViewModel
    @AppStorage("selectedLanguage") private var selectedLanguage = "en"
    @AppStorage("textSize") private var textSize: Double = 16
    @AppStorage("appTheme") private var appTheme = "light"
    
    @State private var showingExportSheet = false
    @State private var showingResetAlert = false
    @State private var showingBackupSheet = false
    @State private var exportURL: URL?
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "FAFAF8")
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // App Info
                        appInfoSection
                        
                        // Preferences
                        preferencesSection
                        
                        // Data Management
                        dataManagementSection
                        
                        // About
                        aboutSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "2C3E50"))
                }
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingBackupSheet) {
            BackupView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
        .alert(isPresented: $showingResetAlert) {
            Alert(
                title: Text("Reset All Data"),
                message: Text("This will delete all your notes permanently. This action cannot be undone."),
                primaryButton: .destructive(Text("Reset")) {
                    resetAllData()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private var appInfoSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.fill")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "1E88E5"))
                .overlay(
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "26A69A"))
                        .offset(x: 25, y: -20)
                )
            
            Text("Daily Notes Master")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color(hex: "2C3E50"))
            
            Text("Version 1.0")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "7F8C8D"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private var preferencesSection: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "Preferences")
            
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "globe",
                    title: "Language",
                    value: selectedLanguage == "en" ? "English" : "Русский",
                    color: Color(hex: "1E88E5")
                ) {
                    selectedLanguage = selectedLanguage == "en" ? "ru" : "en"
                }
                
                Divider().padding(.leading, 60)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "textformat.size")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "26A69A"))
                            .frame(width: 40, height: 40)
                            .background(Color(hex: "26A69A").opacity(0.15))
                            .cornerRadius(10)
                        
                        Text("Text Size")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "2C3E50"))
                        
                        Spacer()
                        
                        Text("\(Int(textSize))pt")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "7F8C8D"))
                    }
                    
                    Slider(value: $textSize, in: 12...24, step: 2)
                        .accentColor(Color(hex: "26A69A"))
                }
                .padding(16)
                
                Divider().padding(.leading, 60)
                
                SettingsRow(
                    icon: "moon.fill",
                    title: "Theme",
                    value: appTheme == "light" ? "Light" : "Soft",
                    color: Color(hex: "FF6F00")
                ) {
                    appTheme = appTheme == "light" ? "soft" : "light"
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
    }
    
    private var dataManagementSection: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "Data Management")
            
            VStack(spacing: 0) {
                SettingsButton(
                    icon: "square.and.arrow.up",
                    title: "Export Notes",
                    color: Color(hex: "1E88E5")
                ) {
                    showingExportSheet = true
                }
                
                Divider().padding(.leading, 60)
                
                SettingsButton(
                    icon: "arrow.clockwise",
                    title: "Backup & Restore",
                    color: Color(hex: "26A69A")
                ) {
                    showingBackupSheet = true
                }
                
                Divider().padding(.leading, 60)
                
                SettingsButton(
                    icon: "trash",
                    title: "Reset All Data",
                    color: Color(hex: "FF5252")
                ) {
                    showingResetAlert = true
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
    }
    
    private var aboutSection: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "About")
            
            VStack(spacing: 0) {
                SettingsButton(
                    icon: "hand.raised.fill",
                    title: "Privacy Policy",
                    color: Color(hex: "1E88E5")
                ) {
                    UIApplication.shared.open(URL(string: "https://dailynotesplus.com/privacy-policy.html")!)
                }
                
                Divider().padding(.leading, 60)
                
                SettingsButton(
                    icon: "info.circle.fill",
                    title: "Contact us",
                    color: Color(hex: "26A69A")
                ) {
                    UIApplication.shared.open(URL(string: "https://dailynotesplus.com/support.html")!)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
    }
    
    private func resetAllData() {
        // Delete all notes
        for note in viewModel.notes {
            viewModel.deleteNote(note)
        }
    }
}

final class ViewController: ObservableObject {
    
    @Published private(set) var mainView: WKWebView!
    @Published var auxiliaryViews: [WKWebView] = []
    
    let sessionStrategy = SessionStrategy()
    
    private var observers = Set<AnyCancellable>()
    
    func setupMainView() {
        let configuration = buildConfiguration()
        mainView = WKWebView(frame: .zero, configuration: configuration)
        applyViewSettings(mainView)
    }
    
    private func buildConfiguration() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.preferences = preferences
        
        let webpagePreferences = WKWebpagePreferences()
        webpagePreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = webpagePreferences
        
        return configuration
    }
    
    private func applyViewSettings(_ view: WKWebView) {
        view.scrollView.minimumZoomScale = 1.0
        view.scrollView.maximumZoomScale = 1.0
        view.scrollView.bounces = false
        view.scrollView.bouncesZoom = false
        view.allowsBackForwardNavigationGestures = true
    }
    
    func performBackNavigation(fallback: URL? = nil) {
        if !auxiliaryViews.isEmpty {
            if let last = auxiliaryViews.last {
                last.removeFromSuperview()
                auxiliaryViews.removeLast()
            }
            
            if let fallback = fallback {
                mainView.load(URLRequest(url: fallback))
            }
        } else if mainView.canGoBack {
            mainView.goBack()
        }
    }
    
    func reloadView() {
        mainView.reload()
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "2C3E50"))
            
            Spacer()
        }
        .padding(.bottom, 12)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.15))
                    .cornerRadius(10)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "2C3E50"))
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "7F8C8D"))
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "7F8C8D"))
            }
            .padding(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

extension ViewHandler: WKUIDelegate {
    
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard navigationAction.targetFrame == nil,
              let controller = controller,
              let main = controller.mainView else {
            return nil
        }
        
        let auxiliary = WKWebView(frame: .zero, configuration: configuration)
        
        configureAuxiliary(auxiliary, within: main)
        attachEdgeGesture(to: auxiliary)
        
        controller.auxiliaryViews.append(auxiliary)
        
        if let url = navigationAction.request.url,
           url.absoluteString != "about:blank" {
            auxiliary.load(navigationAction.request)
        }
        
        return auxiliary
    }
    
    private func configureAuxiliary(_ auxiliary: WKWebView, within main: WKWebView) {
        auxiliary.translatesAutoresizingMaskIntoConstraints = false
        auxiliary.scrollView.isScrollEnabled = true
        auxiliary.scrollView.minimumZoomScale = 1.0
        auxiliary.scrollView.maximumZoomScale = 1.0
        auxiliary.scrollView.bounces = false
        auxiliary.scrollView.bouncesZoom = false
        auxiliary.allowsBackForwardNavigationGestures = true
        auxiliary.navigationDelegate = self
        auxiliary.uiDelegate = self
        
        main.addSubview(auxiliary)
        
        NSLayoutConstraint.activate([
            auxiliary.leadingAnchor.constraint(equalTo: main.leadingAnchor),
            auxiliary.trailingAnchor.constraint(equalTo: main.trailingAnchor),
            auxiliary.topAnchor.constraint(equalTo: main.topAnchor),
            auxiliary.bottomAnchor.constraint(equalTo: main.bottomAnchor)
        ])
    }
    
    private func attachEdgeGesture(to view: WKWebView) {
        let gesture = UIScreenEdgePanGestureRecognizer(
            target: self,
            action: #selector(handleEdgeSwipe(_:))
        )
        gesture.edges = .left
        view.addGestureRecognizer(gesture)
    }
    
    @objc private func handleEdgeSwipe(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        guard recognizer.state == .ended,
              let view = recognizer.view as? WKWebView else {
            return
        }
        
        if view.canGoBack {
            view.goBack()
        } else if controller?.auxiliaryViews.last === view {
            controller?.performBackNavigation(fallback: nil)
        }
    }
    
    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}


struct SettingsButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.15))
                    .cornerRadius(10)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "2C3E50"))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "7F8C8D"))
            }
            .padding(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

extension ViewHandler: WKNavigationDelegate {
    
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let requestURL = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        lastKnownURL = requestURL
        
        if canNavigate(to: requestURL) {
            decisionHandler(.allow)
        } else {
            openInSystem(requestURL)
            decisionHandler(.cancel)
        }
    }
    
    private func canNavigate(to url: URL) -> Bool {
        let scheme = (url.scheme ?? "").lowercased()
        let urlText = url.absoluteString.lowercased()
        
        let validSchemes: Set<String> = [
            "http", "https", "about", "blob", "data", "javascript", "file"
        ]
        
        let validPrefixes = ["srcdoc", "about:blank", "about:srcdoc"]
        
        return validSchemes.contains(scheme) ||
               validPrefixes.contains { urlText.hasPrefix($0) } ||
               urlText == "about:blank"
    }
    
    private func openInSystem(_ url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    func webView(
        _ webView: WKWebView,
        didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!
    ) {
        redirectCounter += 1
        
        if redirectCounter > redirectThreshold {
            webView.stopLoading()
            
            if let recovery = lastKnownURL {
                webView.load(URLRequest(url: recovery))
            }
            
            redirectCounter = 0
            return
        }
        
        lastKnownURL = webView.url
        controller?.sessionStrategy.save(from: webView)
    }
    
    func webView(
        _ webView: WKWebView,
        didFinish navigation: WKNavigation!
    ) {
        injectOptimizations(into: webView)
    }
    
    private func injectOptimizations(into view: WKWebView) {
        let optimizationScript = """
        (function() {
            const metaTag = document.createElement('meta');
            metaTag.name = 'viewport';
            metaTag.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            document.head.appendChild(metaTag);
            
            const styleTag = document.createElement('style');
            styleTag.textContent = 'body { touch-action: pan-x pan-y; } input, textarea { font-size: 16px !important; }';
            document.head.appendChild(styleTag);
            
            document.addEventListener('gesturestart', e => e.preventDefault());
            document.addEventListener('gesturechange', e => e.preventDefault());
        })();
        """
        
        view.evaluateJavaScript(optimizationScript) { _, error in
            if let error = error {
                print("Optimization injection failed: \(error)")
            }
        }
    }
    
    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        let code = (error as NSError).code
        
        if code == NSURLErrorHTTPTooManyRedirects,
           let recovery = lastKnownURL {
            webView.load(URLRequest(url: recovery))
        }
    }
    
    func webView(
        _ webView: WKWebView,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
