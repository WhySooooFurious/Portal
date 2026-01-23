// GuideParser.swift
import Foundation

final class GuideParser {
    static func parse(markdown: String) -> ParsedGuideContent {
        var elements: [GuideElement] = []
        let lines = markdown.components(separatedBy: .newlines)

        var i = 0
        while i < lines.count {
            let line = lines[i]

            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                i += 1
                continue
            }

            if line.hasPrefix("```") {
                let (codeBlock, consumed) = parseCodeBlock(lines: lines, startIndex: i)
                if let codeBlock {
                    elements.append(codeBlock)
                    i += consumed
                    continue
                }
            }

            if line.hasPrefix("#") {
                if let heading = parseHeading(line) {
                    elements.append(heading)
                }
                i += 1
                continue
            }

            if line.hasPrefix(">") {
                elements.append(parseBlockquote(line))
                i += 1
                continue
            }

            if isListLine(line) {
                elements.append(parseListItem(line))
                i += 1
                continue
            }

            if let match = line.range(of: #"^\s*\d+\.\s"#, options: .regularExpression) {
                let level = countLeadingSpaces(line) / 2
                let text = String(line[match.upperBound...])
                elements.append(.listItem(level: level, content: parseInlineContent(text)))
                i += 1
                continue
            }

            if line.trimmingCharacters(in: .whitespaces).hasPrefix("![") {
                if let img = parseImage(line) {
                    elements.append(img)
                    i += 1
                    continue
                }
            }

            let content = parseInlineContent(line)
            if !content.isEmpty {
                elements.append(.paragraph(content: content))
            }
            i += 1
        }

