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
    var cellSize:CGSize = .zero
    var cellsPerRow = 4
    
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
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        cellSize = CGSize(width: (view.bounds.width / CGFloat(cellsPerRow)) - 2, height: (view.bounds.width / CGFloat(cellsPerRow)) - 2)
        cellSize = CGRect(origin: .zero, size: cellSize).integral.size
        layout.itemSize = cellSize
        let url = "https://picsum.photos/\(Int(sourceSize.width))/\(Int(sourceSize.height))/?random"
        let numImage = 200
        for i in 0..<numImage {
            let info = ImageInfo(url: url, guid: UUID().uuidString) // \(i)")
            imageInfos.append(info)
        }
        collectionView.reloadData()
    }
    
    func requestForIndex(index:Int, isLowPriority:Bool) -> ImageFetcherRequest {
        let target = cellSize
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
        let request = requestForIndex(index: indexPath.item, isLowPriority: false)
        cell.imageView.request = request
        if let (token, req) = prefetchCellTokens[indexPath] {
            ImageFetcherController.shared.removeRequestObserver(request: req, token: token)
            prefetchCellTokens[indexPath] = nil
        }
        return cell
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        imageInfos.count
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
        imageView.frame = bounds
        imageView.backgroundColor = .lightGray
    }
}

struct ImageInfo {
    let url:String
    let guid:String
}
