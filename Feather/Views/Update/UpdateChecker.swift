import Foundation
import UIKit

struct UpdateInfo: Decodable {
    let version: String
    let build: Int?
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
        guard let endpoint = URL(string: "https://raw.githubusercontent.com/WSF-Team/WSF/refs/heads/main/portal/configurationfiles/update.json") else {
            return
        }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: endpoint)
                let info = try JSONDecoder().decode(UpdateInfo.self, from: data)

                let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
                print("Update check → local:", currentVersion, "remote:", info.version)

                guard isRemoteVersionNewer(remote: info.version, local: currentVersion) else { return }

                await MainActor.run {
                    let alert = UIAlertController(
                        title: info.title ?? "Update available",
                        message: info.message ?? "A newer version is available.",
                        preferredStyle: .alert
                    )

                    alert.addAction(UIAlertAction(title: "Later", style: .cancel))
                    alert.addAction(UIAlertAction(title: "Update", style: .default) { _ in
                        UIApplication.shared.open(URL(string: info.url)!)
                    })

                    UIApplication.topViewController()?.present(alert, animated: true)
                }
            } catch {
                print("Update check failed:", error)
            }
        }
    }

    private func isRemoteVersionNewer(remote: String, local: String) -> Bool {
        let r = remote.split(separator: ".").map { Int($0) ?? 0 }
        let l = local.split(separator: ".").map { Int($0) ?? 0 }

        let maxCount = max(r.count, l.count)
        for i in 0..<maxCount {
            let rv = i < r.count ? r[i] : 0
            let lv = i < l.count ? l[i] : 0
            if rv != lv { return rv > lv }
        }
        return false
    }
}
