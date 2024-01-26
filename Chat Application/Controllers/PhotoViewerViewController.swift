//
//  PhotoViewerViewController.swift
//  Chat Application
//
//  Created by Harshvardhan Sharma on 28/12/23.
//

import UIKit
import SDWebImage

class PhotoViewerViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    private var url: URL
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.sd_setImage(with: url)
        self.navigationItem.largeTitleDisplayMode = .never
        self.navigationItem.title = "Photo"
    }

    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
