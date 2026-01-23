import Foundation

enum GuideTextNormalizer {
    static func normalize(_ input: String) -> String {
        var s = input
        s = s.replacingOccurrences(of: "\r\n", with: "\n")
        s = s.replacingOccurrences(of: "\r", with: "\n")

        s = splitInlineHeadingsSafely(s)

        s = s.replacingOccurrences(of: "\n\n\n+", with: "\n\n", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func splitInlineHeadingsSafely(_ s: String) -> String {
        var out = ""
        out.reserveCapacity(s.count)

        var i = s.startIndex
        var inInlineCode = false
        var inFence = false

        func isHeadingStart(_ idx: String.Index) -> Int? {
            var j = idx
            var count = 0
            while j < s.endIndex, s[j] == "#", count < 6 {
                count += 1
                j = s.index(after: j)
            }
            if count == 0 { return nil }

            if idx > s.startIndex {
                let prev = s[s.index(before: idx)]
                if prev.isLetter || prev.isNumber { return nil }
                if prev == "/" { return nil } // avoid URL fragments like /#section
            }

            if j == s.endIndex { return nil }
            let next = s[j]

            if next == "#" { return nil }

            return count
        }

        while i < s.endIndex {
            if !inInlineCode && !inFence, s[i] == "`" {
                let next = s.index(after: i)
                if next < s.endIndex, s[next] == "`",
                   s.index(after: next) < s.endIndex, s[s.index(after: next)] == "`" {
                    inFence.toggle()
                    out.append("```")
                    i = s.index(i, offsetBy: 3)
                    continue
                } else {
                    inInlineCode.toggle()
                    out.append("`")
                    i = s.index(after: i)
                    continue
                }
            }

            if !inInlineCode && !inFence, s[i] == "#" {
                if let count = isHeadingStart(i) {
                    let prevChar: Character? = (i > s.startIndex) ? s[s.index(before: i)] : nil

                    let okPrev = (prevChar == nil)
                    || prevChar!.isWhitespace
                    || prevChar!.isPunctuation

                    if okPrev {
                        if !out.hasSuffix("\n") {
                            out.append("\n\n")
                        } else if !out.hasSuffix("\n\n") {
                            out.append("\n")
                        }

                        out.append(String(repeating: "#", count: count))

                        var j = s.index(i, offsetBy: count)
                        if j < s.endIndex, s[j] != " " && s[j] != "\n" {
                            out.append(" ")
                        }

                        i = j
                        continue
                    }
                }
            }

            out.append(s[i])
            i = s.index(after: i)
        }

        return out
    }
}
