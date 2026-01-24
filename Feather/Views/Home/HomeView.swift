import SwiftUI
import UIKit
import PhotosUI

struct HomeView: View {
    private let guideStore = GuideStore(
        service: GuideService(
            indexURL: URL(string: "https://raw.githubusercontent.com/WSF-Team/WSF/refs/heads/main/Portal/Guides/Markdown_filenames.plist")!,
            guidesBaseURL: URL(string: "https://raw.githubusercontent.com/WSF-Team/WSF/refs/heads/main/Portal/Guides/")!
        )
    )

    @AppStorage("feather.profileImage") private var profileImageData: Data?
    @AppStorage("feather.profileName") private var profileName: String = ""

    @State private var homeSelectedItem: PhotosPickerItem?
    @State private var homePickedImage: UIImage?
    @State private var homeShowCropper = false
    @State private var homeIsLoading = false

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<18: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var titleText: String {
        let name = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? greeting : "\(greeting), \(name)"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .center) {
                        Text(titleText)
                            .font(.system(size: 28, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        PhotosPicker(selection: $homeSelectedItem, matching: .images) {
                            ZStack {
                                profileImage
                                    .frame(width: 52, height: 52)

                                if homeIsLoading {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                }
                            }
                        }
                        .disabled(homeIsLoading)
                    }
                    .padding(.bottom, 6)

                    GuidesHomeSectionView(store: guideStore)
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onChange(of: homeSelectedItem) { newItem in
            guard let newItem else { return }
            homeIsLoading = true

            Task {
                let data = try? await newItem.loadTransferable(type: Data.self)
                let uiImage = data.flatMap { UIImage(data: $0) }?.nbNormalized()

                await MainActor.run {
                    homeIsLoading = false
                    if let uiImage {
                        homePickedImage = uiImage
                        homeShowCropper = true
                    } else {
                        homeSelectedItem = nil
                    }
                }
            }
        }
        .sheet(isPresented: $homeShowCropper, onDismiss: {
            homePickedImage = nil
            homeSelectedItem = nil
        }) {
            if let img = homePickedImage {
                ProfileImageCropperSheet(
                    image: img,
                    onCancel: { homeShowCropper = false },
                    onSave: { cropped in
                        profileImageData = cropped.jpegData(compressionQuality: 0.95)
                        homeShowCropper = false
                    }
                )
            }
        }
    }

    private var profileImage: some View {
        Group {
            if let data = profileImageData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.tint)
            }
        }
        .clipShape(Circle())
    }
}
