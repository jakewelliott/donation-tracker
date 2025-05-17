//
//  ItemsView.swift
//  DonationTracker
//
//  Created by Jake Elliott on 5/16/25.
//

import SwiftUI

struct ItemsView: View {
    @EnvironmentObject var viewModel: ItemsViewModel

    var body: some View {
        NavigationView {
            List(viewModel.items) { item in
                HStack(alignment: .top) {
                    // Load image asynchronously if imageUrl is available
                    if let imageUrl = item.imageUrl, let url = URL(string: imageUrl) {
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
            }
            .navigationTitle("Items")
        }
    }
}

#Preview {
    ItemsView()
}
