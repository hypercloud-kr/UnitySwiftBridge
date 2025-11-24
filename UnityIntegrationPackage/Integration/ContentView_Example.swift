// Unity를 시작하는 SwiftUI View 예시

import SwiftUI

struct ContentView: View {
    @State private var showUnityView = false
    @StateObject private var bridgeHandler = UnityBridgeHandler()

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Unity AR Demo")
                    .font(.largeTitle)
                    .padding()

                // Unity 시작 버튼
                Button(action: {
                    startUnity()
                }) {
                    Text("Start Unity AR")
                        .font(.title2)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                // Unity 통신 테스트
                Button(action: {
                    testUnityBridge()
                }) {
                    Text("Test Unity Communication")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .onAppear {
                setupUnityBridge()
            }
            .sheet(isPresented: $showUnityView) {
                UnityViewWrapper()
            }
        }
    }

    private func startUnity() {
        print("[ContentView] Starting Unity...")

        // Unity 시작
        if let window = UIApplication.shared.windows.first {
            UnityManager.shared.showUnity(inWindow: window)
        }
        UnityManager.shared.showUnityWindow()

        showUnityView = true
    }

    private func testUnityBridge() {
        // Unity로 메시지 전송
        UnityBridge.shared.sendMessage(
            to: "iOSBridge",
            method: "TestMessage",
            message: "Hello from iOS!"
        )

        // JSON 데이터 전송
        let testData: [String: Any] = [
            "command": "test",
            "data": "Test data from iOS",
            "timestamp": Date().timeIntervalSince1970
        ]
        UnityBridge.shared.sendJSONData(testData)
    }

    private func setupUnityBridge() {
        print("[ContentView] Set UnityBridge delegate")
        UnityBridge.shared.delegate = bridgeHandler

        // Unity가 닫기를 요청할 때
        bridgeHandler.onCloseRequested = {
            DispatchQueue.main.async {
                UnityManager.shared.hideUnity()
                showUnityView = false
            }
        }
    }
}

// Unity View Wrapper
struct UnityViewWrapper: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // Unity View
            UnityViewRepresentable()
                .edgesIgnoringSafeArea(.all)

            // 닫기 버튼
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        UnityManager.shared.hideUnity()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }
}

// Unity Bridge Handler
class UnityBridgeHandler: ObservableObject, UnityBridgeDelegate {
    var onCloseRequested: (() -> Void)?

    func unityDidReceiveMessage(_ message: String) {
        print("[Unity → iOS] Message: \(message)")
    }

    func unityARPlaneDetected(planeId: String, position: (x: Float, y: Float, z: Float)) {
        print("[Unity → iOS] AR Plane detected: \(planeId) at (\(position.x), \(position.y), \(position.z))")
    }

    func unityARSessionStateChanged(_ state: String) {
        print("[Unity → iOS] AR Session state: \(state)")
    }

    func unityReady() {
        print("[Unity → iOS] Unity is ready!")
    }

    func unityRequestCloseView() {
        print("[Unity → iOS] Close requested")
        onCloseRequested?()
    }
}