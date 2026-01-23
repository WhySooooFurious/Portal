import SwiftUI

struct HomeView: View {
    private let guideStore = GuideStore(
        service: GuideService(
            indexURL: URL(string: "https://raw.githubusercontent.com/WSF-Team/WSF/refs/heads/main/Portal/Guides/Markdown_filenames.plist")!,
            guidesBaseURL: URL(string: "https://raw.githubusercontent.com/WSF-Team/WSF/refs/heads/main/Portal/Guides/")!
        )
    )

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    GuidesHomeSectionView(store: guideStore)
                }
                .padding()
            }
            .navigationTitle("Home")
        }
    }
}
