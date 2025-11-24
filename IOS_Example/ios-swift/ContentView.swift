//
//  ContentView.swift
//  ios-swift
//
//  Created by hypercloud on 11/21/25.
//

import SwiftUI

struct ContentView: View {

    @State private var showUnityView = false
    @State private var statusMessage = "Unity 준비 중..."
    @StateObject private var bridgeHandler = UnityBridgeHandler()

    // 자동 메시지 전송용
    @State private var messageTimer: Timer?
    @State private var messageCount = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {

                // 상태 표시
                VStack(spacing: 10) {
                    Image(systemName: "cube.transparent")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)

                    Text("iOS Unity Connect")
                        .font(.title)
                        .fontWeight(.bold)

                    Text(statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if messageCount > 0 {
                        Text("전송 횟수: \(messageCount)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                .padding()

                Divider()

                // Unity 제어 버튼들
                VStack(spacing: 15) {

                    Button(action: {
                        print("[ContentView] Starting Unity...")

                        // Unity 시작 또는 다시 표시
                        if let window = UIApplication.shared.windows.first {
                            UnityManager.shared.showUnity(inWindow: window)
                        }

                        // Unity window가 숨겨져 있다면 다시 표시
                        UnityManager.shared.showUnityWindow()

                        showUnityView = true
                    }) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text("Unity AR 시작하기")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }

                }
                .padding(.horizontal)

                Spacer()

                // 정보
                VStack(spacing: 5) {
                    Text("💡 AR 기능을 사용하려면 실제 기기가 필요합니다")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .navigationTitle("홈")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                checkUnityStatus()

                // UnityBridge 델리게이트 설정
                UnityBridge.shared.delegate = bridgeHandler
                print("[ContentView] Set UnityBridge delegate")

                // 닫기 요청 처리
                bridgeHandler.onCloseRequested = {
                    print("[ContentView] onCloseRequested called - closing Unity view")
                    DispatchQueue.main.async {
                        print("[ContentView] Executing on main thread")

                        // Unity window 명시적으로 숨기기
                        UnityManager.shared.hideUnity()

                        showUnityView = false
                        print("[ContentView] showUnityView set to false: \(showUnityView)")
                    }
                }

                // 자동 메시지 전송 비활성화 (메모리 에러 방지)
                // startAutoMessageSending()
            }
            .onDisappear {
                stopAutoMessageSending()
            }
            .sheet(isPresented: $showUnityView) {
                UnityViewWrapper()
            }
        }
    }

    // Unity 상태 확인
    private func checkUnityStatus() {
        if UnityBridge.shared.isUnityReady {
            statusMessage = "Unity 준비 완료 ✅"
        } else {
            statusMessage = "Unity 로드 중... ⏳"

            // 1초 후 다시 확인
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                checkUnityStatus()
            }
        }
    }

    // Unity 통신 테스트
    private func testUnityConnection() {
        print("[Test] Sending test message to Unity")
        UnityBridge.shared.sendMessage(
            to: "iOSBridge",
            method: "ReceiveJSONData",
            message: "{\"command\":\"test\",\"data\":\"Hello from Swift!\"}"
        )

        statusMessage = "테스트 메시지 전송됨 📤"

        // 2초 후 상태 복구
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            checkUnityStatus()
        }
    }

    // 자동 메시지 전송 시작
    private func startAutoMessageSending() {
        print("[Auto] Starting automatic message sending")

        // 이미 실행 중이면 중지
        stopAutoMessageSending()

        // 2초마다 Unity에 메시지 전송
        messageTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [self] _ in
            messageCount += 1

            let message = "{\"command\":\"auto_test\",\"count\":\(messageCount),\"timestamp\":\(Date().timeIntervalSince1970)}"

            print("[Auto] Sending message #\(messageCount) to Unity")
            UnityBridge.shared.sendMessage(
                to: "iOSBridge",
                method: "ReceiveJSONData",
                message: message
            )

            statusMessage = "자동 전송 중... #\(messageCount) 📡"
        }

        // 즉시 한 번 전송
        messageCount = 1
        let message = "{\"command\":\"auto_test\",\"count\":\(messageCount),\"timestamp\":\(Date().timeIntervalSince1970)}"
        print("[Auto] Sending initial message #\(messageCount) to Unity")
        UnityBridge.shared.sendMessage(
            to: "iOSBridge",
            method: "ReceiveJSONData",
            message: message
        )
        statusMessage = "자동 전송 시작 📡"
    }

    // 자동 메시지 전송 중지
    private func stopAutoMessageSending() {
        messageTimer?.invalidate()
        messageTimer = nil
        print("[Auto] Stopped automatic message sending")
    }
}

// Unity View Wrapper (모달로 표시)
struct UnityViewWrapper: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // Unity View
            UnityViewRepresentable()
                .ignoresSafeArea(.all)

            // 상단 닫기 버튼
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .shadow(radius: 3)
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
        print("[BridgeHandler] Received message: \(message)")
    }

    func unityARPlaneDetected(planeId: String, position: (x: Float, y: Float, z: Float)) {
        print("[BridgeHandler] Plane detected: \(planeId)")
    }

    func unityARSessionStateChanged(_ state: String) {
        print("[BridgeHandler] Session state: \(state)")
    }

    func unityReady() {
        print("[BridgeHandler] Unity ready")
    }

    func unityRequestCloseView() {
        print("[BridgeHandler] Unity requested to close view")
        DispatchQueue.main.async {
            self.onCloseRequested?()
        }
    }
}

#Preview {
    ContentView()
}
