//
//  ContentView.swift
//  Swicord
//
//  Created by speedy on 4/5/25.
//

import SwiftUI
import UIKit

struct DiscordColors {
    static let background = Color(red: 0.13, green: 0.14, blue: 0.16) // #23272A
    static let darker = Color(red: 0.11, green: 0.12, blue: 0.14) // #1E2124
    static let channelBg = Color(red: 0.2, green: 0.21, blue: 0.24) // #2C2F33
    static let accent = Color(red: 0.29, green: 0.33, blue: 0.84) // #7289DA
    static let text = Color.white
    static let secondaryText = Color(white: 0.7)
}

struct ContentView: View {
    @AppStorage("discordToken") private var discordToken: String = ""
    @AppStorage("gameName") private var gameName: String = ""
    @AppStorage("activityDetails") private var activityDetails: String = ""
    @AppStorage("activityState") private var activityState: String = ""
    @AppStorage("secondGameName") private var secondGameName: String = ""
    @AppStorage("secondActivityDetails") private var secondActivityDetails: String = ""
    @AppStorage("secondActivityState") private var secondActivityState: String = ""
    @AppStorage("button1Label") private var button1Label: String = ""
    @AppStorage("button1URL") private var button1URL: String = ""
    @AppStorage("button2Label") private var button2Label: String = ""
    @AppStorage("button2URL") private var button2URL: String = ""
    
    @State private var showActivity1 = false
    @State private var showActivity2 = false
    @State private var showButton1 = false
    @State private var showButton2 = false
    @State private var showDebugLog = false
    @State private var debugLogs: String = ""
    
    @StateObject private var gatewayClient = DiscordGatewayClient(token: "")

    @State private var autoUpdateTimer: Timer? = nil

