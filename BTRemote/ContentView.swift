import BTHIDKit
import SwiftUI

struct ContentView: View {
    @State private var tab = Tab.setup

    @Environment(\.hid) private var hid
    @StateObject private var directInput = DirectInputController()
    @Environment(\.openURL) private var openURL
    @AppStorage(AppSettings.hasSeenWelcomeKey) private var hasSeenWelcome = false
    @State private var showWelcome = false
    @State private var showGuide = false
    #if os(macOS)
        @State private var showAccessibilityPrompt = false
        @State private var showConnectPrompt = false
    #endif

    private enum Tab {
        case setup, remote, settings
    }

    var body: some View {
        TabView(selection: $tab) {
            SetupView()
                .tabItem { Label(L10n.Tab.setup, systemImage: "gearshape") }
                .tag(Tab.setup)
            RemoteTabView(goToSetup: { tab = .setup })
                .tabItem { Label(L10n.Tab.remote, systemImage: "keyboard") }
                .tag(Tab.remote)
            SettingsView()
                .tabItem { Label(L10n.Tab.settings, systemImage: "slider.horizontal.3") }
                .tag(Tab.settings)
        }
        .environmentObject(directInput)
        #if os(iOS)
            .background(PointerLockHost(locked: directInput.isCapturing))
        #endif
            .onChange(of: hid.isConnected) { connected in
                guard connected else { return }
                #if os(macOS)
                    if !directInput.isCapturing { showConnectPrompt = true }
                #else
                    tab = .remote
                #endif
            }
            .onAppear(perform: _onAppear)
            .alert(L10n.Welcome.title, isPresented: $showWelcome) {
                Button(L10n.Welcome.viewGuide) {
                    hasSeenWelcome = true
                    showGuide = true
                }
                .keyboardShortcut(.defaultAction)
                Button(L10n.Setup.videoInstructions) { openURL(AppSettings.instructionsURL) }
            } message: {
                Text(L10n.Welcome.message)
            }
            .sheet(isPresented: $showGuide) { guideSheet }
        #if os(macOS)
            .frame(minWidth: 480, idealWidth: 560, minHeight: 640, idealHeight: 800)
            .onChange(of: directInput.needsAccessibility) { needs in
                guard needs else { return }
                showAccessibilityPrompt = true
                directInput.clearAccessibilityRequest()
            }
            .alert(L10n.DirectInput.permissionTitle, isPresented: $showAccessibilityPrompt) {
                Button(L10n.DirectInput.openSettings) { AccessibilityPermission.request() }
                Button(L10n.Action.notNow, role: .cancel) {}
            } message: {
                Text(L10n.DirectInput.permissionMessage)
            }
            .alert(L10n.DirectInput.connectedPromptTitle, isPresented: $showConnectPrompt) {
                Button(L10n.DirectInput.enable) { directInput.start(hid) }
                Button(L10n.Action.notNow, role: .cancel) { tab = .remote }
            } message: {
                Text(L10n.DirectInput.connectedPromptMessage)
                    + Text(verbatim: "\n\n")
                    + Text(L10n.DirectInput.releaseHint)
            }
        #endif
    }

    private func _onAppear() {
        if !hasSeenWelcome {
            showWelcome = true
        }
        #if os(macOS)
            if hasSeenWelcome, !AccessibilityPermission.isTrusted { showAccessibilityPrompt = true }
        #endif
    }

    private var guideSheet: some View {
        #if os(macOS)
            NavigationStack { guideSheetContent }
                .frame(minWidth: 420, minHeight: 520)
        #else
            NavigationView { guideSheetContent }
                .navigationViewStyle(.stack)
        #endif
    }

    private var guideSheetContent: some View {
        GuideView(transport: .lowEnergy)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Action.done) { showGuide = false }
                }
            }
    }
}

#if DEBUG
    #Preview {
        #if os(iOS)
            ContentView()
                .environmentObject(HIDPeripheral(profile: Combo()))
                .environmentObject(HIDCentral())
                .environmentObject(DeviceNameStore())
        #else
            ContentView()
                .environmentObject(HIDPeripheral(profile: Combo()))
                .environmentObject(HIDCentral())
                .environmentObject(DeviceNameStore())
                .environmentObject(HIDClassicDevice(profile: Combo()))
        #endif
    }
#endif
