//
//  SigningOptionsView.swift
//  Feather
//
//  Created by samara on 15.04.2025.
//

import SwiftUI
import NimbleViews

// MARK: - View
struct ConfigurationView: View {
	@StateObject private var _optionsManager = OptionsManager.shared
	@State var isRandomAlertPresenting = false
	@State var randomString = ""
	
	// MARK: Body
    var body: some View {
		NBList(.localized("Signing Options")) {
            Section {
                NavigationLink(destination: ConfigurationDictView(
                    title: .localized("Display Names"),
                        dataDict: $_optionsManager.options.displayNames
                    )
                ) {
                    Label(.localized("Display Names"), systemImage: "character.cursor.ibeam")
                }
                NavigationLink(destination: ConfigurationDictView(
                        title: .localized("Identifiers"),
                        dataDict: $_optionsManager.options.identifiers
                    )
                ) {
                    Label(.localized("Identifiers"), systemImage: "person.text.rectangle")
                }
            }
            SigningOptionsView(options: $_optionsManager.options)
		}
    }
}

// MARK: - Extension: View
extension ConfigurationView {
	
	@ViewBuilder
	private func _randomMenuAlert() -> some View {
		TextField(.localized("String"), text: $randomString)
		Button(.localized("Save")) {
			if !randomString.isEmpty {
				_optionsManager.options.ppqString = randomString
			}
		}
		
		Button(.localized("Cancel"), role: .cancel) {}
	}
}
