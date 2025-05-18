//
//  SettingsView.swift
//  DonationTracker
//
//  Created by Jake Elliott on 5/16/25.
//

import SwiftUI
import FirebaseFirestore
import PDFKit

struct SettingsView: View {
    @EnvironmentObject var viewModel: ItemsViewModel
    @State private var showAlert = false
    @State private var isDeleting = false
    @State private var isExporting = false
    @State private var pdfURL: IdentifiableURL?

    var body: some View {
        NavigationView {
            ZStack {
                List {
                    Button(action: exportPDF) {
                        Label("Export as PDF", systemImage: "doc.richtext")
                    }
                    Button(action: {
                        showAlert = true
                    }) {
                        Label("Clear Data", systemImage: "trash")
                    }
                    .alert(isPresented: $showAlert) {
                        Alert(
                            title: Text("Clear All Data?"),
                            message: Text("Are you sure you want to delete all items from your inventory? This action cannot be undone."),
                            primaryButton: .destructive(Text("Delete")) {
                                clearAllData()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
                .disabled(isExporting) // Prevent interaction while exporting

                if isExporting {
                    Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                    ProgressView("Generating PDF...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Settings")
            .listStyle(InsetGroupedListStyle())
            .sheet(item: $pdfURL, onDismiss: { pdfURL = nil }) { identifiable in
                ShareSheet(activityItems: [identifiable.url])
            }
        }
    }

    private func exportPDF() {
        isExporting = true
        Task {
            do {
                let url = try await PDFExporter.export(items: viewModel.items)
                pdfURL = IdentifiableURL(url: url)
            } catch {
                print("Failed to export PDF: \(error)")
            }
            isExporting = false
        }
    }

    private func clearAllData() {
        isDeleting = true
        let db = Firestore.firestore()
        let collection = db.collection("items")
        collection.getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else {
                isDeleting = false
                return
            }
            let batch = db.batch()
            for doc in documents {
                batch.deleteDocument(doc.reference)
            }
            batch.commit { _ in
                isDeleting = false
            }
        }
    }
}

// UIKit Share Sheet for SwiftUI
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

#Preview {
    SettingsView()
}
