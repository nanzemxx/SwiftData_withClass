//
//  Item.swift
//  swiftdataa
//
//  Created by xiongxin on 10/11/2024.
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
