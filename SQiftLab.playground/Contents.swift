import Cocoa
import SQift


let dbc = try Connection(storageLocation: .inMemory)

try dbc.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER, tags TEXT)")

//let tags = """
//["one", "two"]
//"""

let tags = """
[1,2,3]
"""

try dbc.execute("INSERT INTO cars VALUES(1, 'Audi', 52642, '\(tags)')")
try dbc.execute("INSERT INTO cars VALUES(2, 'Mercedes', 57127, '\(tags)')")
try dbc.execute("INSERT INTO cars VALUES(NULL, 'Ford', 20000, '\(tags)')")

struct Car: Codable {
    let id: Int64
    let name: String
//    let type: String
    let price: UInt
    let tags: [Int]
}

extension Car: ExpressibleByRow {
    init(row: Row) throws {
        guard
            let id: Int64 = row[0],
            let name: String = row[1],
            let price: UInt = row[2],
            let tags: [Int] = row[3]
            else {
                throw ExpressibleByRowError(type: Car.self, row: row)
        }
        self.id = id
        self.name = name
//        self.type = type
        self.price = price
        self.tags = tags
    }
}

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
        let data = try JSONSerialization.data(withJSONObject: value, options: .fragmentsAllowed)
        str = String(data: data, encoding: .utf8) ?? ""
    } catch {
        str = ""
    }

    return str
}

func fromBinding(_ value: Any) -> Any? {
    guard let value = value as? String else { return nil }
    guard let data = value.data(using: .utf8) else { return nil }
    let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
    return json
}

let list = ["one", "two"] // [1, 2, 3, 4]
let bv = bindingValue(value: list)
let v = fromBinding(bv)


