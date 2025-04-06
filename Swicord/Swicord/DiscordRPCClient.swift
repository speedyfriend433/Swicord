import Foundation

class DiscordRPCClient: ObservableObject {
    var discordToken: String
    
    private var lastSend: TimeInterval = 0
    private var allowance: Double
    private let maxRequestRate = 4.0
    private let perSeconds = 25.0
    
    private var timer: Timer?
    
    @Published var currentBundleIdentifier: String? = nil
    @Published var currentState: String = "START"
    
    init(token: String) {
        self.discordToken = token
        self.allowance = maxRequestRate
        self.lastSend = Date().timeIntervalSince1970
    }
    
    func sendPresence(bundleIdentifier: String?, state: String) {
        let now = Date().timeIntervalSince1970
        let timePassed = now - lastSend
        lastSend = now
        
        allowance += timePassed * (maxRequestRate / perSeconds)
        if allowance > maxRequestRate {
            allowance = maxRequestRate
        }
        if allowance < 1.0 {
            print("Rate limited, skipping this request")
            return
        }
        allowance -= 1.0
        
        guard !discordToken.isEmpty else { return }
        guard let url = URL(string: "https://discord.com/api/v9/presences") else { return }
        var payload: [String: Any]
        if let bundleID = bundleIdentifier {
            payload = ["package_name": bundleID, "update": state]
        } else {
            payload = ["update": state]
        }

        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(discordToken.trimmingCharacters(in: .whitespacesAndNewlines), forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("max-age=121", forHTTPHeaderField: "Cache-Control")
        request.setValue("Mozilla/5.0 (Linux; Android 11) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/100.0.4896.127 Mobile OceanHero/6 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.httpBody = httpBody

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else { return }

            if httpResponse.statusCode == 204 {
                print("Request sent to Discord successfully")
            } else if httpResponse.statusCode == 429 {
                print("Rate limited by Discord")
            } else {
                print("Discord error: status code \(httpResponse.statusCode)")
            }
        }.resume()
    }
    
    func updatePresence() {
        sendPresence(bundleIdentifier: currentBundleIdentifier, state: currentState)
    }
    
    func startTimer(interval: TimeInterval = 300) {
        DispatchQueue.main.async {
            self.stopTimer()
            self.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                self?.updatePresence()
            }
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
