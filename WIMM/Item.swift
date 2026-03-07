//
//  Item.swift
//  WIMM
//
//  Created by Oleh Zavhorodianskyi on 06.03.26.
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
