//
//  ItemsView.swift
//  DonationTracker
//
//  Created by Jake Elliott on 5/16/25.
//

import SwiftUI

struct ItemsView: View {
    @EnvironmentObject var viewModel: ItemsViewModel
    @State private var editingItem: InventoryItem?
    @State private var showDeleteAlert = false
    @State private var itemToDelete: InventoryItem?

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.items) { item in
                    HStack(alignment: .top) {
                        if let imageUrl = item.imageURL, let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 60, height: 60)
                            } placeholder: {
                                ProgressView()
                            }
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)
                        }
                        VStack(alignment: .leading) {
                            Text(item.name).font(.headline)
                            Text("Brand: \(item.brand)").font(.subheadline)
                            Text("Value: $\(item.value, specifier: "%.2f")")
                            Text("Total Value: $\(item.value * Double(item.quantity), specifier: "%.2f")")
                            Text("Quantity: \(item.quantity)")
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingItem = item
                    }
                }
                .onDelete { indexSet in
                    if let index = indexSet.first {
                        itemToDelete = viewModel.items[index]
                        showDeleteAlert = true
                    }
                }
            }
            .navigationTitle("Items")
            .sheet(item: $editingItem) { item in
                ManualEntryView(
                    upc: item.upc,
                    onSave: { updated in
                        viewModel.updateItem(updated)
                    },
                    existingItem: item
                )
            }
            .alert(isPresented: $showDeleteAlert) {
                Alert(
                    title: Text("Delete Item"),
                    message: Text("Are you sure you want to delete this item?"),
                    primaryButton: .destructive(Text("Delete")) {
                        if let item = itemToDelete {
                            viewModel.deleteItem(item)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}

#Preview {
    ItemsView()
}
