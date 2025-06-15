//
//  ContentView.swift
//  xHistory
//
//  Created by apple on 2024/11/5.
//

import Carbon
import SwiftUI

class PageState: ObservableObject {
    static let shared = PageState()
    @Published var pageID: Int = 1
    @Published var archiveList: [String] = []
    @Published var archiveName: String = ""
    @Published var archiveData: [String] = []
}

struct SearchGroup: View {
    @Binding var keyWord: String
    @Binding var regexSearch: Bool
    @Binding var caseSensitivity: Bool
    
    var body: some View {
        HStack(spacing: 5) {
            Button(action: {
                regexSearch.toggle()
            }, label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(regexSearch ? .blue : .secondary.opacity(0.8), lineWidth: 1.5)
                        .frame(width: 18, height: 18)
                    HStack(alignment: .bottom, spacing: 1) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 2, weight: .medium))
                        Image(systemName: "asterisk")
                            .font(.system(size: 7, weight: .black))
                            .padding(.bottom, 1)
                    }
                    .foregroundStyle(regexSearch ? .blue : .secondary.opacity(0.8))
                    .offset(x: 0.5, y: -1)
                }
                .frame(width: 18, height: 18)
                .background(Color.white.opacity(0.0001))
                
            })
            .buttonStyle(.plain)
            .focusable(false)
            .help("Regular expression")
            Button(action: {
                caseSensitivity.toggle()
            }, label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(caseSensitivity ? .blue : .secondary.opacity(0.8), lineWidth: 1.5)
                        .frame(width: 18, height: 18)
                    Image("textformat")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14)
                        .offset(y: -0.5)
                        .foregroundStyle(caseSensitivity ? .blue : .secondary.opacity(0.8))
                }
                .frame(width: 18, height: 18)
                .background(Color.white.opacity(0.001))
            })
            .buttonStyle(.plain)
            .focusable(false)
            .offset(x: 1)
            .help("Case sensitive")
            SearchField(search: $keyWord).frame(height: 21)
        }.frame(height: 16)
    }
}

struct ButtonGroup: View {
    var body: some View {
        HStack(spacing: 6) {
            HoverButton(
                color: .secondary.opacity(0.8),
                action: {
                    mainPanel.close()
                    openAboutPanel()
                },
                label: { Image(systemName: "info.circle.fill") }
            )
            HoverButton(
                color: .secondary.opacity(0.8),
                action: { openSettingPanel() },
                label: { Image(systemName: "gearshape.fill") }
            )
        }.focusable(false)
    }
}

struct ContentView: View {
    @AppStorage("historyFile") var historyFile = "~/.bash_history"
    @AppStorage("panelOpacity") var panelOpacity = 100
    //@AppStorage("showPinned") var showPinned = false
    @AppStorage("caseSensitivity") var caseSensitivity = false
    @AppStorage("regexSearch") var regexSearch = false
    @AppStorage("cloudSync") var cloudSync = false
    @AppStorage("cloudDirectory") var cloudDirectory = ""
    @AppStorage("buttonSide") var buttonSide = "right"

    @StateObject private var data = HistoryCopyer.shared
    @StateObject private var state = PageState.shared
    
    //@State private var newPanel = false
    @State private var scrollToTop = false
    @State private var keyWord: String = ""
    //@State private var archive: String = ""
    //@State private var archiveData: [String] = []
    //@State private var showPin = 0
    @State private var overQuit: Bool = false
    @State private var result: [String] = []
    @State private var resultP: [String] = []
    @State private var resultA: [String] = []
    @State private var pinnedList = (ud.object(forKey: "pinnedList") ?? []) as! [String]
    //@State private var archiveList = getCloudFiles()
    
    var fromMenubar: Bool = false
    
