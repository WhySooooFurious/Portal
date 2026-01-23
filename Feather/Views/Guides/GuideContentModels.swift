//
//  ParsedGuideContent.swift
//  Feather
//
//  Created by Anmol Singh on 23/1/2026.
//


import Foundation

struct ParsedGuideContent: Equatable {
    let elements: [GuideElement]
}

enum GuideElement: Equatable {
    case heading(level: Int, text: String, isAccent: Bool)
    case paragraph(content: [InlineContent])
    case listItem(level: Int, content: [InlineContent])
    case blockquote(content: [InlineContent])
    case codeBlock(language: String?, code: String)
    case image(url: String, altText: String)
}

enum InlineContent: Equatable {
    case text(String)
    case bold(String)
    case italic(String)
    case code(String)
    case accentText(String)
    case link(url: String, text: String)
    case accentLink(url: String, text: String)
}

