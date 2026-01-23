//
//  SourcesView.swift
//  Feather
//
//  Created by samara on 10.04.2025.
//

import CoreData
import AltSourceKit
import SwiftUI
import NimbleViews

// MARK: - View
struct SourcesView: View {
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	@StateObject var viewModel = SourcesViewModel.shared
	@State private var _isAddingPresenting = false
	@State private var _addingSourceLoading = false
	@State private var _searchText = ""
	
	private var _filteredSources: [AltSource] {
		_sources.filter { _searchText.isEmpty || ($0.name?.localizedCaseInsensitiveContains(_searchText) ?? false) }
	}
	
	@FetchRequest(
		entity: AltSource.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)],
		animation: .snappy
	) private var _sources: FetchedResults<AltSource>
	
	// MARK: Body
	var body: some View {
		NBNavigationView(.localized("Sources")) {
			NBListAdaptable {
				if !_filteredSources.isEmpty {
					Section {
						NavigationLink {
							SourceAppsView(object: Array(_sources), viewModel: viewModel)
						} label: {
							let isRegular = horizontalSizeClass != .compact
							HStack(spacing: 18) {
								Image("Repositories").appIconStyle()
								NBTitleWithSubtitleView(
                                    title: .localized("All Repositories"),
                                    subtitle: "",
								)
							}
							.padding(isRegular ? 12 : 0)
							.background(
								isRegular
								? RoundedRectangle(cornerRadius: 18, style: .continuous)
									.fill(Color(.quaternarySystemFill))
								: nil
							)
						}
						.buttonStyle(.plain)
					}
					
					NBSection(
						.localized("Repositories"),
					) {
						ForEach(_filteredSources) { source in
							NavigationLink {
								SourceAppsView(object: [source], viewModel: viewModel)
							} label: {
								SourcesCellView(source: source)
							}
							.buttonStyle(.plain)
						}
					}
				}
			}
			.searchable(text: $_searchText, placement: .platform())
			.overlay {
				if _filteredSources.isEmpty {
					if #available(iOS 17, *) {
						ContentUnavailableView {
							Label(.localized("No Repositories"), systemImage: "globe.desk.fill")
						}
					}
				}
			}
			.toolbar {
				NBToolbarButton(
					systemImage: "plus",
					style: .icon,
					placement: .topBarTrailing,
					isDisabled: _addingSourceLoading
				) {
					_isAddingPresenting = true
				}
			}
			.refreshable {
				await viewModel.fetchSources(_sources, refresh: true)
			}
			.sheet(isPresented: $_isAddingPresenting) {
				SourcesAddView()
			}
		}
		.task(id: Array(_sources)) {
			await viewModel.fetchSources(_sources)
		}
	}
}
