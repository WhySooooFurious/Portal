import Foundation
import UIKit

struct UpdateInfo: Decodable {
    let version: String
    let build: Int
    let title: String?
    let message: String?
    let url: String
}

final class UpdateChecker {
    static let shared = UpdateChecker()
    private init() {}

    func checkAndPromptIfNeeded() {
        if UserDefaults.standard.bool(forKey: "feather.disableUpdateAlerts") {
            return
        }
        checkAndPrompt()
    }

    func checkAndPromptEvenIfDisabled() {
        checkAndPrompt()
    }

    private func checkAndPrompt() {
        guard let endpoint = URL(string: "https://raw.githubusercontent.com/WSF-Team/WSF/refs/heads/main/Portal/ConfigurationFiles/update.json") else { return }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: endpoint)
                let info = try JSONDecoder().decode(UpdateInfo.self, from: data)

                let currentBuildStr = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
                let currentBuild = Int(currentBuildStr) ?? 0

                guard info.build > currentBuild else { return }

                await MainActor.run {
                    let title = info.title ?? "Update available"
                    let message = info.message ?? "A newer version is available."

                    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Later", style: .cancel))
                    alert.addAction(UIAlertAction(title: "Update", style: .default) { _ in
                        if let url = URL(string: info.url) {
                            UIApplication.shared.open(url)
                        }
                    })

                    UIApplication.topViewController()?.present(alert, animated: true)
                }
            } catch {
                return
            }
        }
    }
}
