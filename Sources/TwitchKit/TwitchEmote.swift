import Foundation

/// Represents a Twitch emote in the message
public struct TwitchEmote {
    public let id: String
    public let startIndex: Int
    public let endIndex: Int
    
    public var url: URL? {
        URL(string: "https://static-cdn.jtvnw.net/emoticons/v2/\(id)/default/dark/3.0")
    }
}
