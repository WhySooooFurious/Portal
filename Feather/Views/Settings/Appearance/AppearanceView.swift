//
//  AppearanceView.swift
//  Feather
//
//  Created by samara on 7.05.2025.
//

import SwiftUI
import NimbleViews
import PhotosUI
import UIKit

struct AppearanceView: View {
    @AppStorage("Feather.userInterfaceStyle")
    private var _userIntefacerStyle: Int = UIUserInterfaceStyle.unspecified.rawValue
    
    @AppStorage("Feather.storeCellAppearance")
    private var _storeCellAppearance: Int = 0
    private let _storeCellAppearanceMethods: [(name: String, desc: String)] = [
        (.localized("Standard"), .localized("Default style for the app, only includes subtitle.")),
        (.localized("Big Description"), .localized("Adds the localized description of the app."))
    ]
    
    @AppStorage("com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck")
    private var _ignoreSolariumLinkedOnCheck: Bool = false
    
    @Binding var currentIcon: String?
    
    @AppStorage("feather.profileName") private var profileName: String = ""
    @AppStorage("feather.profileImage") private var profileImageData: Data?
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?
    @State private var showCropper = false
    @State private var isLoadingPickedImage = false
    
    var body: some View {
        NBList(.localized("Appearance")) {
            Section {
                VStack(alignment: .center, spacing: 8) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        ZStack {
                            profileImage
                                .frame(width: 80, height: 80)
                            
                            if isLoadingPickedImage {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            }
                        }
                    }
                    .disabled(isLoadingPickedImage)
                    
                    TextField(.localized("Your Name"), text: $profileName)
                        .multilineTextAlignment(.center)
                        .font(.title3)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            
            Section {
                Picker(.localized("Appearance"), selection: $_userIntefacerStyle) {
                    ForEach(UIUserInterfaceStyle.allCases.sorted(by: { $0.rawValue < $1.rawValue }), id: \.rawValue) { style in
                        Text(style.label).tag(style.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            NBSection(.localized("Theme")) {
                AppearanceTintColorView()
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(EmptyView())
            }
            
            if #available(iOS 19.0, *) {
                NBSection(.localized("Experiments")) {
                    Toggle(.localized("Enable Liquid Glass"), isOn: $_ignoreSolariumLinkedOnCheck)
                }
            }
        }
        .onChange(of: _userIntefacerStyle) { value in
            if let style = UIUserInterfaceStyle(rawValue: value) {
                UIApplication.topViewController()?.view.window?.overrideUserInterfaceStyle = style
            }
        }
        .onChange(of: _ignoreSolariumLinkedOnCheck) { _ in
            UIApplication.shared.suspendAndReopen()
        }
        .onChange(of: selectedItem) { newItem in
            guard let newItem else { return }
            isLoadingPickedImage = true
            
            Task {
                let data = try? await newItem.loadTransferable(type: Data.self)
                let uiImage = data.flatMap { UIImage(data: $0) }?.nbNormalized()
                
                await MainActor.run {
                    isLoadingPickedImage = false
                    if let uiImage {
                        pickedImage = uiImage
                        showCropper = true
                    } else {
                        selectedItem = nil
                    }
                }
            }
        }
        .sheet(isPresented: $showCropper, onDismiss: {
            pickedImage = nil
            selectedItem = nil
        }) {
            if let img = pickedImage {
                ProfileImageCropperSheet(
                    image: img,
                    onCancel: {
                        showCropper = false
                    },
                    onSave: { cropped in
                        profileImageData = cropped.jpegData(compressionQuality: 0.95)
                        showCropper = false
                    }
                )
            }
        }
    }
    
    private var profileImage: some View {
        Group {
            if let data = profileImageData,
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .clipShape(Circle())
    }
}
