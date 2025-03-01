//
//  Offer.swift
//  WebRTCDemo
//
//  Created by Mohamed Khater on 24/02/2025.
//

import Foundation
import WebRTC

struct Offer: Codable {
    let offer: SessionDescription
}

extension Offer {
    init(sdp: String) {
        self.offer = SessionDescription(sdp: sdp, type: "offer")
    }
}
