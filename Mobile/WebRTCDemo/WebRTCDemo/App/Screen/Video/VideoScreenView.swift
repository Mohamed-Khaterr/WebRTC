//
//  VideoScreenView.swift
//  WebRTCDemo
//
//  Created by Mohamed Khater on 24/02/2025.
//

import SwiftUI

struct VideoScreenView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> VideoViewController {
        VideoViewController()
    }
    
    func updateUIViewController(_ uiViewController: VideoViewController, context: Context) {}
}
