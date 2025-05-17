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
    @State private var quantity = "1"
    @State private var casePack = ""
    // For simplicity, image upload is omitted here

    var body: some View {
        Form {
            Text("Manual Entry for UPC: \(upc)")
            TextField("Name", text: $name)
            TextField("Brand", text: $brand)
            TextField("Value", text: $value)
                .keyboardType(.decimalPad)
            TextField("Quantity", text: $quantity)
                .keyboardType(.numberPad)
            TextField("Case Pack", text: $casePack)
                .keyboardType(.numberPad)
            Button("Save Item") {
                let item = InventoryItem(
                    upc: upc,
                    brand: brand,
                    name: name,
                    value: Double(value) ?? 0,
                    quantity: Int(quantity) ?? 1,
                    imageUrl: nil,
                    casePack: Int(casePack)
                )
                onSave(item)
            }
        }
    }
}
