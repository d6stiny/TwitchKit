import Foundation

/// A Swift library for connecting to Twitch chat and receiving messages in real time
public class TwitchKit {
    // MARK: - Properties
    private var connection: URLSessionWebSocketTask?
    private var session: URLSession?
    private let queue = DispatchQueue(label: "twitchkit.queue", qos: .utility)
    private var isConnected = false
    private var pingTimer: Timer?
    
    // Configuration
    private var username: String = ""
    private var token: String = ""
    private var channel: String = ""
    
    // Callbacks
    public var onConnect: (() -> Void)?
    public var onDisconnect: ((Error?) -> Void)?
    public var onMessage: ((TwitchChatMessage) -> Void)?
    public var onError: ((Error) -> Void)?
    
    // MARK: - Initialization
    public init() {
        session = URLSession(configuration: .default)
    }
    
    deinit {
        disconnect()
    }
    
    // MARK: - Public Methods
    
    /// Configure the connection with your Twitch credentials
    /// - Parameters:
    ///   - username: Your Twitch username
    ///   - token: OAuth token (format: "oauth:xxxxxx")
    ///   - channel: The channel to join
    public func configure(username: String, token: String, channel: String) {
        self.username = username.lowercased()
        self.token = token
        self.channel = channel.lowercased()
    }
    
