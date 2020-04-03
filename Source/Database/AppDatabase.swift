//
//  AppDatabase.swift
//  SQift iOS
//
//  Created by Jason Jobe on 3/12/20.
//  Copyright © 2020 WildThink, LLC. All rights reserved.
//

import Foundation

open class AppDatabase {
    
    public static var shared: AppDatabase! = try? AppDatabase()
    
    var attachedDatabases: [String:StorageLocation] = [:]
    let queue: ConnectionQueue
    let connection: Connection
    
    public init(_ storageLocation: StorageLocation = .sharedMemory(":shared:")) throws {
        connection = try Connection(storageLocation: storageLocation,
                                       tableLockPolicy: .fastFail, readOnly: false,
                                       multiThreaded: true, sharedCache: false)
        queue = ConnectionQueue(connection: connection)
    }
    
    public func executeRead(_ transactionType: Connection.TransactionType = .deferred, closure: (Connection) throws -> Void) throws {
        try queue.executeInTransaction(transactionType: transactionType) {
            try closure($0)
        }
    }

    /// Executes the specified closure on the writer connection queue.
    ///
    /// - Parameter closure: The closure to execute.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error executing the closure.
    public func executeWrite(_ transactionType: Connection.TransactionType = .deferred, closure: (Connection) throws -> Void) throws {
        try queue.executeInTransaction(transactionType: transactionType) {
             try closure($0)
        }
    }
    
    public func attachDatabase(from storageLocation: StorageLocation, withName name: String) throws {
        try executeWrite { (c) in
            try c.attachDatabase(from: storageLocation, withName: name)
        }
        attachedDatabases[name] = storageLocation
    }

    public func detachDatabase(named name: String) throws {
        try executeWrite { (c) in
            try c.detachDatabase(named: name)
        }
        attachedDatabases.removeValue(forKey: name)
    }

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
            else { return } //throw Database.DBError.invalidFile }
        
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
    
    public private(set) var applicationEnvTable = "app_env"
    public private(set) var applicationLogTable = "app_log"

    open func createApplicationDatabase(reset: Bool = false) throws {
        try createApplicationDatabase(applicationEnvTable, reset: reset)
        try createApplicationDatabase(applicationLogTable, reset: reset)
    }
    
    public func createApplicationDatabase(_ table: String, reset: Bool) throws {
        try executeWrite {
            if reset {
                try $0.execute("DROP TABLE IF EXISTS \(table)")
            }
            try $0.execute("""
                CREATE TABLE IF NOT EXISTS \(table) (
                    id INTEGER PRIMARY KEY,
                    tag TEXT,
                    key TEXT UNIQUE,
                    value BLOB
                )
            """)
        }
    }
        
    public func set(env: String, to value: Bindable) throws {
        try set(env, in: applicationEnvTable, to: value)
    }
    
    public func get(env: String, default other: Any? = nil) -> Any? {
        (try? get (env, in: applicationEnvTable)) ?? other
    }
    
    func set(_ key: String, in table: String, to value: Bindable) throws {
        try executeWrite {
            let sql: SQL =
            """
                INSERT INTO \(table) (key, value) VALUES(? ,?)
                ON CONFLICT(key) DO UPDATE SET value = ?
            """
            try $0.prepare(sql, key, value, value).run()
        }
    }
    
    func get(_ key: String, in table: String) throws -> Any? {
        var row: Row?
        try executeRead {
            row = try $0.query("SELECT value FROM \(applicationEnvTable) WHERE key = ?", [key])
        }
        return row?.value(at: 0)
    }
    
    public func update(_ table: String, with keyvalues: [String:Bindable?]) throws {
        try executeWrite {
            try $0.update(table: table, with: keyvalues as [String:Any])
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
