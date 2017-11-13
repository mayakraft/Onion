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
	
	var previewView = UIView()
	var overlayImageView = UIImageView()
	var comparisonImage:UIImage?
	let cvImageView = UIImageView()
	let cvImageButton = UIButton()
	let photoAlbumView = UIImageView()
	let photoAlbumButton = UIButton()

	let shutterButton = UIButton()
	let shutterOutlineBlack = UIView()
	let shutterOutlineWhite = UIView()
	
	let tapGesture = UITapGestureRecognizer()
	let picker = UIImagePickerController()
	
	// top bar buttons
	let newSessionButton = UIButton()
	let firstLastButton = UIButton()

	// program modes
	var firstLast:Bool = true
	var cvFullScreen:Bool = false
	
	var focusSquare: CameraFocusSquare?
	var frameExtractor:FrameExtractor!
	
	let openCV = OpenCVWrapper()

	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.view.backgroundColor = UIColor.init(white: 0.1, alpha: 1.0)
		
		let cameraSize = CGSize(width: self.view.bounds.size.width, height: self.view.bounds.size.width*4/3)
		self.previewView.frame.size = cameraSize
		self.overlayImageView.frame.size = cameraSize
		self.previewView.backgroundColor = .black
		self.previewView.frame = CGRect(x: 0, y: 0, width: cameraSize.width, height: cameraSize.height)
//		self.overlayImageView.frame = self.view.bounds
		self.previewView.center = CGPoint(x: self.view.center.x, y: self.view.center.y-30)
		self.overlayImageView.center = CGPoint(x: self.view.center.x, y: self.view.center.y-30)
		self.view.addSubview(self.previewView)
		self.view.addSubview(self.overlayImageView)
		
		self.overlayImageView.contentMode = .scaleAspectFit
		self.overlayImageView.alpha = 0.3
		
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
		self.photoAlbumView.contentMode = .scaleAspectFit
		self.photoAlbumView.clipsToBounds = true
		self.view.addSubview(self.photoAlbumView)
		
		self.photoAlbumButton.frame = self.photoAlbumView.frame
		self.photoAlbumButton.backgroundColor = .clear
		self.photoAlbumButton.addTarget(self, action: #selector(photoAlbumHandler), for: .touchUpInside)
		self.view.addSubview(photoAlbumButton)

		self.cvImageView.frame = CGRect(x: 0, y: 0, width: vmin*0.2, height: vmin*0.2)
		self.cvImageView.center = CGPoint(x: self.view.bounds.width - vmin*0.1 + 4, y: buttonCenter.y)
		self.cvImageView.contentMode = .scaleAspectFit
		self.cvImageView.clipsToBounds = true
		self.view.addSubview(self.cvImageView)
		
		self.cvImageButton.frame = self.cvImageView.frame
		self.cvImageButton.backgroundColor = .clear
		self.cvImageButton.addTarget(self, action: #selector(cvImageButtonHandler), for: .touchUpInside)
		self.view.addSubview(cvImageButton)

		
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
		// photo album stuff
		
		getLastPhoto { (image) in
			self.photoAlbumView.image = image
		}

		picker.sourceType = .savedPhotosAlbum
//		picker.allowsEditing = true
		picker.delegate = self
		
		tapGesture.addTarget(self, action: #selector(tapToFocus(_:)))
		self.previewView.addGestureRecognizer(tapGesture)
		
		//////////////////////////////////////
		// setup camera device
		
		self.frameExtractor = FrameExtractor()
		self.frameExtractor.delegate = self
		
		self.frameExtractor.previewLayer.frame = previewView.bounds
		previewView.layer.addSublayer(self.frameExtractor.previewLayer)

	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		print("Orientation")
		print(UIDevice.current.orientation)
	}
	
	func removeRotationForImage(image: UIImage) -> UIImage {
		if image.imageOrientation == UIImageOrientation.up {
			return image
		}
		UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
		image.draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: image.size))
		let normalizedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
		UIGraphicsEndImageContext()
		return normalizedImage
	}
	
	func frame(image: UIImage) {
		if let comparison = self.comparisonImage{
			let comparisonUp = removeRotationForImage(image: comparison)
			let difference = openCV.differenceBetween(image, and: comparisonUp)
			if(cvFullScreen){
				self.overlayImageView.image = difference
				self.cvImageView.image = image
			} else{
				self.cvImageView.image = difference
			}
		}
//		let bwImage = openCV.makeGray(image)
//		self.cvImageView.image = bwImage
	}
	
	func captured(image: UIImage) {
		self.comparisonImage = image
		if firstLast || self.overlayImageView.image == nil{
			self.overlayImageView.image = image
		}
		UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
	}
	
	@objc func newSessionHandler(){
		self.overlayImageView.image = nil
	}
	
	@objc func firstLastHandler(){
		self.firstLast = !self.firstLast
		if self.firstLast{
			self.firstLastButton.setTitle("last", for: .normal)
		}else{
			self.firstLastButton.setTitle("first", for: .normal)
		}
	}
	
	@objc func shutterButtonHandler(_ sender: UIButton) {
		self.frameExtractor.takePhoto()
	}
	
	@objc func photoAlbumHandler(){
		self.present(picker, animated: true, completion: nil)
	}
	
	@objc func cvImageButtonHandler(){
		cvFullScreen = !cvFullScreen

		if(cvFullScreen){
			self.overlayImageView.alpha = 1.0
		} else{
			self.overlayImageView.alpha = 0.3
		}
	}
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
		print("got an image")
		picker.dismiss(animated: true) {
			print(info)
			if let image = info["UIImagePickerControllerOriginalImage"] as? UIImage{
				self.comparisonImage = image
				self.overlayImageView.image = image
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
