# Unity Swift Bridge

A powerful Swift bridge library for seamless Unity Framework integration in iOS native applications.

[![Swift](https://img.shields.io/badge/Swift-5.5+-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-14.0+-blue.svg)](https://www.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Features

- **Bidirectional Communication**: Send messages between Swift and Unity seamlessly
- **SwiftUI Support**: Modern UI framework integration with full support
- **Lifecycle Management**: Complete control over Unity's lifecycle
- **AR Foundation Ready**: Built-in AR session management and plane detection
- **Type-Safe JSON Communication**: Structured data exchange between platforms
- **Thread-Safe Operations**: Safe cross-thread communication handling

## Requirements

- iOS 14.0+
- Xcode 13.0+
- Swift 5.5+
- Unity 2021.3+ (for framework generation)

## Installation

### Manual Installation

1. Copy the following files to your project:

```
UnityBridge/
├── UnityManager.swift
├── UnityBridge.swift
└── UnityViewRepresentable.swift
```

2. Add UnityFramework.framework to your project (Embed & Sign)
3. Configure your project settings (see [Integration Guide](./통합_가이드.md))

### Swift Package Manager

Coming soon...

## Quick Start

### 1. Initialize Unity in AppDelegate

```swift
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize Unity after app launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UnityManager.shared.loadUnity()
        }
        return true
    }
}
```

### 2. Display Unity View in SwiftUI

```swift
import SwiftUI

struct ContentView: View {
    @State private var showUnity = false

    var body: some View {
        VStack(spacing: 20) {
            Button("Launch Unity") {
                showUnity = true
            }
            .buttonStyle(.borderedProminent)
        }
        .sheet(isPresented: $showUnity) {
            UnityViewRepresentable()
                .edgesIgnoringSafeArea(.all)
        }
    }
}
```

### 3. Send Messages to Unity

```swift
// Send JSON data to Unity
let data: [String: Any] = [
    "command": "startGame",
    "level": 1,
    "playerName": "Swift User"
]

UnityBridge.shared.sendJSONData(data)

// Or send direct messages
UnityBridge.shared.sendMessage(
    to: "GameController",
    method: "LoadLevel",
    message: "1"
)
```

### 4. Receive Messages from Unity

```swift
class GameBridgeHandler: ObservableObject, UnityBridgeDelegate {
    @Published var gameScore: Int = 0
    @Published var gameState: String = "idle"

    func unityDidReceiveMessage(_ message: String) {
        // Parse Unity messages
        if let data = message.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

            if let score = json["score"] as? Int {
                DispatchQueue.main.async {
                    self.gameScore = score
                }
            }

            if let state = json["state"] as? String {
                DispatchQueue.main.async {
                    self.gameState = state
                }
            }
        }
    }

    func unityReady() {
        print("Unity is ready for communication")
    }

    func unityRequestCloseView() {
        // Handle Unity close request
    }
}
```

## API Reference

### UnityManager

Singleton class managing Unity's lifecycle.

```swift
// Load Unity Framework
UnityManager.shared.loadUnity()

// Show Unity in a window
UnityManager.shared.showUnity(inWindow: window)

// Hide Unity view
UnityManager.shared.hideUnity()

// Pause/Resume Unity
UnityManager.shared.pauseUnity()
UnityManager.shared.resumeUnity()

// Unload Unity (cleanup)
UnityManager.shared.unloadUnity()
```

### UnityBridge

Handles bidirectional communication between Swift and Unity.

```swift
// Set delegate for receiving messages
UnityBridge.shared.delegate = myDelegate

// Send message to GameObject
UnityBridge.shared.sendMessage(
    to: "GameObject",      // Target GameObject name
    method: "MethodName",  // Method to call
    message: "data"        // String parameter
)

// Send JSON data
UnityBridge.shared.sendJSONData(["key": "value"])

// AR-specific commands
UnityBridge.shared.startARSession(config: ["planeDetection": true])
UnityBridge.shared.stopARSession()
UnityBridge.shared.resetARSession()
UnityBridge.shared.togglePlaneDetection(enabled: true)
```

### UnityBridgeDelegate

Protocol for receiving Unity messages.

```swift
protocol UnityBridgeDelegate: AnyObject {
    func unityDidReceiveMessage(_ message: String)
    func unityARPlaneDetected(planeId: String, position: (x: Float, y: Float, z: Float))
    func unityARSessionStateChanged(_ state: String)
    func unityReady()
    func unityRequestCloseView()
}
```

## Communication Protocol

### Swift → Unity

Messages are sent to the `iOSBridge` GameObject in Unity. Available methods:

- `ReceiveJSONData(string jsonData)` - Receive JSON data
- `StartARSession(string config)` - Start AR session
- `StopARSession(string dummy)` - Stop AR session
- `ResetARSession(string dummy)` - Reset AR session
- `TogglePlaneDetection(string enabled)` - Toggle plane detection

### Unity → Swift

Unity can call native iOS methods through the bridge:

```csharp
// In Unity C#
[DllImport("__Internal")]
private static extern void SendMessageToiOS(string message);

// Send message to iOS
SendMessageToiOS("{\"event\":\"gameComplete\",\"score\":100}");
```

## Project Configuration

### Required Build Settings

1. **Framework Search Paths**: `$(PROJECT_DIR)`
2. **Other Linker Flags**: `-Wl,-U,_UnityReplayKitDelegate`
3. **Enable Bitcode**: `No`
4. **Always Embed Swift Standard Libraries**: `Yes`

### Info.plist Additions

```xml
<key>io.unity3d.framework</key>
<string>unity</string>
<key>CADisableMinimumFrameDurationOnPhone</key>
<true/>
```

## Example Projects

Check out the `/IOS_Example` directory for a complete working example with:
- SwiftUI integration
- AR functionality
- Bidirectional communication
- State management

## Best Practices

1. **Initialization Timing**: Load Unity after app launch (0.5s delay recommended)
2. **Thread Safety**: Always update UI on main thread when receiving Unity callbacks
3. **Memory Management**: Properly unload Unity when not needed
4. **Error Handling**: Implement proper error handling for Unity initialization failures
5. **Testing**: Test on real devices for AR features

## Troubleshooting

### Unity doesn't start
- Verify UnityFramework is properly embedded (Embed & Sign)
- Check Framework Search Paths in Build Settings
- Ensure Data folder is added as folder reference

### Communication not working
- Verify "iOSBridge" GameObject exists in Unity scene
- Check delegate is properly set before sending messages
- Ensure JSON format is correct for data exchange

### AR features not working
- Test on real device (simulator doesn't support AR)
- Check camera permissions in Info.plist
- Verify AR session configuration

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues, questions, or suggestions, please open an issue on GitHub.

## Acknowledgments

- Unity Technologies for the Unity Framework
- Apple for SwiftUI and ARKit
- The iOS development community

---

Made with ❤️ by Hypercloud