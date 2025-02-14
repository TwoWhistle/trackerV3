//
//  Item.swift
//  trackerV3
//
//  Created by Ryan Yue on 2/4/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
