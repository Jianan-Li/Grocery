//
//  TableViewController.swift
//  Grocery
//
//  Created by Jianan Li on 2/8/19.
//  Copyright © 2019 Jianan Li. All rights reserved.
//

import UIKit
import TouchVisualizer

class GroceryTableViewController: UITableViewController, UpdateModelFromCell{
    
    // Cell delegate methods
    func updateItemNameForCellAt(indexPath: IndexPath, newItemName: String) {
        gl.updateItemName(at: indexPath, newItemName: newItemName)
    }
    
    func updateItemQuantityForCellAt(indexPath: IndexPath, newItemQuantity: Int) {
        gl.updateQuantityOfItem(at: indexPath, newItemQuantity: newItemQuantity)
    }
        
    @IBOutlet var groceryTableView: UITableView!
    
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    @IBOutlet weak var moveItemsButton: UIBarButtonItem!
    
    @IBOutlet weak var deleteItemsButton: UIBarButtonItem!
    
    @IBOutlet weak var selectionToggleButton: UIBarButtonItem!
    
    @IBAction func editItems(_ sender: UIBarButtonItem) {
        // Clear all selections and accessories when switching to and from editing mode
        groceryTableView.visibleCells.forEach { (UITableViewCell) in
            UITableViewCell.setSelected(false, animated: false)
            UITableViewCell.accessoryType = .none
        }
        
        // Takes care of toggling the button's title, and animation
        super.setEditing(!isEditing, animated: true)
        
        // Toggle edit and done button text
        editButton.title = isEditing ? "Done" : "Edit"
        
        // Show the group move and delete buttons
        deleteItemsButton.tintColor = isEditing ? #colorLiteral(red: 0.25, green: 0.25, blue: 0.25, alpha: 1) : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
        moveItemsButton.tintColor = isEditing ? #colorLiteral(red: 0.25, green: 0.25, blue: 0.25, alpha: 1) : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
    }
    
    @IBAction func moveItems(_ sender: Any) {
        if !isEditing { return }
        if groceryTableView.indexPathsForSelectedRows == nil { return }
        
        while let selectedRows = groceryTableView.indexPathsForSelectedRows {
            groceryTableView.beginUpdates()
            
            // First sort the selectedRows, because they are currently in the order of selection
            // [[1, 3], [1, 1], [0, 2], [0, 1]] -> [[0, 2], [0, 1], [1, 1], [1, 3]]
            let selectedRowsSorted = selectedRows.sorted(by: {
                if $0.section == $1.section {
                    if $0.section == 1 {
                        return $0.row < $1.row
                    } else {
                        return $0.row > $1.row
                    }
                } else {
                    return $0.section < $1.section
                }
            })
            
            let selectedRow = selectedRowsSorted.first!
            groceryTableView.deselectRow(at: selectedRow, animated: false)
            var indexPathForItemToBeMovedTo: IndexPath!
            
            if selectedRow.section == 0 {
                indexPathForItemToBeMovedTo = IndexPath(row: 0, section: 1)
            } else if selectedRow.section == 1 {
                let numberOfRowsInSectionToBeMovedTo = self.groceryTableView.numberOfRows(inSection: 0)
                indexPathForItemToBeMovedTo = IndexPath(row: numberOfRowsInSectionToBeMovedTo, section: 0)
            }
            gl.moveItem(from: selectedRow, to: indexPathForItemToBeMovedTo)
            groceryTableView.moveRow(at: selectedRow, to: indexPathForItemToBeMovedTo)
            groceryTableView.endUpdates()
        }
        
        setButtonStateBasedOnRowSelection()
    }
    
    @IBAction func deleteItems(_ sender: UIBarButtonItem) {
        if !isEditing { return }
        
        if let selectedRows = groceryTableView.indexPathsForSelectedRows {
            
            gl.deleteItems(selectedRows: selectedRows)
            
            groceryTableView.beginUpdates()
            groceryTableView.deleteRows(at: selectedRows, with: .automatic)
            groceryTableView.endUpdates()
            
            setButtonStateBasedOnRowSelection()
        }
    }
    
