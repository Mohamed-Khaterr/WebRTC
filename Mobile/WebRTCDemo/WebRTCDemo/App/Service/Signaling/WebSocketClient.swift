//
//  WebSocketClient.swift
//  WebRTCDemo
//
//  Created by Mohamed Khater on 23/02/2025.
//

import Foundation

final class WebSocketClient: NSObject, SignalingService {
    weak var delegate: SignalingServiceDelegate?
    private var webSocketTask: URLSessionWebSocketTask?
    private let webSocketURL: URL = URL(string: "ws://XXX.XXX.X.X:8080")!
    
    func connect() {
        webSocketTask = URLSession.shared.webSocketTask(with: webSocketURL)
        webSocketTask?.delegate = self
        webSocketTask?.resume()
        startReceive()
    }
    
    private func startReceive() {
        webSocketTask?.receive(completionHandler: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    delegate?.signalingService(self, on: data)
                case .string(let text):
                    if let data = text.data(using: .utf8) {
                        delegate?.signalingService(self, on: data)
                    }
                @unknown default:
                    fatalError()
                }
            case .failure(let error):
                print(error)
            }
            startReceive()
        })
    }
    
    func send(_ obj: any Encodable) {
        guard let data = try? JSONEncoder().encode(obj) else { return }
        let messageObj = URLSessionWebSocketTask.Message.data(data)
        webSocketTask?.send(messageObj) { error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
}

extension WebSocketClient: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket Connected!")
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket Closed!")
    }
}
