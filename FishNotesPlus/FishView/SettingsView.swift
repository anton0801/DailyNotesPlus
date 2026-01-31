import SwiftUI
import WebKit
import Combine
import StoreKit

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

struct SettingsView: View {
    @EnvironmentObject var notesViewModel: NotesViewModel
    @EnvironmentObject var gearViewModel: GearViewModel
    @EnvironmentObject var checklistViewModel: ChecklistViewModel
    
    @AppStorage("selectedLanguage") private var selectedLanguage = "en"
    @AppStorage("textSize") private var textSize: Double = 16
    @AppStorage("appTheme") private var appTheme = "dark"
    
    @State private var showingExportSheet = false
    @State private var showingResetAlert = false
    @State private var showingBackupSheet = false
    @State private var showingAboutSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // App info card
                        appInfoCard
                        
                        // Statistics card
                        statisticsCard
                        
                        // Preferences section
                        preferencesSection
                        
                        // Data management section
                        dataManagementSection
                        
                        // About section
                        aboutSection
                        
                        // Version info
                        versionInfo
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportView()
                .environmentObject(notesViewModel)
        }
        .sheet(isPresented: $showingBackupSheet) {
            BackupView()
                .environmentObject(notesViewModel)
                .environmentObject(gearViewModel)
                .environmentObject(checklistViewModel)
        }
        .sheet(isPresented: $showingAboutSheet) {
            AboutView()
        }
        .alert(isPresented: $showingResetAlert) {
            Alert(
                title: Text("Reset All Data"),
                message: Text("This will delete all notes, gear, and checklists permanently. This action cannot be undone."),
                primaryButton: .destructive(Text("Reset Everything")) {
                    resetAllData()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // MARK: - App Info Card
    private var appInfoCard: some View {
        VStack(spacing: 20) {
            // App icon with glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppTheme.primaryAccent.opacity(0.4),
                                AppTheme.primaryAccent.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)
                
                Circle()
                    .fill(AppTheme.surface)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(AppTheme.primaryAccent.opacity(0.5), lineWidth: 3)
                    )
                    .shadow(color: AppTheme.primaryAccent.opacity(0.4), radius: 20, x: 0, y: 10)
                
                Image(systemName: "book.fill")
                    .font(.system(size: 45))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.primaryAccent, AppTheme.secondaryAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Image(systemName: "fish.fill")
                            .font(.system(size: 18))
                            .foregroundColor(AppTheme.secondaryAccent)
                            .offset(x: 20, y: -15)
                    )
            }
            
            VStack(spacing: 8) {
                Text("Daily Notes Master")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.textPrimary, AppTheme.primaryAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Dark Waters Edition")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(AppTheme.textSecondary)
                    .tracking(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(AppTheme.primaryAccent.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Statistics Card
    private var statisticsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Statistics")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                StatMiniCard(
                    icon: "note.text",
                    value: "\(notesViewModel.notes.count)",
                    label: "Notes",
                    color: AppTheme.primaryAccent
                )
                
                StatMiniCard(
                    icon: "figure.fishing",
                    value: "\(gearViewModel.gearItems.count)",
                    label: "Gear",
                    color: AppTheme.secondaryAccent
                )
                
                StatMiniCard(
                    icon: "checklist",
                    value: "\(checklistViewModel.checklists.count)",
                    label: "Lists",
                    color: AppTheme.success
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.primaryAccent.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Preferences Section
    private var preferencesSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Preferences", icon: "slider.horizontal.3")
            
            VStack(spacing: 0) {
//                SettingsToggleRow(
//                    icon: "globe",
//                    title: "Language",
//                    value: selectedLanguage == "en" ? "English" : "Русский",
//                    color: AppTheme.primaryAccent
//                ) {
//                    selectedLanguage = selectedLanguage == "en" ? "ru" : "en"
//                }
//                
//                Divider()
//                    .background(AppTheme.cardHighlight)
//                    .padding(.leading, 60)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "textformat.size")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.secondaryAccent)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(AppTheme.secondaryAccent.opacity(0.2))
                            )
                        
                        Text("Text Size")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Spacer()
                        
                        Text("\(Int(textSize))pt")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppTheme.secondaryAccent)
                    }
                    
                    Slider(value: $textSize, in: 12...24, step: 2)
                        .accentColor(AppTheme.secondaryAccent)
                }
                .padding(16)
                
                Divider()
                    .background(AppTheme.cardHighlight)
                    .padding(.leading, 60)
                
                SettingsToggleRow(
                    icon: "moon.stars.fill",
                    title: "Theme",
                    value: "Dark Waters",
                    color: Color(hex: "FF6B35")
                ) {
                    // Theme is always dark
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.primaryAccent.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            )
        }
    }
    
    // MARK: - Data Management Section
    private var dataManagementSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Data Management", icon: "externaldrive.fill")
            
            VStack(spacing: 12) {
                SettingsActionButton(
                    icon: "square.and.arrow.up",
                    title: "Export Notes",
                    description: "Save your notes as TXT or CSV",
                    color: AppTheme.primaryAccent
                ) {
                    showingExportSheet = true
                }
                
//                SettingsActionButton(
//                    icon: "arrow.clockwise",
//                    title: "Backup & Restore",
//                    description: "Create local backup of all data",
//                    color: AppTheme.success
//                ) {
//                    showingBackupSheet = true
//                }
                
                SettingsActionButton(
                    icon: "trash.fill",
                    title: "Reset All Data",
                    description: "Delete everything permanently",
                    color: AppTheme.danger
                ) {
                    showingResetAlert = true
                }
            }
        }
    }
    
    @Environment(\.requestReview) var requestReview
    
    private var aboutSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "About", icon: "info.circle.fill")
            
            VStack(spacing: 12) {
                SettingsActionButton(
                    icon: "hand.raised.fill",
                    title: "Privacy Policy",
                    description: "How we protect your data",
                    color: AppTheme.primaryAccent
                ) {
                    UIApplication.shared.open(URL(string: "https://dailynotesplus.com/privacy-policy.html")!)

                }
                
                SettingsActionButton(
                    icon: "questionmark.circle.fill",
                    title: "About This App",
                    description: "Learn more about Daily Notes Plus",
                    color: AppTheme.secondaryAccent
                ) {
                    showingAboutSheet = true
                }
                
                SettingsActionButton(
                    icon: "star.fill",
                    title: "Rate This App",
                    description: "Share your feedback",
                    color: Color(hex: "FF6B35")
                ) {
                    requestReview()
                }
            }
        }
    }
    
    // MARK: - Version Info
    private var versionInfo: some View {
        VStack(spacing: 8) {
            Text("Daily Notes Master")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.textSecondary)
            
            Text("Version 1.0.0 (Dark Waters)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.textDisabled)
            
            Text("Made with ❤️ for anglers")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.textDisabled)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private func resetAllData() {
        // Delete all notes
        for note in notesViewModel.notes {
            notesViewModel.deleteNote(note)
        }
        
        // Delete all gear
        for gear in gearViewModel.gearItems {
            gearViewModel.deleteGearItem(gear)
        }
        
        // Delete all checklists
        for checklist in checklistViewModel.checklists {
            checklistViewModel.deleteChecklist(checklist)
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(AppTheme.primaryAccent)
            
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            
            Spacer()
        }
    }
}

