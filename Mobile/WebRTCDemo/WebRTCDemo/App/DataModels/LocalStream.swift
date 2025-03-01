//
//  LocalStream.swift
//  WebRTCDemo
//
//  Created by Mohamed Khater on 27/02/2025.
//

import Foundation
import WebRTC

class LocalStream {
    /// Reference of local peer track
    var track: RTCVideoTrack?
    /// Reference of local Capture session
    var capture: RTCVideoCapturer?
}
