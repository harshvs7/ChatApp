//
//  StorageManager.swift
//  Chat Application
//
//  Created by Harshvardhan Sharma on 14/01/24.
//

import Foundation
import FirebaseStorage

public enum StorageErrors: Error {
    case failedToUpload
    case failedToGetDownloadUrl
}

final class StorageManager {
    
    static let shared = StorageManager()
    private let storage = Storage.storage().reference()
    
    public typealias UploadPictureCompletion = (Result<String,Error>) -> Void
    
    
    ///Uploads profile picture and return the url to download
    public func uploadProfilePicture ( with data: Data, fileName: String, completion: @escaping UploadPictureCompletion ) {
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: { metadata, error in
            guard  error == nil else {
                completion(.failure(StorageErrors.failedToUpload ))
                return
            }
            self.storage.child("images/\(fileName)").downloadURL(completion: { url, error in
                
                guard let url = url else {
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                completion(.success(urlString))
            })
        })
    }
}
