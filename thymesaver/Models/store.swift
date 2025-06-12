//
//  store.swift
//  thymesaver
//
//  Created by Aiden Van Dyke on 6/11/25.
//

import Foundation
import SwiftData

@Model
final class Store {
    private(set) var id = UUID()
    var name: String
    
    init(name: String) {
        self.name = name
    }
}
