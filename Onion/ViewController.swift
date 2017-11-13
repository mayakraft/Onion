//
//  ViewController.swift
//  Onion
//
//  Created by Robby on 11/8/17.
//  Copyright © 2017 Robby Kraft. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, FrameExtractorDelegate {
	
//	var captureSession: AVCaptureSession!
//	var cameraOutput: AVCapturePhotoOutput!
//	var previewLayer: AVCaptureVideoPreviewLayer!
//	var videoOutput: AVCaptureVideoDataOutput!
	
	let cvView = UIImageView()
	
	var capturedImage: UIImageView = UIImageView()
	var previewView: UIView = UIView()
	
	let shutterButton = UIButton()
	let shutterOutlineBlack = UIView()
	let shutterOutlineWhite = UIView()
	
	let photoAlbumView = UIImageView()
	let photoAlbumButton = UIButton()
	
	let picker = UIImagePickerController()
	
	let tapGesture = UITapGestureRecognizer()
	
	var focusSquare: CameraFocusSquare?
	
	let context = CIContext()
	
	let newSessionButton = UIButton()
	
	let firstLastButton = UIButton()
	var firstLast:Bool = true
	
	
//	private let sessionQueue = DispatchQueue(label: "session queue")

	
	var frameExtractor:FrameExtractor!

	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.view.backgroundColor = UIColor.init(white: 0.1, alpha: 1.0)
		
		let cameraSize = CGSize(width: self.view.bounds.size.width, height: self.view.bounds.size.width*4/3)
		self.previewView.frame.size = cameraSize
		self.capturedImage.frame.size = cameraSize
		self.previewView.backgroundColor = .black
		self.previewView.frame = CGRect(x: 0, y: 0, width: cameraSize.width, height: cameraSize.height)
