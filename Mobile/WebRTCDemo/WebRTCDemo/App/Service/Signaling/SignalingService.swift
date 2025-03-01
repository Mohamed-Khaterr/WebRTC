//
//  SignalingService.swift
//  WebRTCDemo
//
//  Created by Mohamed Khater on 23/02/2025.
//

import Foundation

protocol SignalingService: AnyObject {
    var delegate: SignalingServiceDelegate? { get set }
    func connect()
    func send(_ data: Encodable)
}
