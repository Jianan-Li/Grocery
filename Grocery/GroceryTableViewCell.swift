//
//  GroceryTableViewCell.swift
//  Grocery
//
//  Created by Jianan Li on 2/10/19.
//  Copyright © 2019 Jianan Li. All rights reserved.
//

import UIKit

protocol UpdateModelFromCell {
    func updateItemNameForCellAt(indexPath: IndexPath, newItemName: String)
    
    func updateItemQuantityForCellAt(indexPath: IndexPath, newItemQuantity: Int)
}

class GroceryTableViewCell: UITableViewCell, UITextFieldDelegate {
    
    // Delegate
    var delegate: UpdateModelFromCell?
    
    let impactFeedbackGenerator: (
        light: UIImpactFeedbackGenerator,
        medium: UIImpactFeedbackGenerator,
        heavy: UIImpactFeedbackGenerator) = (
            UIImpactFeedbackGenerator(style: .light),
            UIImpactFeedbackGenerator(style: .medium),
            UIImpactFeedbackGenerator(style: .heavy)
    )

    
    @IBOutlet weak var itemQuantity: UILabel!
    @IBOutlet weak var mainTextField: UITextField!
    
    @IBOutlet weak var slider: UISlider!
    
    @IBAction func saveNewQuantity(_ slider: UISlider) {
        
        // Prepare feedback generator
        impactFeedbackGenerator.light.prepare()
        
        
        
        // Get current quantity
        let previousQuantityString = itemQuantity.text!
        
        // New item quantity
        let newQuantity = Int(slider.value)
        let newQuantityString = ( newQuantity == 0 ? "" : String(newQuantity) )
        
        if newQuantityString != previousQuantityString {
            // Play the haptic signal
            impactFeedbackGenerator.light.impactOccurred()
        }
        
        itemQuantity.text = newQuantityString
//        print("\(slider.value)\t\(newQuantity)\t\(Float(newQuantity) + 0.5)")
        // Setting the slider value to be newQuantity + 0.5, so that it's
        // equidistant from quantity-1 and quantity+1
        // Assume the user set the slider to 8.2 (slider.value = 8.2)
        // The new quantity from that is 8 (newQuantity = 8)
        // If we don't give the slider a new value based on the quantity,
        // the distance to quantity=7 is only 0.2, while the disntance to quantity = 9 is 0.8
        // If we set the slider to 8+0.5=8.5, then the distance to both 7 and 9 becomes 0.5
        slider.setValue(Float(newQuantity) + 0.5, animated: false)
        
        // Get indexPath of the cell that contains the textField
        let glCell = slider.superview?.superview as! GroceryTableViewCell
        let glTable = glCell.superview as! UITableView
        let sliderIndexPath = glTable.indexPath(for: glCell)
        
        delegate?.updateItemQuantityForCellAt(indexPath: sliderIndexPath!, newItemQuantity: newQuantity)
    }
    
    @IBAction func saveNewItemName(_ textField: UITextField) {
        
        // New item name
        let newItemName = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        textField.text = newItemName
        textField.sizeToFit()
        
        // Get indexPath of the cell that contains the textField
        let glCell = textField.superview?.superview as! GroceryTableViewCell
        let glTable = glCell.superview as! UITableView
        let textFieldIndexPath = glTable.indexPath(for: glCell)
        
        // Call delegate method
        delegate?.updateItemNameForCellAt(indexPath: textFieldIndexPath!, newItemName: newItemName!)
    }
    
    @objc func updateTextFieldWidth() {
        mainTextField.sizeToFit()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        for state: UIControl.State in [.normal, .selected, .application, .reserved] {
            slider.setThumbImage(#imageLiteral(resourceName: "Rectangle"), for: state)
            slider.setMinimumTrackImage(UIImage(), for: state)
            slider.setMaximumTrackImage(UIImage(), for: state)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateTextFieldWidth), name: UITextField.textDidChangeNotification, object: nil)

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
