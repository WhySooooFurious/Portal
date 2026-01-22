import SwiftUI

struct HomeView: View {
    @AppStorage("feather.profileName") private var profileName: String = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    quickActions

                    infoCard
                }
                .padding()
            }
            .navigationTitle("Home")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Welcome")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text(profileName.isEmpty ? "Friend" : profileName)
                .font(.largeTitle)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            HStack(spacing: 12) {
                actionCard(title: "Settings", icon: "gear")
                actionCard(title: "Appearance", icon: "paintbrush")
                actionCard(title: "Profile", icon: "person.crop.circle")
            }
        }
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Status")
                .font(.headline)

            Text("Everything looks good.")
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func actionCard(title: String, icon: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))

            Text(title)
                .font(.footnote)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
