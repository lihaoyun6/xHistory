//
//  SettingsView.swift
//  xHistory
//
//  Created by apple on 2024/11/6.
//

import SwiftUI
import ServiceManagement
import KeyboardShortcuts
import MatrixColorSelector

struct SettingsView: View {
    @State private var selectedItem: String? = "General"
    
    var body: some View {
        NavigationView {
            List(selection: $selectedItem) {
                NavigationLink(destination: GeneralView(), tag: "General", selection: $selectedItem) {
                    Label("General", image: "gear")
                }
                NavigationLink(destination: HistoryView(), tag: "History", selection: $selectedItem) {
                    Label("History", image: "history")
                }
                NavigationLink(destination: HotkeyView(), tag: "Hotkey", selection: $selectedItem) {
                    Label("Hotkey", image: "hotkey")
                }
                NavigationLink(destination: ShellView(), tag: "Shell", selection: $selectedItem) {
                    Label("Shell", image: "shell")
                }
                NavigationLink(destination: CloudView(), tag: "Cloud", selection: $selectedItem) {
                    Label("Cloud", image: "cloud")
                }
                NavigationLink(destination: BlacklistView(), tag: "Blacklist", selection: $selectedItem) {
                    Label("Blacklist", image: "block")
                }
            }
            .listStyle(.sidebar)
            .padding(.top, 9)
        }
        .frame(width: 600, height: 442)
        .navigationTitle("xHistory Settings")
    }
}

struct GeneralView: View {
    @AppStorage("panelOpacity") var panelOpacity = 100
    @AppStorage("statusBar") var statusBar = true
    //@AppStorage("dockIcon") var dockIcon = false
    @AppStorage("statusIconName") var statusIconName = "menuBar"
    
    @State private var showStatusBar = true
    @State private var launchAtLogin = false
    
    var body: some View {
        SForm {
            SGroupBox(label: "General") {
                if #available(macOS 13, *) {
                    SToggle("Launch at Login", isOn: $launchAtLogin)
                        .onAppear{ launchAtLogin = (SMAppService.mainApp.status == .enabled) }
                        .onChange(of: launchAtLogin) { newValue in
                            do {
                                if newValue {
                                    try SMAppService.mainApp.register()
                                } else {
                                    try SMAppService.mainApp.unregister()
                                }
                            }catch{
                                print("Failed to \(newValue ? "enable" : "disable") launch at login: \(error.localizedDescription)")
                            }
                        }
                    SDivider()
                }
                SToggle("Show Menu bar Icon", isOn: $statusBar)
                SDivider()
                if showStatusBar {
                    SItem(label: "Menu Bar Icon") {
                        HStack {
                            Button(action: {
                                if let button = statusBarItem.button {
                                    statusIconName = "menuBarInvert"
                                    button.image = NSImage(named: statusIconName)
                                }
                            }, label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .foregroundStyle(statusIconName == "menuBarInvert" ? .blue : .clear)
                                    Image("menuBarInvert")
                                        .offset(x: 0.5, y: 0.5)
                                        .foregroundStyle(statusIconName == "menuBarInvert" ? .white : .secondary)
                                }.frame(width: 24, height: 24)
                            }).buttonStyle(.plain)
                            Button(action: {
                                if let button = statusBarItem.button {
                                    statusIconName = "menuBar"
                                    button.image = NSImage(named: statusIconName)
                                }
                            }, label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .foregroundStyle(statusIconName == "menuBar" ? .blue : .clear)
                                    Image("menuBar")
                                        .offset(x: 0.5, y: 0.5)
                                        .foregroundStyle(statusIconName == "menuBar" ? .white : .secondary)
                                }.frame(width: 24, height: 24)
                            }).buttonStyle(.plain)
                        }
                    }
                    SDivider()
                }
                //SToggle("Show Dock Icon", isOn: $dockIcon)
                //SDivider()
                HStack {
                    SSlider(label: "History Panel Opacity", value: $panelOpacity, range: 10...100, width: 160)
                    Text("\(panelOpacity)%").frame(width: 35)
                }
            }
            SGroupBox(label: "Update") { UpdaterSettingsView(updater: updaterController.updater) }
            VStack(spacing: 8) {
                HStack {
                    CheckForUpdatesView(updater: updaterController.updater)
                    if !statusBar {
                        Button(action: {
                            NSApp.terminate(self)
                        }, label: {
                            Text("Quit".local + " xHistory").foregroundStyle(.red)
                        })
                    }
                }
                if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    Text("xHistory v\(appVersion)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear { showStatusBar = statusBar }
        .onChange(of: statusBar) { newValue in
            showStatusBar = newValue
            statusBarItem.isVisible = newValue
        }
        /*.onChange(of: dockIcon) { newValue in
            if newValue {
                NSApp.setActivationPolicy(.regular)
            } else {
                NSApp.setActivationPolicy(.accessory)
            }
        }*/
    }
}

