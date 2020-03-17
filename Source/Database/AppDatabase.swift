//
//  AppDatabase.swift
//  SQift iOS
//
//  Created by Jason Jobe on 3/12/20.
//  Copyright © 2020 WildThink, LLC. All rights reserved.
//

import Foundation

open class AppDatabase: Database {
    
    public static var shared: AppDatabase! = try? AppDatabase()
    
    public func execute(contentsOfFile file: String) throws {
        let sql = try String(contentsOfFile: file)
        try executeWrite {
            try $0.execute(SQL(sql))
        }
    }
    
    public func execute(contentsOfURL url: URL) throws {
        let sql = try String(contentsOf: url)
        try executeWrite {
            try $0.execute(SQL(sql))
        }
    }

    public func execute(resource name: String, in bundle: Bundle?) throws {
        let bundle = bundle ?? Bundle.main
        guard let path = bundle.path(forResource: name, ofType: "sql")
        else { throw Database.DBError.invalidFile }
        
        let sql = try String(contentsOfFile: path)
        try executeWrite {
            try $0.execute(SQL(sql))
        }
    }

// MARK: Application Setting Operations

    public func set(_ key: String, to value: Any) {
        
    }
    
    public func get(_ key: String) -> Any? {
        return nil
    }
    
    /// The `append` method  wraps the value into a JSON array
    public func append(_ value: Any, to key: String) {
        
    }
    
    /// Removes the value , if found, from the JSON value array
    public func remove(_ value: Any, from key: String) {
    
    }
}

extension AppDatabase {
    
    func sql_type(for nob: Any) -> String {
        
        switch nob {
        case is String: return "TEXT"
        case is Double: return "REAL"
        case is Int: return "INTEGER"
        case is Data: return "BLOB"
        case is NSNull: return "NULL"
        case is Date: return "DATE"
        case is Array<Any>: return "JSON"
        case is Dictionary<String,Any>: return "JSON"
        default:
            return ""
        }
    }

    public func createSQL(_ table: String, for nob: [String:Any], pkey: String? = nil) -> SQL {
        
        var endx = nob.count - 1
        var sql = "CREATE TABLE \(table) (\n"
        
        // We prefer the primary key be first
        if let key = pkey, let value = nob[key] {
            let comma = nob.count > 1 ? "," : ""
            print("\t", key, " PRIMARY KEY ", sql_type(for: value), comma, separator: "", to: &sql)
        }
        
        for (key, v) in nob {
            let comma = endx > 0 ? "," : ""
            if key != pkey {
                print("\t", key, " ", sql_type(for: v), comma, separator: "", to: &sql)
            }
            endx -= 1
        }
        print(")", to: &sql)
        return SQL(sql)
    }
}
