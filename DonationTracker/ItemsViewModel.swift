//
//  ItemsViewModel.swift
//  DonationTracker
//
//  Created by Jake Elliott on 5/16/25.
//

import Foundation
import FirebaseFirestore
import Combine

class ItemsViewModel: ObservableObject {
    @Published var items: [InventoryItem] = []
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?

    init() {
        fetchItems()
    }

    func fetchItems() {
        listener = db.collection("items").addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                return
            }
            self.items = querySnapshot?.documents.compactMap { document in
                try? document.data(as: InventoryItem.self)
            } ?? []
        }
    }
    
    func updateItem(_ item: InventoryItem) {
            do {
                try db.collection("items").document(item.upc).setData(from: item)
            } catch {
                print("Failed to update item: \(error)")
            }
        }

        func deleteItem(_ item: InventoryItem, completion: (() -> Void)? = nil) {
            db.collection("items").document(item.upc).delete { error in
                if let error = error {
                    print("Failed to delete item: \(error)")
                }
                completion?()
            }
        }

    deinit {
        listener?.remove()
    }
}
