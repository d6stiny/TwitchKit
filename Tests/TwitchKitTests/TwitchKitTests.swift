import XCTest
import Testing
import Foundation
@testable import TwitchKit

@Suite("TwitchKitTests")
struct TwitchKitTests {
    @Test("Configuration")
    func testConfiguration() throws {
        let twitchKit = TwitchKit()
        twitchKit.configure(username: "testuser", token: "oauth:testtoken", channel: "testchannel")
        
        // Use reflection to access private properties for testing
        let mirror = Mirror(reflecting: twitchKit)
        
        #expect(mirror.children.first(where: { $0.label == "username" })?.value as? String == "testuser")
        #expect(mirror.children.first(where: { $0.label == "token" })?.value as? String == "oauth:testtoken")
        #expect(mirror.children.first(where: { $0.label == "channel" })?.value as? String == "testchannel")
    }
    
    @Test("Parse Message")
    func testParseMessage() throws {
        let twitchKit = TwitchKit()
        let rawMessage = "@badge-info=subscriber/8;badges=subscriber/6,premium/1;color=#0000FF;display-name=TestUser;emotes=25:0-4,12-16/1902:6-10;id=b34ccfc7-4977-403a-8a94-33c6bac34fb8;mod=0;room-id=12345678;subscriber=1;tmi-sent-ts=1619191991246;turbo=0;user-id=87654321;user-type= :testuser!testuser@testuser.tmi.twitch.tv PRIVMSG #channel :Kappa Hello Kappa World"
        
        // Use reflection to access private method for testing
        let mirror = Mirror(reflecting: twitchKit)
        guard let parseMessageMethod = mirror.children.first(where: { $0.label == "parseMessage" })?.value as? (String) -> TwitchChatMessage else {
            XCTFail("Could not access parseMessage method")
            return
        }
        
        let parsedMessage = parseMessageMethod(rawMessage)
        
        #expect(parsedMessage.author.username == "testuser")
        #expect(parsedMessage.author.displayName == "TestUser")
        #expect(parsedMessage.channel == "channel")
        #expect(parsedMessage.content == "Kappa Hello Kappa World")
        #expect(parsedMessage.author.color == "#0000FF")
        #expect(parsedMessage.author.badges["subscriber"] == "6")
        #expect(parsedMessage.author.badges["premium"] == "1")
        #expect(parsedMessage.emotes.count == 3)
        #expect(parsedMessage.id == "b34ccfc7-4977-403a-8a94-33c6bac34fb8")
        #expect(parsedMessage.timestamp == Date(timeIntervalSince1970: 1619191991.246))
    }
    
    @Test("Parse Emotes")
    func testParseEmotes() throws {
        let twitchKit = TwitchKit()
        let emotesString = "25:0-4,12-16/1902:6-10"
        
        // Use reflection to access private method for testing
        let mirror = Mirror(reflecting: twitchKit)
        guard let parseEmotesMethod = mirror.children.first(where: { $0.label == "parseEmotes" })?.value as? (String) -> [TwitchEmote] else {
            XCTFail("Could not access parseEmotes method")
            return
        }
        
        let parsedEmotes = parseEmotesMethod(emotesString)
        
        #expect(parsedEmotes.count == 3)
        #expect(parsedEmotes[0].id == "25")
        #expect(parsedEmotes[0].startIndex == 0)
        #expect(parsedEmotes[0].endIndex == 4)
        #expect(parsedEmotes[1].id == "25")
        #expect(parsedEmotes[1].startIndex == 12)
        #expect(parsedEmotes[1].endIndex == 16)
        #expect(parsedEmotes[2].id == "1902")
        #expect(parsedEmotes[2].startIndex == 6)
        #expect(parsedEmotes[2].endIndex == 10)
    }
    
    @Test("Parse Badges")
    func testParseBadges() throws {
        let twitchKit = TwitchKit()
        let badgesString = "subscriber/6,premium/1"
        
        // Use reflection to access private method for testing
        let mirror = Mirror(reflecting: twitchKit)
        guard let parseBadgesMethod = mirror.children.first(where: { $0.label == "parseBadges" })?.value as? (String) -> [String: String] else {
            XCTFail("Could not access parseBadges method")
            return
        }
        
        let parsedBadges = parseBadgesMethod(badgesString)
        
        #expect(parsedBadges.count == 2)
        #expect(parsedBadges["subscriber"] == "6")
        #expect(parsedBadges["premium"] == "1")
    }
    
    @Test("Twitch Emote URL")
    func testTwitchEmoteURL() {
        let emote = TwitchEmote(id: "25", startIndex: 0, endIndex: 4)
        let expectedURL = URL(string: "https://static-cdn.jtvnw.net/emoticons/v2/25/default/dark/3.0")
        
        #expect(emote.url == expectedURL)
    }
}
