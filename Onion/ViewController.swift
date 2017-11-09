//
//  ViewController.swift
//  Onion
//
//  Created by Robby on 11/8/17.
//  Copyright © 2017 Robby Kraft. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate {
	
	var captureSesssion: AVCaptureSession!
	var cameraOutput: AVCapturePhotoOutput!
	var previewLayer: AVCaptureVideoPreviewLayer!
	
	var capturedImage: UIImageView = UIImageView()
	var previewView: UIView = UIView()
	
	let shutterButton = UIButton()
	let shutterOutlineBlack = UIView()
	let shutterOutlineWhite = UIView()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.view.backgroundColor = .black
		
		captureSesssion = AVCaptureSession()
		captureSesssion.sessionPreset = AVCaptureSession.Preset.photo
		cameraOutput = AVCapturePhotoOutput()
		
		self.previewView.frame = self.view.bounds
		self.capturedImage.frame = self.view.bounds
		self.view.addSubview(self.previewView)
		self.view.addSubview(self.capturedImage)
		
		self.capturedImage.contentMode = .scaleAspectFit
		self.capturedImage.alpha = 0.3

		var vmin = self.view.bounds.size.height
		if self.view.bounds.size.width < self.view.bounds.size.height { vmin = self.view.bounds.size.width }
		shutterButton.frame = CGRect(x: 0, y: 0, width: vmin*0.2, height: vmin*0.2)
		shutterButton.layer.cornerRadius = vmin*0.1
		shutterButton.layer.backgroundColor = UIColor.white.cgColor
		shutterOutlineWhite.frame = CGRect(x: 0, y: 0, width: vmin*0.2+20, height: vmin*0.2+20)
		shutterOutlineBlack.frame = CGRect(x: 0, y: 0, width: vmin*0.2+8, height: vmin*0.2+8)
		shutterOutlineWhite.layer.cornerRadius = vmin*0.1+10
		shutterOutlineBlack.layer.cornerRadius = vmin*0.1+4
		shutterOutlineWhite.layer.backgroundColor = UIColor.white.cgColor
		shutterOutlineBlack.layer.backgroundColor = UIColor.black.cgColor

		let buttonCenter = CGPoint(x: self.view.bounds.size.width*0.5, y: self.view.bounds.size.height - vmin*0.1 - 10)
		shutterOutlineBlack.center = buttonCenter
		shutterOutlineWhite.center = buttonCenter
		shutterButton.center = buttonCenter
		shutterButton.addTarget(self, action: #selector(shutterButtonHandler), for: .touchUpInside)
		self.view.addSubview(shutterOutlineWhite)
		self.view.addSubview(shutterOutlineBlack)
		self.view.addSubview(shutterButton)

		let device = AVCaptureDevice.default(for: .video)!
		
		if let input = try? AVCaptureDeviceInput(device: device) {
			if (captureSesssion.canAddInput(input)) {
				captureSesssion.addInput(input)
				if (captureSesssion.canAddOutput(cameraOutput)) {
					captureSesssion.addOutput(cameraOutput)
					previewLayer = AVCaptureVideoPreviewLayer(session: captureSesssion)
					previewLayer.frame = previewView.bounds
					previewView.layer.addSublayer(previewLayer)
					captureSesssion.startRunning()
				}
			} else {
				print("issue here : captureSesssion.canAddInput")
			}
		} else {
			print("some problem here")
		}
	}
	
	@objc func shutterButtonHandler(_ sender: UIButton) {
		let settings = AVCapturePhotoSettings()
		let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
		let previewFormat = [
			kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
			kCVPixelBufferWidthKey as String: 160,
			kCVPixelBufferHeightKey as String: 160
		]
		settings.previewPhotoFormat = previewFormat
		cameraOutput.capturePhoto(with: settings, delegate: self)
	}
	
	// callBack from take picture
	func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
		
		if let error = error {
			print("error: \(error.localizedDescription)")
		}
		
		if  let sampleBuffer = photoSampleBuffer,
			let previewBuffer = previewPhotoSampleBuffer,
			let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
			
			let dataProvider = CGDataProvider(data: dataImage as CFData)
			let cgImageRef: CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
			let image = UIImage(cgImage: cgImageRef, scale: 1.0, orientation: .right)
			
			self.capturedImage.image = image
		} else {
			print("some error here")
		}
	}
	
	func askPermission() {
		let cameraPermissionStatus =  AVCaptureDevice.authorizationStatus(for: .video)
		switch cameraPermissionStatus {
//		case .authorized:
//		case .restricted:
		case .denied:
			let alert = UIAlertController(title: "Camera Permissions" , message: "This app requires access to the camera",  preferredStyle: .alert)
			let action = UIAlertAction(title: "Ok", style: .cancel,  handler: nil)
			alert.addAction(action)
			present(alert, animated: true, completion: nil)
		default:
			AVCaptureDevice.requestAccess(for: .video, completionHandler: {
				[weak self]
				(granted:Bool) -> Void in
				if granted == true {
					// user granted access
					DispatchQueue.main.async(){ }
				}
				else {
					// user rejected access
					DispatchQueue.main.async(){
						let alert = UIAlertController(title: "Sorry" , message: "This app cannot work without access to the camera", preferredStyle: .alert)
						let action = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
						alert.addAction(action)
						self?.present(alert, animated: true, completion: nil)
					}
				}
			});
		}
	}
}
