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
    override func viewDidLoad() {
        super.viewDidLoad()
//        innerTextField.delegate = self
//        outerTextField.delegate = self
        let innerRadius = UserDefaults.standard.double(forKey: AppDelegate.innerRadiusKey)
        let outerRadius = UserDefaults.standard.double(forKey: AppDelegate.outerRadiusKey)
        // Do any additional setup after loading the view.
        innerTextField.text = String(innerRadius)
        outerTextField.text = String(outerRadius)

    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func saveButtonClick(_ sender: Any) {
        
        let innerRadius = Double(innerTextField.text ?? "25")
        let outerRadius  = Double(outerTextField.text ?? "100")
        
        UserDefaults.standard.set(innerRadius, forKey: AppDelegate.innerRadiusKey)
        UserDefaults.standard.set(outerRadius, forKey: AppDelegate.outerRadiusKey)

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.locationServiceObject.updateMonitoredRegions()
        
        
 
    }
    
    
    
}

extension RadiusViewController : UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }
    
}
