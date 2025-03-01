//
//  WebRTCClient.swift
//  WebRTCDemo
//
//  Created by Mohamed Khater on 23/02/2025.
//

import Foundation
import WebRTC
import AVFoundation

final class WebRTCClient: NSObject, RTCPeerConnectionDelegate {
    weak var delegate: WebRTCClientDelegate?
    
    private let mediaConstraints: RTCMediaConstraints = RTCMediaConstraints(
        mandatoryConstraints: nil,
        optionalConstraints: [
//            kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,
            kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue
        ]
    )
    
    private let factory: RTCPeerConnectionFactory = RTCPeerConnectionFactory(
        encoderFactory: RTCDefaultVideoEncoderFactory(),
        decoderFactory: RTCDefaultVideoDecoderFactory()
    )
    private var peerConnection: RTCPeerConnection?
    
    // Need to store steam properties on class scope not method scope
    // So that the video appear on view
    let localStream = LocalStream()
    let remoteStream = RemoteStream()
    
    // Send all generated ICE to remote Peer after gathering
    private var iceCandidates: [RTCIceCandidate] = []
    
    override init() {
        super.init()
        setPeerConnection()
    }
    
    private func setPeerConnection() {
        let config = RTCConfiguration()
        // Set STUN Servers
        // if STUN server the URL must start with "stun:"
        // if TRUN server the URL must start with "trun:"
        config.iceServers = [
            RTCIceServer(urlStrings: [
                "stun:stun.l.google.com:19302",
                "stun:stun2.l.google.com:19302",
                "stun:stun3.l.google.com:19302",
                "stun:stun4.l.google.com:19302"
            ])
        ]
        
        peerConnection = factory.peerConnection(with: config, constraints: mediaConstraints, delegate: self)
    }
    
    func trackLocalStream(showOn view: UIView, contentMode: UIView.ContentMode, position: AVCaptureDevice.Position) {
        let videoAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        guard videoAuthorizationStatus == .authorized else {
            let error = NSError(domain: "Camera Access Permission", code: 403, userInfo: [NSLocalizedDescriptionKey: "Camera access permission is not authorized"])
            delegate?.webRTC(self, onError: error)
            return
        }
        
        let videoSource = factory.videoSource()
        
        let videoTrack = factory.videoTrack(with: videoSource, trackId: UUID().uuidString)
        localStream.track = videoTrack
        
        let capture = RTCCameraVideoCapturer(delegate: videoSource)
        localStream.capture = capture
        
        // Start Capture local Video
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) {
            let format = device.activeFormat
            
            // Get the highest FPS
            let fps = device.activeFormat.videoSupportedFrameRateRanges.max { $0.maxFrameRate < $1.maxFrameRate }?.maxFrameRate ?? 30
            
            capture.startCapture(with: device, format: format, fps: Int(fps))
            
            // Show local video on given view
            DispatchQueue.main.async {
                let localVideoRender = RTCMTLVideoView(frame: view.bounds)
                localVideoRender.videoContentMode = contentMode
                view.addSubview(localVideoRender)
                videoTrack.add(localVideoRender) // Will display video captured by AVCaptureSession
            }
        }
        
        // Send local track to remote peer
        peerConnection?.add(videoTrack, streamIds: [UUID().uuidString])
    }
    
    func trackRemoteStream(showOn view: UIView, contentMode: UIView.ContentMode) {
        remoteStream.view = view
        remoteStream.contentMode = contentMode
    }
    
    private func renderRemoteStream(from track: RTCVideoTrack) {
        guard let view = remoteStream.view else { return }
        remoteStream.track = track
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let remoteVideoRender = RTCMTLVideoView(frame: view.bounds)
            remoteVideoRender.videoContentMode = remoteStream.contentMode
            view.addSubview(remoteVideoRender)
            track.add(remoteVideoRender) // Will display remote video
        }
    }
    
    func setRemoteICE(_ ice: ICECandidate) {
        peerConnection?.add(ice.iceCandidate) { [weak self] error in
            guard let self else { return }
            if let error {
                self.delegate?.webRTC(self, onError: error)
            }
        }
    }
}

// MARK: - Caller -
extension WebRTCClient {
    func createOffer() {
        peerConnection?.offer(for: mediaConstraints, completionHandler: { [weak self] offer, error in
            guard let self else { return }
            if let error = error {
                self.delegate?.webRTC(self, onError: error)
                return
            }
            
            guard let offer else { return }
            self.peerConnection?.setLocalDescription(offer) { setSDPError in
                if let error = setSDPError {
                    self.delegate?.webRTC(self, onError: error)
                } else {
                    self.delegate?.webRTC(self, didCreate: offer.sdp, of: .offer)
                }
            }
        })
    }
    
    func setAnswer(_ sdp: String) {
        let remoteSDP = RTCSessionDescription(type: .answer, sdp: sdp)
        peerConnection?.setRemoteDescription(remoteSDP, completionHandler: { [weak self] error in
            guard let self = self, let error else { return }
            self.delegate?.webRTC(self, onError: error)
        })
    }
}

// MARK: - Receiver -
extension WebRTCClient {
    func setOffer(_ sdp: String) {
        let remoteSDP = RTCSessionDescription(type: .offer, sdp: sdp)
        peerConnection?.setRemoteDescription(remoteSDP) { [weak self] error in
            guard let self else { return }
            if let error {
                delegate?.webRTC(self, onError: error)
            } else {
                createAnswer()
            }
        }
    }
    
    func createAnswer() {
        peerConnection?.answer(for: mediaConstraints, completionHandler: { [weak self] answer, error in
            guard let self else { return }
            if let error = error {
                self.delegate?.webRTC(self, onError: error)
                return
            }
            
            guard let answer else { return }
            self.peerConnection?.setLocalDescription(answer) { setSDPError in
                if let error = setSDPError {
                    self.delegate?.webRTC(self, onError: error)
                } else {
                    self.delegate?.webRTC(self, didCreate: answer.sdp, of: .answer)
                }
            }
        })
    }
}

// MARK: - Peer Connection -
extension WebRTCClient {
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        // unimplemented..
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        switch newState {
        case .new:
            print("Peer Connection State: New")
        case .checking:
            print("Peer Connection State: Checking")
        case .connected:
            print("Peer Connection State: connected")
        case .completed:
            print("Peer Connection State: completed")
        case .failed:
            print("Peer Connection State: failed")
        case .disconnected:
            print("Peer Connection State: disconnected")
        case .closed:
            print("Peer Connection State: closed")
        case .count:
            print("Peer Connection State: count")
        @unknown default:
            print("Peer Connection State: default")
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        // unimplemented..
    }
}

// MARK: - Remote Stream -
extension WebRTCClient {
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("Remote track received")
        for track in stream.videoTracks {
            renderRemoteStream(from: track)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        // unimplemented..
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didStartReceivingOn transceiver: RTCRtpTransceiver) {
        // unimplemented..
    }
}

// MARK: - ICE Candidate -
extension WebRTCClient {
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        iceCandidates.append(candidate)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        switch newState {
        case .new:
            print("Generate ICE State: New")
        case .gathering:
            print("Generate ICE State: Gathering")
        case .complete:
            print("Generate ICE State: Complete")
            for ice in iceCandidates {
                delegate?.webRTC(self, didGenerate: ICECandidate(ice: ice))
            }
            iceCandidates = []
        @unknown default:
            print("Generate ICE State: default")
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        // unimplemented..
    }
}

// MARK: - DataChannel -
extension WebRTCClient {
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        // unimplemented..
    }
}
