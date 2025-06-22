//
//  Item.swift
//  AITrading
//
//  Created by Jin Salon on 6/18/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date = Date()
    
    init(timestamp: Date = Date()) {
        self.timestamp = timestamp
    }
}
