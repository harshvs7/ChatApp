//
//  UIView.swift
//  Chat Application
//
//  Created by Harshvardhan Sharma on 28/12/23.
//

import Foundation
import UIKit

extension UIView {
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return self.layer.cornerRadius
        }
        set {
            self.layer.cornerRadius = newValue
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return self.layer.borderWidth
        }
        set {
            self.layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor {
        get {
            return UIColor(cgColor: self.layer.borderColor!)
        }
        set {
            self.layer.borderColor = newValue.cgColor
        }
    }
    
    func textFieldBorder(){
        
        self.layer.borderWidth = 1
        self.borderColor = UIColor.green
        self.layer.cornerRadius = 6
    }
    // Error red Border
    func errorBorder(){
        
        self.layer.borderWidth = 1
        self.borderColor = UIColor.red
        self.layer.cornerRadius = 6
    }
    
    func makeCircleRound() {
        self.layer.masksToBounds = true
        self.layer.cornerRadius = self.layer.bounds.width / 2.0
    }
}

extension UIViewController {
    
    func showAlert(with title: String, with message: String, with buttonText: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: buttonText, style: .cancel) { [weak self] _ in
            guard let strongSelf = self else { return }
            if buttonText.elementsEqual("Dismiss") {
                alert.dismiss(animated: true)
            }
            if buttonText.elementsEqual("Pop") {
                strongSelf.navigationController?.popViewController(animated: true)
            }
            
            
        }
        alert.addAction(action)
        DispatchQueue.main.async{ [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.present(alert, animated: true)
        }
    }
    func showAlertTwoButton(with title: String, with message: String, with buttonTextOne: String,with buttonTextTwo: String, completion: @escaping ((Bool) -> Void) ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: buttonTextOne, style: .default) { _ in
            completion(false)
        }
        let actionTwo = UIAlertAction(title: buttonTextTwo, style: .default) { _ in
            completion(true)
        }
        alert.addAction(action)
        alert.addAction(actionTwo)
        
        DispatchQueue.main.async{
            self.present(alert, animated: true)
        }
    }
}

@IBDesignable
class CustomTextField: UITextField {
    
    var padding: UIEdgeInsets {
        get {
            return UIEdgeInsets(top: 0, left: paddingValue, bottom: 0, right: paddingValue)
        }
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    @IBInspectable var paddingValue: CGFloat = 0
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func draw(_ rect: CGRect) {
        self.layer.cornerRadius = self.cornerRadius
        self.layer.borderWidth = self.borderWidth
        self.layer.borderColor = self.borderColor.cgColor
    }
    
}