struct HistoryView: View {
    @AppStorage("historyFile") var historyFile = "~/.bash_history"
    @AppStorage("autoClose") var autoClose = false
    @AppStorage("autoSpace") var autoSpace = false
    @AppStorage("noSameLine") var noSameLine = true
    @AppStorage("highlighting") var highlighting = true
    @AppStorage("autoReturn") var autoReturn = false
    
    @State private var userPath: String = ""
    @State private var disabled: Bool = false
    @State private var styleChanged: Bool = false
    @State private var functionColor: Color = ud.color(forKey: "functionColor") ?? Color(nsColor: .systemOrange)
    @State private var keywordColor: Color = ud.color(forKey: "keywordColor") ?? Color(nsColor: .systemPink)
    @State private var stringColor: Color = ud.color(forKey: "stringColor") ?? Color(nsColor: .systemGreen)
    @State private var propertyColor: Color = ud.color(forKey: "propertyColor") ?? Color(nsColor: .systemBlue)
    @State private var operatorColor: Color = ud.color(forKey: "operatorColor") ?? Color(nsColor: .systemGray)
    @State private var constantColor: Color = ud.color(forKey: "constantColor") ?? Color(nsColor: .systemMint)
    @State private var numberColor: Color = ud.color(forKey: "numberColor") ?? Color(nsColor: .red)
    @State private var embeddedColor: Color = ud.color(forKey: "embeddedColor") ?? Color(nsColor: .systemPurple)
    
