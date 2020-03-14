//
//  AppDatabase.swift
//  SQift iOS
//
//  Created by Jason Jobe on 3/12/20.
//  Copyright © 2020 WildThink, LLC. All rights reserved.
//

import Foundation

open class AppDatabase: Database {
    
    public func execute(contentsOfFile file: String) throw {
        let sql = try String(contentsOfFile: file)
        try executeWrite {
            try $0.execute(sql)
        }
    }
    
    public func execute(contentsOfURL url: URL) throw {
        let sql = try String(contentsOf: url)
        try executeWrite {
            try $0.execute(sql)
        }
    }

// MARK: Application Setting Operations

    public set(_ key: String, to value: Any) {
        
    }
    
    public get(_ key: String) -> Any? {
        return nil
    }
    
    /// The `append` method  wraps the value into a JSON array
    public append(_ value: Any, to key: String) {
        
    }
    
    /// Removes the value , if found, from the JSON value array
    public remove(_ value: Any), from key: String) {
    
    }
}