    @IBAction func importItems(_ sender: UIBarButtonItem) {
        // Construct the alert
        let alert = UIAlertController(title: "Enter one item per line", message: "\n\n\n\n\n\n\n\n\n\n", preferredStyle: .alert)

        let textView = UITextView(frame: CGRect.zero)
        textView.translatesAutoresizingMaskIntoConstraints = false

        let leadConstraint = NSLayoutConstraint(item: alert.view!, attribute: .leading, relatedBy: .equal, toItem: textView, attribute: .leading, multiplier: 1.0, constant: -29.0)
        let trailConstraint = NSLayoutConstraint(item: alert.view!, attribute: .trailing, relatedBy: .equal, toItem: textView, attribute: .trailing, multiplier: 1.0, constant: 29.0)
        let topConstraint = NSLayoutConstraint(item: alert.view!, attribute: .top, relatedBy: .equal, toItem: textView, attribute: .top, multiplier: 1.0, constant: -60.0)
        let bottomConstraint = NSLayoutConstraint(item: alert.view!, attribute: .bottom, relatedBy: .equal, toItem: textView, attribute: .bottom, multiplier: 1.0, constant: 60.0)
        
        textView.layer.cornerRadius = 4.0
        textView.autocapitalizationType = .words
        textView.autocorrectionType = .yes
        textView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
        textView.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        textView.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        textView.font = UIFont.systemFont(ofSize: 15)
        alert.view.addSubview(textView)
        
        NSLayoutConstraint.activate([leadConstraint, trailConstraint, topConstraint, bottomConstraint])
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        let action = UIAlertAction(title: "Add Items", style: .default) { action in
            let newItemsTextTrimmed = textView.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            if newItemsTextTrimmed == "" { return }
                            
            // Convert text view input to array of new items, and clean up the items
            let newItems: [String] = newItemsTextTrimmed.split(separator: "\n").map({ (substring) in
                return String(substring).trimmingCharacters(in: .whitespacesAndNewlines)
            }).filter({ (string) -> Bool in
                return string != ""
            })
            
            // To-do: check for duplicate between the new items
            var newItemsDeduped: [String] = []
            
            for i in 0..<newItems.count {
                let newItemToCheck = newItems[i]
                var duplicateItemFound = false
                
                for j in 0..<newItemsDeduped.count {
                    if self.gl.isSameName(name1: newItemsDeduped[j], name2: newItemToCheck) {
                        print("\(newItemsDeduped[j]) and \(newItems[i]) is same item")
                        duplicateItemFound = true
                    }
                }
                
                if !duplicateItemFound {
                    newItemsDeduped.append(newItemToCheck)
                }
            }
            
            // For each item in newItemsDeduped, check for duplicate with existing items
            // If not duplicate, add to section 0
            for newItem in newItemsDeduped {
                self.updateBothModelAndViewWith(newItem: newItem)
            }
        }
        
        alert.addAction(cancel)
        alert.addAction(action)
        
        // The following is a hack: adding a text field enables the alert to reposition after keyboard pops up
        // Setting autocorrectionType to .yes allows the autocorrect bar to show up simultaneously as the alert
        alert.addTextField { (UITextField) in
            UITextField.autocorrectionType = .yes
            UITextField.autocapitalizationType = .words
            UITextField.tintColor = #colorLiteral(red: 1, green: 0.596382017, blue: 0.3041648327, alpha: 0)
        }
        
        // Configure alert view (not sure what this does)
        alert.view.autoresizesSubviews = true
        // Alert button text color
        alert.view.tintColor = UIColor.white
        // Alert background color and corner radius
        alert.view.subviews.first?.subviews.first?.subviews.first?.backgroundColor = #colorLiteral(red: 0.9960784314, green: 0.5529411765, blue: 0.2980392157, alpha: 1)
        alert.view.subviews.first?.subviews.first?.subviews.first?.layer.cornerRadius = 10
        // Alert title font size and color
        let attributedString = NSAttributedString(string: "Enter one item per line", attributes:
            [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 21),
            NSAttributedString.Key.foregroundColor : #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)])
        alert.setValue(attributedString, forKey: "attributedTitle")
        
        self.present(alert, animated: true, completion: {
            // Take focus away from text field and give it to text view, where user would input multiline data
            textView.becomeFirstResponder()
        })
        
        // Hide text field border and make it transparent
        for textField in alert.textFields! {
            let container = textField.superview
            let effectView = container?.superview?.subviews[0]
            
            if let view = effectView as? UIVisualEffectView {
                container?.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
                view.removeFromSuperview()
            }
        }
        
    }
    
    @IBAction func addItem(_ sender: UIBarButtonItem) {
        
        // Use an alert to receive user input
        let alert = UIAlertController(title: nil, message: "", preferredStyle: .alert)
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        let submit = UIAlertAction(title: "Add", style: .default) { (UIAlertAction) in
            // Retrieve the text input from the textFields[0] of alert
            let newItem = alert.textFields![0].text!.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if newItem == "" { return }
            
            self.updateBothModelAndViewWith(newItem: newItem)
        }
        
        alert.addAction(submit)
        alert.addAction(cancel)
        alert.addTextField { (UITextField) in
            UITextField.autocapitalizationType = .words
            UITextField.autocorrectionType = .yes
            UITextField.borderStyle = .none
            UITextField.returnKeyType = .done
            UITextField.font = UIFont(name: UITextField.font!.fontName, size: 24)
            UITextField.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        }
        
        // Using height constraint to make the alert layout more beautiful
        // replaced constant: self.view.frame.height * 0.123 with 110
        let height = NSLayoutConstraint(item: alert.view!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 110)
        alert.view.addConstraint(height)
        // Alert button text color
        alert.view.tintColor = UIColor.white
        // Alert background color and corner radius
        alert.view.subviews.first?.subviews.first?.subviews.first?.backgroundColor = #colorLiteral(red: 0.9960784314, green: 0.5529411765, blue: 0.2980392157, alpha: 1)
        alert.view.subviews.first?.subviews.first?.subviews.first?.layer.cornerRadius = 10
        
        self.present(alert, animated: true)

        // Hide text field border and make it transparent
        for textField in alert.textFields! {
            let container = textField.superview
            let effectView = container?.superview?.subviews[0]

            if let view = effectView as? UIVisualEffectView {
                container?.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
                //container?.layer.cornerRadius = 4.0
                view.removeFromSuperview()
            }
        }
    }
    
    @IBAction func uncheckSelectedItems(_ sender: UIBarButtonItem) {
//        if groceryTableView.indexPathsForSelectedRows == nil {
//            for s in 0..<numberOfSections(in: groceryTableView) {
//                for r in 0..<tableView(groceryTableView, numberOfRowsInSection: s) {
//                    groceryTableView.selectRow(at: IndexPath(row: r, section: s), animated: false, scrollPosition: .none)
//                }
//            }
//
//            toggleButtonStateBasedOnRowSelection()
//
//        }
        if groceryTableView.indexPathsForSelectedRows == nil { return }
        
        deselectAllRowsAndHideButtons()
        
        // Set all the visible cell accessory mark to none
        groceryTableView.visibleCells.forEach { (UITableViewCell) in
            UITableViewCell.accessoryType = .none
        }
        
        // The accessory mark for all the cells that are not currently displayed
        // will be cleared in tableView willDisplay cell
    }
    
    func updateBothModelAndViewWith(newItem: String) {
        if let existingItemIndexPath = self.gl.getIndexPath(of: newItem) {
            // Item already exists in the list
            //   If item is in section 0, do nothing
            //   if item is in section 1, move it to section 0
            
            if existingItemIndexPath.section == 1 {
                let currentNumberOfRowsInSection0 = self.groceryTableView.numberOfRows(inSection: 0)
                let newIndexPathForExistingItem = IndexPath(row: currentNumberOfRowsInSection0, section: 0)
                
                // Move item in model
                self.gl.moveItem(from: existingItemIndexPath, to: newIndexPathForExistingItem)
                
                // Update view
                self.groceryTableView.beginUpdates()
                self.groceryTableView.moveRow(at: existingItemIndexPath, to: newIndexPathForExistingItem)
                self.groceryTableView.endUpdates()
            }
            
        } else {
            // Item does not exist in the list. Safe to add.
            
            // First add to model and get location
            let indexPathForNewItem = self.gl.addItem(name: newItem)
            
            // Then update view
            self.groceryTableView.beginUpdates()
            self.groceryTableView.insertRows(at: [indexPathForNewItem], with: .automatic)
            self.groceryTableView.endUpdates()
        }
    }
    
    func setButtonStateBasedOnRowSelection() {
        if groceryTableView.indexPathsForSelectedRows == nil {
            deleteItemsButton.tintColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
            moveItemsButton.tintColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
            selectionToggleButton.tintColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
        } else {
            deleteItemsButton.tintColor = #colorLiteral(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
            moveItemsButton.tintColor = #colorLiteral(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
            selectionToggleButton.tintColor = #colorLiteral(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        }
    }
    
    func deselectAllRowsAndHideButtons() {
        groceryTableView.indexPathsForSelectedRows?.forEach({ (IndexPath) in
            groceryTableView.deselectRow(at: IndexPath, animated: false)
        })
        setButtonStateBasedOnRowSelection()
    }
    
    var gl: GroceryList!
    
    let impactFeedbackGenerator: (
        light: UIImpactFeedbackGenerator,
        medium: UIImpactFeedbackGenerator,
        heavy: UIImpactFeedbackGenerator) = (
            UIImpactFeedbackGenerator(style: .light),
            UIImpactFeedbackGenerator(style: .medium),
            UIImpactFeedbackGenerator(style: .heavy)
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        gl = GroceryList()
        setEditing(true, animated: false)
        
        // Touch visualizer setup
        var config = Configuration()
        config.color = #colorLiteral(red: 0.5723067522, green: 0.5723067522, blue: 0.5723067522, alpha: 1)
        Visualizer.start(config)
    }
    
    // MARK: - TABLE VIEW DATA SOURCE START -----------------------------------------------------------
    
    // BASIC CONFIGURATION START -----------
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return gl.numberOfSections
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return gl.getNumberOfItems(in: section)
    }
    
    // Supply table view with section names
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return gl.sectionNames[section]
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let glCell = cell as! GroceryTableViewCell
        
        let selectionColorUIView = UIView()
        selectionColorUIView.backgroundColor = #colorLiteral(red: 1, green: 0.3833333333, blue: 0, alpha: 0.1032130282)
        glCell.selectedBackgroundView = selectionColorUIView
        
        glCell.mainTextField.text = gl.getItemName(at: indexPath)
        glCell.mainTextField.sizeToFit()
        
        let itemQuantity = gl.getQuantityOfItem(at: indexPath)
        glCell.itemQuantity.text = (itemQuantity == 0 ? "" : String(itemQuantity))
        glCell.slider.setValue(Float(itemQuantity), animated: false)
        // Assign self (GroceryTableViewController) as the delegate to each glcell instance
        glCell.delegate = self
        
        return glCell
    }

