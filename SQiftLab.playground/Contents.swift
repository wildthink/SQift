import Cocoa
import SQift


let dbc = try Connection(storageLocation: .inMemory)

try dbc.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")

try dbc.execute("INSERT INTO cars VALUES(1, 'Audi', 52642)")
try dbc.execute("INSERT INTO cars VALUES(2, 'Mercedes', 57127)")
try dbc.execute("INSERT INTO cars VALUES(NULL, 'Ford', 20000)")

struct Car: Codable {
    let name: String
    let type: String
    let price: UInt
}

extension Car: ExpressibleByRow {
    init(row: Row) throws {
        guard
            let name: String = row[0],
            let type: String = row[1],
            let price: UInt = row[2]
            else {
                throw ExpressibleByRowError(type: Car.self, row: row)
        }

        self.name = name
        self.type = type
        self.price = price
    }
}

let names: [String] = try dbc.query("SELECT name FROM cars WHERE price >= ?", [20_000])

print (names)

let stmnt = try dbc.prepare("SELECT * FROM cars WHERE price > ?", [20_000])

try stmnt.fetch {
    print ($0)
}

try dbc.fetch("SELECT * FROM cars WHERE price >= ?", [20_000]) {
    print ($0)
}

