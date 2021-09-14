//
//  HomeTabbarControllerViewController.swift
//  Location
//
//  Created by shikha on 01/08/21.
//

import UIKit

class HomeTabbarControllerViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
//        tabBar.sizeThatFits(CGSize.init(width: UIScreen.main.bounds.size.width, height: 60))
//        tabBar.bottomAnchor.constraint(equalTo: self.view.layoutMarginsGuide.bottomAnchor).isActive = true
//        [self.tabBar.bottomAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.bottomAnchor].active = YES;

        // Do any additional setup after loading the view.
    }
    
    override func viewDidLayoutSubviews() {

        super.viewDidLayoutSubviews()
        let bot = view.safeAreaInsets.bottom
        print("BOTTTTTOM=======\(bot)")
        if bot > 0 {
            self.tabBarItem.imageInsets = UIEdgeInsets(top: 20, left: 0, bottom: -20, right: 0)

        } else {
//            self.tabBarItem.imageInsets = UIEdgeInsets(top: 10, left: 0, bottom: -10, right: 0)

        }
//        var tabFrame            = tabBar.frame
//        tabFrame.size.height    = 65
//        tabFrame.origin.y       = view.frame.size.height - 65
//        tabBar.frame            = tabFrame
    }
 
  
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

//class TabBar: UITabBar {
//    private var cachedSafeAreaInsets = UIEdgeInsets.zero
//
//    let keyWindow = UIApplication.shared.connectedScenes
//        .filter { $0.activationState == .foregroundActive }
//        .compactMap { $0 as? UIWindowScene }
//        .first?.windows
//        .filter { $0.isKeyWindow }
//        .first
//
//    override var safeAreaInsets: UIEdgeInsets {
//        if let insets = keyWindow?.safeAreaInsets {
//            if insets.bottom < bounds.height {
//                cachedSafeAreaInsets = insets
//            }
//        }
//        return cachedSafeAreaInsets
//    }
//}

extension UITabBar {
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        super.sizeThatFits(size)
        guard let window = UIApplication.shared.keyWindow else {
            return super.sizeThatFits(size)
        }
        var sizeThatFits = super.sizeThatFits(size)
        sizeThatFits.height = window.safeAreaInsets.bottom + 40
        return sizeThatFits
    }
}
