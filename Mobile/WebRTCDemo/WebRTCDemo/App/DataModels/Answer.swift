//
//  Answer.swift
//  WebRTCDemo
//
//  Created by Mohamed Khater on 24/02/2025.
//

import Foundation

struct Answer: Codable {
    let answer: SessionDescription
}

extension Answer {
    init(sdp: String) {
        self.answer = SessionDescription(sdp: sdp, type: "answer")
    }
}
