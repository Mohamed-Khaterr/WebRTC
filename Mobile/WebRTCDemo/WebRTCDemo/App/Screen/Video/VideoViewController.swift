//
//  VideoViewController.swift
//  WebRTCDemo
//
//  Created by Mohamed Khater on 23/02/2025.
//

import UIKit
import AVFoundation

final class VideoViewController: UIViewController {
    let signaling: SignalingService = WebSocketClient()
    let webRTC: WebRTCClient = .init()
    @IBOutlet weak var localVideoView: UIView!
    @IBOutlet weak var remoteVideoView: UIView!
    
    init() {
        super.init(nibName: String(describing: Self.self), bundle: nil)
        signaling.delegate = self
        signaling.connect()
        webRTC.delegate = self
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AVCaptureDevice.requestAccess(for: .video) { _ in
            
        }
    }
    
    @IBAction func callAction(_ sender: UIButton) {
        webRTC.trackLocalStream(showOn: localVideoView, contentMode: .scaleAspectFill, position: .front)
        webRTC.trackRemoteStream(showOn: remoteVideoView, contentMode: .scaleAspectFit)
        webRTC.createOffer()
    }
}

// MARK: - Signaling
extension VideoViewController: SignalingServiceDelegate {
    func signalingService(_ service: any SignalingService, on message: Data) {
        if let response = try? JSONDecoder().decode(BaseResponse<Offer>.self, from: message) {
            print("Receive Offer")
            webRTC.setOffer(response.message.offer.sdp)
        }
        
        if let response = try? JSONDecoder().decode(BaseResponse<Answer>.self, from: message) {
            print("Receive Answer")
            webRTC.setAnswer(response.message.answer.sdp)
        }
        
        if let response = try? JSONDecoder().decode(BaseResponse<ICECandidate>.self, from: message) {
            print("Receive ICE")
            webRTC.setRemoteICE(response.message)
        }
    }
}

// MARK: - WebRTC
extension VideoViewController: WebRTCClientDelegate {
    func webRTC(_ client: WebRTCClient, onError error: any Error) {
        print("Error:", error)
    }
    
    func webRTC(_ client: WebRTCClient, didCreate sdp: String, of type: SessionDescriptionType) {
        switch type {
        case .offer:
            print("Send Offer")
            let offer = Offer(sdp: sdp)
            signaling.send(offer)
        case .answer:
            print("Send Answer")
            let answer = Answer(sdp: sdp)
            signaling.send(answer)
        }
    }
    
    func webRTC(_ client: WebRTCClient, didGenerate ice: ICECandidate) {
        print("Send ICE")
        signaling.send(ice)
    }
}
