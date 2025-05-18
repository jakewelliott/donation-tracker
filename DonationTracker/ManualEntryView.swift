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
    var existingItem: InventoryItem? = nil
    var showQuantityField: Bool { existingItem != nil }

    @State private var name = ""
    @State private var brand = ""
    @State private var value = ""
    @State private var priceSource = ""
    @State private var quantity = ""
    
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Form {
            Text("Manual Entry for UPC: \(upc)")
            TextField("Name", text: $name)
            TextField("Brand", text: $brand)
            TextField("Value", text: $value)
                .keyboardType(.decimalPad)
            TextField("Price Source", text: $priceSource)
            if showQuantityField {
                            TextField("Quantity", text: $quantity)
                                .keyboardType(.numberPad)
                        }
            Button("Save Item") {
                let item = InventoryItem(
                    upc: upc,
                    brand: brand,
                    name: name,
                    value: Double(value) ?? 0,
                    quantity: Int(quantity) ?? 1,
                    imageURL: existingItem?.imageURL,
                    priceSource: priceSource
                )
                onSave(item)
                presentationMode.wrappedValue.dismiss()
            }
        }
        .onAppear {
                    if let item = existingItem {
                        name = item.name
                        brand = item.brand
                        value = String(item.value)
                        priceSource = item.priceSource ?? ""
                        quantity = String(item.quantity)
                    }
                }
    }
}
