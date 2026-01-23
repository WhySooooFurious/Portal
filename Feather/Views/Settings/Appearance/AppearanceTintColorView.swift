//
//  AppearanceTintColorView.swift
//  Feather
//
//  Created by samara on 14.06.2025.
//

import SwiftUI

// MARK: - View
struct AppearanceTintColorView: View {
	@AppStorage("Feather.userTintColor") private var selectedColorHex: String = "#B496DC"
	private let tintOptions: [(name: String, hex: String)] = [
        (name: "Cherry Jam",      hex: "#C1121F"),
        (name: "Watermelon Slice",hex: "#F43F5E"),
        (name: "Pink Macaron",    hex: "#F9A8D4"),
        (name: "Orchid Glow",     hex: "#D946EF"),
        (name: "Lavender Ink",    hex: "#8B5CF6"),
        (name: "Deep Ocean",      hex: "#1D4ED8"),
        (name: "Sky Glass",       hex: "#38BDF8"),
        (name: "Mint Leaf",       hex: "#34D399"),
        (name: "Wasabi Pop",      hex: "#84CC16"),
        (name: "Mango Sorbet",    hex: "#FACC15"),
        (name: "Pumpkin Spice",   hex: "#F97316"),
        (name: "Apricot Nectar",  hex: "#FDBA74"),
        (name: "Peach Latte",     hex: "#F4A896"),
        (name: "Biscoff Spread",  hex: "#A47C65"),
        (name: "Slate Stone",     hex: "#6B7280"),
        (name: "Vanilla Cream",   hex: "#DCCFBF"),

	]

	@AppStorage("com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck")
	private var _ignoreSolariumLinkedOnCheck: Bool = false

	// MARK: Body
	var body: some View {
		ScrollView(.horizontal, showsIndicators: false) {
			LazyHGrid(rows: [GridItem(.fixed(100))], spacing: 12) {
				ForEach(tintOptions, id: \.hex) { option in
					let color = Color(hex: option.hex)
					let cornerRadius = _ignoreSolariumLinkedOnCheck ? 28.0 : 10.5
					VStack(spacing: 8) {
						Circle()
							.fill(color)
							.frame(width: 30, height: 30)
							.overlay(
								Circle()
									.strokeBorder(Color.black.opacity(0.3), lineWidth: 2)
							)

						Text(option.name)
							.font(.subheadline)
							.foregroundColor(.secondary)
					}
					.frame(width: 120, height: 100)
					.background(Color(uiColor: .secondarySystemGroupedBackground))
					.clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
					.overlay(
						RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
							.strokeBorder(selectedColorHex == option.hex ? color : .clear, lineWidth: 2)
					)
					.onTapGesture {
						selectedColorHex = option.hex
					}
					.accessibilityLabel(Text(option.name))
				}
			}
		}
		.onChange(of: selectedColorHex) { value in
			UIApplication.topViewController()?.view.window?.tintColor = UIColor(Color(hex: value))
		}
	}
}
