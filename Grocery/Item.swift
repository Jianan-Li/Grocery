//
//  GroceryModel.swift
//  Grocery
//
//  Created by Jianan Li on 2/8/19.
//  Copyright © 2019 Jianan Li. All rights reserved.
//

import Foundation

class GroceryList{
    
    //MARK: Properties
    
    var name: String
    var quantity: Int?
    
    //MARK: Initialization
    
    init (name: String) {
        // Initialize stored properties.
        self.name = name
    }

}
