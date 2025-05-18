//
//  PDFExporter.swift
//  DonationTracker
//
//  Created by Jake Elliott on 5/17/25.
//

import UIKit
import PDFKit

struct PDFExporter {
    static func export(items: [InventoryItem]) async throws -> URL {
        let pdfMetaData = [
            kCGPDFContextCreator: "DonationTracker",
            kCGPDFContextAuthor: "DonationTracker App"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 32

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)

        let exportDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short

        let totalValue = items.reduce(0.0) { $0 + ($1.value * Double($1.quantity)) }

        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            var y = margin

            // Title
            let title = "My Donations"
            let titleFont = UIFont.boldSystemFont(ofSize: 32)
            let titleRect = CGRect(x: margin, y: y, width: pageWidth - 2 * margin, height: 40)
            title.draw(in: titleRect, withAttributes: [.font: titleFont])
            y += 48

            // Export date
            let dateStr = "Exported from Donation Tracker on \(dateFormatter.string(from: exportDate))"
            let dateFont = UIFont.systemFont(ofSize: 14)
            let dateRect = CGRect(x: margin, y: y, width: pageWidth - 2 * margin, height: 20)
            dateStr.draw(in: dateRect, withAttributes: [.font: dateFont])
            y += 28

            // Grand total
            let totalStr = "Total value of all donations: $\(String(format: "%.2f", totalValue))"
            let totalFont = UIFont.boldSystemFont(ofSize: 20)
            let totalRect = CGRect(x: margin, y: y, width: pageWidth - 2 * margin, height: 28)
            totalStr.draw(in: totalRect, withAttributes: [.font: totalFont, .foregroundColor: UIColor.systemBlue])
            y += 40

            // Table headers
            let headers = ["Photo", "Name", "Brand", "UPC", "Retail Price", "Qty", "Total Value"]
            let columnWidths: [CGFloat] = [60, 90, 70, 70, 60, 40, 60]
            let gutter: CGFloat = 12
            var x = margin
            for (i, header) in headers.enumerated() {
                let headerRect = CGRect(x: x, y: y, width: columnWidths[i], height: 36) // Increased height
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineBreakMode = .byWordWrapping
                paragraphStyle.alignment = .left
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 12),
                    .paragraphStyle: paragraphStyle
                ]
                header.draw(in: headerRect, withAttributes: attributes)
                x += columnWidths[i] + gutter
            }
            y += 44 // More vertical space for headers

            // Draw a line under headers
            ctx.cgContext.setStrokeColor(UIColor.black.cgColor)
            ctx.cgContext.setLineWidth(1)
            ctx.cgContext.move(to: CGPoint(x: margin, y: y))
            ctx.cgContext.addLine(to: CGPoint(x: pageWidth - margin, y: y))
            ctx.cgContext.strokePath()

            // Table rows
            for item in items {
                
                // Gather all cell texts for this row
                // For the price cell
                let priceText = "$\(String(format: "%.2f", item.value))"
                let priceFont = UIFont.systemFont(ofSize: 12)
                let priceHeight = heightForText(priceText, font: priceFont, width: columnWidths[4])

                var sourceText = ""
                var sourceHeight: CGFloat = 0
                if let source = item.priceSource, !source.isEmpty {
                    sourceText = source
                    let sourceFont = UIFont.italicSystemFont(ofSize: 9)
                    sourceHeight = heightForText(sourceText, font: sourceFont, width: columnWidths[4])
                }

                // The cell height for this column is the sum of both heights plus a little spacing
                let retailPriceCellHeight = priceHeight + (sourceHeight > 0 ? sourceHeight + 2 : 0)

                    let cellTexts: [String] = [
                        "", // Image, skip
                        item.name,
                        item.brand,
                        item.upc,
                        "$\(String(format: "%.2f", item.value))" + (item.priceSource != nil ? "\n\(item.priceSource!)" : ""),
                        "\(item.quantity)",
                        "$\(String(format: "%.2f", item.value * Double(item.quantity)))"
                    ]
                    let cellFonts: [UIFont] = [
                        UIFont.systemFont(ofSize: 12), // image placeholder
                        UIFont.systemFont(ofSize: 12),
                        UIFont.systemFont(ofSize: 12),
                        UIFont.systemFont(ofSize: 12),
                        UIFont.systemFont(ofSize: 12),
                        UIFont.systemFont(ofSize: 12),
                        UIFont.systemFont(ofSize: 12)
                    ]

                    // Calculate heights for each cell
                    var cellHeights: [CGFloat] = []
                    for i in 0..<cellTexts.count {
                        if i == 0 {
                            // Image cell: use fixed height (e.g., 40)
                            cellHeights.append(40)
                        } else if i == 4 {
                            cellHeights.append(retailPriceCellHeight)
                        } else {
                            cellHeights.append(heightForText(cellTexts[i], font: cellFonts[i], width: columnWidths[i]))
                        }
                    }
                    let rowHeight = cellHeights.max() ?? 0
                
                // Draw a horizontal line above each row
                ctx.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
                ctx.cgContext.setLineWidth(0.5)
                ctx.cgContext.move(to: CGPoint(x: margin, y: y))
                ctx.cgContext.addLine(to: CGPoint(x: pageWidth - margin, y: y))
                ctx.cgContext.strokePath()

                x = margin

                for i in 0..<cellTexts.count {
                    let rect = CGRect(x: x, y: y, width: columnWidths[i], height: rowHeight)
                    if i == 0, let urlStr = item.imageURL, let url = URL(string: urlStr), let data = try? Data(contentsOf: url), let img = UIImage(data: data) {
                        let imgRect = CGRect(x: x, y: y + (rowHeight - 40)/2, width: 40, height: 40)
                        img.draw(in: imgRect)
                    } else if i == 4 {
                        // Retail Price cell: draw price and source separately
                        let priceParagraph = NSMutableParagraphStyle()
                        priceParagraph.lineBreakMode = .byWordWrapping
                        priceParagraph.alignment = .left
                        let priceAttributes: [NSAttributedString.Key: Any] = [
                            .font: priceFont,
                            .paragraphStyle: priceParagraph
                        ]
                        let priceRect = CGRect(x: x, y: y, width: columnWidths[4], height: priceHeight)
                        priceText.draw(in: priceRect, withAttributes: priceAttributes)

                        if !sourceText.isEmpty {
                            let sourceParagraph = NSMutableParagraphStyle()
                            sourceParagraph.lineBreakMode = .byWordWrapping
                            sourceParagraph.alignment = .left
                            let sourceAttributes: [NSAttributedString.Key: Any] = [
                                .font: UIFont.italicSystemFont(ofSize: 9),
                                .paragraphStyle: sourceParagraph,
                                .foregroundColor: UIColor.gray
                            ]
                            let sourceRect = CGRect(x: x, y: y + priceHeight + 2, width: columnWidths[4], height: sourceHeight)
                            sourceText.draw(in: sourceRect, withAttributes: sourceAttributes)
                        }
                    } else {
                        // All other cells
                        let paragraphStyle = NSMutableParagraphStyle()
                        paragraphStyle.lineBreakMode = .byWordWrapping
                        paragraphStyle.alignment = .left
                        let attributes: [NSAttributedString.Key: Any] = [
                            .font: cellFonts[i],
                            .paragraphStyle: paragraphStyle
                        ]
                        cellTexts[i].draw(in: rect, withAttributes: attributes)
                    }
                    x += columnWidths[i] + gutter
                }

                    y += rowHeight + 8 // 8pt padding
                
                if y > pageHeight - margin - 50 {
                    ctx.beginPage()
                    y = margin
                }
            }

            // Draw a line after the last row
            ctx.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
            ctx.cgContext.setLineWidth(0.5)
            ctx.cgContext.move(to: CGPoint(x: margin, y: y))
            ctx.cgContext.addLine(to: CGPoint(x: pageWidth - margin, y: y))
            ctx.cgContext.strokePath()
        }

        // Save PDF to temp directory
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Donations-\(UUID().uuidString).pdf")
        try data.write(to: tempURL)
        return tempURL
    }
    
    

}


func heightForText(_ text: String, font: UIFont, width: CGFloat) -> CGFloat {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineBreakMode = .byWordWrapping
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .paragraphStyle: paragraphStyle
    ]
    let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
    let boundingBox = text.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
    return ceil(boundingBox.height)
}
