//
//  ViewController.swift
//  ImageFetcherController
//
//  Created by jhowlin on 08/11/2018.
//  Copyright (c) 2018 jhowlin. All rights reserved.
//

import UIKit
import ImageFetcherController

class ViewController: UICollectionViewController, UICollectionViewDataSourcePrefetching {
    
    var imageInfos:[ImageInfo] = []
    let sourceSize = CGSize(width: 600, height: 600)
    var prefetchCellTokens = [IndexPath:(String, ImageFetcherRequest)]()
    
    init() {
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.register(Cell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.backgroundColor = .white
        collectionView.prefetchDataSource = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.minimumLineSpacing = 2
        layout.minimumInteritemSpacing = 2
        let heightWidth:CGFloat = ((view.bounds.width / 2) - 1).rounded(.down)
        let size = CGSize(width: heightWidth, height: heightWidth)
        layout.itemSize = size
        let url = "https://picsum.photos/\(sourceSize.width)/\(sourceSize.height)/?random"
        for _ in 0..<100 {
            let info = ImageInfo(url: url, guid: UUID().uuidString)
            imageInfos.append(info)
        }
    }
    
    func requestForIndex(index:Int, isLowPriority:Bool) -> ImageFetcherRequest {
        let heightWidth:CGFloat = ((view.bounds.width / 2) - 1).rounded(.down)
        let target = CGSize(width: heightWidth, height: heightWidth)
        let metrics = ImageFetcherImageSizeMetrics(targetSize: target.scaledForScreen, sourceSize: sourceSize)
        let info = imageInfos[index]
        let request = ImageFetcherRequest(url: info.url, identifier: info.guid, isLowPriority: isLowPriority, sizeMetrics: metrics)
        return request
    }
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let request = requestForIndex(index: indexPath.item, isLowPriority: true)
            let token = UUID().uuidString
            prefetchCellTokens[indexPath] = (token, request)
            ImageFetcherController.shared.fetchImage(imageRequest: request, observationToken: token) { _ in }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            if let (token, req) = prefetchCellTokens[indexPath] {
                ImageFetcherController.shared.removeRequestObserver(request: req, token: token)
                prefetchCellTokens[indexPath] = nil
            }
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! Cell
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cell = cell as! Cell
        let request = requestForIndex(index: indexPath.item, isLowPriority: false)
        cell.imageView.request = request
        if let (token, req) = prefetchCellTokens[indexPath] {
            ImageFetcherController.shared.removeRequestObserver(request: req, token: token)
            prefetchCellTokens[indexPath] = nil
        }
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageInfos.count
    }
}

class Cell:UICollectionViewCell {
    var imageView = UIImageView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = contentView.bounds
        imageView.backgroundColor = .lightGray
    }
}

struct ImageInfo {
    let url:String
    let guid:String
}
