import Foundation
import Starscream

class DiscordGatewayClient: NSObject, ObservableObject {
    @Published var isConnected: Bool = false
    @Published var status: String = "Disconnected"
    
    var token: String
    var spoofMode: Bool = false
    
    private var socket: WebSocket?
    private var heartbeatInterval: TimeInterval = 41.25
    private var heartbeatTimer: Timer?
    
    var logHandler: ((String) -> Void)?
    
    init(token: String) {
        self.token = token
    }
    
    func connect() {
        if spoofMode {
            logHandler?("[SPOOF MODE] Skipping connection. Faking connected state.")
            DispatchQueue.main.async {
                self.isConnected = true
                self.status = "Connected (Spoof)"
            }
            return
        }
        logHandler?("Connecting to Discord Gateway...")
        disconnect()
        guard let url = URL(string: "wss://gateway.discord.gg/?v=9&encoding=json") else {
            logHandler?("Invalid Discord Gateway URL")
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let newSocket = WebSocket(request: request)
        newSocket.delegate = self
        newSocket.connect()
        socket = newSocket
    }
    
    func disconnect() {
        if spoofMode {
            logHandler?("[SPOOF MODE] Skipping disconnect. Faking disconnected state.")
            DispatchQueue.main.async {
                self.isConnected = false
                self.status = "Disconnected (Spoof)"
            }
            return
        }
        logHandler?("Disconnecting from Discord Gateway")
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        socket?.disconnect()
        socket = nil
        DispatchQueue.main.async {
            self.isConnected = false
            self.status = "Disconnected"
        }
    }
    
    public func send(json payload: [String: Any]) {
        if spoofMode {
            logHandler?("[SPOOF MODE] Suppressed sending payload: \(payload)")
            return
        }
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let jsonString = String(data: data, encoding: .utf8) else { 
            logHandler?("Failed to encode JSON payload: \(payload)")
            return 
        }
        logHandler?("Sending payload:\n\(jsonString)")
        socket?.write(string: jsonString)
    }
    
    private func handleGatewayMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let payload = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            logHandler?("Failed to parse gateway message")
            return
        }
        
        if let t = payload["t"] as? String {
            logHandler?("Received event: \(t)")
        } else if let op = payload["op"] as? Int {
            logHandler?("Received op code: \(op)")
        } else {
            logHandler?("Received gateway message")
        }

        if let op = payload["op"] as? Int {
            switch op {
            case 10:
                if let d = payload["d"] as? [String: Any],
                   let interval = d["heartbeat_interval"] as? Double {
                    heartbeatInterval = interval / 1000.0
                    startHeartbeating()
                    DispatchQueue.main.async {
                        self.status = "Ready, heartbeat started"
                    }
                    logHandler?("Received Hello, started heartbeat: \(heartbeatInterval)s")
                }
            default:
                break
            }
        }
    }
    
    private func startHeartbeating() {
        DispatchQueue.global(qos: .background).async {
            self.heartbeatTimer?.invalidate()
            let timer = Timer(timeInterval: self.heartbeatInterval, repeats: true) { [weak self] _ in
                self?.sendHeartbeat()
            }
            self.heartbeatTimer = timer
            RunLoop.current.add(timer, forMode: .common)
            RunLoop.current.run()
        }
    }
    
    private func sendIdentify() {
        let payload: [String: Any] = [
            "op": 2,
            "d": [
                "token": token,
                "intents": 513,
                "properties": [
                    "$os": "ios",
                    "$browser": "SwicordBot",
                    "$device": "SwicordBot"
                ],
                "compress": false,
                "large_threshold": 250,
                "presence": [
                    "status": "online",
                    "since": 0,
                    "activities": [],
                    "afk": false
                ]
            ]
        ]
        send(json: payload)
    }
    
    private func sendHeartbeat() {
        let payload: [String: Any] = [
            "op": 1,
            "d": NSNull()
        ]
        send(json: payload)
    }
}

extension DiscordGatewayClient: Starscream.WebSocketDelegate {
    func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
        if spoofMode {
            logHandler?("[SPOOF MODE] Ignored WebSocket event: \(event)")
            return
        }
        switch event {
        case .connected(_):
            logHandler?("WebSocket connected")
            DispatchQueue.main.async {
                self.isConnected = true
                self.status = "Connected, identifying"
            }
            sendIdentify()
        case .disconnected(let reason, let code):
            logHandler?("WebSocket disconnected: Code=\(code), Reason=\(reason)")
            DispatchQueue.main.async {
                self.isConnected = false
                self.status = "Disconnected"
            }
        case .text(let text):
            logHandler?("Received gateway text message")
            handleGatewayMessage(text)
        case .error(let error):
            logHandler?("WebSocket error: \(String(describing: error))")
            DispatchQueue.main.async {
                self.isConnected = false
                self.status = "Error"
            }
        default:
            break
        }
    }
}