    var body: some View {
        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .top)) {
            ZStack {
                Button("") { if buttonSide == "right" { buttonSide = "left" } }
                    .keyboardShortcut(.leftArrow, modifiers: [.command])
                Button("") { if buttonSide == "left" { buttonSide = "right" } }
                    .keyboardShortcut(.rightArrow, modifiers: [.command])
            }.opacity(0)
            if !fromMenubar {
                Color.clear
                    .background(.thinMaterial)
                    .environment(\.controlActiveState, .active)
                    .opacity(Double(panelOpacity) / 100)
            }
            VStack {
                HStack(spacing: 5) {
                    if fromMenubar {
                        Button(action: {
                            NSApp.terminate(self)
                        }, label: {
                            Text("Quit")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 26, height: 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 4.5, style: .continuous)
                                        .fill(overQuit ? .buttonRed.opacity(0.8) : .buttonRed)
                                )
                        })
                        .buttonStyle(.plain)
                        .padding(.leading, 1)
                        .focusable(false)
                        .onHover { hovering in overQuit = hovering }
                        Spacer()
                        Picker("", selection: $state.pageID) {
                            Text("History").tag(1).keyboardShortcut("1", modifiers: [.control])
                            Text("Pinned").tag(2).keyboardShortcut("2", modifiers: [.control])
                            if cloudSync { Text("Cloud").tag(3).keyboardShortcut("3", modifiers: [.control]) }
                        }
                        .pickerStyle(.segmented)
                        .fixedSize()
                        .focusable(false)
                        Spacer()
                        ButtonGroup().offset(y: -1)
                    } else {
                        Group {
                            Picker("", selection: $state.pageID) {
                                Text("History").tag(1).keyboardShortcut("1", modifiers: [.control])
                                Text("Pinned").tag(2).keyboardShortcut("2", modifiers: [.control])
                                if cloudSync { Text("Archive").tag(3).keyboardShortcut("3", modifiers: [.control]) }
                            }
                            .pickerStyle(.segmented)
                            .fixedSize()
                            .padding(.leading, -8)
                            .focusable(false)
                            SearchGroup(keyWord: $keyWord, regexSearch: $regexSearch, caseSensitivity: $caseSensitivity)
                                .padding(.leading, 4)
                        }.padding(.vertical, -3)
                    }
                }
                if fromMenubar {
                    SearchGroup(keyWord: $keyWord, regexSearch: $regexSearch, caseSensitivity: $caseSensitivity)
                        .padding(.leading, 2)
                        .padding(.top, 5)
                }
                if state.pageID == 1 {
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators:false) {
                            LazyVStack(alignment: .leading, spacing: 6) {
                                ForEach(keyWord == "" ? data.historys.indices : result.indices, id: \.self) { index in
                                    CommandView(index: index,
                                                command: keyWord == "" ? data.historys[index] : result[index],
                                                pinnedList: $pinnedList, fromMenubar: fromMenubar)
                                    .id(index)
                                    .padding(.horizontal, 1)
                                    .shadow(color: (panelOpacity != 100 && !fromMenubar) ? .clear :.secondary.opacity(0.8), radius: 0.3, y: 0.5)
                                }
                            }.padding(.bottom, 1)
                        }
                        .focusable(false)
                        .mask(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .onChange(of: scrollToTop) { _ in proxy.scrollTo(0, anchor: .top) }
                    }
                } else if state.pageID == 2 {
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators:false) {
                            LazyVStack(alignment: .leading, spacing: 6) {
                                ForEach(keyWord == "" ? pinnedList.indices : resultP.indices, id: \.self) { index in
                                    CommandView(index: index,
                                                command: keyWord == "" ? pinnedList[index] : resultP[index],
                                                pinnedList: $pinnedList, fromMenubar: fromMenubar, editable: true)
                                    .id(index)
                                    .padding(.horizontal, 1)
                                    .shadow(color: (panelOpacity != 100 && !fromMenubar) ? .clear :.secondary.opacity(0.8), radius: 0.3, y: 0.5)
                                }
                            }.padding(.bottom, 1)
                        }
                        .focusable(false)
                        .mask(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .onChange(of: scrollToTop) { _ in proxy.scrollTo(0, anchor: .top) }
                    }
                } else {
                    HStack(spacing: 5) {
                        Picker(selection: $state.archiveName, content: {
                            Text("Select an archive").tag("")
                            ForEach(state.archiveList, id: \.self) { item in
                                Text(item).tag(item)
                            }
                        }, label: {})
                        .onAppear { state.archiveList = getCloudFiles() }
                        .onChange(of: state.archiveName) { newValue in
                            if newValue != "" {
                                let path = cloudDirectory.url.appendingPathComponent("\(newValue).xha").path
                                state.archiveData = HistoryCopyer.shared.readHistory(file: path).reversed()
                            } else { state.archiveData = [] }
                        }
                        Button("Refresh", action: {
                            state.archiveList = getCloudFiles()
                            if !state.archiveList.contains(state.archiveName) {
                                state.archiveName = ""
                                state.archiveData.removeAll()
                            } else {
                                let path = cloudDirectory.url.appendingPathComponent("\(state.archiveName).xha").path
                                state.archiveData = HistoryCopyer.shared.readHistory(file: path).reversed()
                            }
                        }).keyboardShortcut("r", modifiers: [.command])
                    }
                    .padding(.top, 3)
                    .padding(.trailing, 1)
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators:false) {
                            LazyVStack(alignment: .leading, spacing: 6) {
                                ForEach(keyWord == "" ? state.archiveData.indices : resultA.indices, id: \.self) { index in
                                    CommandView(index: index,
                                                command: keyWord == "" ? state.archiveData[index] : resultA[index],
                                                pinnedList: $pinnedList, fromMenubar: fromMenubar)
                                    .id(index)
                                    .padding(.horizontal, 1)
                                    .shadow(color: (panelOpacity != 100 && !fromMenubar) ? .clear :.secondary.opacity(0.8), radius: 0.3, y: 0.5)
                                }
                            }.padding(.bottom, 1)
                        }
                        .focusable(false)
                        .mask(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .onChange(of: scrollToTop) { _ in proxy.scrollTo(0, anchor: .top) }
                    }
                }
            }
            .padding(7)
            .padding(.bottom, 1)
            .padding(.top, fromMenubar ? 0 : 21)
            if !fromMenubar {
                ButtonGroup()
                    .padding(.horizontal, 7.5)
                    .padding(.vertical, 6)
            }
        }
        .frame(minWidth: 360, minHeight: 119)
        .onAppear { data.historys = data.readHistory().reversed() }
        /*.overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(.secondary.opacity(0.5), lineWidth: fromMenubar ? 0 : 1)
        )*/
        .background(
            WindowAccessor(onWindowClose: {
                self.scrollToTop.toggle()
                self.keyWord = ""
                self.state.pageID = 1
            })
        )
        .onChange(of: keyWord) { newValue in updateResult() }
        .onChange(of: caseSensitivity) { _ in updateResult() }
        .onChange(of: regexSearch) { _ in updateResult() }
        .onChange(of: state.pageID) { _ in updateResult() }
        .onChange(of: data.historys) { _ in
            if state.pageID == 1 { result = searchHistory(data.historys) }
        }
        .onChange(of: pinnedList) { _ in
            if state.pageID == 2 { resultP = searchHistory(pinnedList) }
        }
        .onChange(of: state.archiveData) { _ in
            if state.pageID == 3 { resultA = searchHistory(state.archiveData) }
        }
        .onReceive(archiveTimer) { t in
            if data.needArchive {
                data.needArchive = false
                let archiveURL = cloudDirectory.url.appendingPathComponent("\(getMacDeviceName()) [\(historyFile.absolutePath.url.lastPathComponent.deletingPathExtension)].xha")
                if fd.fileExists(atPath: archiveURL.path) { try? fd.removeItem(at: archiveURL) }
                try? fd.copyItem(at: historyFile.absolutePath.url, to: archiveURL)
            }
        }
        .padding(.top, fromMenubar ? 0 : -28)
    }
    
    func updateResult() {
        if keyWord != "" {
            switch state.pageID {
            case 2:
                resultP = searchHistory(pinnedList)
            case 3:
                resultA = searchHistory(state.archiveData)
            default:
                result = searchHistory(data.historys)
            }
        }
    }
    
    func searchHistory(_ data: [String]) -> [String] {
        if !keyWord.isEmpty && !(keyWord == "") {
            if regexSearch {
                do {
                    let options: NSRegularExpression.Options = caseSensitivity ? [] : [.caseInsensitive]
                    let regex = try NSRegularExpression(pattern: keyWord, options: options)
                    
                    let matchingItems = data.filter { item in
                        let range = NSRange(location: 0, length: item.utf16.count)
                        return regex.firstMatch(in: item, options: [], range: range) != nil
                    }
                    return matchingItems
                } catch {
                    //print("Invalid regular expression: \(error)")
                    return []
                }
            } else {
                let options: String.CompareOptions = caseSensitivity ? [] : [.caseInsensitive]
                return data.filter { $0.range(of: keyWord, options: options) != nil }
            }
        }
        return data
    }
}

