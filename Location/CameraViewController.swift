//
//  CameraViewController.swift
//  Location
//
//  Created by shikha on 26/07/21.
//

import UIKit
import AVFoundation
import Firebase
import SwiftKeychainWrapper
import CoreLocation

class CameraViewController: UIViewController, UIImagePickerControllerDelegate, AVCapturePhotoCaptureDelegate {

    private let UNIQUE_KEY = "UniqueId"

    let imagePicker = UIImagePickerController()
    @IBOutlet var previewView: UIView!
    @IBOutlet var photoPreviewView: UIView!
    @IBOutlet weak var previewImageView: UIImageView!
    
    @IBOutlet var clickPhoto: UIButton!
    var captureSession: AVCaptureSession!
    var stillImageOutput: AVCapturePhotoOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var locationServiceObject: LocationService!

    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    
    override func viewDidLoad() {
        super.viewDidLoad()
        clickPhoto.layer.cornerRadius = 0.5 * clickPhoto.bounds.size.width
        clickPhoto.layer.borderWidth = 8.0
        clickPhoto.layer.borderColor = UIColor.lightGray.cgColor
        clickPhoto.clipsToBounds = true

        locationServiceObject = appDelegate.locationServiceObject
        locationServiceObject.getLocation()
    }
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        photoPreviewView.isHidden = true
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let session = captureSession, session.isRunning {
            session.stopRunning()
        }
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        guard let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
            else {
                print("Unable to access back camera!")
                return
        }
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            stillImageOutput = AVCapturePhotoOutput()

