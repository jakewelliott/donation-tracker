//
//  ManualEntryView.swift
//  DonationTracker
//
//  Created by Jake Elliott on 5/16/25.
//

import SwiftUI

struct ManualEntryView: View {
    let upc: String
    var onSave: (InventoryItem) -> Void

    @State private var name = ""
    @State private var brand = ""
    @State private var value = ""
    @State private var priceSource = ""

    var body: some View {
        Form {
            Text("Manual Entry for UPC: \(upc)")
            TextField("Name", text: $name)
            TextField("Brand", text: $brand)
            TextField("Value", text: $value)
                .keyboardType(.decimalPad)
            TextField("Price Source", text: $priceSource)
            Button("Save Item") {
                let item = InventoryItem(
                    upc: upc,
                    brand: brand,
                    name: name,
                    value: Double(value) ?? 0,
                    quantity: 1,
                    imageURL: nil,
                    priceSource: priceSource
                )
                onSave(item)
            }
        }
    }
}
