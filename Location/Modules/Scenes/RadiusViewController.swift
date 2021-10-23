//
//  RadiusViewController.swift
//  Location
//
//  Created by shikha on 15/09/21.
//

import UIKit
import Foundation

class RadiusViewController: UIViewController {

    @IBOutlet weak var innerTextField: UITextField!
    @IBOutlet weak var outerTextField: UITextField!
    @IBOutlet weak var foregroundTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        let innerRadius = UserDefaults.standard.double(forKey: AppDelegate.innerRadiusKey)
        let outerRadius = UserDefaults.standard.double(forKey: AppDelegate.outerRadiusKey)
        innerTextField.text = String(innerRadius)
        outerTextField.text = String(outerRadius)
        foregroundTextField.text = String(AppDelegate.localGPSRadius)

    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    @IBAction func backgroundTapped(_ sender: Any) {
        view.endEditing(true)
    }
    
    @IBAction func saveButtonClick(_ sender: Any) {
        let innerRadius = Double(innerTextField.text ?? "25")
        let outerRadius  = Double(outerTextField.text ?? "100")
        let foregroundRadius  = Double(foregroundTextField.text ?? "20.0") ?? 20.0
        
        AppDelegate.localGPSRadius = foregroundRadius
        UserDefaults.standard.set(innerRadius, forKey: AppDelegate.innerRadiusKey)
        UserDefaults.standard.set(outerRadius, forKey: AppDelegate.outerRadiusKey)
        UserDefaults.standard.synchronize()

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.locationServiceObject.updateMonitoredRegions()
    }
}

extension RadiusViewController : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }
    
}
