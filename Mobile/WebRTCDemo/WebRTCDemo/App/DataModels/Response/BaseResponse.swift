//
//  BaseResponse.swift
//  WebRTCDemo
//
//  Created by Mohamed Khater on 23/02/2025.
//

import Foundation

struct BaseResponse<T: Decodable>: Decodable {
//    let user: UserResponse
    let message: T
}
