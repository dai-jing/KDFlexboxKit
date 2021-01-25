//
//  ViewController.swift
//  KDFlexboxKit
//
//  Created by dai-jing on 01/25/2021.
//  Copyright (c) 2021 dai-jing. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    var items = [FlexCellModel]()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = UIColor.white
        
        view.addSubview(theCollectionView)
        
        reloadData()
    }
    
    func reloadData() {
        var item1 = FlexCellModel()
        item1.avatarImageUrl = "https://cdn.zozo.cn/ori_image/a2/d45aeba075ffd489f64ee0c5f7da36.jpg"
        item1.desc = "1252 wears"
        item1.isFollowing = true
        item1.nickname = "ZOZO, China"
        
        var item2 = FlexCellModel()
        item2.avatarImageUrl = "https://cdn.zozo.cn/ori_image/48/a289da01266367e4253375167bacf8.jpg"
        item2.desc = "222 wears"
        item2.isFollowing = false
        item2.nickname = "Kobe Dai"
        
        
        items = [item1, item2, item1, item2, item1, item2, item1, item2, item1, item2, item1, item2, item1, item2, item1, item2, item1, item2]
        
        
        theCollectionView.reloadData()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FlexCell", for: indexPath) as? FlexCell {
            let model = items[indexPath.item]
            cell.setCell(with: model)
            
            return cell
        }
        return UICollectionViewCell.init()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let model = items[indexPath.item]
        
        return FlexCell.cellSize(with: model)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }
    
    lazy var theCollectionView: UICollectionView = {
        let theCollectionView = UICollectionView(frame: .init(x: 0, y: 64, width: view.frame.size.width, height: view.frame.size.height-64), collectionViewLayout: UICollectionViewFlowLayout.init())
        theCollectionView.dataSource = self
        theCollectionView.delegate = self
        theCollectionView.backgroundColor = .white
        theCollectionView.register(FlexCell.self, forCellWithReuseIdentifier: "FlexCell")
        
        return theCollectionView
    }()
}
