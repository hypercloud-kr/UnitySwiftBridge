//
//  UnityBridge.swift
//  ios-swift
//
//  Bridge for communication between Swift and Unity
//

import Foundation
import UnityFramework

/// Protocol for handling Unity callbacks
protocol UnityBridgeDelegate: AnyObject {
    func unityDidReceiveMessage(_ message: String)
    func unityARPlaneDetected(planeId: String, position: (x: Float, y: Float, z: Float))
    func unityARSessionStateChanged(_ state: String)
    func unityReady()
    func unityRequestCloseView()
}

/// Singleton bridge for Unity <-> Swift communication
@objc(UnityBridge)
class UnityBridge: NSObject {

    // MARK: - Singleton
    @objc static let shared = UnityBridge()

    // MARK: - Properties
    weak var delegate: UnityBridgeDelegate?
    private var unityFramework: UnityFramework?

    private override init() {
        super.init()
    }

    // MARK: - Unity Framework Setup

    func setUnityFramework(_ framework: UnityFramework) {
        self.unityFramework = framework
    }

    // MARK: - Swift -> Unity Communication

    /// Send a message to Unity
    /// - Parameters:
    ///   - objectName: The GameObject name in Unity
    ///   - method: The method name to call
    ///   - message: The message/parameter to pass
    func sendMessage(to objectName: String, method: String, message: String) {
        guard let framework = unityFramework else {
            print("[Swift->Unity] Error: UnityFramework not set")
            return
        }

        print("[Swift->Unity] Sending to \(objectName).\(method): \(message)")
        framework.sendMessageToGO(
            withName: objectName,
            functionName: method,
            message: message
        )
    }

    /// Start AR session in Unity
    func startARSession(config: String = "") {
        sendMessage(to: "iOSBridge", method: "StartARSession", message: config)
    }

    /// Stop AR session in Unity
    func stopARSession() {
        sendMessage(to: "iOSBridge", method: "StopARSession", message: "")
    }

    /// Reset AR session in Unity
    func resetARSession() {
        sendMessage(to: "iOSBridge", method: "ResetARSession", message: "")
    }

    /// Toggle plane detection in Unity
    func togglePlaneDetection(enabled: Bool) {
        sendMessage(to: "iOSBridge", method: "TogglePlaneDetection", message: enabled ? "true" : "false")
    }

    /// Send JSON data to Unity
    func sendJSONData(_ data: [String: Any]) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("[Swift->Unity] Error: Failed to serialize JSON")
            return
        }

        sendMessage(to: "iOSBridge", method: "ReceiveJSONData", message: jsonString)
    }

    /// Send command to Unity
    func sendCommand(_ command: String, data: String = "") {
        let json: [String: Any] = [
            "command": command,
            "data": data
        ]
        sendJSONData(json)
    }

    // MARK: - Unity -> Swift Communication (Callbacks)

    /// Called from Unity when a message is sent
    /// This method is exposed to Unity via C++ bridge
    @objc func onUnityMessage(_ message: String) {
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
    @objc func onARPlaneDetectedJSON(_ jsonString: String) {
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
    @objc func onARPlaneDetected(_ planeId: String, x: Float, y: Float, z: Float) {
        print("[Unity->Swift] Plane detected: \(planeId) at (\(x), \(y), \(z))")
        delegate?.unityARPlaneDetected(planeId: planeId, position: (x, y, z))
    }

    /// Called from Unity when AR session state changes
    @objc func onARSessionStateChanged(_ state: String) {
        print("[Unity->Swift] AR Session state: \(state)")
        delegate?.unityARSessionStateChanged(state)
    }

    /// Called from Unity when it's ready
    @objc func onUnityReady() {
        print("[Unity->Swift] Unity is ready")
        delegate?.unityReady()
    }
}

// MARK: - Unity Message Handler Extension

extension UnityBridge {

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

extension UnityBridge {

    /// Check if Unity is ready
    var isUnityReady: Bool {
        return unityFramework != nil
    }

    /// Show Unity view
    func showUnityView() {
        unityFramework?.showUnityWindow()
    }

    /// Hide Unity view
    func hideUnityView() {
        // Note: Unity doesn't provide a direct hide method
        // You'll need to implement this by managing the view hierarchy
    }

    /// Pause Unity
    func pauseUnity() {
        unityFramework?.pause(true)
    }

    /// Resume Unity
    func resumeUnity() {
        unityFramework?.pause(false)
    }
}
