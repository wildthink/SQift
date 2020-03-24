//
//  Database.swift
//
//  Copyright 2015-present, Nike, Inc.
//  All rights reserved.
//
//  This source code is licensed under the BSD-stylelicense found in the LICENSE
//  file in the root directory of this source tree.
//

import Foundation

/// The `Database` class is a lightweight way to create a single writable connection queue and connection pool for
/// all read statements. The read and write APIs are designed to make it simple to execute SQL statements on the
/// appropriate type of `Connection` in a thread-safe manner.
open class Database {
    
    public struct DBError: Error, CustomStringConvertible {
        public var description: String
        
        static var inMemoryInvalidOption = DBError(description: "DBERROR: The .inMemory StorageLocation is not valid when using multiple Connections" )
        
        static var invalidFile = DBError(description: "DBERROR: File NOT found" )

    }
    
    /// The writer connection queue used to execute all write operations.
    public var writerConnectionQueue: ConnectionQueue!

    /// The reader connection pool used to execute all read operations.
    public var readerConnectionPool: ConnectionPool!
    
    // MARK: - Initialization

    /// Creates a `Database` instance with the specified storage location, initialization flags and preparation closures.
    ///
    /// The writer connection preparation closure is executed immediately after the writer connection is created. This
    /// can be very useful for setting up PRAGMAs or custom collation closures on the connection before use. The reader
    /// connection preparation closure is executed immediately after a new reader connection is created.
    /// The default StorageLocation is 'file::memory:?cache=shared'
    ///
    /// - Parameters:
    ///   - storageLocation:             The storage location path to use during initialization.
    ///   - tableLockPolicy:             The table lock policy used to handle table lock errors. `.fastFail` by default.
    ///   - multiThreaded:               Whether the database should be multi-threaded. `true` by default.
    ///   - sharedCache:                 Whether the database should use a shared cache. `false` by default.
    ///   - drainDelay:                  Total time to wait before draining available reader connections. `1.0` by 
    ///                                  default.
    ///   - writerConnectionPreparation: The closure executed when the writer connection is created. `nil` by default.
    ///   - readerConnectionPreparation: The closure executed when each new reader connection is created. `nil` by 
    ///                                  default.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error opening the writable connection.
    public init(
        storageLocation: StorageLocation = .sharedMemory(":memory:"),
        tableLockPolicy: TableLockPolicy = .fastFail,
        multiThreaded: Bool = true,
        sharedCache: Bool = false,
        drainDelay: TimeInterval = 1.0,
        writerConnectionPreparation: ((Connection) throws -> Void)? = nil,
        readerConnectionPreparation: ((Connection) throws -> Void)? = nil)
        throws
    {
        
        guard storageLocation.isShared else { throw DBError.inMemoryInvalidOption }
        
        let writerConnection = try Connection(
            storageLocation: storageLocation,
            tableLockPolicy: tableLockPolicy,
            readOnly: false,
            multiThreaded: multiThreaded,
            sharedCache: sharedCache
        )

        try writerConnectionPreparation?(writerConnection)

        writerConnectionQueue = ConnectionQueue(connection: writerConnection)

        readerConnectionPool = ConnectionPool(
            storageLocation: storageLocation,
            tableLockPolicy: tableLockPolicy,
            availableConnectionDrainDelay: drainDelay,
            connectionPreparation: readerConnectionPreparation
        )
    }

    /// Creates a `Database` instance with the specified storage location, initialization flags and preparation closures.
    ///
    /// The writer connection preparation closure is executed immediately after the writer connection is created. This
    /// can be very useful for setting up PRAGMAs or custom collation closures on the connection before use. The reader
    /// connection preparation closure is executed immediately after a new reader connection is created.
    ///
    /// - Parameters:
    ///   - storageLocation:             The storage location path to use during initialization.
    ///   - tableLockPolicy:             The table lock policy used to handle table lock errors. `.fastFail` by default.
    ///   - flags:                       The bitmask flags to use when initializing the database.
    ///   - drainDelay:                  Total time to wait before draining available reader connections. `1.0` by 
    ///                                  default.
    ///   - writerConnectionPreparation: The closure executed when the writer connection is created. `nil` by default.
    ///   - readerConnectionPreparation: The closure executed when each new reader connection is created. `nil` by 
    ///                                  default.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error opening the writable connection.
    // NOTE: jmj - The ONLY difference between the two `inits` is that this one the user
    // passes all the flags as an Int32 bitmask
    public init(
        storageLocation: StorageLocation = .sharedMemory(":memory:"),
        tableLockPolicy: TableLockPolicy = .fastFail,
        flags: Int32,
        drainDelay: TimeInterval = 1.0,
        writerConnectionPreparation: ((Connection) throws -> Void)? = nil,
        readerConnectionPreparation: ((Connection) throws -> Void)? = nil)
        throws
    {
        guard storageLocation.isShared else { throw DBError.inMemoryInvalidOption }

        let writerConnection = try Connection(
            storageLocation: storageLocation,
            tableLockPolicy: tableLockPolicy,
            flags: flags
        )

        try writerConnectionPreparation?(writerConnection)

        writerConnectionQueue = ConnectionQueue(connection: writerConnection)

        readerConnectionPool = ConnectionPool(
            storageLocation: storageLocation,
            tableLockPolicy: tableLockPolicy,
            availableConnectionDrainDelay: drainDelay,
            connectionPreparation: readerConnectionPreparation
        )
    }

    // MARK: - Execution

    /// Executes the specified closure on the read-only connection pool.
    ///
    /// - Parameter closure: The closure to execute.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error executing the closure.
    public func executeRead(_ transactionType: Connection.TransactionType = .deferred, closure: (Connection) throws -> Void) throws {
        try readerConnectionPool.execute { connection in
            // jmj - added transaction
            try connection.transaction(transactionType: transactionType) {
                try closure(connection)
            }
        }
    }

    /// Executes the specified closure on the writer connection queue.
    ///
    /// - Parameter closure: The closure to execute.
    ///
    /// - Throws: A `SQLiteError` if SQLite encounters an error executing the closure.
    public func executeWrite(_ transactionType: Connection.TransactionType = .deferred, closure: (Connection) throws -> Void) throws {
        try writerConnectionQueue.execute { connection in
            // jmj - added transaction
            try connection.transaction(transactionType: transactionType) {
                try closure(connection)
            }
        }
    }
}
