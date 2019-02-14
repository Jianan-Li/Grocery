//
//  GroceryList.swift
//  Grocery
//
//  Created by Jianan Li on 2/9/19.
//  Copyright © 2019 Jianan Li. All rights reserved.
//

import Foundation

class Item {
    
    //MARK: Properties
    
    var name: String
    var quantity: Int
    
    //MARK: Initialization
    
    init (name: String) {
        // Initialize stored properties.
        self.name = name
        self.quantity = 0
    }
    
    init (name: String, quantity: Int) {
        // Initialize stored properties.
        self.name = name
        self.quantity = quantity
    }
    
}

class GroceryList: CustomStringConvertible{
    
    // Implement CustomStringConvertible for print()
    var description: String {
        get {
            // Initialize an empty string to be returned
            var listContent: String = ""
            
            for sectionName in sectionNames {
                let sectionItems = list[sectionName]!
                listContent.append("\(sectionName):\n")
                for item in sectionItems {
                    listContent.append("\t\(item.name)\t")
                    listContent.append("\t\(item.quantity)\n")
                }
            }
            return listContent
        }
    }
    
    //MARK: Class Properties
    
    var sectionNames: [String] = ["get these", "past purchases"]
    
    var numberOfSections: Int {
        get {
            return sectionNames.count
        }
    }
    
    var list: [String : [Item]] = [:]
    
    var listTempNSArray: [String : [NSArray]] = [:]
    
    var storageKey = "SavedGroceryList"
    
    init () {
        //        list = [sectionNames[0] : section0, sectionNames[1] : section1]
        if UserDefaults.standard.object(forKey: storageKey) == nil {
            list = [sectionNames[0] : [], sectionNames[1] : []]
        } else {
            listTempNSArray = (UserDefaults.standard.object(forKey: storageKey) as? [String : [NSArray]])!
            for (sectionName, sectionNSArray) in listTempNSArray {
                var sectionItems: [Item] = []
                for itemNSArray in sectionNSArray {
                    let item = Item(name: itemNSArray[0] as! String, quantity: itemNSArray[1] as! Int)
                    sectionItems.append(item)
                }
                list[sectionName] = sectionItems
            }
        }
    }
    
    func saveGroceryList() {
        // [section1: [Item0, Item1], section2: [] ] ->
        // [section1: [ [Item0.name: Item0.quantity], [Item1.name: Item1.quantity] ], section2:   ]
        for (sectionName, sectionItems) in list {
            var sectionNSArray: [NSArray] = []
            for item in sectionItems {
                let itemNSArray: NSArray = [item.name, item.quantity]
                sectionNSArray.append(itemNSArray)
            }
            listTempNSArray[sectionName] = sectionNSArray
        }
        UserDefaults.standard.set(listTempNSArray, forKey: storageKey)
    }
    
    func isSameName(name1: String, name2: String) -> Bool {
        var name1Array = [name1]
        var name2Array = [name2]
        
        if name1.hasSuffix("ies") {
            name1Array.append(String(name1.dropLast(3)+"y"))
        } else if name1.hasSuffix("es") {
            name1Array.append(String(name1.dropLast(2)))
        } else if name1.hasSuffix("s"){
            name1Array.append(String(name1.dropLast()))
        } else {
            name1Array.append(name1 + "s")
            name1Array.append(name1 + "es")
        }
        
        if name2.hasSuffix("ies") {
            name2Array.append(String(name2.dropLast(3)+"y"))
        } else if name2.hasSuffix("es") {
            name2Array.append(String(name2.dropLast(2)))
        } else if name2.hasSuffix("s"){
            name2Array.append(String(name2.dropLast()))
        } else {
            name2Array.append(name2 + "s")
            name2Array.append(name2 + "es")
        }
        
        let name1ArrayNonempty = name1Array.filter{ $0 != "" }
        let name2ArrayNonempty = name2Array.filter{ $0 != "" }
        
        let match = name1ArrayNonempty.filter(name2ArrayNonempty.contains)
        
        if match != [] {
            return true
        } else {
            return false
        }
    }
    
    // Mark: Retrive information about the items in the list ----------------------------------
    
    func getNumberOfItems(in section: Int) -> Int {
        return list[sectionNames[section]]!.count
    }
    
    func getItemName(at indexpath: IndexPath) -> String {
        return list[sectionNames[indexpath.section]]![indexpath.row].name
    }
    
    func getQuantityOfItem(at indexpath: IndexPath) -> Int {
        return list[sectionNames[indexpath.section]]![indexpath.row].quantity
    }
    
    // This is a rough matching using isSameName, which takes into consideration singular and plural forms
    func getIndexPath(of itemName: String) -> IndexPath? {
        let emptyIndexPath: IndexPath? = nil
        
        for sectionName in sectionNames {
            let sectionItems = list[sectionName]!
            for itemIndex in 0..<sectionItems.count {
                if isSameName(name1: sectionItems[itemIndex].name, name2: itemName) {
                    let sectionNumber = sectionNames.firstIndex(of: sectionName)!
                    print("Duplicate item found: \(sectionItems[itemIndex].name) at \(IndexPath(row: itemIndex, section: sectionNumber))")
                    return IndexPath(row: itemIndex, section: sectionNumber)
                }
            }
        }
        return emptyIndexPath
    }
    
    
    // MARK: Update item properties in the list ----------------------------------------------
    
    func updateItemName(at indexpath: IndexPath, newItemName: String) {
        if list[sectionNames[indexpath.section]]![indexpath.row].name != newItemName {
            list[sectionNames[indexpath.section]]![indexpath.row].name = newItemName
            
            // Save modified list
            saveGroceryList()
        }
    }
    
    func updateQuantityOfItem(at indexpath: IndexPath, newItemQuantity: Int) {
        if list[sectionNames[indexpath.section]]![indexpath.row].quantity != newItemQuantity {
            list[sectionNames[indexpath.section]]![indexpath.row].quantity = newItemQuantity
            
            // Save modified list
            saveGroceryList()
        }
    }
    
    
    // MARK: Modify the list: add, move, delete ----------------------------------------------
    
    func addItem(name: String, quantity: Int = 0) -> IndexPath {
        let newItem = Item(name: name, quantity: quantity)
        list[sectionNames[0]]!.append(newItem)
        
        // Save modified list
        saveGroceryList()
        
        return IndexPath(row: list[sectionNames[0]]!.count-1, section: 0)
    }
    
    func addItems(names: [String]) {
        for name in names {
            let newItem = Item(name: name)
            list[sectionNames[0]]!.append(newItem)
        }
        
        // Save modified list
        saveGroceryList()
    }
    
    func moveItem(from: IndexPath, to: IndexPath) {
        let item = list[sectionNames[from.section]]!.remove(at: from.row)
        list[sectionNames[to.section]]!.insert(item, at: to.row)
        
        // Save modified list
        saveGroceryList()
    }
    
    func deleteItem(at indexPath: IndexPath) {
        list[sectionNames[indexPath.section]]!.remove(at: indexPath.row)
        // Save modified list
        saveGroceryList()
    }
    
    func deleteItems(selectedRows: [IndexPath]) {
        for selectedRow in selectedRows {
            list[sectionNames[selectedRow.section]]?[selectedRow.row].name = "toBeRemoved"
        }
        list[sectionNames[0]] = list[sectionNames[0]]?.filter({ (Item) -> Bool in
            return Item.name != "toBeRemoved"
        })
        list[sectionNames[1]] = list[sectionNames[1]]?.filter({ (Item) -> Bool in
            return Item.name != "toBeRemoved"
        })
        
        // Save modified list
        saveGroceryList()
    }
    
}
