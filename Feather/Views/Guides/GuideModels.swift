//
//  GuideIndexEntry.swift
//  Feather
//
//  Created by Anmol Singh on 23/1/2026.
//


import Foundation

struct GuideIndexEntry: Identifiable, Hashable {
    let id: String
    let title: String
    let filename: String

    init(title: String, filename: String) {
        self.title = title
        self.filename = filename
        self.id = filename
    }
}

enum GuideError: Error, LocalizedError {
    case badURL
    case badResponse
    case invalidPlist
    case empty

    var errorDescription: String? {
        switch self {
        case .badURL: return "Invalid URL."
        case .badResponse: return "Couldn’t load guides."
        case .invalidPlist: return "Guide index format is invalid."
        case .empty: return "No guides found."
        }
    }
}
