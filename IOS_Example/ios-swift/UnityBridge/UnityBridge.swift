//
//  UnityBridge.swift
//  ios-swift
//
//  Bridge for communication between Swift and Unity
//

import Foundation

/// Protocol for handling Unity callbacks
public protocol UnityBridgeDelegate: AnyObject {
    func unityDidReceiveMessage(_ message: String)
    func unityARPlaneDetected(planeId: String, position: (x: Float, y: Float, z: Float))
    func unityARSessionStateChanged(_ state: String)
    func unityReady()
    func unityRequestCloseView()
}

/// Singleton bridge for Unity <-> Swift communication
@objc(UnityBridge)
public class UnityBridge: NSObject {

    // MARK: - Singleton
    @objc public static let shared = UnityBridge()

    // MARK: - Properties
    public weak var delegate: UnityBridgeDelegate?
    private var unityFramework: NSObject?

    private override init() {
        super.init()
    }

    // MARK: - Unity Framework Setup

    public func setUnityFramework(_ framework: NSObject) {
        self.unityFramework = framework
    }

    // MARK: - Swift -> Unity Communication

    /// Send a message to Unity
    /// - Parameters:
    ///   - objectName: The GameObject name in Unity
    ///   - method: The method name to call
    ///   - message: The message/parameter to pass
    public func sendMessage(to objectName: String, method: String, message: String) {
        guard let framework = unityFramework else {
            print("[Swift->Unity] Error: UnityFramework not set")
            return
        }

        print("[Swift->Unity] Sending to \(objectName).\(method): \(message)")

        // Use selector-based invocation with proper type casting
        let selector = NSSelectorFromString("sendMessageToGOWithName:functionName:message:")
        if framework.responds(to: selector) {
            // Create a closure that matches the expected signature
            typealias SendMessageIMP = @convention(c) (AnyObject, Selector, NSString, NSString, NSString) -> Void

            // Get the method implementation
            let instanceMethod = class_getInstanceMethod(type(of: framework), selector)!
            let imp = method_getImplementation(instanceMethod)

            // Cast to function type
            let function = unsafeBitCast(imp, to: SendMessageIMP.self)

            // Call with proper NSString objects
            function(framework, selector, objectName as NSString, method as NSString, message as NSString)
        } else {
            print("[Swift->Unity] Error: UnityFramework doesn't respond to sendMessageToGOWithName")
        }
    }

    /// Start AR session in Unity
    public func startARSession(config: String = "") {
        sendMessage(to: "iOSBridge", method: "StartARSession", message: config)
    }

    /// Stop AR session in Unity
    public func stopARSession() {
        sendMessage(to: "iOSBridge", method: "StopARSession", message: "")
    }

    /// Reset AR session in Unity
    public func resetARSession() {
        sendMessage(to: "iOSBridge", method: "ResetARSession", message: "")
    }

    /// Toggle plane detection in Unity
    public func togglePlaneDetection(enabled: Bool) {
        sendMessage(to: "iOSBridge", method: "TogglePlaneDetection", message: enabled ? "true" : "false")
    }

    /// Send JSON data to Unity
    public func sendJSONData(_ data: [String: Any]) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("[Swift->Unity] Error: Failed to serialize JSON")
            return
        }

        sendMessage(to: "iOSBridge", method: "ReceiveJSONData", message: jsonString)
    }

    /// Send command to Unity
    public func sendCommand(_ command: String, data: String = "") {
        let json: [String: Any] = [
            "command": command,
            "data": data
        ]
        sendJSONData(json)
    }

    // MARK: - Unity -> Swift Communication (Callbacks)

    /// Called from Unity when a message is sent
    /// This method is exposed to Unity via C++ bridge
    @objc public func onUnityMessage(_ message: String) {
        print("[Unity->Swift] Message: \(message)")

        // 특수 메시지 처리
        if message == "close_unity_view" {
            print("[Unity->Swift] Requesting to close Unity view")
            delegate?.unityRequestCloseView()
            return
        }

        delegate?.unityDidReceiveMessage(message)
    }

    /// Called from Unity when an AR plane is detected (JSON format)
    @objc public func onARPlaneDetectedJSON(_ jsonString: String) {
        print("[Unity->Swift] Plane detected JSON: \(jsonString)")

        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let planeId = json["planeId"] as? String,
              let x = json["x"] as? NSNumber,
              let y = json["y"] as? NSNumber,
              let z = json["z"] as? NSNumber else {
            print("[Unity->Swift] Error: Failed to parse plane detection JSON")
            return
        }

        delegate?.unityARPlaneDetected(planeId: planeId, position: (x.floatValue, y.floatValue, z.floatValue))
    }

    /// Called from Unity when an AR plane is detected (legacy method - kept for compatibility)
    @objc public func onARPlaneDetected(_ planeId: String, x: Float, y: Float, z: Float) {
        print("[Unity->Swift] Plane detected: \(planeId) at (\(x), \(y), \(z))")
        delegate?.unityARPlaneDetected(planeId: planeId, position: (x, y, z))
    }

    /// Called from Unity when AR session state changes
    @objc public func onARSessionStateChanged(_ state: String) {
        print("[Unity->Swift] AR Session state: \(state)")
        delegate?.unityARSessionStateChanged(state)
    }

    /// Called from Unity when it's ready
    @objc public func onUnityReady() {
        print("[Unity->Swift] Unity is ready")
        delegate?.unityReady()
    }
}

// MARK: - Unity Message Handler Extension

public extension UnityBridge {

    /// Parse and handle structured messages from Unity
    func handleStructuredMessage(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let messageType = json["type"] as? String else {
            print("[Unity->Swift] Error: Failed to parse structured message")
            return
        }

        switch messageType {
        case "planeDetected":
            if let planeId = json["planeId"] as? String,
               let position = json["position"] as? [String: Float],
               let x = position["x"], let y = position["y"], let z = position["z"] {
                delegate?.unityARPlaneDetected(planeId: planeId, position: (x, y, z))
            }

        case "sessionStateChanged":
            if let state = json["state"] as? String {
                delegate?.unityARSessionStateChanged(state)
            }

        default:
            print("[Unity->Swift] Unknown message type: \(messageType)")
        }
    }
}

// MARK: - Convenience Methods

public extension UnityBridge {

    /// Check if Unity is ready
    var isUnityReady: Bool {
        return unityFramework != nil
    }

    /// Show Unity view
    func showUnityView() {
        guard let framework = unityFramework else { return }

        let selector = NSSelectorFromString("showUnityWindow")
        if framework.responds(to: selector) {
            framework.perform(selector)
        }
    }

    /// Hide Unity view
    func hideUnityView() {
        // Note: Unity doesn't provide a direct hide method
        // You'll need to implement this by managing the view hierarchy
    }

    /// Pause Unity
    func pauseUnity() {
        guard let framework = unityFramework else { return }

        let selector = NSSelectorFromString("pause:")
        if framework.responds(to: selector) {
            framework.perform(selector, with: NSNumber(value: true))
        }
    }

    /// Resume Unity
    func resumeUnity() {
        guard let framework = unityFramework else { return }

        let selector = NSSelectorFromString("pause:")
        if framework.responds(to: selector) {
            framework.perform(selector, with: NSNumber(value: false))
        }
    }
}
