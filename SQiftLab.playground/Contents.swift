import Cocoa
import SQift

// https://news.ycombinator.com/item?id=19277809
// https://github.com/rgov/sqlite_protobuf
// https://www.sqlite.org/json1.html#jgrouparray
// https://gist.github.com/wildthink/287848614e9bc4c984357d3c72d7479d


struct Location: CodableBinding {
    typealias BindingType = String
    var name: String
}

let dbc = try Connection(storageLocation: .inMemory)

try dbc.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER, tags JSON, location JSON, freq TEXT)")

let tags = """
["alpha", "beta", 33]
"""

let itags = """
[1,2,3]
"""

let loc = Location(name: "Somewhere")
var loc_s = """
{"name":"Somewhere"}
"""

if case BindingValue.text(let bv_s) = loc.bindingValue {
    print (#line, bv_s)
    loc_s = bv_s
}

let statement = try dbc.prepare("INSERT INTO cars(name, price, tags, location) VALUES(?, ?, ?, ?)", "Ford Focus", 25_999, tags, loc_s)

try statement.bind("Ford Sprint", 28_999, tags, loc_s).run()

try dbc.execute("INSERT INTO cars (name, price, tags) VALUES('Audi', 52642, '\(tags)')")
try dbc.execute("INSERT INTO cars (name, price, tags) VALUES('Mercedes', 57127, '\(tags)')")
try dbc.execute("INSERT INTO cars (name, price, tags) VALUES('Ford', 20000, '\(tags)')")
try dbc.execute("INSERT INTO cars (name, price, tags, freq) VALUES ('Mazda', 25000, '\(tags)', 'anytime')")

// The struct need NOT be Codable but must be JSON compatible
public struct Car {
    public enum Frequency: String, Codable, CaseIterable { case once, daily, weekly, anytime }

    let id: Int64
    let name: String
//    let type: String
    let price: UInt
    let tags: [Any] // [AnyCodabe]
    let location: Location?
    let frequency: Frequency?
    
//    let location: [String:AnyCodable]?
}

extension Car.Frequency: Extractable {
    public typealias BindingType = String
    public static func fromBindingValue(_ value: Any) -> Car.Frequency? {
        guard let key = value as? String else { return nil }
        for f in Car.Frequency.allCases {
            if f.rawValue == key { return f }
        }
        return nil
    }
}

extension Car: ExpressibleByRow {
    public init(row: Row) throws {
        self.id = row[0]
        self.name = row[1]
        self.price = row[2]
        self.tags = row[3]
        self.location = row[4]
        self.frequency = row[5]
    }
//    public init(row: Row) throws {
//        guard
//            let id: Int64 = row[0],
//            let name: String = row[1],
//            let price: UInt = row[2],
//            let tags: [AnyCodable] = row[3]
//            else {
//                throw ExpressibleByRowError(type: Car.self, row: row)
//        }
//        self.id = id
//        self.name = name
////        self.type = type
//        self.price = price
//        self.tags = tags
//        self.location = row[4]
//        self.frequency = row[5]
//    }
}

let jq_1: SQL = """
SELECT name, tags.value
 FROM cars, json_each(cars.tags) as tags
WHERE tags.value = 33
"""

let jq_2: SQL = """
select name, json_extract(cars.location, '$.name') from cars
"""

let jq_3: SQL = """
SELECT name
 FROM cars, json_each(cars.location, '$.name') as loc_name
WHERE loc_name.value LIKE 'Bum%'
"""

let jq_4: SQL = """
SELECT name, json_extract(tags, '$[0]') as jt
 FROM cars
"""

try dbc.query(jq_1)
let bname = try dbc.query(jq_2)
try dbc.fetch(jq_2, []) {
    print (#line, $0)
}

try dbc.query(jq_3)
try dbc.query(jq_4)
//print(#line, bname)

let names: [String] = try dbc.query("SELECT name FROM cars WHERE price >= ?", [20_000])

print (names)

// let cars: [Car] = try dbc.query("SELECT * FROM cars, json_each(cars.tags) as tag WHERE tag.value == 'alpha' OR price > ?", [20_000])
let cars: [Car] = try dbc.query("SELECT * FROM cars, json_each(cars.tags) as tags WHERE tags.value == 'alpha'", [])
print (#line, "CAR:", cars)

let stmnt = try dbc.prepare("SELECT * FROM cars WHERE price > ?", [20_000])

try stmnt.fetch {
    print ($0)
}

var rows: [Any] = []

try dbc.fetch("SELECT * FROM cars WHERE price >= ?", [20_000]) {
    print ($0)
    rows.append($0.values)
}

for row in rows {
    print (#line, row)
}

try dbc.fetch("PRAGMA table_info('cars')", []) {
    print ($0)
}

try dbc.fetch("select * from pragma_table_info('cars')", []) {
    print ($0)
}

//let db = try Database(storageLocation: .inMemory)
//let db = try Database(storageLocation: .onDisk("/Users/jason/demo.db"))
let db = try Database(storageLocation: .sharedMemory("demo"))
//let db = try Database(storageLocation: .temporary)

try db.executeWrite {
    try $0.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER, tags JSON, location JSON, freq TEXT)")

    try $0.execute("INSERT INTO cars (name, price, tags) VALUES('Audi', 52642, '\(tags)')")
    try $0.execute("INSERT INTO cars (name, price, tags) VALUES('Mercedes', 57127, '\(tags)')")
    print(#line, "PASS")
}

try db.executeRead {
    let row = try $0.query("SELECT * FROM cars WHERE price > ?", [20_000])
    let stmnt = try $0.prepare("SELECT * FROM cars", [])
    let count: Int? = try $0.query("SELECT count(*) FROM cars", [])

    try stmnt.fetch {
        print (#line, $0)
    }
}
print(#line, "PASS")

/*
func bindingValue(value: Any) -> String {
    
    var str: String

    do {
        let data = try JSONSerialization.data(withJSONObject: value, options: [])
        str = String(data: data, encoding: .utf8) ?? ""
    } catch {
        str = ""
    }

    return str
}

func fromBinding(_ value: Any) -> Any? {
    guard let value = value as? String else { return nil }
    guard let data = value.data(using: .utf8) else { return nil }
    let json = try? JSONSerialization.jsonObject(with: data, options: [])
    return json
}

let list = ["one", "two"] // [1, 2, 3, 4]
let bv = bindingValue(value: list)
let v = fromBinding(bv)

let plist: [String : AnyCodable] = ["a": 23, "b": "stirng" ]
let pv = plist.bindingValue

if case BindingValue.text(let bv_s) = pv {
    [String:AnyCodable].fromBindingValue(bv_s)
}
*/
