//
//  WebRTCClientDelegate.swift
//  WebRTCDemo
//
//  Created by Mohamed Khater on 24/02/2025.
//

import Foundation

protocol WebRTCClientDelegate: AnyObject {
    func webRTC(_ client: WebRTCClient, onError error: Error)
    func webRTC(_ client: WebRTCClient, didCreate sdp: String, of type: SessionDescriptionType)
    func webRTC(_ client: WebRTCClient, didGenerate ice: ICECandidate)
}
