# TwitchKit

**TwitchKit** is a Swift framework designed to seamlessly integrate Twitch chat functionality into your applications. With TwitchKit, you can easily connect to Twitch chat, receive messages in real-time, and enhance interactivity for your users.

## Key Features

- **Simple Configuration**: Get started quickly with straightforward setup.
- **Real-Time Message Reception**: Listen for messages as they come in.
- **Twitch-Specific Message Parsing**: Handle badges, emotes, and more with ease.
- **Event-Based Architecture**: Easily integrate chat functionality into your app's workflow.

## Getting Started

To begin using TwitchKit in your project, follow these simple steps:

### Installation

Add TwitchKit as a package dependency in Xcode:

1. From the **File** menu, select **Add Package Dependencies**
2. Enter the following URL: `https://github.com/d6stiny/TwitchKit.git`
3. Click **Add Package** to include it in your project.

### Usage

Here’s how to connect to Twitch chat and listen for messages:

```swift

import TwitchKit

let twitch = TwitchKit()

// Configure with your Twitch credentials
twitch.configure(username: "your_username", token: "oauth:your_oauth_token", channel: "channel_to_join")

// Set up event handlers
twitch.onConnect = {
    print("Connected to Twitch chat!")
}

twitch.onMessage = { message in
    print("\(message.displayName): \(message.message)")
}

twitch.onError = { error in
    print("Error: \(error.localizedDescription)")
}

// Connect to Twitch chat
twitch.connect()

// To disconnect when you're done
// twitch.disconnect()

```

Make sure to replace `"your_username"`, `"oauth:your_oauth_token"`, and `"channel_to_join"` with your actual Twitch credentials and the channel you want to join.

## License

TwitchKit is released under the MIT License. See [LICENSE](LICENSE) for details.

---

With TwitchKit, you can create engaging experiences by bringing Twitch chat directly into your applications. Enjoy building!