            if captureSession.canAddInput(input) && captureSession.canAddOutput(stillImageOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(stillImageOutput)
                setupLivePreview()
            }
        }
        catch let error  {
            print("Error Unable to initialize back camera:  \(error.localizedDescription)")
        }

       
        
    }
    
    func setupLivePreview() {
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.videoPreviewLayer.frame = self.previewView.bounds

        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.connection?.videoOrientation = .portrait
        videoPreviewLayer.position = CGPoint.init(x: self.previewView.bounds.midX, y: self.previewView.bounds.midY)
        self.previewView.clipsToBounds = true
        previewView.layer.addSublayer(videoPreviewLayer)
        DispatchQueue.global(qos: .userInitiated).async { //[weak self] in
            self.captureSession.startRunning()

        }
    }
       
    @IBAction func cameraClicked(_ sender: Any) {
        if TARGET_IPHONE_SIMULATOR != 0 {
            let image = UIImage(named: "SampleImage")
            uploadMedia(image: image!) { result in
            }
        }else {
            let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
            stillImageOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        guard let imageData = photo.fileDataRepresentation()
            else { return }
        let image = UIImage(data: imageData)
        // save data to firebase
        previewImageView.image = image
        photoPreviewView.isHidden = false
    }
    
    
    func uploadMedia(image: UIImage, completion: @escaping (_ url: String?) -> Void) {
        let imagename = "\(generateUuid()).jpeg"
        let storageRef = Storage.storage().reference().child(imagename)
        if let uploadData = image.jpegData(compressionQuality: 0.3) {
            self.showSpinner(onView: self.view)
            storageRef.putData(uploadData, metadata: nil) { metadata, error in
                if error == nil {
                    print("Image uploaded")
                    storageRef.downloadURL { url, error in
                        print("url=========\(url)")
                        if error == nil, let urlString = url?.absoluteString {
                            
                            self.saveData(imageURL: urlString)
                        } else {
                            self.removeSpinner()
                            self.showErrorAlert(message: "Fail to create url")
                        }
                    }
                    
                } else {
                    print(error?.localizedDescription)
                    print("Image not  uploaded")
                    self.removeSpinner()
                    self.showErrorAlert(message: "Fail to upload image")
                }
            }

     }
    }
    
    func showErrorAlert(title: String = "Error", message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction.init(title: "Ok", style: .default, handler: nil))
        //...
        var rootViewController = UIApplication.shared.keyWindow?.rootViewController
        if let navigationController = rootViewController as? UINavigationController {
            rootViewController = navigationController.viewControllers.first
        }
        if let tabBarController = rootViewController as? UITabBarController {
            rootViewController = tabBarController.selectedViewController
        }
        //...
        rootViewController?.present(alertController, animated: true, completion: nil)
    }
    
    func saveData(imageURL: String) {
        locationServiceObject.getLocation { result in
            if case let .success(latestLocation) = result {
                
                let lat = latestLocation.coordinate.latitude
                let longi = latestLocation.coordinate.longitude
                
                AppDelegate.ref.child("Regions").observeSingleEvent(of: .value) { snapshot in
                    
                    if let tempDic : Dictionary = snapshot.value as? Dictionary<String,Any> {
                        
                        var isRegion = false
                        //var regionID: String?
                        var hstryHotspotRegionList = [[String: Any]]()

                        for key in tempDic.keys {
                            let selectedDic = tempDic[key] as! Dictionary<String,Any>
                            let latittude = selectedDic["Latitude"] as! Double
                            let longitude = selectedDic["Longitude"] as! Double

//                            let innerRadius  = UserDefaults.standard.double(forKey: AppDelegate.innerRadiusKey)
                            let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: latittude, longitude: longitude), radius: (AppDelegate.localGPSRadius * 2.0), identifier: "test")
                            
                            if region.contains(latestLocation.coordinate) {
                                hstryHotspotRegionList.append(selectedDic)
                               // regionID = selectedDic["rid"] as? String
                                isRegion = true
                                //break
                            }
                        }
                        if isRegion {
                            // Region Exist
                            if let selctedRgionID = self.appDelegate.locationServiceObject.minimumDistanceBetweenCoordinates(arrRegions: hstryHotspotRegionList,currentLocation: latestLocation) {
                                self.saveImage(rid: selctedRgionID, imageURL: imageURL)
                            }
                        } else {
                            let uuid = self.generateUuid()
                            AppDelegate.ref.child("Regions").childByAutoId().setValue([
                                "Latitude"      : lat,
                                "Longitude"    : longi,
                                "timestamp"     : NSDate().timeIntervalSince1970,
                                "rid"       : uuid
                            ]) { [weak self] (error:Error?, ref:DatabaseReference) in
                                self?.removeSpinner()
                                if let error = error {
                                    self?.showErrorAlert(message: "Failed to save region: \(error).")
                                    print("Region can not be saved: \(error).")
                                } else {
                                    self?.photoPreviewView.isHidden = true
                                    let innerRadius  = UserDefaults.standard.double(forKey: AppDelegate.innerRadiusKey)
//                                    self?.locationServiceObject.createRegion(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: longi), radius: innerRadius, regionName: uuid)
                                    self?.saveImage(rid: uuid, imageURL: imageURL)
                                    print("Region saved successfully!")
                                }
                            }
                        }
                    } else {
                        let uuid = self.generateUuid()
                        AppDelegate.ref.child("Regions").childByAutoId().setValue([
                            "Latitude"      : lat,
                            "Longitude"    : longi,
                            "timestamp"     : NSDate().timeIntervalSince1970,
                            "rid"       : uuid
                        ]) {
                            (error:Error?, ref:DatabaseReference) in
                            self.removeSpinner()
                            if let error = error {
                                self.showErrorAlert(message: "Failed to save region: \(error).")
                                print("Region can not be saved: \(error).")
                            } else {
                                self.photoPreviewView.isHidden = true
                                self.saveImage(rid: uuid, imageURL: imageURL)
                                print("Region saved successfully!")
                            }
                        }
                        
                    }
                }
                
            }
        }
        
    }
        
    func saveImage(rid: String, imageURL: String) {
        AppDelegate.ref.child("Posts").childByAutoId().setValue([
            "timestamp"     : NSDate().timeIntervalSince1970,
            "uid"       : generateUuid(),
            "myImageURL" : imageURL,
            "regionid": rid
        ]) {
            (error:Error?, ref:DatabaseReference) in
            self.removeSpinner()
            if let error = error {
                self.showErrorAlert(message: "Data could not be saved: \(error).")
                print("Data could not be saved: \(error).")
            } else {
                
                self.photoPreviewView.isHidden = true
                self.showErrorAlert(title: "Success", message: "Data saved successfully!")
                
                print("Data saved successfully!")
            }
        }
    }
    
    private func generateUuid() -> String {
         let uuidRef: CFUUID = CFUUIDCreate(nil)
         let uuidStringRef: CFString = CFUUIDCreateString(nil, uuidRef)
         return uuidStringRef as String
     }
    
    @IBAction func cancelButtonClick(_ sender: Any) {
        photoPreviewView.isHidden = true
    }

    @IBAction func saveButtonClick(_ sender: Any) {
        // photoPreviewView.isHidden = true
        if let finalImage = previewImageView.image {
            uploadMedia(image: finalImage) { test in
            }
        }
        
    }
    
}





