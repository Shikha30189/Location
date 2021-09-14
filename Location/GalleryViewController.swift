//
//  GalleryViewController.swift
//  Location
//
//  Created by shikha on 04/08/21.
//

import UIKit
import Haneke

let CellReuseIdentifier = "Cell"

class GalleryViewController: UICollectionViewController {

    var items : [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView!.register(CollectionViewCell.self, forCellWithReuseIdentifier: CellReuseIdentifier)
        let layout = UICollectionViewFlowLayout()
//        layout.itemSize = CGSize(width: 100, height: 100)
        layout.itemSize = CGSize(width: UIScreen.main.bounds.size.width - 10, height: UIScreen.main.bounds.size.height - 50)

        self.collectionView!.collectionViewLayout = layout
        
        self.initializeItemsWithURLs()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.barTintColor = UIColor.white
        navigationController?.setNavigationBarHidden(false, animated: animated)
       



        self.tabBarController?.tabBar.isHidden = true

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.isHidden = true

        self.tabBarController?.tabBar.isHidden = false
    }

    // MARK: UIViewCollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let CellIdentifier = "Cell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellIdentifier, for: indexPath) as! CollectionViewCell
        let URLString = self.items[(indexPath as NSIndexPath).row]
        let url = URL(string:URLString)!
        cell.imageView.hnk_setImage(from: url)
        return cell
    }
    
    // MARK: Helpers
    
    func initializeItemsWithURLs() {
//        items = ["http://imgs.xkcd.com/comics/election.png",
//                 "http://imgs.xkcd.com/comics/election.png",
//                 "http://imgs.xkcd.com/comics/election.png",
//                 "http://imgs.xkcd.com/comics/election.png",
//                 "http://imgs.xkcd.com/comics/election.png",
//                 "http://imgs.xkcd.com/comics/election.png"
//            ]
    }

}



class CollectionViewCell: UICollectionViewCell {
    
    var imageView : UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.green
        initHelper()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initHelper()
    }
    
    func initHelper() {
        imageView = UIImageView(frame: self.contentView.bounds)
        imageView.backgroundColor = UIColor.black
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleToFill
//        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.contentView.addSubview(imageView)
    }
    
    override func prepareForReuse() {
        imageView.hnk_cancelSetImage()
        imageView.image = nil
    }
    
}
