import Foundation

/// Represents a parsed message from Twitch chat
public struct TwitchChatMessage {
    public let raw: String
    public let tags: [String: String]
    public let prefix: String
    public let command: String
    public let params: [String]
    public let content: String
    public let author: Author
    public let channel: String
    
    public let emotes: [TwitchEmote]
    public let id: String
    public let timestamp: Date?
}

public struct Author {
    public let username: String
    public let displayName: String
    public let color: String
    public let badges: [String: String]

    public var isModerator: Bool {
        badges["moderator"] != nil
    }
    
    public var isSubscriber: Bool {
        badges["subscriber"] != nil
    }
    
    public var isBroadcaster: Bool {
        badges["broadcaster"] != nil
    }
}
