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

try dbc.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER, tags TEXT, location TEXT)")

let tags = """
["alpha", "beta"]
"""

let itags = """
[1,2,3]
"""

let loc = Location(name: "Bumfuk")
var loc_s = """
{"name":"Bumfuk"}
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
try dbc.execute("INSERT INTO cars (name, price, tags) VALUES ('Mazda', 25000, '\(tags)')")

struct Car: Codable {
    let id: Int64
    let name: String
//    let type: String
    let price: UInt
    let tags: [AnyCodable]
    let location: Location?
//    let location: [String:AnyCodable]?
}

extension Car: ExpressibleByRow {
    init(row: Row) throws {
        guard
            let id: Int64 = row[0],
            let name: String = row[1],
            let price: UInt = row[2],
            let tags: [AnyCodable] = row[3]
            else {
                throw ExpressibleByRowError(type: Car.self, row: row)
        }
        self.id = id
        self.name = name
//        self.type = type
        self.price = price
        self.tags = tags
        self.location = row[4]
    }
}

let jq_1 = """
SELECT name, tags.value
 FROM cars, json_each(cars.tags) as tags
WHERE tags.value = 1
"""

let jq_2 = """
select name, json_extract(cars.location, '$.name') from cars
"""

let jq_3 = """
SELECT name
 FROM cars, json_tree(cars.location, '$.name')
WHERE json_tree.value LIKE 'Bum%'
"""

let jq_4 = """
SELECT name, json_extract(cars.tags, '$[0]') as jt
 FROM cars
WHERE jt = 1
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

let cars: [Car] = try dbc.query("SELECT * FROM cars WHERE price > ?", [20_000])
print (cars)

let stmnt = try dbc.prepare("SELECT * FROM cars WHERE price > ?", [20_000])

try stmnt.fetch {
    print ($0)
}

try dbc.fetch("SELECT * FROM cars WHERE price >= ?", [20_000]) {
    print ($0)
}


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
