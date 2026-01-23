//
//  GuideStore.swift
//  Feather
//
//  Created by Anmol Singh on 23/1/2026.
//


import Foundation

@MainActor
final class GuideStore: ObservableObject {
    @Published var guides: [GuideIndexEntry] = []
    @Published var isLoadingIndex = false
    @Published var indexError: String?

    private let service: GuideService
    private var parsedCache: [String: ParsedGuideContent] = [:]

    init(service: GuideService) {
        self.service = service
    }

    func loadIndex() async {
        if isLoadingIndex { return }
        isLoadingIndex = true
        indexError = nil
        do {
            guides = try await service.fetchIndex()
        } catch {
            indexError = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
        }
        isLoadingIndex = false
    }

    func loadGuideParsed(filename: String) async throws -> ParsedGuideContent {
        if let cached = parsedCache[filename] { return cached }
        let md = try await service.fetchMarkdown(filename: filename)
        let normalized = GuideTextNormalizer.normalize(md)
        let parsed = GuideParser.parse(markdown: normalized)
        parsedCache[filename] = parsed
        return parsed
    }
}