    var body: some View {
        SForm {
            SGroupBox(label: "History") {
                SPicker("Read History From", selection: $historyFile) {
                    Text("Zsh").tag("~/.zsh_history")
                    Text("Bash").tag("~/.bash_history")
                    if historyFile != "~/.bash_history" && historyFile != "~/.zsh_history" {
                        Text("Custom").tag(historyFile)
                    } else {
                        Text("Custom").tag(historyFile.absolutePath)
                    }
                }.onChange(of: historyFile) { newValue in
                    HistoryCopyer.shared.updateHistory()
                    for cmd in HistoryCopyer.shared.historys {
                        SyntaxHighlighter.shared.getHighlightedTextAsync(for: cmd) { _ in }
                    }
                    queue?.removeAllURLs()
                    DispatchQueue.main.async {
                        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { (timer) in
                            if queue?.numberOfWatchedURLs() == 0 {
                                timer.invalidate()
                                _ = queue?.addURL(historyFile.absolutePath.url)
                            }
                        }
                    }
                }
                SDivider()
                if historyFile != "~/.bash_history" && historyFile != "~/.zsh_history" {
                    HStack {
                        SField("Custom History File Path", text: $userPath)
                        Button("Save") { historyFile = userPath }
                    }
                    SDivider()
                }
                SToggle("Merge adjacent duplicates", isOn: $noSameLine)
                SDivider()
                SToggle("Close history panel after filling", isOn: $autoClose)
                SDivider()
                SToggle("Auto-press Return after filling", isOn: $autoReturn)
                SDivider()
                SToggle("Add trailing space when filling", isOn: $autoSpace)
            }
            SGroupBox(label: "Highlight") {
                SToggle("Syntax Highlighting", isOn: $highlighting)
                SDivider()
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Highlight Color Scheme")
                        Text("Hover over a color to see more information and click to modify it.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(action: {
                        functionColor = Color(nsColor: .systemOrange)
                        keywordColor = Color(nsColor: .systemPink)
                        stringColor = Color(nsColor: .systemGreen)
                        propertyColor = Color(nsColor: .systemBlue)
                        operatorColor = Color(nsColor: .systemGray)
                        constantColor = Color(nsColor: .systemMint)
                        numberColor = Color(nsColor: .red)
                        embeddedColor = Color(nsColor: .systemPurple)
                    }, label: {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.secondary)
                    })
                    .buttonStyle(.plain)
                    .help("Reset Color Scheme")
                    Button("Save") { HistoryCopyer.shared.reHighlight() }
                }.disabled(!highlighting)
                HStack {
                    CS(tips: "The color of keywords in the code", name: "keywordColor", selection: $keywordColor, styleChanged: $styleChanged)
                    CS(tips: "The color of functions in the code", name: "functionColor", selection: $functionColor, styleChanged: $styleChanged)
                    CS(tips: "The color of constants in the code", name: "constantColor", selection: $constantColor, styleChanged: $styleChanged)
                    CS(tips: "The color of properties in the code", name: "propertyColor", selection: $propertyColor, styleChanged: $styleChanged)
                    CS(tips: "The color of operators in the code", name: "operatorColor", selection: $operatorColor, styleChanged: $styleChanged)
                    CS(tips: "The color of strings in the code", name: "stringColor", selection: $stringColor, styleChanged: $styleChanged)
                    CS(tips: "The color of embedded code in the code", name: "embeddedColor", selection: $embeddedColor, styleChanged: $styleChanged)
                    CS(tips: "The color of numbers in the code", name: "numberColor", selection: $numberColor, styleChanged: $styleChanged)
                }
                .frame(height: 16)
                .padding(.bottom, 3)
                .disabled(disabled)
            }
        }
        .onAppear { userPath = historyFile }
        .onChange(of: historyFile) { newValue in userPath = newValue }
        .onChange(of: highlighting) { newValue in
            disabled = !newValue
            HistoryCopyer.shared.reHighlight()
        }
    }
}

struct HotkeyView: View {
    @State var hotKey1: String = "⌘←  /  ⌘→"
    @State var hotKey2: String = "⌃1"
    @State var hotKey3: String = "⌃2"
    @State var hotKey4: String = "⌃3"
    
