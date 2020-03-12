//
//  StorageLocation.swift
//
//  Copyright 2015-present, Nike, Inc.
//  All rights reserved.
//
//  This source code is licensed under the BSD-stylelicense found in the LICENSE
//  file in the root directory of this source tree.
//

import Foundation

/// Used to specify the path of the database for initialization.
///
/// - onDisk:    Creates an [on-disk database](https://www.sqlite.org/uri.html).
/// - inMemory:  Creates an [in-memory database](https://www.sqlite.org/inmemorydb.html#sharedmemdb).
/// - sharedMemory:  Creates an [in-memory shared database](https://www.sqlite.org/inmemorydb.html#sharedmemdb).
/// - temporary: Creates a [temporary on-disk database](https://www.sqlite.org/inmemorydb.html#temp_db).
public enum StorageLocation {
    case onDisk(String)
    case inMemory
    case sharedMemory(String)
    case temporary

    /// Returns the path of the database.
    public var path: String {
        switch self {
        case .onDisk(let path):
            return path

        // file::memory:?cache=shared
        // If two or more distinct but shareable in-memory databases are
        // needed in a single process, then the mode=memory query parameter
        // can be used with a URI filename to create a named in-memory database:
        //
        // rc = sqlite3_open("file:memdb1?mode=memory&cache=shared", &db);
        case .sharedMemory(let name):
            return "file:\(name)?mode=memory&cache=shared"

        case .inMemory:
            return ":memory:"

        case .temporary:
            return ""
        }
    }
}
