//
//  Product.swift
//  DonationTracker
//
//  Created by Jake Elliott on 5/16/25.
//

import Foundation

struct Product: Identifiable {
    let id = UUID()
    let productId: String // UPC
    let name: String
    let brand: String?
    let retailPrice: Double?
}

struct UPCResponse: Codable {
    let items: [UPCItem]
}

struct UPCItem: Codable {
    let upc: String?
    let title: String
    let brand: String?
    let offers: [UPCOffer]?
}

struct UPCOffer: Codable {
    let price: Double?
    let updated_t: Int?
}
