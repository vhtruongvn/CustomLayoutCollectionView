//
//  AwsomeCollectionViewController.swift
//  AwesomeCollectionView
//
//  Created by Truong Vo on 10/7/17.
//  Copyright © 2017 RayMob. All rights reserved.
//

import UIKit
import AVFoundation
import NVActivityIndicatorView

private let reuseIdentifier = "PhotoCell"
private let sectionInsets = UIEdgeInsets(top: 20.0, left: 20.0, bottom: 20.0, right: 20.0)

class AwsomeCollectionViewController: UICollectionViewController, NVActivityIndicatorViewable {

    fileprivate var photos = [Photo]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Truong Vo"
        
        collectionView!.backgroundColor = UIColor.white
        collectionView!.contentInset = UIEdgeInsets(top: 10, left: 5, bottom: 10, right: 5)
        
        getData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - App Methods
    
    private func getData() {
        startAnimating(CGSize(width: 40, height: 40), message: "Loading...")
        
        APIClient.sharedInstance.getSampleData(success: { (json) in
            self.stopAnimating()
            
            print(json)
            
            var _photos = [Photo]()
            
            let photosReceived = json["items"].arrayObject as! [NSDictionary]
            for photoObject in photosReceived {
                guard let photoID = photoObject["uuid"] as? String,
                    let imageUrlString = photoObject["imageUrlString"] as? String else {
                    break
                }
                let photo = Photo(photoID: photoID, imageURLString: imageUrlString)
                _photos.append(photo)
            }
            
            // last object is used as add button
            let addButton = Photo(photoID: "", imageURLString: "")
            addButton.isButton = true
            _photos.append(addButton)
            
            self.photos = _photos
            
            DispatchQueue.main.async {
                self.collectionView!.reloadData()
            }
        }) { (error) in
            self.stopAnimating()
            
            print(error)
            
            let alert = UIAlertController(title: "Oops", message: "\(error.localizedDescription)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func photoForIndexPath(_ indexPath: IndexPath) -> Photo {
        return photos[indexPath.row]
    }
    
    func removePhotoAtIndexPath(_ indexPath: IndexPath) {
        photos.remove(at: indexPath.row)
    }
    
    func insertPhotoAtIndexPath(photo: Photo, indexPath: IndexPath) {
        photos.insert(photo, at: indexPath.row)
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoCell
        
        let photo = photoForIndexPath(indexPath)
        
        // add buton
        if photo.isButton {
            cell.activityIndicator.stopAnimating()
            cell.imageView.image = UIImage(named: "icon_add")
            cell.cellLabel.text = ""
            cell.deleteButton.isHidden = true
            return cell
        }
        
        // photo cell's extra info
        cell.cellLabel.text = "(\(indexPath.section):\(indexPath.row))"
        cell.deleteButton.isHidden = false
        cell.deleteButton.addTarget(self, action: #selector(AwsomeCollectionViewController.deleteButtonTapped(sender:event:)), for: .touchUpInside)
        
        // load image for photo cell
        cell.activityIndicator.stopAnimating()
        guard photo.image == nil else {
            cell.imageView.image = photo.image
            return cell
        }
        
        cell.activityIndicator.startAnimating()
        cell.imageView.image = UIImage(named: "image_placeholder")
        photo.loadImage { loadedPhoto, error in
            cell.activityIndicator.stopAnimating()
            
            guard loadedPhoto.image != nil && error == nil else {
                return
            }
            
            if let cell = collectionView.cellForItem(at: indexPath) as? PhotoCell {
                cell.imageView.image = loadedPhoto.image
            }
        }
        
        return cell
    }
    
    func deleteButtonTapped(sender: UIButton, event: UIEvent) {
        let touch: UITouch = event.allTouches!.first!
        let touchPosition: CGPoint = touch.location(in: self.view)
        
        if let indexPath = collectionView!.indexPathForItem(at: touchPosition) {
            let photo = photoForIndexPath(indexPath)
            
            let alert = UIAlertController(title: "", message: "Do you really want to delete the item with identifier \(photo.photoID)?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes",
                                          style: .default,
                                          handler: {(alert: UIAlertAction!) in
                                            print("Deleting \(indexPath)")
                                            
                                            self.removePhotoAtIndexPath(indexPath)
                                            if indexPath.section == 0 {
                                                self.collectionView!.reloadData()
                                            } else {
                                                self.collectionView!.performBatchUpdates({
                                                    self.collectionView!.deleteItems(at: [indexPath])
                                                }, completion: nil)
                                            }
                                            self.collectionView!.collectionViewLayout.invalidateLayout()
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        let photo = photoForIndexPath(indexPath)
        if photo.isButton {
            return false
        }
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveFromItemAt originalIndexPath: IndexPath, toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
        print("proposedIndexPath = \(proposedIndexPath)")
        
        let destinationPhoto = photoForIndexPath(proposedIndexPath)
        if destinationPhoto.isButton {
            return IndexPath(row: proposedIndexPath.row - 1, section: proposedIndexPath.section)
        }
        
        return proposedIndexPath
    }
    
    override func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let sourcePhoto = photoForIndexPath(sourceIndexPath)
        
        print("Remove photo at \(sourceIndexPath)")
        removePhotoAtIndexPath(sourceIndexPath)
        
        print("Insert photo at \(destinationIndexPath)")
        insertPhotoAtIndexPath(photo: sourcePhoto, indexPath: destinationIndexPath)
        
        collectionView.reloadData()
    }

    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Tapped cell \(indexPath)")
        
        let photo = photoForIndexPath(indexPath)
        print(photo.description())
        
        if photo.isButton {
            let alert = UIAlertController(title: "Add Photo", message: "Note: photo url cannot be empty", preferredStyle: .alert)
            alert.addTextField { (textField) in
                textField.placeholder = "Enter photo url here"
                textField.keyboardType = .URL
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "OK",
                                          style: .default,
                                          handler: { [weak alert] (_) in
                                            let textField = alert!.textFields![0]
                                            let urlString = textField.text!
                                            if urlString.characters.count > 0 {
                                                print("Add photo with url = \(urlString)")
                                                
                                                let uuid = UUID().uuidString
                                                let photo = Photo(photoID: uuid, imageURLString: urlString)
                                                self.photos.insert(photo, at: self.photos.count - 1)
                                                if self.photos.count > numberOfColumns {
                                                    self.collectionView!.reloadData()
                                                } else {
                                                    self.collectionView!.performBatchUpdates({
                                                        self.collectionView!.insertItems(at: [indexPath])
                                                    }, completion: nil)
                                                }
                                                self.collectionView!.collectionViewLayout.invalidateLayout()
                                            }
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "", message: "You have selected the item with identifier \(photo.photoID)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