    // BASIC CONFIGURATION END -----------
    
    
    // INSERTION AND DELETION START -----------
    
    // Support conditional editing
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    // Support editing
    // note: must implement to support swipe-to-delete
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            gl.deleteItem(at: indexPath)
            
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    // INSERTION AND DELETION END -----------
    
    
    // REORDERING START -----------
    
    // Support conditional rearranging
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    
    // Support rearranging
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        gl.moveItem(from: fromIndexPath, to: to)
    }
    
    // REORDERING END -----------
    
    // MARK: - TABLE VIEW DATA SOURCE END -----------------------------------------------------------
    
    
    // MARK: - TABLE VIEW DELEGATE START ------------------------------------------------------------
    
    // MANAGE SELECTION START -----------
    
    // In non-editing mode, display/hide checkmark according to row selection state
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        // Prepare shortly before playing
        impactFeedbackGenerator.medium.prepare()
        
        return indexPath
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Play the haptic signal
        impactFeedbackGenerator.medium.impactOccurred()
        
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        
        setButtonStateBasedOnRowSelection()
    }

    override func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        // Prepare shortly before playing
        impactFeedbackGenerator.light.prepare()
        
        return indexPath
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        // Play the haptic signal
        impactFeedbackGenerator.light.impactOccurred()
        
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
        
        // If everything is deselected, make delete and move buttons invisible
        setButtonStateBasedOnRowSelection()
    }
    
    // MANAGE SELECTION END -----------

    
    // For the cells that temporarily went out of display, during which whose accessoryType is unreachable
    // configure accessory correctly according to their selection state before displaying
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if cell.isSelected {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
    }
    
//    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        
//    }
//    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 60.0
//    }
    
    // MARK: - TABLE VIEW DELEGATE END ------------------------------------------------------------
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}