    var body: some View {
        SForm(spacing: 10) {
            SGroupBox(label: "Hotkey") {
                SItem(label: "Open History Panel") { KeyboardShortcuts.Recorder("", name: .showPanel) }
                SDivider()
                SItem(label: "Open panel and show pinned history") { KeyboardShortcuts.Recorder("", name: .showPinnedPanel) }
                SDivider()
                SItem(label: "Open History Panel as Overlay") {
                    HStack(spacing: -5) {
                        SInfoButton(tips: "xHistory will detect the current frontmost window and open a floating panel of the same size on top of it.")
                        KeyboardShortcuts.Recorder("", name: .showOverlay)
                    }
                }
                SDivider()
                SItem(label: "Open overlay and show pinned history") {
                    HStack(spacing: -5) {
                        SInfoButton(tips: "xHistory will detect the current frontmost window and open a floating panel of the same size on top of it.")
                        KeyboardShortcuts.Recorder("", name: .showPinnedOverlay)
                    }
                }
            }
            SGroupBox {
                SItem(label: "Switch to \"History\" page") {
                    TextField("", text: $hotKey2)
                        .disabled(true)
                        .frame(width: 128)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.center)
                }
                SDivider()
                SItem(label: "Switch to \"Pinned\" page") {
                    TextField("", text: $hotKey3)
                        .disabled(true)
                        .frame(width: 128)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.center)
                }
                SDivider()
                SItem(label: "Switch to \"Archive\" page") {
                    TextField("", text: $hotKey4)
                        .disabled(true)
                        .frame(width: 128)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.center)
                }
                SDivider()
                SItem(label: "Swap action button positions") {
                    HStack(spacing: 5) {
                        SInfoButton(tips: "Put \"Copy\", \"Pin\" and \"Expand\" buttons on the other side of history items.\nThis is useful for full screen or very long window.")
                        //KeyboardShortcuts.Recorder("", name: .swapButtons)
                        TextField("", text: $hotKey1)
                            .disabled(true)
                            .frame(width: 128)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
    }
}

struct ShellView: View {
    @State private var cltInstalled: Bool = false
    @AppStorage("customShellConfig") var customShellConfig = true
    @AppStorage("historyLimit") var historyLimit = 1000
    @AppStorage("noDuplicates") var noDuplicates = true
    @AppStorage("realtimeSave") var realtimeSave = true
    @AppStorage("preFormatter") var preFormatter = ""
    @State private var disabled: Bool = false
    @State private var userFormatter = ""
    
    var body: some View {
        SForm(spacing: 10) {
            GroupBox(label:
            VStack(alignment: .leading) {
                Text("Shell Configuration").font(.headline)
                Text("These settings will only take effect in newly logged-in shells when you modify them.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            ) {
                VStack(spacing: 10) {
                    SToggle("Custom Configuration (for Bash & Zsh)", isOn: $customShellConfig)
                    SDivider()
                    Group {
                        SToggle("Real-time History Saving", isOn: $realtimeSave)
                        SDivider()
                        SToggle("Ignore Consecutive Duplicates", isOn: $noDuplicates)
                        SDivider()
                        SSteper("Maximum Number of History Items", value: $historyLimit, min: 1, max: 10000, width: 60)
                    }.disabled(disabled)
                }.padding(5)
            }
            SGroupBox {
                HStack(spacing: 4) {
                    SField("Preformatter", placeholder: "Enter regular expression here", text: $userFormatter)
                    SInfoButton(tips: "You can use regular expressions to match each line of history.\nxHistory will only show you the content in the matching groups.")
                    Button("Save") { preFormatter = userFormatter }
                }
            }
            SGroupBox {
                SButton("Command Line Tool", buttonTitle: cltInstalled ? "Uninstall" : "Install",
                        tips: "After installation, you can run \"xhistory\" in yor terminal to quickly open the floating panel.") {
                    if cltInstalled {
                        CommandLineTool.uninstall { updateCTL() }
                    } else {
                        CommandLineTool.install { updateCTL() }
                    }
                }.onAppear { cltInstalled = CommandLineTool.isInstalled() }
            }
        }
        .onAppear { userFormatter = preFormatter }
        .onChange(of: preFormatter) { _ in HistoryCopyer.shared.reHighlight() }
        .onChange(of: customShellConfig) { newValue in
            disabled = !newValue
            updateShellConfig()
        }
        .onChange(of: realtimeSave) { _ in updateShellConfig() }
        .onChange(of: noDuplicates) { _ in updateShellConfig() }
        .onChange(of: historyLimit) { _ in updateShellConfig() }
    }
    
    func updateCTL() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            cltInstalled = CommandLineTool.isInstalled()
        }
    }
}

struct CloudView: View {
    @AppStorage("cloudSync") var cloudSync = false
    @AppStorage("cloudDirectory") var cloudDirectory = ""
    @StateObject private var state = PageState.shared
    