//		self.capturedImage.frame = self.view.bounds
		self.previewView.center = CGPoint(x: self.view.center.x, y: self.view.center.y-30)
		self.capturedImage.center = CGPoint(x: self.view.center.x, y: self.view.center.y-30)
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

		let buttonCenter = CGPoint(x: self.view.bounds.size.width*0.5, y: self.view.bounds.size.height - vmin*0.1 - 15)
		shutterOutlineBlack.center = buttonCenter
		shutterOutlineWhite.center = buttonCenter
		shutterButton.center = buttonCenter
		shutterButton.addTarget(self, action: #selector(shutterButtonHandler), for: .touchUpInside)
		self.view.addSubview(shutterOutlineWhite)
		self.view.addSubview(shutterOutlineBlack)
		self.view.addSubview(shutterButton)

		self.photoAlbumView.frame = CGRect(x: 0, y: 0, width: vmin*0.2, height: vmin*0.2)
//		self.photoAlbumView.center = CGPoint(x: vmin*0.1 + 4, y: self.view.bounds.size.height - vmin*0.1 - 4)
		self.photoAlbumView.center = CGPoint(x: vmin*0.1 + 4, y: buttonCenter.y)
		self.photoAlbumView.contentMode = .scaleAspectFill
		self.photoAlbumView.clipsToBounds = true
		self.view.addSubview(self.photoAlbumView)
		
		
		self.cvView.frame = CGRect(x: 0, y: 0, width: vmin*0.2, height: vmin*0.2)
		self.cvView.center = CGPoint(x: self.view.bounds.width - vmin*0.1 + 4, y: buttonCenter.y)
		self.cvView.contentMode = .scaleAspectFill
		self.cvView.clipsToBounds = true
		self.view.addSubview(self.cvView)
		
		self.photoAlbumButton.frame = self.photoAlbumView.frame
		self.photoAlbumButton.backgroundColor = .clear
		self.photoAlbumButton.addTarget(self, action: #selector(photoAlbumHandler), for: .touchUpInside)
		self.view.addSubview(photoAlbumButton)
		
//		self.newSessionButton.setImage(UIImage(named:"Plus"), for: .normal)
		self.newSessionButton.setTitle("clear", for: .normal)
		self.newSessionButton.setTitleColor(.white, for: .normal)
		self.newSessionButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
		self.newSessionButton.sizeToFit()
		self.newSessionButton.addTarget(self, action: #selector(newSessionHandler), for: .touchUpInside)
//		self.newSessionButton.frame = CGRect(x: 0, y: 0, width: vmin*0.08, height: vmin*0.08)
		self.newSessionButton.center = CGPoint(x: self.view.frame.size.width*0.15, y: -5+vmin*0.08)
		self.view.addSubview(newSessionButton)
		
		self.firstLastButton.setTitle("last", for: .normal)
		self.firstLastButton.setTitleColor(.white, for: .normal)
		self.firstLastButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
		self.firstLastButton.sizeToFit()
		self.firstLastButton.center = CGPoint(x: self.view.frame.size.width*0.85, y: -5+vmin*0.08)
		self.firstLastButton.addTarget(self, action: #selector(firstLastHandler), for: .touchUpInside)
		self.view.addSubview(self.firstLastButton)
		
		//////////////////////////////////////
		
		getLastPhoto { (image) in
			self.photoAlbumView.image = image
		}
		
		//////////////////////////////////////

		picker.sourceType = .savedPhotosAlbum
//		picker.allowsEditing = true
		picker.delegate = self
		
		tapGesture.addTarget(self, action: #selector(tapToFocus(_:)))
		self.view.addGestureRecognizer(tapGesture)
		
		//////////////////////////////////////
		// setup camera device

//		self.setupCaptureDevice()
//		self.captureSession.startRunning()

//		sessionQueue.async { [unowned self] in
//			self.setupCaptureDevice()
//			self.captureSession.startRunning()
//		}
		
		self.frameExtractor = FrameExtractor()
		self.frameExtractor.delegate = self
		
		self.frameExtractor.previewLayer.frame = previewView.bounds
		previewView.layer.addSublayer(self.frameExtractor.previewLayer)

	}
	
	func frame(image: UIImage) {
		self.cvView.image = image
	}
	
	func captured(image: UIImage) {
		if firstLast || self.capturedImage.image == nil{
			self.capturedImage.image = image
		}
		UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
	}
	
//	func setupCaptureDevice(){
//		self.captureSession = AVCaptureSession()
//		self.captureSession.sessionPreset = AVCaptureSession.Preset.photo
//
//		guard let device = AVCaptureDevice.default(for: .video) else { return }
//
//		if let input = try? AVCaptureDeviceInput(device: device) {
//			if (self.captureSession.canAddInput(input)) {
//				self.captureSession.addInput(input)
//
//				self.cameraOutput = AVCapturePhotoOutput()
//				if (self.captureSession.canAddOutput(cameraOutput)) {
//					captureSession.addOutput(cameraOutput)
//					previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//					previewLayer.frame = previewView.bounds
//					previewView.layer.addSublayer(previewLayer)
//				}
//
//				self.videoOutput = AVCaptureVideoDataOutput()
//				if (captureSession.canAddOutput(videoOutput)){
//					videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer"))
////					videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
//					guard captureSession.canAddOutput(videoOutput) else { return }
//					captureSession.addOutput(videoOutput)
//					print("capture session added video data output")
//
//				}
//			} else {
//				print("issue here: captureSesssion.canAddInput")
//			}
//		} else {
//			print("problem")
//		}
//
//	}
	
/*
	/////////////////////////////////////////////////////////////
	// MARK: Sample buffer to UIImage conversion
	private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage? {
		guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
		let ciImage = CIImage(cvPixelBuffer: imageBuffer)
		guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
		return UIImage(cgImage: cgImage)
	}
	// MARK: AVCaptureVideoDataOutputSampleBufferDelegate
	func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
		print("Got a frame!")
//		guard let uiImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
//		DispatchQueue.main.async { [unowned self] in
//			print("capture output did output sample buffer")
////			self.delegate?.captured(image: uiImage)
////			self.photoAlbum.image = uiImage
//		}
	}
	/////////////////////////////////////////////////////////////
*/
	
	@objc func newSessionHandler(){
		self.capturedImage.image = nil
	}
	
	@objc func firstLastHandler(){
		self.firstLast = !self.firstLast
		if self.firstLast{
			self.firstLastButton.setTitle("last", for: .normal)
		}else{
			self.firstLastButton.setTitle("first", for: .normal)
		}
	}
	
	@objc func photoAlbumHandler(){
		self.present(picker, animated: true, completion: nil)
	}
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
		print("got an image")
		picker.dismiss(animated: true) {
			print(info)
			if let image = info["UIImagePickerControllerOriginalImage"] as? UIImage{
				self.capturedImage.image = image
				self.photoAlbumView.image = image
			}
		}
	}
	
	@objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
		getLastPhoto { (image) in
			self.photoAlbumView.image = image
		}
	}
	
	func getLastPhoto(_ completionHandler:@escaping (UIImage) -> ()){
		let fetchOptions = PHFetchOptions()
		fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
		fetchOptions.fetchLimit = 1
		let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
		if let asset = fetchResult.firstObject {
			let manager = PHImageManager.default()
			let targetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
			manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: nil, resultHandler: { (image, info) in
				if let yesImage = image{
					completionHandler(yesImage)
				}
			})
		}
	}
	
	@objc func shutterButtonHandler(_ sender: UIButton) {
		self.frameExtractor.takePhoto()
//		let settings = AVCapturePhotoSettings()
//		let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
//		let previewFormat = [
//			kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
//			kCVPixelBufferWidthKey as String: 160,
//			kCVPixelBufferHeightKey as String: 160
//		]
//		settings.previewPhotoFormat = previewFormat
//		self.cameraOutput.capturePhoto(with: settings, delegate: self)
	}
	
//	func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
//
//		if let error = error {
//			print("error: \(error.localizedDescription)")
//		}
//
//		if  let sampleBuffer = photoSampleBuffer,
//			let previewBuffer = previewPhotoSampleBuffer,
//			let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
//
//			let dataProvider = CGDataProvider(data: dataImage as CFData)
//			let cgImageRef: CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
//			let image = UIImage(cgImage: cgImageRef, scale: 1.0, orientation: .right)
//
//			if firstLast || self.capturedImage.image == nil{
//				self.capturedImage.image = image
//			}
//			UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
//
//		} else {
//			print("error")
//		}
//	}

	///////////////////////////////////////////////////////////////
	
	@objc func tapToFocus(_ gesture : UITapGestureRecognizer) {
		let touchPoint:CGPoint = gesture.location(in: self.previewView)
		if let fsquare = self.focusSquare {
			fsquare.updatePoint(touchPoint)
		}else{
			self.focusSquare = CameraFocusSquare(touchPoint: touchPoint)
			self.previewView.addSubview(self.focusSquare!)
			self.focusSquare?.setNeedsDisplay()
		}

		self.focusSquare?.animateFocusingAction()
		let convertedPoint:CGPoint = frameExtractor.previewLayer.captureDevicePointConverted(fromLayerPoint: touchPoint)
		let currentDevice:AVCaptureDevice = AVCaptureDevice.default(for: .video)!
		if currentDevice.isFocusPointOfInterestSupported && currentDevice.isFocusModeSupported(AVCaptureDevice.FocusMode.autoFocus){
			do {
				try currentDevice.lockForConfiguration()
				currentDevice.focusPointOfInterest = convertedPoint
				currentDevice.focusMode = AVCaptureDevice.FocusMode.autoFocus

				if currentDevice.isExposureModeSupported(AVCaptureDevice.ExposureMode.continuousAutoExposure){
					currentDevice.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
				}
				currentDevice.isSubjectAreaChangeMonitoringEnabled = true
				currentDevice.unlockForConfiguration()

			} catch {

			}
		}
	}

}
