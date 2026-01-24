//
//  SettingsView.swift
//  Feather
//
//  Created by samara on 10.04.2025.
//

import SwiftUI
import NimbleViews
import UIKit
import Darwin
import IDeviceSwift

struct SettingsView: View {
    @State private var _currentIcon: String? = UIApplication.shared.alternateIconName

    var body: some View {
        NBNavigationView(.localized("Settings")) {
            List {
                    NavigationLink(destination: GeneralView()) {
                        Label(.localized("General"), systemImage: "gearshape")
                    }
                    NavigationLink(destination: AppearanceView(currentIcon: $_currentIcon)) {
                        Label(.localized("Appearance"), systemImage: "paintbrush")
                    }
                    NavigationLink(destination: CertificatesView()) {
                        Label(.localized("Certificates"), systemImage: "checkmark.seal")
                    }

                    NavigationLink(destination: ConfigurationView()) {
                        Label(.localized("Signing Options"), systemImage: "signature")
                    }

                    NavigationLink(destination: InstallationView()) {
                        Label(.localized("Installation"), systemImage: "arrow.down.circle")
                    }
                }

                Section {
                    NavigationLink(destination: ResetView()) {
                        Label(.localized("Reset"), systemImage: "trash")
                    }
                }
            }
        }
    }
