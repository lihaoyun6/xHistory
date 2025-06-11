//
//  main.swift
//  xhistory
//
//  Created by apple on 2024/11/6.
//
import ArgumentParser
import Foundation

struct xhistory: ParsableCommand {
    static var configuration = CommandConfiguration(version: "0.1.4")
    
    @Flag(name: .shortAndLong, help: "Read the history file for the current session")
    var session: Bool = false
    
    @Flag(name: .shortAndLong, help: "Open xHistory overlay and show pinned history")
    var pinned: Bool = false
    
    @Flag(name: .shortAndLong, help: "Open xHistory overlay and show cloud archive")
    var archive: Bool = false
    
    @Option(name: .shortAndLong, help: ArgumentHelp("Get custom shell configuration", valueName: "bash|zsh[23]"))
    var config: String? = nil

    @Option(name: .shortAndLong, help: "Read the specified history file")
    var file: String? = nil
    
    mutating func validate() throws {
        let arguments = [session, pinned, archive, config != nil, file != nil]
        let activeCount = arguments.filter { $0 }.count
        if activeCount > 1 {
            throw ValidationError("These options cannot be used together!")
        }
    }

    mutating func run() throws {
        if let file = file {
            openCustomURLWithActiveWindowGeometry(prompt: "&file=\(file)")
            return
        }
        if session {
            if let file = ProcessInfo.processInfo.environment["HISTFILE"] {
                openCustomURLWithActiveWindowGeometry(prompt: "&file=\(file)")
            }
            return
        }
        if pinned {
            openCustomURLWithActiveWindowGeometry(prompt: "&mode=pinned")
            return
        }
        if archive {
            openCustomURLWithActiveWindowGeometry(prompt: "&mode=archive")
            return
        }
        if let shell = config {
            guard let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
            let plistPath = appSupportDir.appendingPathComponent("xHistory/shellConfig.plist").path
            if let config = readPlistValue(filePath: plistPath, key: "customShellConfig") as? Bool, config {
                if let value = readPlistValue(filePath: plistPath, key: "historyLimit") {
                    if shell == "bash" || shell == "zsh" { print("export HISTSIZE=\(value)") }
                }
                if let value = readPlistValue(filePath: plistPath, key: "realtimeSave") as? Bool, value {
                    if shell == "bash" { print("export PROMPT_COMMAND=\"history -a\"") }
                    if shell == "zsh2" { print("setopt INC_APPEND_HISTORY") }
                }
                if let value = readPlistValue(filePath: plistPath, key: "noDuplicates") as? Bool, value {
                    if shell == "bash" { print("export HISTCONTROL=ignoredups") }
                    if shell == "zsh3" { print("setopt HIST_IGNORE_DUPS") }
                }
            }
            return
        }
        openCustomURLWithActiveWindowGeometry()
    }
}

xhistory.main()
