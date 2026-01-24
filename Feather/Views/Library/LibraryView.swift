//
//  ContentView.swift
//  Feather
//
//  Created by samara on 10.04.2025.
//

import SwiftUI
import CoreData
import NimbleViews

struct LibraryView: View {
    @StateObject var downloadManager = DownloadManager.shared
    
    @State private var _selectedInfoAppPresenting: AnyApp?
    @State private var _selectedSigningAppPresenting: AnyApp?
    @State private var _selectedInstallAppPresenting: AnyApp?
    @State private var _isImportingPresenting = false
    @State private var _isDownloadingPresenting = false
    @State private var _alertDownloadString: String = ""
    
    @State private var _selectedAppUUIDs: Set<String> = []
    @State private var _editMode: EditMode = .inactive
    
    @State private var _selectedScope: Scope = .imported
    @Namespace private var _namespace
    
    private func filteredAndSortedApps<T>(from apps: FetchedResults<T>) -> [T] where T: NSManagedObject {
        Array(apps)
    }
    
    private var _filteredSignedApps: [Signed] {
        filteredAndSortedApps(from: _signedApps)
    }
    
    private var _filteredImportedApps: [Imported] {
        filteredAndSortedApps(from: _importedApps)
    }
    
    @FetchRequest(
        entity: Signed.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Signed.date, ascending: false)],
        animation: .snappy
    ) private var _signedApps: FetchedResults<Signed>
    
    @FetchRequest(
        entity: Imported.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Imported.date, ascending: false)],
        animation: .snappy
    ) private var _importedApps: FetchedResults<Imported>
    
    var body: some View {
        NBNavigationView(.localized("Library")) {
            VStack(spacing: 0) {
                _pickerBar()
                    .padding(.horizontal)
                    .padding(.top, 6)
                    .padding(.bottom, 8)
                
                NBListAdaptable {
                    if _selectedScope == .signed {
                        if !_filteredSignedApps.isEmpty {
                            ForEach(_filteredSignedApps, id: \.uuid) { app in
                                LibraryCellView(
                                    app: app,
                                    selectedInfoAppPresenting: $_selectedInfoAppPresenting,
                                    selectedSigningAppPresenting: $_selectedSigningAppPresenting,
                                    selectedInstallAppPresenting: $_selectedInstallAppPresenting,
                                    selectedAppUUIDs: $_selectedAppUUIDs
                                )
                                .compatMatchedTransitionSource(id: app.uuid ?? "", ns: _namespace)
                            }
                        }
                    } else {
                        if !_filteredImportedApps.isEmpty {
                            ForEach(_filteredImportedApps, id: \.uuid) { app in
                                LibraryCellView(
                                    app: app,
                                    selectedInfoAppPresenting: $_selectedInfoAppPresenting,
                                    selectedSigningAppPresenting: $_selectedSigningAppPresenting,
                                    selectedInstallAppPresenting: $_selectedInstallAppPresenting,
                                    selectedAppUUIDs: $_selectedAppUUIDs
                                )
                                .compatMatchedTransitionSource(id: app.uuid ?? "", ns: _namespace)
                            }
                        }
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .overlay {
                    if (_selectedScope == .signed && _filteredSignedApps.isEmpty) ||
                        (_selectedScope == .imported && _filteredImportedApps.isEmpty) {
                        if #available(iOS 17, *) {
                            ContentUnavailableView {
                                Label(.localized("No Apps"), systemImage: "questionmark.app.fill")
                            }
                        }
                    }
                }
            }
            .toolbar {
                if _editMode.isEditing {
                    NBToolbarButton(
                        .localized("Delete"),
                        systemImage: "trash",
                        isDisabled: _selectedAppUUIDs.isEmpty
                    ) {
                        _bulkDeleteSelectedApps()
                    }
                } else {
                    NBToolbarMenu(
                        systemImage: "plus",
                        style: .icon,
                        placement: .topBarTrailing
                    ) {
                        _importActions()
                    }
                }
            }
            .environment(\.editMode, $_editMode)
            .sheet(item: $_selectedInfoAppPresenting) { app in
                LibraryInfoView(app: app.base)
            }
            .sheet(item: $_selectedInstallAppPresenting) { app in
                InstallPreviewView(app: app.base, isSharing: app.archive)
                    .presentationDetents([.height(200)])
                    .presentationDragIndicator(.visible)
                    .compatPresentationRadius(21)
            }
            .fullScreenCover(item: $_selectedSigningAppPresenting) { app in
                SigningView(app: app.base)
                    .compatNavigationTransition(id: app.base.uuid ?? "", ns: _namespace)
            }
            .sheet(isPresented: $_isImportingPresenting) {
                FileImporterRepresentableView(
                    allowedContentTypes:  [.ipa, .tipa],
                    allowsMultipleSelection: true,
                    onDocumentsPicked: { urls in
                        guard !urls.isEmpty else { return }
                        for url in urls {
                            let id = "FeatherManualDownload_\(UUID().uuidString)"
                            let dl = downloadManager.startArchive(from: url, id: id)
                            try? downloadManager.handlePachageFile(url: url, dl: dl)
                        }
                    }
                )
                .ignoresSafeArea()
            }
            .alert(.localized("Import from URL"), isPresented: $_isDownloadingPresenting) {
                TextField(.localized("URL"), text: $_alertDownloadString)
                    .textInputAutocapitalization(.never)
                Button(.localized("Cancel"), role: .cancel) {
                    _alertDownloadString = ""
                }
                Button(.localized("OK")) {
                    if let url = URL(string: _alertDownloadString) {
                        _ = downloadManager.startDownload(from: url, id: "FeatherManualDownload_\(UUID().uuidString)")
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("Feather.installApp"))) { _ in
                if let latest = _signedApps.first {
                    _selectedInstallAppPresenting = AnyApp(base: latest)
                }
            }
            .onChange(of: _editMode) { mode in
                if mode == .inactive {
                    _selectedAppUUIDs.removeAll()
                }
            }
        }
    }
    
    private func _pickerBar() -> some View {
        Picker("", selection: $_selectedScope) {
            Text(.localized("Unsigned")).tag(Scope.imported)
            Text(.localized("Signed")).tag(Scope.signed)
        }
        .pickerStyle(.segmented)
    }
}

extension LibraryView {
    @ViewBuilder
    private func _importActions() -> some View {
        Button(.localized("Import from Files"), systemImage: "folder") {
            _isImportingPresenting = true
        }
        Button(.localized("Import from URL"), systemImage: "globe") {
            _isDownloadingPresenting = true
        }
    }
}

extension LibraryView {
    private func _bulkDeleteSelectedApps() {
        let selectedApps = _getAllApps().filter { app in
            guard let uuid = app.uuid else { return false }
            return _selectedAppUUIDs.contains(uuid)
        }
        
        for app in selectedApps {
            Storage.shared.deleteApp(for: app)
        }
        
        _selectedAppUUIDs.removeAll()
    }
    
    private func _getAllApps() -> [AppInfoPresentable] {
        switch _selectedScope {
        case .signed:
            return _filteredSignedApps
        case .imported:
            return _filteredImportedApps
        }
    }
}

extension LibraryView {
    enum Scope: CaseIterable {
        case signed
        case imported
        
        var displayName: String {
            switch self {
            case .signed: return .localized("Signed")
            case .imported: return .localized("Unsigned")
            }
        }
    }
}
