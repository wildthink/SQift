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
    
//    public init()
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

    /// The Application Environment State is stored in the `applicationTable`
    /// which is defined by the following schema.
    ///
    /// CREATE TABLE app_env (
    ///     key TEXT PRIMARY KEY,
    ///     value BLOB
    ///  )
    
    public private(set) var applicationTable = "app_env"
    
    open func createApplicationDatabase() throws {
        try executeWrite {
            try $0.execute("""
                CREATE TABLE \(applicationTable) (
                    key TEXT PRIMARY KEY,
                    tag TEXT,
                    value BLOB
                )
            """)
        }
    }
    
    /*
     INSERT INTO memos(id,text)
     SELECT 5, 'text to insert'
     WHERE NOT EXISTS(SELECT 1 FROM memos WHERE id = 5 AND text = 'text to insert');
     */
    
    public func set(_ key: String, to value: Any) throws {
        try executeWrite {
            let q_value = sql_quote(value)
            let sql = """
                INSERT INTO \(applicationTable) (key,value)
                SELECT \(key), \(q_value)
                WHERE NOT EXISTS(SELECT 1 FROM \(applicationTable) WHERE key = \(key);
            
                UPDATE \(applicationTable) SET key = \(key), value = \(q_value)
                WHERE NOT (key = \(key) AND value = \(q_value))
            """
            try $0.execute(sql)
        }
    }
    
    public func get(_ key: String) -> Any? {
        var value: Any?
        try? executeRead {
            value = try $0.query("SELECT value FROM \(applicationTable) WHERE key = ?", [key])
        }
        return value
    }
    
    public func update(_ table: String, with keyvalues: [String:Any]) throws {
        try executeWrite {
            try $0.update(table: table, with: keyvalues)
        }
    }

    
    /// The `append` method  wraps the value into a JSON array
    public func append(_ value: Any, to key: String) {
        
    }
    
    /// Removes the value , if found, from the JSON value array
    public func remove(_ value: Any, from key: String) {
    
    }
}

public extension AppDatabase {
    struct Table {
        var name: String
    }
    
    struct Column: CustomStringConvertible {
        public let name: String
        public let sqlType: String
        public let dataType: String
        
        public var description: String { "\(name) \(sqlType)" }
        
        static var id_c: Column = Column(name: "id", sqlType: "INTEGER PRIMARY KEY", dataType: "Int64")
        static func text(_ name: String) -> Column {
            Column(name: name, sqlType: "TEXT", dataType: "String")
        }
        static func int(_ name: String) -> Column {
            Column(name: name, sqlType: "INT", dataType: "Int64")
        }
        static func real(_ name: String) -> Column {
            Column(name: name, sqlType: "REAL", dataType: "Double")
        }
        static func json_obj(_ name: String) -> Column {
            Column(name: name, sqlType: "JSON OBJ TEXT", dataType: "[String:Any]")
        }
    }
}

extension AppDatabase {
    
    public func sql_type(for nob: Any) -> String {
        
        switch nob {
        case is String: return "TEXT"
        case is Double: return "REAL"
        case is Int: return "INTEGER"
        case is Data: return "BLOB"
        case is NSNull: return "NULL"
        case is Date: return "DATE"
        case is Array<Any>: return "JSON ARRAY TEXT"
        case is Dictionary<String,Any>: return "JSON OBJ TEXT"
        default:
            return ""
        }
    }

    public func createSQL(_ table: String, for nob: [String:Any], pkey: String? = nil,
                          skipPrefix: String? = nil) -> SQL {
        
        var endx = nob.count - 1
        var sql = "CREATE TABLE \(table) (\n"
        
        // We prefer the primary key be first
        if let key = pkey, let value = nob[key] {
            let comma = nob.count > 1 ? "," : ""
            print("\t", key, " PRIMARY KEY ", sql_type(for: value), comma, separator: "", to: &sql)
        }
        
        for (key, v) in nob {
            if key == pkey, let skip = skipPrefix, key.starts(with: skip) {
                endx += 1
                continue
            }
            let comma = endx > 0 ? "," : ""
            print("\t", key, " ", sql_type(for: v), comma, separator: "", to: &sql)
            endx -= 1
        }
        print(")", to: &sql)
        return SQL(sql)
    }
}
