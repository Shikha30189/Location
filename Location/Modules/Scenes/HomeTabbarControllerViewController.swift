//
//  HomeTabbarControllerViewController.swift
//  Location
//
//  Created by shikha on 01/08/21.
//

import UIKit

class HomeTabbarControllerViewController: UITabBarController {
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let bot = view.safeAreaInsets.bottom
        if bot > 0 {
            self.tabBarItem.imageInsets = UIEdgeInsets(top: 20, left: 0, bottom: -20, right: 0)
        }
    }
    
}
