import SwiftUI

struct FlowLayout<Content: View>: View {
    let items: [String]
    let content: (String) -> Content

    init(items: [String], @ViewBuilder content: @escaping (String) -> Content) {
        self.items = items
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let rows = makeRows()
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 8) {
                    ForEach(rows[rowIndex], id: \.self) { item in
                        content(item)
                    }
                    Spacer()
                }
            }
        }
    }

    func makeRows() -> [[String]] {
        var rows: [[String]] = [[]]
        var currentRowCount = 0

        for item in items {
            if currentRowCount >= 3 {
                rows.append([item])
                currentRowCount = 1
            } else {
                rows[rows.count - 1].append(item)
                currentRowCount += 1
            }
        }
        return rows
    }
}
