import SwiftUI
import UIKit

struct HomeView: View {
    private let guideStore = GuideStore(
        service: GuideService(
            indexURL: URL(string: "https://raw.githubusercontent.com/WSF-Team/WSF/refs/heads/main/Portal/Guides/Markdown_filenames.plist")!,
            guidesBaseURL: URL(string: "https://raw.githubusercontent.com/WSF-Team/WSF/refs/heads/main/Portal/Guides/")!
        )
    )

    @AppStorage("feather.profileImage") private var profileImageData: Data?
    @AppStorage("feather.profileName") private var profileName: String = ""

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

                        profileImage
                    }
                    .padding(.bottom, 6)

                    GuidesHomeSectionView(store: guideStore)
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var profileImage: some View {
        Group {
            if let data = profileImageData, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .frame(width: 36, height: 36)
        .clipShape(Circle())
    }
}
