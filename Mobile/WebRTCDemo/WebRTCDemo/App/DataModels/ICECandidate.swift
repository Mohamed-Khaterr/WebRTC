//
//  ICECandidate.swift
//  WebRTCDemo
//
//  Created by Mohamed Khater on 27/02/2025.
//

import Foundation
import WebRTC

struct ICECandidate: Codable {
    let ice: ICE
    
    struct ICE: Codable {
        /// The Session Description Protocol (SDP) of the candidate.
        let candidate: String
        /// The index of the media stream this candidate applies to.
        let sdpMLineIndex: Int32
        /// The media stream ID.
        let sdpMid: String?
    }
}

extension ICECandidate {
    init(ice: RTCIceCandidate) {
        self.ice = .init(candidate: ice.sdp, sdpMLineIndex: ice.sdpMLineIndex, sdpMid: ice.sdpMid)
    }
    
    var iceCandidate: RTCIceCandidate {
        RTCIceCandidate(sdp: ice.candidate, sdpMLineIndex: ice.sdpMLineIndex, sdpMid: ice.sdpMid)
    }
}