struct ActionButtons: View {
    var command: String
    @State var cmd = ""
    @State var editable: Bool = false
    
    @Binding var showMore: Bool
    @Binding var pinnedList: [String]
    
    @State private var copied: Bool = false
    @State private var boomList = [String]()
    @State private var boomMode: Bool = false
    @State private var save: Bool = false
    
    var body: some View {
        HStack(spacing: 5) {
            HoverButton(
                color: .secondary,
                action: {
                    copyToPasetboard(text: command)
                    copied = true
                    withAnimation(.easeInOut(duration: 1)) { copied = false }
                }, label: {
                    Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.clipboard")
                        .font(.system(size: 12, weight: .medium))
                        .frame(width: 12)
                        .frame(maxHeight: .infinity)
                })
            HoverButton(
                color: .secondary,
                action: {
                    if pinnedList.contains(command) {
                        pinnedList.removeAll(where: { $0 == command })
                    } else {
                        pinnedList.append(command)
                    }
                    ud.set(pinnedList, forKey: "pinnedList")
                }, label: {
                    Image(systemName: pinnedList.contains(command) ? "pin.fill" : "pin")
                        .font(.system(size: 13, weight: .bold))
                        .rotationEffect(.degrees(45))
                        .frame(width: 14)
                        .frame(maxHeight: .infinity)
                })
            HoverButton(
                color: .secondary,
                action: {
                    if let regex = try? NSRegularExpression(pattern: #"(?:"[^"]*"|'[^']*'|`[^`]*`|[^;\s&|]+)"#) {
                        let matches = regex.matches(in: command, range: NSRange(command.startIndex..., in: command))
                        boomList = matches.map { match in String(command[Range(match.range, in: command)!]) }
                        boomMode = true
                    }
                }, label: {
                    Image(systemName: showMore ? "character.cursor.ibeam" : "rectangle.expand.vertical")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 14)
                        .frame(maxHeight: .infinity)
                }).onHover { hovering in if hovering { showMore = true }}
        }
        .onAppear { cmd = command }
        .onChange(of: boomList) { _ in boomMode = true }
        .onChange(of: cmd) { _ in save = true }
        .sheet(isPresented: $boomMode) {
            VStack(spacing: 10) {
                GroupBox(label: Text("Magic Slice").font(.headline)) {
                    FlowLayout(items: boomList, spacing: 6) { item in CommandSliceView(command: item) }
                }
                if editable {
                    GroupBox(label: Text("Edit Command").font(.headline)) {
                        ZStack {
                            TextEditor(text: $cmd)
                                .font(.system(size: 11, weight: .regular, design: .monospaced))
                                .multilineTextAlignment(.leading)
                                .lineLimit(nil)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                                .padding(3)
                        }.background(Color.background)
                    }
                } else {
                    GroupBox(label: Text("Manual Selection").font(.headline)) {
                        Text(AttributedString(SyntaxHighlighter.shared.getHighlightedText(for: command)))
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .padding(2)
                    }
                }
                HStack {
                    Spacer()
                    if save {
                        Button("Cancel") { boomMode = false }
                        Button("Save") {
                            if let index = pinnedList.firstIndex(of: command) {
                                pinnedList[index] = command
                                ud.set(pinnedList, forKey: "pinnedList")
                            }
                            boomMode = false
                        }.keyboardShortcut(.defaultAction)
                    } else {
                        Button("Close") { boomMode = false }
                            .keyboardShortcut(.defaultAction)
                    }
                }
            }
            .padding()
            .focusable(false)
        }
    }
}

