//
//  SQiftExtensions.swift
//  SQiftExtensions
//
//  Created by Jobe, Jason on 3/13/20.
//  Copyright © 2020 Jobe, Jason. All rights reserved.
//

import Foundation

extension Connection {

    public func count(_ table: String, where test: String? = nil) -> Int {
        var sql: SQL
        if let test = test {
            sql = "SELECT count(*) FROM \(table) WHERE \(test)"
        } else {
            sql = "SELECT count(*) FROM \(table)"
        }

        let count: Int? = try? query(sql)
        return count ?? 0
    }

    public func create(view: String, from table: String, select cols: [String]) throws {

        let formatted_cols = cols.map { format(column: $0, as: $0) }
        let sql = """
            CREATE VIEW \(table) IF NOT EXISTS AS SELECT \(formatted_cols) from \(table)
        """

        try execute(sql)
    }

    public func create(_ table: String, addID: Bool = true, with defs: String) throws {

        let sql = addID
            ? "CREATE TABLE \(table) (id INTEGER PRIMARY KEY, \(defs))"
            : "CREATE TABLE \(table) (\(defs))"

        try execute("DROP TABLE IF EXISTS \(table)")
        try execute(sql)
    }

    /// Formats json keypaths for SQL query
    public func format(column: String, as alias: String? = nil) -> String {
        guard column.starts(with: "$") ||  column.contains(".")
            else { return column }
        let parts = column.starts(with: "$")
            ? column.dropFirst().split(separator: ".", maxSplits: 1)
            : column.split(separator: ".", maxSplits: 1)

        let str = "json_extract(\(parts[0]),'$.\(parts[1])')"

        if let alias = alias {
            return str + " AS \(alias.replacingOccurrences(of: ".", with: "_"))"
        } else {
            return str
        }
    }

    public func select(_ col: String, from table: String, id: Int) throws -> Any? {
        let sql: SQL = "SELECT \(format(column:col)) FROM \(table) WHERE id = \(id) LIMIT 1"
        return try query(sql, [])?.value(at: 0)
    }

    public func select(_ cols: [String], from table: String, where test: String? = nil) throws -> [[String:Any]] {
        let sql: SQL
        if let test = test {
            sql = "SELECT \(cols.joined(separator: ",")) FROM \(table) WHERE \(test)"
        } else {
            sql = "SELECT \(cols.joined(separator: ",")) FROM \(table)"
        }

        var results = [[String:Any]]()
        try fetch(sql, []) { row in
            var dict = [String:Any]()
            for col in row.columns {
                dict[col.name] = col.value
            }
            results.append(dict)
        }
        return results
    }

    public func insert(into table: String, dictionary: [String:Any]) throws {
        var keys: [String] = ["id"]
        var values: [String] = ["NULL"]

        for (key, value) in dictionary {
            keys.append (key)
            if let str = value as? String {
                if str.contains("\'") {
                    let esc_str = str.replacingOccurrences(of: "'", with: "''")
                    values.append("'\(esc_str)'")
                } else {
                    values.append("'\(str)'")
                }
            } else if value is Array<Any> || value is Dictionary<String,Any> {
                values.append (json_to_sql(value))
            } else {
                values.append (String(describing: value))
            }
        }

        let keys_s = keys.joined(separator: ",")
        let vals_s = values.joined(separator: ",")

        let sql = "INSERT INTO \(table) (\(keys_s)) VALUES (\(vals_s))"
        try execute(sql)
    }

    public func json_to_sql(_ value: Any) -> String {
        if let data = try? JSONSerialization.data(withJSONObject: value, options: .fragmentsAllowed),
            let str = String(data: data, encoding: .utf8) {
            return "json('\(str)')"
        }
        return "NULL"
    }
}