// MARK: - Stat Mini Card
struct StatMiniCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.cardHighlight)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Settings Toggle Row
struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(color.opacity(0.2))
                    )
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.textDisabled)
            }
            .padding(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Settings Action Button
struct SettingsActionButton: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(color.opacity(0.2))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text(description)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.textDisabled)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            AppTheme.primaryAccent.opacity(0.4),
                                            AppTheme.primaryAccent.opacity(0.2),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 100
                                    )
                                )
                                .frame(width: 200, height: 200)
                                .blur(radius: 30)
                            
                            Image(systemName: "book.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [AppTheme.primaryAccent, AppTheme.secondaryAccent],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: AppTheme.primaryAccent.opacity(0.5), radius: 20, x: 0, y: 10)
                        }
                        .padding(.top, 40)
                        
                        VStack(spacing: 16) {
                            Text("Daily Notes Master")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                            
                            Text("Your ultimate fishing journal companion")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        VStack(alignment: .leading, spacing: 20) {
                            FeatureRow(
                                icon: "note.text",
                                title: "Comprehensive Notes",
                                description: "Document every detail of your fishing experiences with photos and metadata"
                            )
                            
                            FeatureRow(
                                icon: "figure.fishing",
                                title: "Gear Management",
                                description: "Track your fishing gear with effectiveness ratings and usage statistics"
                            )
                            
                            FeatureRow(
                                icon: "checklist",
                                title: "Smart Checklists",
                                description: "Never forget essential equipment with customizable checklists"
                            )
                            
                            FeatureRow(
                                icon: "chart.bar.fill",
                                title: "Insights & Analytics",
                                description: "Analyze your fishing patterns with detailed statistics and trends"
                            )
                            
                            FeatureRow(
                                icon: "lock.shield.fill",
                                title: "Privacy First",
                                description: "Your data stays on your device and in your Firebase account"
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        VStack(spacing: 12) {
                            Text("Dark Waters Edition")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(AppTheme.primaryAccent)
                            
                            Text("Version 1.0.0")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                            
                            Text("© 2024 Daily Notes Plus")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppTheme.textDisabled)
                                .padding(.top, 8)
                        }
                        .padding(.vertical, 32)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppTheme.primaryAccent)
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(AppTheme.primaryAccent)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(AppTheme.primaryAccent.opacity(0.2))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(NotesViewModel())
        .environmentObject(GearViewModel())
        .environmentObject(ChecklistViewModel())
}
