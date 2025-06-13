import Foundation
import GRDB
import os.log

extension AppDatabase {
    // Uncomment for enabling SQL logging
    //private static let sqlLogger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "SQL")
    
    static func makeConfiguration() -> Configuration {
        var config = Configuration()
        config.prepareDatabase { db in
            db.trace {
                print("SQL: \($0)")
            }
        }
        
        return config
    }
}