struct CommandView: View {
    var index: Int
    var command: String
    
    @Binding var pinnedList: [String]
    var fromMenubar: Bool = false
    var editable: Bool = false
    
    @AppStorage("panelOpacity") var panelOpacity = 100
    @AppStorage("autoClose") var autoClose = false
    @AppStorage("autoSpace") var autoSpace = false
    @AppStorage("autoReturn") var autoReturn = false
    @AppStorage("buttonSide") var buttonSide = "right"
    
    @State private var isHovered: Bool = false
    @State private var showMore: Bool = false
    
    var body: some View {
        HStack(spacing: 6) {
            Text((0...8).contains(index) ? "⌘\(index + 1)" : "\(index + 1)")
                .font(.system(size: 11, weight: (0...8).contains(index) ? .bold : .regular))
                .foregroundStyle(isHovered ? .white : .primary)
                .padding(.horizontal, 2)
                .lineLimit(1)
                .minimumScaleFactor(0.3)
                .frame(width: 26)
                .frame(maxHeight: .infinity)
                .background(isHovered ? Color.blue : Color.background.opacity(fromMenubar ? 1 : Double(panelOpacity) / 100))
                .mask(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isHovered = hovering
                    }
                }
            HStack(spacing: 0) {
                if buttonSide == "left" {
                    ActionButtons(command: command, editable: editable, showMore: $showMore, pinnedList: $pinnedList)
                        .padding(.leading, 8)
                }
                Button(action: {
                    copyToPasteboardAndPaste(text: "\(command)\(autoSpace ? " " : "")", enter: autoReturn)
                    if autoClose {
                        mainPanel.close()
                        menuPopover.performClose(self)
                    }
                }, label: {
                    ZStack {
                        Color.primary.opacity(0.0001)
                        HStack {
                            Text(AttributedString(SyntaxHighlighter.shared.getHighlightedText(for: command)))
                                .font(.system(size: 11, weight: .regular, design: .monospaced))
                                .multilineTextAlignment(.leading)
                                .lineLimit(showMore ? nil : 1)
                                .padding(6)
                                .padding(.leading, 2)
                            Spacer()
                        }
                    }
                })
                .buttonStyle(.plain)
                .setHotkey(index: index)
                if buttonSide == "right" {
                    ActionButtons(command: command, editable: editable, showMore: $showMore, pinnedList: $pinnedList)
                        .padding(.trailing, 8)
                }
            }
            .background(Color.background.opacity((isHovered || fromMenubar) ? 1.0 : Double(panelOpacity) / 100))
            .frame(maxWidth: .infinity)
            .overlay {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(.blue, lineWidth: isHovered ? 2 : 0)
                    .padding(1)
            }
            .mask(RoundedRectangle(cornerRadius: 5, style: .continuous))
            .onHover { hovering in
                isHovered = hovering
                if !hovering { showMore = false }
            }
        }
    }
}

