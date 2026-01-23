//
//  GuideService.swift
//  Feather
//
//  Created by Anmol Singh on 23/1/2026.
//


import Foundation

final class GuideService {
    let indexURL: URL
    let guidesBaseURL: URL

    init(indexURL: URL, guidesBaseURL: URL) {
        self.indexURL = indexURL
        self.guidesBaseURL = guidesBaseURL
    }

    func fetchIndex() async throws -> [GuideIndexEntry] {
        let (data, resp) = try await URLSession.shared.data(from: indexURL)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw GuideError.badResponse
        }

        let obj = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        guard let array = obj as? [[String: Any]] else { throw GuideError.invalidPlist }

        let entries = array.compactMap { dict -> GuideIndexEntry? in
            guard let title = dict["file_title"] as? String,
                  let name = dict["file_name"] as? String else { return nil }
            return GuideIndexEntry(title: title, filename: name)
        }

        if entries.isEmpty { throw GuideError.empty }
        return entries
    }

    func fetchMarkdown(filename: String) async throws -> String {
        guard let url = URL(string: filename, relativeTo: guidesBaseURL) else { throw GuideError.badURL }

        let (data, resp) = try await URLSession.shared.data(from: url)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw GuideError.badResponse
        }

        return String(decoding: data, as: UTF8.self)
    }
}