    var body: some View {
        SForm(spacing: 10, noSpacer: true) {
            SGroupBox(label: "Cloud") {
                SToggle("Cloud Archiving", isOn: $cloudSync)
                SDivider()
                SItem(label: "Archive Folder", spacing: 4) {
                    Text(cloudDirectory)
                        .font(.footnote)
                        .foregroundColor(Color.secondary)
                        .lineLimit(1)
                        .truncationMode(.head)
                    SInfoButton(tips: "Select a folder in iCloud Drive to store and sync history across multiple devices.")
                    Button("Select...", action: { updateCloudDirectory() })
                }
            }
            GroupBox(label:
                        HStack(spacing: 5) {
                Text("Archives").font(.headline)
                Button(action: {
                    state.archiveList = getCloudFiles()
                }, label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary)
                }).buttonStyle(.plain)
            }) {
                VStack(spacing: 10) {
                    ScrollView(showsIndicators: true) {
                        ForEach(state.archiveList.indices, id: \.self) { index in
                            HStack {
                                Text(state.archiveList[index])
                                Spacer()
                                ConfirmButton(label: "Delete", title: "Delete This Archive?", confirmButton: "Delete") {
                                    if state.archiveList[index] == state.archiveName {
                                        state.archiveName = ""
                                        state.archiveData.removeAll()
                                    }
                                    let archiveURL = cloudDirectory.url.appendingPathComponent("\(state.archiveList[index]).xha")
                                    try? fd.removeItem(at: archiveURL)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { state.archiveList = getCloudFiles() }
                                }
                            }
                            .frame(height: 12)
                            .padding(.vertical, 4)
                            SDivider()
                        }
                    }.frame(maxWidth: .infinity)
                }.padding(5)
            }
        }
        .onAppear { state.archiveList = getCloudFiles() }
        .onChange(of: cloudSync) { _ in state.archiveList = getCloudFiles() }
    }
    
    func updateCloudDirectory() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.allowedContentTypes = []
        openPanel.allowsOtherFileTypes = false
        if openPanel.runModal() == NSApplication.ModalResponse.OK {
            if let path = openPanel.urls.first?.path { cloudDirectory = path }
        }
    }
}

struct ConfirmButton: View {
    var label: LocalizedStringKey
    var title: LocalizedStringKey = "Are you sure?"
    var confirmButton: LocalizedStringKey = "Confirm"
    var message: LocalizedStringKey = "You will not be able to recover it!"
    var action: () -> Void
    @State private var showAlert = false
    
    var body: some View {
        Button(action: {
            showAlert = true
        }, label: {
            Text(label).foregroundStyle(.red)
        }).alert(title, isPresented: $showAlert) {
            Button(confirmButton, role: .destructive) { action() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(message)
        }
    }
}

struct BlacklistView: View {
    @State private var blockedItems = [String]()
    @State private var temp = ""
    @State private var showSheet = false
    @State private var editingIndex: Int?
    
