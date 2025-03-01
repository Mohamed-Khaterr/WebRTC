//
//  SignalingServiceDelegate.swift
//  WebRTCDemo
//
//  Created by Mohamed Khater on 01/03/2025.
//

import Foundation

protocol SignalingServiceDelegate: AnyObject {
    func signalingService(_ service: SignalingService, on message: Data)
}
