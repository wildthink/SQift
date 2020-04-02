//
//  AppDatabaseTests.swift
//  SQift
//
//  Created by Jason Jobe on 4/1/20.
//  Copyright © 2020 Nike. All rights reserved.
//

import Foundation
import SQift
import SQLite3
import XCTest

class AppDatabaseTests: BaseTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAppDatabaseAppTables() throws {
        let db = try AppDatabase(storageLocation: .onDisk("/Users/jason/test.db"))
        try db.createApplicationDatabase(reset: true)
        
        try db.set(env: "select.any", to: "abc")
        var value = db.get(env: "select.any") as? String
        XCTAssert(value == "abc")

        try db.set(env: "select.any", to: "abc123")
        value = db.get(env: "select.any") as? String
        XCTAssert(value == "abc123")
     }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
