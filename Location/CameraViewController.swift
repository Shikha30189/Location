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
//    var ref: DatabaseReference!
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
            DispatchQueue.main.async {
//                self.videoPreviewLayer.frame = self.previewView.bounds
               // self.previewView.clipsToBounds = true
            }
        }
    }
       
    @IBAction func cameraClicked(_ sender: Any) {
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        stillImageOutput.capturePhoto(with: settings, delegate: self)

    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        guard let imageData = photo.fileDataRepresentation()
            else { return }
        let image = UIImage(data: imageData)
        // save data to firebase
        previewImageView.image = image
        photoPreviewView.isHidden = false

        print("IMage=======\(image)")
    }
    
    func uploadMedia(image: UIImage, completion: @escaping (_ url: String?) -> Void) {
        //image.pngData()
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
                    //print("ImageURL=====\(storageRef.downloadURL(completion: <#T##(URL?, Error?) -> Void#>))")
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
    
//    func uniqueID() -> String? {
//        var uniqueDeviceId: String? = KeychainWrapper.standard.string(forKey: UNIQUE_KEY)
//
//                guard uniqueDeviceId != nil else {
//                    let uuid = generateUuid()
//                    let saveSuccessful: Bool = KeychainWrapper.standard.set(uuid, forKey: UNIQUE_KEY)
//                    if saveSuccessful {
//                        uniqueDeviceId = uuid
//                    } else {
//                        fatalError("Unable to save uuid")
//                    }
//                    return nil
//                }
//        return uniqueDeviceId
//    }
    

    
    func saveData(imageURL: String) {
        
        
        /// check for region in region table, if exist fetch it otherwise create it
        
        var regionID: String?
        let lat = self.locationServiceObject.myLocation?.coordinate.latitude ?? 0.0
        let longi = self.locationServiceObject.myLocation?.coordinate.longitude ?? 0.0
        
        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: longi), radius: 25, identifier: "test")

        
        self.appDelegate.ref.child("Regions").observeSingleEvent(of: .value) { snapshot in
            print("\(String(describing:  snapshot.value))")
            if let tempDic : Dictionary = snapshot.value as? Dictionary<String,Any> {
                print(tempDic)
                
                var isRegion = false
                for key in tempDic.keys {
                    let selectedDic = tempDic[key] as! Dictionary<String,Any>
                    let latittude = selectedDic["Latitude"] as! Double
                    let longitude = selectedDic["Longitude"] as! Double
                    let coords = CLLocationCoordinate2D(latitude: latittude, longitude: longitude)

                    if region.contains(coords) {
                        //
                        regionID = selectedDic["rid"] as? String
                        isRegion = true
                        break
                    }
                }

                if isRegion {
                    // Region Exist
                    self.saveImage(rid: regionID!, imageURL: imageURL)
                    //self.scheduleLocalNotification(alert: "data", identifier: "FenceCreate", imageURLS: imgURLS)
                } else {
                    let uuid = self.generateUuid()
                        self.appDelegate.ref.child("Regions").childByAutoId().setValue([
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

                                //self.showErrorAlert(title: "Success", message: "Region created successfully!")
                                
                                print("Region saved successfully!")
                            }
                        }
                    
                }
 
            } else {
                let uuid = self.generateUuid()
                    self.appDelegate.ref.child("Regions").childByAutoId().setValue([
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

                            //self.showErrorAlert(title: "Success", message: "Region created successfully!")
                            
                            print("Region saved successfully!")
                        }
                    }
                
            }
        }
        
        
        

        }
        
    func saveImage(rid: String, imageURL: String) {
        let uuid = generateUuid()
        
        // self.ref.child("users/\(user.uid)/username").setValue(username)
        //            childByAutoId().key
        appDelegate.ref.child("Posts").childByAutoId().setValue([
            //                "Latitude"      : locationServiceObject.myLocation?.coordinate.latitude ?? 0.0,
            //                "Longitude"    : locationServiceObject.myLocation?.coordinate.longitude ?? 0.0,
            "timestamp"     : NSDate().timeIntervalSince1970,
            "uid"       : uuid,
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
                print(test)
            }
        }

    }
    
}