    /// Connect to Twitch chat
    public func connect() {
        guard !isConnected else { return }
        guard !username.isEmpty, !token.isEmpty, !channel.isEmpty else {
            onError?(NSError(domain: "TwitchKit", code: 400, userInfo: [NSLocalizedDescriptionKey: "Username, token, and channel must be configured"]))
            return
        }
        
        guard let url = URL(string: "wss://irc-ws.chat.twitch.tv:443") else {
            onError?(NSError(domain: "TwitchKit", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        connection = session?.webSocketTask(with: url)
        setupMessageReceiver()
        connection?.resume()
        
        // Send authentication messages
        sendMessage("PASS \(token)")
        sendMessage("NICK \(username)")
        sendMessage("JOIN #\(channel)")
        
        // Request additional message capabilities
        sendMessage("CAP REQ :twitch.tv/tags twitch.tv/commands twitch.tv/membership")
        
        isConnected = true
        startPingTimer()
        onConnect?()
    }
    
    /// Disconnect from Twitch chat
    public func disconnect() {
        guard isConnected else { return }
        pingTimer?.invalidate()
        pingTimer = nil
        connection?.cancel(with: .goingAway, reason: nil)
        connection = nil
        isConnected = false
        onDisconnect?(nil)
    }
    
    /// Send a chat message to the channel
    /// - Parameter message: The message to send
    public func sendChatMessage(_ message: String) {
        guard isConnected else {
            onError?(NSError(domain: "TwitchKit", code: 400, userInfo: [NSLocalizedDescriptionKey: "Not connected"]))
            return
        }
        
        sendMessage("PRIVMSG #\(channel) :\(message)")
    }
    
    // MARK: - Private Methods
    
    private func sendMessage(_ message: String) {
        connection?.send(.string(message)) { [weak self] error in
            if let error = error {
                self?.onError?(error)
            }
        }
    }
    
    private func setupMessageReceiver() {
        receiveMessage()
    }
    
    private func receiveMessage() {
        connection?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
                case .success(let message):
                    switch message {
                        case .string(let text):
                            self.handleMessage(text)
                        case .data(let data):
                            if let text = String(data: data, encoding: .utf8) {
                                self.handleMessage(text)
                            }
                        @unknown default:
                            break
                    }
                    
                    // Continue receiving messages
                    self.receiveMessage()
                    
                case .failure(let error):
                    self.isConnected = false
                    self.onDisconnect?(error)
            }
        }
    }
    
    private func handleMessage(_ rawMessage: String) {
        // Handle ping to maintain connection
        if rawMessage.hasPrefix("PING") {
            sendMessage("PONG :tmi.twitch.tv")
            return
        }
        
        // Parse the message
        let parsedMessage = parseMessage(rawMessage)
        
        // Call the onMessage callback with the parsed message
        if parsedMessage.command == "PRIVMSG" {
            queue.async { [weak self] in
                self?.onMessage?(parsedMessage)
            }
        }
    }
    
    private func parseMessage(_ rawMessage: String) -> TwitchChatMessage {
        var tags: [String: String] = [:]
        var prefix: String = ""
        var command: String = ""
        var params: [String] = []
        var message: String = ""
        
        var currentPosition = 0
        let components = rawMessage.components(separatedBy: " ")
        
        // Parse tags if present
        if rawMessage.hasPrefix("@") {
            let tagPart = components[currentPosition].dropFirst()
            let tagComponents = tagPart.components(separatedBy: ";")
            
            for tag in tagComponents {
                let keyValue = tag.components(separatedBy: "=")
                if keyValue.count == 2 {
                    tags[keyValue[0]] = keyValue[1]
                }
            }
            
            currentPosition += 1
        }
        
        // Parse prefix if present
        if currentPosition < components.count && components[currentPosition].hasPrefix(":") {
            prefix = String(components[currentPosition].dropFirst())
            currentPosition += 1
        }
        
        // Parse command
        if currentPosition < components.count {
            command = components[currentPosition]
            currentPosition += 1
        }
        
        // Parse params and message
        if currentPosition < components.count {
            var messageStartIndex = -1
            
            for i in currentPosition..<components.count {
                if components[i].hasPrefix(":") {
                    messageStartIndex = i
                    break
                } else {
                    params.append(components[i])
                }
            }
            
            if messageStartIndex != -1 {
                let messageComponents = components[messageStartIndex...].joined(separator: " ")
                message = String(messageComponents.dropFirst())
            }
        }
        
        // Extract username from prefix
        var username = ""
        if let usernameEndIndex = prefix.firstIndex(of: "!") {
            username = String(prefix[..<usernameEndIndex])
        }
        
        // Extract channel from params
        var channel = ""
        if let channelParam = params.first, channelParam.hasPrefix("#") {
            channel = String(channelParam.dropFirst())
        }
        
        return TwitchChatMessage(
            raw: rawMessage,
            tags: tags,
            prefix: prefix,
            command: command,
            params: params,
            content: message,
            author: Author(
                username: username,
                displayName: tags["display-name"] ?? username,
                color: tags["color"] ?? "",
                badges: parseBadges(tags["badges"] ?? "")
            ),
            channel: channel,
            emotes: parseEmotes(tags["emotes"] ?? ""),
            id: tags["id"] ?? "",
            timestamp: parseTimestamp(tags["tmi-sent-ts"])
        )
    }
    
    private func parseBadges(_ badgesString: String) -> [String: String] {
        var badges: [String: String] = [:]
        let badgePairs = badgesString.components(separatedBy: ",")
        
        for pair in badgePairs where !pair.isEmpty {
            let components = pair.components(separatedBy: "/")
            if components.count == 2 {
                badges[components[0]] = components[1]
            }
        }
        
        return badges
    }
    
    private func parseEmotes(_ emotesString: String) -> [TwitchEmote] {
        var emotes: [TwitchEmote] = []
        let emotePairs = emotesString.components(separatedBy: "/")
        
        for pair in emotePairs where !pair.isEmpty {
            let components = pair.components(separatedBy: ":")
            if components.count == 2 {
                let emoteID = components[0]
                let positions = components[1].components(separatedBy: ",")
                
                for position in positions {
                    let indices = position.components(separatedBy: "-")
                    if indices.count == 2,
                       let startIndex = Int(indices[0]),
                       let endIndex = Int(indices[1]) {
                        emotes.append(TwitchEmote(
                            id: emoteID,
                            startIndex: startIndex,
                            endIndex: endIndex
                        ))
                    }
                }
            }
        }
        
        return emotes
    }
    
    private func parseTimestamp(_ timestampString: String?) -> Date? {
        guard let timestampString = timestampString,
              let timestamp = Int64(timestampString) else {
            return nil
        }
        
        return Date(timeIntervalSince1970: Double(timestamp) / 1000.0)
    }
    
    private func startPingTimer() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.sendMessage("PING :tmi.twitch.tv")
        }
    }
}