        return ParsedGuideContent(elements: elements)
    }

    private static func isListLine(_ line: String) -> Bool {
        line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ") ||
        line.hasPrefix("  - ") || line.hasPrefix("  * ") || line.hasPrefix("  + ") ||
        line.hasPrefix("    - ") || line.hasPrefix("    * ") || line.hasPrefix("    + ")
    }

    private static func countLeadingSpaces(_ line: String) -> Int {
        var count = 0
        for c in line {
            if c == " " { count += 1 } else { break }
        }
        return count
    }

    private static func parseHeading(_ line: String) -> GuideElement? {
        var level = 0
        var text = line

        while text.hasPrefix("#") {
            level += 1
            text = String(text.dropFirst())
        }

        text = text.trimmingCharacters(in: .whitespaces)

        var isAccent = false
        let accentPattern = #"^\[([^\]]+)\]\(accent://[^\)]*\)$"#
        let bracketOnlyPattern = #"^\[([^\]]+)\]$"#

        if let re = try? NSRegularExpression(pattern: accentPattern),
           let m = re.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let r = Range(m.range(at: 1), in: text) {
            text = String(text[r])
            isAccent = true
        } else if let re = try? NSRegularExpression(pattern: bracketOnlyPattern),
                  let m = re.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                  let r = Range(m.range(at: 1), in: text) {
            text = String(text[r])
        } else if text.hasPrefix("(accent://)") {
            text = String(text.dropFirst("(accent://)".count)).trimmingCharacters(in: .whitespaces)
            isAccent = true
        } else if text.contains("(accent://)") {
            text = text.replacingOccurrences(of: "(accent://)", with: "").trimmingCharacters(in: .whitespaces)
            isAccent = true
        } else if text.contains("accent://") {
            text = text.replacingOccurrences(of: "accent://", with: "").trimmingCharacters(in: .whitespaces)
            isAccent = true
        }

        if level > 0 && !text.isEmpty {
            return .heading(level: level, text: text, isAccent: isAccent)
        }
        return nil
    }

    private static func parseCodeBlock(lines: [String], startIndex: Int) -> (GuideElement?, Int) {
        let first = lines[startIndex]
        let language = String(first.dropFirst(3).trimmingCharacters(in: .whitespaces))

        var codeLines: [String] = []
        var i = startIndex + 1

        while i < lines.count {
            let line = lines[i]
            if line.hasPrefix("```") {
                let code = codeLines.joined(separator: "\n")
                return (.codeBlock(language: language.isEmpty ? nil : language, code: code), i - startIndex + 1)
            }
            codeLines.append(line)
            i += 1
        }

        let code = codeLines.joined(separator: "\n")
        return (.codeBlock(language: language.isEmpty ? nil : language, code: code), i - startIndex)
    }

    private static func parseBlockquote(_ line: String) -> GuideElement {
        let text = line.dropFirst().trimmingCharacters(in: .whitespaces)
        return .blockquote(content: parseInlineContent(String(text)))
    }

    private static func parseListItem(_ line: String) -> GuideElement {
        var text = line
        let level = countLeadingSpaces(text) / 2

        text = text.trimmingCharacters(in: .whitespaces)
        if text.hasPrefix("- ") || text.hasPrefix("* ") || text.hasPrefix("+ ") {
            text = String(text.dropFirst(2))
        }

        return .listItem(level: level, content: parseInlineContent(text))
    }

    private static func parseInlineContent(_ text: String) -> [InlineContent] {
        var result: [InlineContent] = []
        var buffer = ""
        var i = text.startIndex

        func flush() {
            if buffer.isEmpty { return }
            result.append(contentsOf: parseInlineFormatting(buffer))
            buffer = ""
        }

        while i < text.endIndex {
            if text[i] == "[" {
                flush()

                guard let closeBracket = findMatchingBracket(in: text, start: i) else {
                    buffer.append(text[i])
                    i = text.index(after: i)
                    continue
                }

                let next = text.index(after: closeBracket)
                guard next < text.endIndex, text[next] == "(",
                      let closeParen = text.range(of: ")", range: next..<text.endIndex) else {
                    buffer.append(text[i])
                    i = text.index(after: i)
                    continue
                }

                let linkText = String(text[text.index(after: i)..<closeBracket])
                let urlStart = text.index(after: next)
                var url = String(text[urlStart..<closeParen.lowerBound]).trimmingCharacters(in: .whitespaces)

                url = url.replacingOccurrences(of: " ", with: "")
                url = url.replacingOccurrences(of: "[", with: "")
                url = url.replacingOccurrences(of: "]", with: "")

                if url.hasPrefix("accent://") {
                    result.append(.accentLink(url: url, text: linkText))
                } else {
                    result.append(.link(url: url, text: linkText))
                }

                i = closeParen.upperBound
                continue
            }

            buffer.append(text[i])
            i = text.index(after: i)
        }

        flush()

        if result.isEmpty { return [.text(text)] }
        return result
    }

    private static func parseInlineFormatting(_ input: String) -> [InlineContent] {
        var out: [InlineContent] = []
        var s = input
        var idx = s.startIndex
        var plain = ""

        func flushPlain() {
            if plain.isEmpty { return }
            out.append(contentsOf: splitAccentMarkers(plain))
            plain = ""
        }

        func starts(_ token: String, _ at: String.Index) -> Bool {
            s[at...].hasPrefix(token)
        }

        while idx < s.endIndex {
            if starts("`", idx) {
                let after = s.index(after: idx)
                if let end = s[after...].firstIndex(of: "`") {
                    flushPlain()
                    out.append(.code(String(s[after..<end])))
                    idx = s.index(after: end)
                    continue
                }
            }

            if starts("**", idx) {
                let after = s.index(idx, offsetBy: 2)
                if let end = s[after...].range(of: "**")?.lowerBound {
                    flushPlain()
                    out.append(.bold(String(s[after..<end])))
                    idx = s.index(end, offsetBy: 2)
                    continue
                }
            }

            if starts("*", idx) {
                let after = s.index(after: idx)
                if let end = s[after...].firstIndex(of: "*") {
                    flushPlain()
                    out.append(.italic(String(s[after..<end])))
                    idx = s.index(after: end)
                    continue
                }
            }

            if starts("_", idx) {
                let after = s.index(after: idx)
                if let end = s[after...].firstIndex(of: "_") {
                    flushPlain()
                    out.append(.italic(String(s[after..<end])))
                    idx = s.index(after: end)
                    continue
                }
            }

            plain.append(s[idx])
            idx = s.index(after: idx)
        }

        flushPlain()
        return out
    }

    private static func splitAccentMarkers(_ input: String) -> [InlineContent] {
        var result: [InlineContent] = []
        var remaining = input

        while let marker = remaining.range(of: "(accent://)") {
            let before = String(remaining[..<marker.lowerBound])
            if !before.isEmpty { result.append(.text(before)) }

            let after = marker.upperBound
            var end = after
            while end < remaining.endIndex {
                if remaining[end].isWhitespace { break }
                end = remaining.index(after: end)
            }

            let accentText = String(remaining[after..<end])
            if !accentText.isEmpty { result.append(.accentText(accentText)) }

            if end < remaining.endIndex {
                remaining = String(remaining[end...])
            } else {
                remaining = ""
                break
            }
        }

        while let accentRange = remaining.range(of: "accent://") {
            let before = String(remaining[..<accentRange.lowerBound])
            if !before.isEmpty { result.append(.text(before)) }

            let afterPrefix = accentRange.upperBound
            var end = afterPrefix
            while end < remaining.endIndex {
                let c = remaining[end]
                if c.isWhitespace || c.isPunctuation { break }
                end = remaining.index(after: end)
            }

            let accentText = String(remaining[afterPrefix..<end])
            if !accentText.isEmpty { result.append(.accentText(accentText)) }

            if end < remaining.endIndex {
                remaining = String(remaining[end...])
            } else {
                remaining = ""
                break
            }
        }

        if !remaining.isEmpty {
            result.append(.text(remaining))
        }

        return result
    }

    private static func findMatchingBracket(in text: String, start: String.Index) -> String.Index? {
        var depth = 0
        var i = start
        while i < text.endIndex {
            if text[i] == "[" { depth += 1 }
            else if text[i] == "]" {
                depth -= 1
                if depth == 0 { return i }
            }
            i = text.index(after: i)
        }
        return nil
    }

    private static func parseImage(_ line: String) -> GuideElement? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        guard let altStart = trimmed.range(of: "!["),
              let altEnd = trimmed.range(of: "](", range: altStart.upperBound..<trimmed.endIndex),
              let urlEnd = trimmed.range(of: ")", range: altEnd.upperBound..<trimmed.endIndex) else {
            return nil
        }

        let altText = String(trimmed[altStart.upperBound..<altEnd.lowerBound])
        var url = String(trimmed[altEnd.upperBound..<urlEnd.lowerBound])
        url = url.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "")
        return .image(url: url, altText: altText)
    }
}
