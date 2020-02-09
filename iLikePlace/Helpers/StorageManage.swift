 //
//  StorageManage.swift
//  FavoritePlaces
//
//  Created by Lucky on 06/02/2020.
//  Copyright © 2020 DmitriyYatsyuk. All rights reserved.
//

import RealmSwift
 
 let realm = try! Realm()
 
 class StorageManager {
    
    static func saveObject(_ place: Place) {
        
        try! realm.write {
            realm.add(place)
            
        }
    }
  
    static func deleteObject(_ place: Place) {
        try! realm.write {
            realm.delete(place)
            
        }
    }
 }
 
 
 
 
 