    var body: some View {
        VStack {
            GroupBox(label:
                        VStack(alignment: .leading) {
                Text("Blacklist").font(.headline)
                Text("The following commands will be ignored from the history")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            ) {
                VStack(spacing: 10) {
                    ZStack(alignment: Alignment(horizontal: .trailing, vertical: .bottom)) {
                        List {
                            ForEach(blockedItems.indices, id: \.self) { index in
                                HStack {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.red)
                                        .onTapGesture { if editingIndex == nil { blockedItems.remove(at: index) } }
                                    Text(blockedItems[index])
                                }
                            }
                        }
                        Button(action: {
                            showSheet = true
                        }) {
                            Image(systemName: "plus.square.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .sheet(isPresented: $showSheet){
                            VStack {
                                TextField("Enter Command".local, text: $temp).frame(width: 300)
                                HStack(spacing: 20) {
                                    Button {
                                        if temp == "" { return }
                                        if !blockedItems.contains(temp) { blockedItems.append(temp) }
                                        temp = ""
                                        showSheet = false
                                    } label: {
                                        Text("Add to List").frame(width: 80)
                                    }.keyboardShortcut(.defaultAction)
                                    Button {
                                        showSheet = false
                                    } label: {
                                        Text("Cancel").frame(width: 80)
                                    }
                                }.padding(.top, 10)
                            }.padding()
                        }
                    }
                    Text("You can add a \"#\" at the beginning of a keyword to convert it to a regex pattern")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(5)
                .onAppear { blockedItems = (ud.object(forKey: "blockedCommands") as? [String]) ?? [] }
                .onChange(of: blockedItems) {
                    b in ud.setValue(b, forKey: "blockedCommands")
                    HistoryCopyer.shared.updateHistory()
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

func getCloudFiles() -> [String] {
    @AppStorage("cloudDirectory") var cloudDirectory = ""
    var result = [String]()
    
    let contents = try? fd.contentsOfDirectory(atPath: cloudDirectory)
    result = contents?.filter { $0.hasSuffix(".\(cloudFileExtension)") }.map { $0.deletingPathExtension }  ?? []
    
    return result
}

struct CS: View {
    var tips: LocalizedStringKey
    var name: String
    @Binding var selection: Color
    @Binding var styleChanged: Bool
    
    var body: some View {
        HStack {
            if #unavailable(macOS 13) {
                ColorPicker("", selection: $selection).frame(width: 43)
            } else {
                MatrixColorSelector("", selection: $selection)
            }
        }
        .help(tips)
        .onChange(of: selection) { userColor in ud.setColor(userColor, forKey: name); styleChanged = true }
    }
}

struct FlowLayout<Content: View>: View {
    var items: [String]
    var spacing: CGFloat
    var content: (String) -> Content

    @State private var totalHeight = CGFloat.zero // Track total height of the layout

    var body: some View {
        VStack {
            GeometryReader { geometry in
                self.generateContent(in: geometry)
            }
        }
        .frame(height: totalHeight) // Set the total height dynamically
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        var lastHeight = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(items.indices, id: \.self) { index in
                content(items[index])
                    .alignmentGuide(.leading) { dimension in
                        if (abs(width - dimension.width) > geometry.size.width) {
                            width = 0 // Move to the next line'
                            height -= lastHeight + spacing
                        }
                        lastHeight = dimension.height // 记录当前元素的高度
                        let result = width
                        if items[index] == items.last! { // Last item
                            width = 0 // Reset width
                        } else {
                            width -= dimension.width + spacing
                        }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if items[index] == items.last! { // 最后一个元素，重置宽度和高度
                            width = 0
                            height = 0
                        }
                        return result
                    }
            }
        }.background(viewHeightReader($totalHeight)) // Capture total height of the layout
    }

    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geometry -> Color in
            DispatchQueue.main.async {
                binding.wrappedValue = geometry.size.height
            }
            return Color.clear
        }
    }
}

extension KeyboardShortcuts.Name {
    static let showPanel = Self("showPanel")
    static let showPinnedPanel = Self("showPinnedPanel")
    static let showOverlay = Self("showOverlay")
    static let showPinnedOverlay = Self("showPinnedOverlay")
    //static let swapButtons = Self("switchButtons")
}

extension UserDefaults {
    func setColor(_ color: Color?, forKey key: String) {
        guard let color = color else {
            removeObject(forKey: key)
            return
        }
        
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: NSColor(color), requiringSecureCoding: false)
            set(data, forKey: key)
        } catch {
            print("Error archiving color:", error)
        }
    }
    
    func color(forKey key: String) -> Color? {
        guard let data = data(forKey: key),
              let nsColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data) else {
            return nil
        }
        return Color(nsColor)
    }
    
    func nsColor(forKey key: String) -> NSColor? {
        guard let data = data(forKey: key),
              let nsColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data) else {
            return nil
        }
        return nsColor
    }
    
    func cgColor(forKey key: String) -> CGColor? { return self.nsColor(forKey: key)?.cgColor }
}
