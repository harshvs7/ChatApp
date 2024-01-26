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
    public typealias DownloadPictureCompletion = (Result<URL,Error>) -> Void
    
    ///Uploads profile picture and return the url to download
    public func uploadProfilePicture ( with data: Data, fileName: String, completion: @escaping UploadPictureCompletion ) {
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: { [weak self] metadata, error in
            guard  error == nil else {
                completion(.failure(StorageErrors.failedToUpload ))
                return
            }
            self?.storage.child("images/\(fileName)").downloadURL(completion: { url, error in
                
                guard let url = url else {
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                completion(.success(urlString))
            })
        })
    }
    
    ///Gets the profilePicture back as an url
    public func downloadURL( with path: String, completion: @escaping DownloadPictureCompletion ) {
        let reference = storage.child(path)
        
        reference.downloadURL(completion: { url, error in
            guard let url = url, error == nil else {
                completion(.failure(StorageErrors.failedToGetDownloadUrl))
                return
            }
            
            completion(.success(url))
            
        })
    }
    
    ///upload image to be sent in conversations
    public func uploadMessagePhoto( with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("messages_images/\(fileName)").putData(data,metadata: nil,completion: { [weak self] metadata, error in
            guard error == nil else {
                completion(.failure(StorageErrors.failedToUpload ))
                return
            }
            self?.storage.child("messages_images/\(fileName)").downloadURL(completion: { url, error in
                
                guard let url = url else {
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                completion(.success(urlString))
            })
            
            
        })
    }
    
    ///upload video to be sent in conversations
    public func uploadMessageVideo( with fileUrl: URL, fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("messages_videos/\(fileName)").putFile(from: fileUrl, metadata: nil,completion: { [weak self] metadata, error in
            guard error == nil else {
                completion(.failure(StorageErrors.failedToUpload ))
                return
            }
            self?.storage.child("messages_videos/\(fileName)").downloadURL(completion: { url, error in
                
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
