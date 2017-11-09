//
//  ViewController.swift
//  Onion
//
//  Created by Robby on 11/8/17.
//  Copyright © 2017 Robby Kraft. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
	
	var overlayCamera: UIView = UIView()
	var capturedImage: UIImageView = UIImageView()
	
	var captureSession: AVCaptureSession?
	var stillImageOutput: AVCaptureStillImageOutput? //AVCapturePhotoOutput
	var previewLayer: AVCaptureVideoPreviewLayer?
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		previewLayer!.frame = overlayCamera.bounds
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		self.overlayCamera.frame = self.view.bounds
		self.capturedImage.frame = self.view.bounds
		self.view.addSubview(self.overlayCamera)
		self.view.addSubview(self.capturedImage)
		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cameraDidTaped))
		overlayCamera.addGestureRecognizer(tapGesture)
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	
	override func viewWillAppear(_ animated: Bool) {
		self.navigationController?.setNavigationBarHidden(true, animated: false)
		super.viewWillAppear(animated)
		
		self.captureSession = AVCaptureSession()
		guard let captureSession = self.captureSession else { return }
		captureSession.sessionPreset = AVCaptureSession.Preset.photo
		
		let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
		
		var error: NSError?
		var input: AVCaptureDeviceInput!
		do {
			input = try AVCaptureDeviceInput(device: backCamera!)
		} catch let error1 as NSError {
			error = error1
			input = nil
		}
		
		if error == nil && captureSession.canAddInput(input) {
			captureSession.addInput(input)
			
			stillImageOutput = AVCaptureStillImageOutput()
			stillImageOutput!.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
			if captureSession.canAddOutput(stillImageOutput!) {
				captureSession.addOutput(stillImageOutput!)
				
				self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
				guard let previewLayer = self.previewLayer else { return }
				previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
				previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
				overlayCamera.layer.addSublayer(previewLayer)
				
				captureSession.startRunning()
			}
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		self.navigationController?.setNavigationBarHidden(false, animated: false)
		super.viewWillDisappear(animated)
	}
	
	@objc func cameraDidTaped() {
		
		//		if let videoConnection = stillImageOutput!.connectionWithMediaType(AVMediaType.video) {
		if let videoConnection = stillImageOutput!.connection(with: AVMediaType.video) {
			videoConnection.videoOrientation = AVCaptureVideoOrientation.portrait
			stillImageOutput?.captureStillImageAsynchronously(from: videoConnection, completionHandler: {(sampleBuffer, error) in
				if (sampleBuffer != nil) {
					let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer!)
					let dataProvider = CGDataProvider(data: imageData! as CFData)
					
					let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
					
					let image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.right)
					self.capturedImage.image = image
				}
			})
		}
	}
}