struct CommandSliceView: View {
    var command: String
    @State private var isHovered: Bool = false
    @State private var copied: Bool = false
    
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("autoClose") var autoClose = false
    @AppStorage("autoSpace") var autoSpace = false
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: {
                copyToPasteboardAndPaste(text: "\(command)\(autoSpace ? " " : "")")
                if autoClose {
                    presentationMode.wrappedValue.dismiss()
                    mainPanel.close()
                    menuPopover.performClose(self)
                }
            }, label: {
                Text(command)
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .lineLimit(1)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .padding(.trailing, 14)
                    .help(command)
            }).buttonStyle(.plain)
            HoverButton(
                color: .secondary,
                action: {
                    copyToPasetboard(text: command)
                    copied = true
                    withAnimation(.easeInOut(duration: 1)) { copied = false }
                }, label: {
                    Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.clipboard")
                        .resizable().scaledToFit()
                        .font(.system(size: 12, weight: .medium))
                        .frame(width: 12)
                }).padding(.leading, -18)
        }
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(.background2)
                .shadow(color: .secondary.opacity(0.8), radius: 0.3, y: 0.5)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .stroke(.blue, lineWidth: isHovered ? 2 : 0)
                .padding(1)
        }
        .onHover { hovering in isHovered = hovering }
        .focusable(false)
    }
}

