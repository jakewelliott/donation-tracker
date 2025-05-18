//
//  InventoryItem.swift
//  DonationTracker
//
//  Created by Jake Elliott on 5/16/25.
//

import Foundation

struct InventoryItem: Identifiable, Codable {
    var id: String { upc }
    let upc: String
    var brand: String
    var name: String
    var value: Double
    var quantity: Int
    var imageURL: String?
    var priceSource: String?
}
