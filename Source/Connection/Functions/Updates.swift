//
//  Updates.swift
//  SQift iOS
//
//  Created by Jason Jobe on 3/21/20.
//  Copyright © 2020 Nike. All rights reserved.
//

import Foundation

extension Connection {
    
    /// This `insert` method is useful when it is desirable to insert  values
    /// from a Dictionary.
    ///
    /// - Parameter table: The name of the table
    ///
    /// - Parameter plist: A Dictionary with values for a record.
    ///
    /// - Returns: Void
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error stepping through the statement.
    @discardableResult
    public func insert(into table: String, from plist: [String:Any]) throws -> Int64 {
        
        var keys: [String] = []
        var slots: [String] = []
        var values: [Bindable?] = []
        
        for (key, val) in plist {
            keys.append(key)
            slots.append("?")
            guard let bval = asBindable(val) else {
                throw Database.DBError("Cannot insert non Bindable value \(val) into \(table) \(key)")
            }
            values.append(bval)
        }
        let sql: SQL = "INSERT INTO \(table) (\(keys.joined(separator: ","))) VALUES(\(slots.joined(separator: ",")))"
        
        try run(sql, values)
        return lastInsertRowID
    }

/*
    /// This `insert` method is useful when it is desirable to insert  values
    /// from a Dictionary.
    ///
    /// - Parameter table: The name of the table
    ///
    /// - Parameter plist: A Dictionary with values for a record.
    ///
    /// - Returns: Void
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error stepping through the statement.
    @discardableResult
    public func insert(into table: String, from plist: [String:Bindable?]) throws -> Int64 {
        
        var keys: [String] = []
        var slots: [String] = []
        var values: [Bindable?] = []

        for (key, val) in plist {
            keys.append(key)
            slots.append("?")
            values.append(val)
        }
        let sql: SQL = "INSERT INTO \(table) (\(keys.joined(separator: ","))) VALUES(\(slots.joined(separator: ",")))"
        
        try run(sql, values)
        return lastInsertRowID
    }
*/
    /// The `delete` method deletes records from the given `table`
    /// In the exceptional case you really want to remove all the records
    /// in the table the `confirmAll` MUST be explicitly set and the test
    /// be empty
    public func delete(from table: String, where test: String, confirmAll: Bool = false) throws {
        if confirmAll, test == "" {
            try execute("DELETE FROM \(table)")
        } else {
            try execute("DELETE FROM \(table) WHERE \(test)")
        }
    }

    /// This `update` method is useful when it is desirable to update  values
    /// from a Dictionary. Furthermore the row is only updated if the values
    /// have actually changed thus avoiding any trigger when nothing has changed.
    ///
    /// - Parameter table: The name of the table
    ///
    /// - Parameter plist: A Dictionary with values for a record.
    /// - Parameter limit: A negative limit indicates ALL or NO Limit
    ///
    /// - Returns: Void
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error stepping through the statement.
    public func update(table: String, with plist: [String:Any], limit: Int = -1) throws {
        
            var sets: [String] = []
            var values: [Bindable?] = []
        
            for (key, value) in plist {
                sets.append("\(key) = ?")
                guard let bval = asBindable(value) else {
                    throw Database.DBError("Cannot insert non Bindable value \(value) into \(table) \(key)")
                }
                values.append(bval)
            }
            
        let sql: SQL = """
                UPDATE \(table)
                SET \(sets.joined(separator: ","))
                WHERE NOT (
                    \(sets.joined(separator: " AND ")))
                LIMIT \(limit)
            """
            /*
             ORDER column_or_expression
             LIMIT row_count OFFSET offset;
             */
            try run(sql, values)
    }

    func asBindable(_ any: Any) -> Bindable? {
        if let bind = any as? Bindable { return bind }
        switch any {
        case is NSArray: return (any as? [Any])
        case is NSDictionary: return (any as? [String:Any])
        case is NSString: return (any as? String)
        case let num as NSNumber:
            if num is Int { return num.intValue }
            if num is Double { return num.doubleValue }
            return (num as Any) as? Bindable
        default:
            return any as? Bindable
        }
    }

}
