//
//  Photo.swift
//  AwesomeCollectionView
//
//  Created by Truong Vo on 10/7/17.
//  Copyright © 2017 RayMob. All rights reserved.
//

import UIKit

class Photo: Equatable {
    let photoID: String
    let imageURLString: String
    var image: UIImage?
    var isAddButton: Bool = false
    
    init (photoID: String, imageURLString: String) {
        self.photoID = photoID
        self.imageURLString = imageURLString
    }
    
    func imageURL() -> URL? {
        if let url =  URL(string: "\(imageURLString)") {
            return url
        }
        return nil
    }
    
    func loadImage(_ completion: @escaping (_ photo: Photo, _ error: NSError?) -> Void) {
        guard let loadURL = imageURL() else {
            DispatchQueue.main.async {
                completion(self, nil)
            }
            return
        }
        
        let loadRequest = URLRequest(url: loadURL)
        
        URLSession.shared.dataTask(with: loadRequest, completionHandler: { (data, response, error) in
            if let error = error {
                DispatchQueue.main.async {
                    completion(self, error as NSError?)
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(self, nil)
                }
                return
            }
            
            let returnedImage = UIImage(data: data)
            self.image = returnedImage
            DispatchQueue.main.async {
                completion(self, nil)
            }
        }) .resume()
    }
    
}

func == (lhs: Photo, rhs: Photo) -> Bool {
    return lhs.photoID == rhs.photoID
}