    var body: some View {
        ZStack {
            DiscordColors.background.edgesIgnoringSafeArea(.all)
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    discordTextField(title: "Discord Token", text: $discordToken, isSecure: true)
                        .onChange(of: discordToken) { newValue in
                            if gatewayClient.isConnected { gatewayClient.disconnect() }
                            gatewayClient.token = newValue
                        }
                    Section {
                        Button {
                            withAnimation { showActivity1.toggle() }
                        } label: {
                            HStack {
                                Text("Activity 1 \(showActivity1 ? "▲" : "▼")")
                                    .foregroundColor(DiscordColors.accent)
                                    .fontWeight(.medium)
                                Spacer()
                            }.padding(.horizontal)
                        }
                        if showActivity1 {
                            discordTextField(title: "Game / App Name", text: $gameName)
                            discordTextField(title: "Activity Details", text: $activityDetails)
                            discordTextField(title: "Activity State", text: $activityState)
                        }
                    }
                    Section {
                        Button {
                            withAnimation { showActivity2.toggle() }
                        } label: {
                            HStack {
                                Text("Activity 2 \(showActivity2 ? "▲" : "▼")")
                                    .foregroundColor(DiscordColors.accent)
                                    .fontWeight(.medium)
                                Spacer()
                            }.padding(.horizontal)
                        }
                        if showActivity2 {
                            discordTextField(title: "Game / App Name", text: $secondGameName)
                            discordTextField(title: "Activity Details", text: $secondActivityDetails)
                            discordTextField(title: "Activity State", text: $secondActivityState)
                        }
                    }
                    Section {
                        Button {
                            withAnimation { showButton1.toggle() }
                        } label: {
                            HStack {
                                Text("Button 1 \(showButton1 ? "▲" : "▼")")
                                    .foregroundColor(DiscordColors.accent)
                                    .fontWeight(.medium)
                                Spacer()
                            }.padding(.horizontal)
                        }
                        if showButton1 {
                            discordTextField(title: "Label", text: $button1Label)
                            discordTextField(title: "URL", text: $button1URL)
                        }
                    }
                    Section {
                        Button {
                            withAnimation { showButton2.toggle() }
                        } label: {
                            HStack {
                                Text("Button 2 \(showButton2 ? "▲" : "▼")")
                                    .foregroundColor(DiscordColors.accent)
                                    .fontWeight(.medium)
                                Spacer()
                            }.padding(.horizontal)
                        }
                        if showButton2 {
                            discordTextField(title: "Label", text: $button2Label)
                            discordTextField(title: "URL", text: $button2URL)
                        }
                    }
                }
                .padding()
                .background(DiscordColors.channelBg)
                .cornerRadius(8)
                
                HStack(spacing: 12) {
                    discordButton(
                        title: gatewayClient.isConnected ? "Disconnect" : "Connect",
                        color: gatewayClient.isConnected ? Color.red.opacity(0.8) : DiscordColors.accent
                    ) {
                        if gatewayClient.isConnected {
                            gatewayClient.disconnect()
                        } else {
                            gatewayClient.token = discordToken
                            gatewayClient.connect()
                        }
                    }
                    
                    discordButton(title: "Update Presence", color: DiscordColors.accent) {
                        updatePresenceWithCurrentInfo()
                    }
                    .disabled(!gatewayClient.isConnected)
                    .opacity(gatewayClient.isConnected ? 1.0 : 0.5)
                }

                HStack(spacing: 12) {
                    discordButton(
                        title: "Start Auto Presence",
                        color: Color.green.opacity(0.7),
                        icon: "play.fill"
                    ) {
                        startAutoPresenceUpdates()
                    }
                    .disabled(autoUpdateTimer != nil)
                    .opacity(autoUpdateTimer == nil ? 1.0 : 0.5)
                    
                    discordButton(
                        title: "Stop Auto Presence",
                        color: Color.red.opacity(0.7),
                        icon: "stop.fill"
                    ) {
                        stopAutoPresenceUpdates()
                    }
                    .disabled(autoUpdateTimer == nil)
                    .opacity(autoUpdateTimer != nil ? 1.0 : 0.5)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        showDebugLog.toggle()
                    }
                }) {
                    HStack {
                        Text(showDebugLog ? "Hide Debug Log ▲" : "Show Debug Log ▼")
                            .foregroundColor(.yellow)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                
                if showDebugLog {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Spacer()
                            Button(action: {
                                UIPasteboard.general.string = debugLogs
                            }) {
                                Text("Copy All Logs")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(Color.gray.opacity(0.5))
                                    .cornerRadius(4)
                            }
                        }
                        ScrollView {
                            Text(debugLogs)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                        }
                        .frame(maxHeight: 200)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                        .padding(.horizontal, -4)
                    }
                    .padding(.horizontal)
                }
                
                Text("Swicord")
                    .font(.caption)
                    .foregroundColor(DiscordColors.secondaryText)
                    .padding(.bottom, 8)
            }
            .padding()
        }
        .onAppear {
            restoreTokenFileIfPresent()
            gatewayClient.logHandler = { message in
                DispatchQueue.main.async {
                    debugLogs.append("\n\(message)")
                }
            }
        }
    }
    
    private func discordTextField(title: String, text: Binding<String>, isSecure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(DiscordColors.secondaryText)
            
            if isSecure {
                SecureField("", text: text)
                    .padding(10)
                    .background(DiscordColors.darker)
                    .cornerRadius(4)
                    .foregroundColor(DiscordColors.text)
            } else {
                TextField("", text: text)
                    .padding(10)
                    .background(DiscordColors.darker)
                    .cornerRadius(4)
                    .foregroundColor(DiscordColors.text)
            }
        }
    }
    
    private func discordButton(title: String, color: Color, icon: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                if let iconName = icon {
                    Image(systemName: iconName)
                        .font(.system(size: 14, weight: .bold))
                }
                Text(title)
                    .fontWeight(.medium)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(color)
            .cornerRadius(4)
            .foregroundColor(.white)
        }
    }
    
    // this was supposed to load tokens from internal files
    private func restoreTokenFileIfPresent() {
        if discordToken.isEmpty {
            let fileURL = URL(fileURLWithPath: "/Users/speedy/Desktop/Swicord/Swicord/dct0ken.txt")
            if let tokenFromFile = try? String(contentsOf: fileURL, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines) {
                discordToken = tokenFromFile
            }
        }
    }
    
    private func startAutoPresenceUpdates() {
        stopAutoPresenceUpdates()
        autoUpdateTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { _ in
            updatePresenceWithCurrentInfo()
        }
        autoUpdateTimer?.tolerance = 3
        updatePresenceWithCurrentInfo()
    }
    
    private func stopAutoPresenceUpdates() {
        autoUpdateTimer?.invalidate()
        autoUpdateTimer = nil
    }
    
    private func updatePresenceWithCurrentInfo() {
        let now = Int(Date().timeIntervalSince1970 * 1000)

        var buttons: [[String: Any]] = []
        if !button1Label.isEmpty && !button1URL.isEmpty {
            buttons.append(["label": button1Label, "url": button1URL])
        }
        if !button2Label.isEmpty && !button2URL.isEmpty {
            buttons.append(["label": button2Label, "url": button2URL])
        }

        func createActivity(name: String, details: String, state: String) -> [String: Any]? {
            guard !name.isEmpty else { return nil }
            var activity: [String: Any] = [
                "name": name,
                "type": 0,
                "timestamps": ["start": now]
            ]
            if !details.isEmpty { activity["details"] = details }
            if !state.isEmpty { activity["state"] = state }
            if !buttons.isEmpty { activity["buttons"] = buttons }
            return activity
        }

        var activitiesArray: [[String: Any]] = []
        if let firstActivity = createActivity(name: gameName, details: activityDetails, state: activityState) {
            activitiesArray.append(firstActivity)
        }
        if let secondActivity = createActivity(name: secondGameName, details: secondActivityDetails, state: secondActivityState) {
            activitiesArray.append(secondActivity)
        }

        let payload: [String: Any] = [
            "op": 3,
            "d": [
                "since": now,
                "activities": activitiesArray,
                "status": "online",
                "afk": false
            ]
        ]
        gatewayClient.logHandler?("Updating presence at timestamp: \(now)")
        gatewayClient.logHandler?("Payload: \(payload)")
        gatewayClient.send(json: payload)
    }
    
}

#Preview {
    ContentView()
}
