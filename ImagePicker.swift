import SwiftUI
import PhotosUI
import UIKit

struct ImagePicker: View {
    @Binding var image: UIImage?
    @State private var selectedItem: PhotosPickerItem? = nil

    var body: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle()
                        .fill(Color.dumbelleSurface)
                        .frame(width: 100, height: 100)
                    VStack(spacing: 4) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.dumbelleAccent)
                        Text("Add Photo")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.dumbelleTextSecondary)
                    }
                }
            }
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    image = uiImage
                }
            }
        }
    }
}
