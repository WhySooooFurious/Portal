import SwiftUI
import NimbleViews

struct GeneralView: View {
    @AppStorage("feather.disableUpdateAlerts")
    private var disableUpdateAlerts: Bool = false

    var body: some View {
        NBList(.localized("General")) {
            Section {
                Toggle(.localized("Update Notifications"), isOn: Binding(
                    get: { !disableUpdateAlerts },
                    set: { disableUpdateAlerts = !$0 }
                ))
            }
        }
        .onChange(of: disableUpdateAlerts) { newValue in
            if newValue == false {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    UpdateChecker.shared.checkAndPromptIfNeeded()
                }
            }
        }
    }
}