struct ConditionalKeyboardShortcut: ViewModifier {
    var index: Int

    func body(content: Content) -> some View {
        if (0...8).contains(index) {
            content.keyboardShortcut(
                KeyEquivalent(Character("\(index + 1)")),
                modifiers: [.command]
            )
        } else {
            content
        }
    }
}

extension View {
    func setHotkey(index: Int) -> some View {
        self.modifier(ConditionalKeyboardShortcut(index: index))
    }
}

func copyToPasetboard(text: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
}

func copyToPasteboardAndPaste(text: String, enter: Bool = false) {
    let pasteboard = NSPasteboard.general
    var backupItems: [NSPasteboardItem] = []

    for item in pasteboard.pasteboardItems ?? [] {
        let newItem = NSPasteboardItem()
        
        for type in item.types {
            if let data = item.data(forType: type) {
                newItem.setData(data, forType: type)
            }
        }
        backupItems.append(newItem)
    }
    
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
    
    let eventSource = CGEventSource(stateID: .hidSystemState)
    let cmdDown = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(kVK_Command), keyDown: true)
    let cmdUp = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(kVK_Command), keyDown: false)
    let vDown = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
    let vUp = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
    let enterDown = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(kVK_Return), keyDown: true)
    let enterUp = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(kVK_Return), keyDown: false)

    cmdDown?.flags = .maskCommand
    vDown?.flags = .maskCommand
    
    cmdDown?.post(tap: .cgAnnotatedSessionEventTap)
    vDown?.post(tap: .cgAnnotatedSessionEventTap)
    vUp?.post(tap: .cgAnnotatedSessionEventTap)
    cmdUp?.post(tap: .cgAnnotatedSessionEventTap)
    if enter {
        enterDown?.post(tap: .cgAnnotatedSessionEventTap)
        enterUp?.post(tap: .cgAnnotatedSessionEventTap)
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        pasteboard.clearContents()
        pasteboard.writeObjects(backupItems)
    }
}

struct SearchField: NSViewRepresentable {
    class Coordinator: NSObject, NSSearchFieldDelegate {
        var parent: SearchField

        init(_ parent: SearchField) {
            self.parent = parent
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let searchField = notification.object as? NSSearchField else {
                print("Unexpected control in update notification")
                return
            }
            self.parent.search = searchField.stringValue
        }
    }

    @Binding var search: String
    @Environment(\.colorScheme) var colorScheme  // 使用环境变量监听深浅色模式的变化

    func makeNSView(context: Context) -> NSSearchField {
        let searchField = NSSearchField(frame: .zero)
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.heightAnchor.constraint(equalToConstant: 24).isActive = true
        searchField.focusRingType = .none

        updateAppearance(for: searchField)  // 设置初始 appearance
        return searchField
    }

    func updateNSView(_ searchField: NSSearchField, context: Context) {
        searchField.placeholderString = "Search".local
        searchField.stringValue = search
        searchField.delegate = context.coordinator
        
        // 每次更新时重新检查系统外观
        updateAppearance(for: searchField)
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    private func updateAppearance(for searchField: NSSearchField) {
        if colorScheme == .dark {
            searchField.appearance = NSAppearance(named: .vibrantDark)
        } else {
            searchField.appearance = NSAppearance(named: .vibrantLight)
        }
    }
}
