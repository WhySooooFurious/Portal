//
//  AppIconView.swift
//  Feather
//
//  Created by samara on 19.06.2025.
//

import SwiftUI
import NimbleViews

// MARK: - View extension: Model
extension AppIconView {
	struct AltIcon: Identifiable {
		var displayName: String
		var author: String
		var key: String?
		var image: UIImage
		var id: String { key ?? displayName }
		
		init(displayName: String, author: String, key: String? = nil) {
			self.displayName = displayName
			self.author = author
			self.key = key
			self.image = altImage(key)
		}
	}
	
    static func altImage(_ name: String?) -> UIImage {
        let file = (name ?? "ModernPortal") + ".png"
        let dir = "Resources/Icons/Main"

        guard let url = Bundle.main.url(forResource: file, withExtension: nil, subdirectory: dir),
              let image = UIImage(contentsOfFile: url.path) else {
            return UIImage()
        }

        return image
    }
}

// MARK: - View
struct AppIconView: View {
	@Binding var currentIcon: String?
	
	// dont translate
	var sections: [String: [AltIcon]] = [
		"Main": [
			AltIcon(displayName: "Modern Portal", author: "WSF", key: nil),
			AltIcon(displayName: "Classic Portal", author: "WSF", key: "NormalPortal"),
            AltIcon(displayName: "Light Classic Portal", author: "WSF", key: "LightPortal"),
			AltIcon(displayName: "Dark Classic Portal", author: "WSF", key: "DarkPortal"),
			AltIcon(displayName: "Transparent Classic Portal", author: "WSF", key: "TransparentPortal"),
		],
		"Themed": [
			AltIcon(displayName: "Light Christmas Cheer", author: "WSF", key: "LightChristmas"),
            AltIcon(displayName: "Dark Christmas Cheer", author: "WSF", key: "DarkChristmas")
        ],
        "Special": [
            AltIcon(displayName: "Revoked", author: "Samara", key: "Revoked"),
        ]
	]
	
	// MARK: Body
	var body: some View {
		NBList(.localized("App Icon")) {
			ForEach(sections.keys.sorted(), id: \.self) { section in
				if let icons = sections[section] {
					NBSection(section) {
						ForEach(icons) { icon in
							_icon(icon: icon)
						}
					}
				}
			}
		}
		.onAppear {
			currentIcon = UIApplication.shared.alternateIconName
		}
	}
}

// MARK: - View extension
extension AppIconView {
	@ViewBuilder
	private func _icon(
		icon: AppIconView.AltIcon
	) -> some View {
		Button {
			UIApplication.shared.setAlternateIconName(icon.key) { _ in
				currentIcon = UIApplication.shared.alternateIconName
			}
		} label: {
			HStack(spacing: 18) {
				Image(uiImage: icon.image)
					.appIconStyle()
				
				NBTitleWithSubtitleView(
					title: icon.displayName,
					subtitle: icon.author,
					linelimit: 0
				)
				
				if currentIcon == icon.key {
					Image(systemName: "checkmark").bold()
				}
			}
		}
	}
}
