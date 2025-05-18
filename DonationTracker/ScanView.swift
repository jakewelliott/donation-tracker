//
//  ScanView.swift
//  DonationTracker
//
//  Created by Jake Elliott on 5/16/25.
//

import SwiftUI
import CodeScanner
import FirebaseFirestore

struct ScanView: View {
    @EnvironmentObject var itemsViewModel: ItemsViewModel

    @State private var isPresentingScanner = true
    @State private var isActiveScreen = true
    @State private var scannedCode: String?
    @State private var showManualEntry = false
    @State private var searchResults: [Product] = []
    @State private var isLoading = false
    @State private var showSuccess = false

    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                Button("Scan Again") {
                    isPresentingScanner = true
                }
                .font(.title)
                .padding()
                
                if let code = scannedCode {
                    Text("Scanned UPC: \(code)")
                }
                
                if isLoading {
                    ProgressView("Searching for item…")
                }
                
                if !searchResults.isEmpty {
                    List(searchResults) { product in
                        Button {
                            handleProductSelection(product)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(product.name).bold()
                                if let brand = product.brand {
                                    Text(brand)
                                }
                                if let price = product.retailPrice {
                                    Text(String(format: "Price: $%.2f", price))
                                }
                            }
                        }
                    }
                }
                
                if showManualEntry {
                    ManualEntryView(upc: scannedCode ?? "", onSave: handleManualEntry)
                }
                
                if showSuccess {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.green)
                        .transition(.scale)
                }
            }
            if isPresentingScanner {
                Color.black.opacity(0.5) // Optional: dim background
                                .ignoresSafeArea()
                CodeScannerView(codeTypes: [.ean13, .upce, .ean8], completion: handleScan)
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut, value: isPresentingScanner)
        .onDisappear {
            isActiveScreen = false
                isPresentingScanner = false
            }
        .onAppear {
            isActiveScreen = true
        }
    }
    
    func handleProductSelection(_ product: Product) {
        updateInventory(
            upc: scannedCode ?? "",
            name: product.name,
            brand: product.brand ?? "",
            value: product.retailPrice ?? 0,
            priceSource: product.priceSource ?? "",
            imageUrl: product.imageURL ?? ""
        )
    }

    // MARK: - Scan Handler
    func handleScan(result: Result<ScanResult, ScanError>) {
        isPresentingScanner = false
        if isActiveScreen {
            switch result {
            case .success(let res):
                scannedCode = res.string
                handleScannedUPC(res.string)
            case .failure:
                scannedCode = nil
            }
        }
    }

    // MARK: - UPC Handling
    func handleScannedUPC(_ upc: String) {
        // Check if item exists in local items list
        if itemsViewModel.items.first(where: { $0.upc == upc }) != nil {
            incrementItemQuantity(upc: upc)
        } else {
            // Not found locally, proceed to Amazon/manual
            searchProduct(upc: upc)
        }
    }

    func incrementItemQuantity(upc: String) {
        let db = Firestore.firestore()
        let docRef = db.collection("items").document(upc)
        docRef.updateData([
            "quantity": FieldValue.increment(Int64(1))
        ]) { _ in
            showSuccessFeedback()
        }
    }

    func searchProduct(upc: String) {
        isLoading = true
        searchResults = []
        
        let urlString = "https://api.upcitemdb.com/prod/trial/lookup?upc=\(upc)"
        guard let url = URL(string: urlString) else {
            isLoading = false
            showManualEntry = true
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("Network error: \(error.localizedDescription)")
                    self.showManualEntry = true
                    return
                }
                
                guard let data = data else {
                    self.showManualEntry = true
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(UPCResponse.self, from: data)
                                        
                    if response.items.isEmpty {
                        self.showManualEntry = true
                    } else {
                        self.searchResults = response.items.map { item in
                            // Find the offer with the most recent updated_t
                            let mostRecentOffer = item.offers?
                                .max(by: {
                                    (lhs, rhs) in
                                    (Int(lhs.updated_t ?? 0)) < (Int(rhs.updated_t ?? 0))
                                })
                            
                            let offerPrice = mostRecentOffer?.price
                            let offerSource = mostRecentOffer?.merchant
                            let firstImageUrl = item.images?.first
                            
                            return Product(
                                productId: item.upc ?? "",
                                name: item.title,
                                brand: item.brand,
                                retailPrice: offerPrice,
                                priceSource: offerSource,
                                imageURL: firstImageUrl
                            )
                        }
                    }
                } catch {
                    print("JSON parsing error: \(error.localizedDescription)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                            print("Raw JSON string received:\n\(jsonString)")
                        } else {
                            print("Could not convert data to string for inspection.")
                        }
                    self.showManualEntry = true
                }
            }
        }.resume()
    }


    func handleAmazonSelection(_ product: Product) {
        updateInventory(upc: scannedCode ?? "", name: product.name, brand: product.brand ?? "", value: product.retailPrice ?? 0, priceSource: product.priceSource ?? "", imageUrl: product.imageURL ?? "")
    }

    func handleManualEntry(_ item: InventoryItem) {
        updateInventory(item: item)
    }

    func updateInventory(upc: String, name: String, brand: String, value: Double, priceSource: String, imageUrl: String) {
        let db = Firestore.firestore()
        let docRef = db.collection("items").document(upc)
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                docRef.updateData([
                    "quantity": FieldValue.increment(Int64(1)),
                ])
            } else {
                let item = InventoryItem(
                    upc: upc,
                    brand: brand,
                    name: name,
                    value: value,
                    quantity: 1,
                    imageURL: imageUrl,
                    priceSource: priceSource,
                )
                try? docRef.setData(from: item)
            }
            showSuccessFeedback()
        }
    }

    func updateInventory(item: InventoryItem) {
        let db = Firestore.firestore()
        let docRef = db.collection("items").document(item.upc)
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                docRef.updateData([
                    "quantity": FieldValue.increment(Int64(1))
                ])
            } else {
                try? docRef.setData(from: item)
            }
            showSuccessFeedback()
        }
    }

    func showSuccessFeedback() {
        searchResults = []
        showManualEntry = false
        showSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showSuccess = false
            scannedCode = nil
            if isActiveScreen {
                isPresentingScanner = true
            }
            
        }
    }
}


#Preview {
    ScanView()
}
