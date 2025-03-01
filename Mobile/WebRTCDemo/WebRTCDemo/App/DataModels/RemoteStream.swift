//
//  RemoteStream.swift
//  WebRTCDemo
//
//  Created by Mohamed Khater on 27/02/2025.
//

import Foundation
import WebRTC

class RemoteStream {
    /// View that will present remote peer video
    var view: UIView?
    /// Content Mode of remote peer video
    var contentMode: UIView.ContentMode = .scaleAspectFit
    /// Remote peer track
    var track: RTCVideoTrack?
}
