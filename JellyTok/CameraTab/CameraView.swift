//
//  CameraView.swift
//  JellyTok
//
//  Created by Moiz Siddiqui on 29/05/2025.
//


import SwiftUI
import AVFoundation

struct CameraView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UICameraPreviewView {
        let view = UICameraPreviewView() // Using a custom UIView subclass
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: UICameraPreviewView, context: Context) {}
}



// Custom UIView subclass to manage previewLayer's frame correctly
class UICameraPreviewView: UIView {
    let previewLayer: AVCaptureVideoPreviewLayer

    override init(frame: CGRect) {
        self.previewLayer = AVCaptureVideoPreviewLayer()
        super.init(frame: frame)
        layer.addSublayer(previewLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds // Crucial for preview to resize correctly
    }
}
