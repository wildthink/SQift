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
    public func insert(into table: String, from plist: [String:Bindable?]) throws -> Int64 {
        
        var keys: [String] = []
        var slots: [String] = []
        var values: [Bindable?] = []

        for (key, val) in plist {
            keys.append(key)
            slots.append("?")
//            values.append (sql_quote(val))
            values.append(val)
        }
        let sql: SQL = "INSERT INTO \(table) (\(keys.joined(separator: ","))) VALUES(\(slots.joined(separator: ",")))"
        
        try run(sql, values)
        return lastInsertRowID
    }
    
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
    public func update(table: String, with plist: [String:Bindable?], limit: Int = -1) throws {
        
            var sets: [String] = []
            var values: [Bindable?] = []
        
            for (key, value) in plist {
//                let q_value = sql_quote(value as Any)
//                sets.append("\(key) = \(q_value)")
                sets.append("\(key) = ?")
                values.append(value)
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
//         try execute(sql)
    }

}
