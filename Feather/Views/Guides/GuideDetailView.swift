import SwiftUI

struct GuideDetailView: View {
    @ObservedObject var store: GuideStore
    let guide: GuideIndexEntry

    @State private var isLoading = true
    @State private var errorText: String?
    @State private var parsed: ParsedGuideContent = .init(elements: [])

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let errorText {
                VStack(spacing: 12) {
                    Text(errorText)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") { Task { await load() } }
                }
                .padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(parsed.elements.enumerated()), id: \.offset) { _, el in
                            GuideElementView(element: el)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
            }
        }
        .navigationTitle(guide.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    @MainActor
    private func load() async {
        isLoading = true
        errorText = nil
        do {
            parsed = try await store.loadGuideParsed(filename: guide.filename)
        } catch {
            errorText = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
        }
        isLoading = false
    }
}

private struct GuideElementView: View {
    let element: GuideElement

    var body: some View {
        switch element {
        case .heading(let level, let text, let isAccent):
            Text(text)
                .font(headerFont(level))
                .foregroundColor(isAccent ? .accentColor : .primary)
                .padding(.top, level <= 2 ? 8 : 4)

        case .paragraph(let content):
            InlineContentText(content: content)
                .foregroundColor(.primary)

        case .listItem(let level, let content):
            HStack(alignment: .top, spacing: 10) {
                Text("•")
                    .font(.body.weight(.semibold))
                    .padding(.leading, CGFloat(level) * 14)
                InlineContentText(content: content)
                    .foregroundColor(.primary)
                Spacer(minLength: 0)
            }

        case .blockquote(let content):
            HStack(alignment: .top, spacing: 10) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor)
                    .frame(width: 4)
                InlineContentText(content: content)
                    .foregroundColor(.secondary)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Color.primary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))

        case .codeBlock(let language, let code):
            VStack(alignment: .leading, spacing: 8) {
                if let language, !language.isEmpty {
                    Text(language)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14))

        case .image(let url, let altText):
            VStack(alignment: .leading, spacing: 6) {
                if let u = URL(string: url) {
                    AsyncImage(url: u) { phase in
                        switch phase {
                        case .empty:
                            ProgressView().frame(maxWidth: .infinity, minHeight: 160)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        case .failure:
                            Text(altText.isEmpty ? "Image failed to load" : altText)
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.primary.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Text(altText.isEmpty ? "Invalid image URL" : altText)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func headerFont(_ level: Int) -> Font {
        switch level {
        case 1: return .system(size: 30, weight: .bold)
        case 2: return .system(size: 22, weight: .bold)
        case 3: return .system(size: 18, weight: .semibold)
        default: return .system(size: 16, weight: .semibold)
        }
    }
}

private struct InlineContentText: View {
    let content: [InlineContent]

    var body: some View {
        content.reduce(Text("")) { partial, item in
            partial + makeText(for: item)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func makeText(for item: InlineContent) -> Text {
        switch item {
        case .text(let s):
            return Text(s)

        case .bold(let s):
            return Text(s).bold()

        case .italic(let s):
            return Text(s).italic()

        case .code(let s):
            return Text(s).font(.system(.body, design: .monospaced))

        case .accentText(let s):
            return Text(s).foregroundColor(.accentColor)

        case .link(let url, let text):
            if let u = URL(string: url) {
                return Text(.init("[\(text)](\(u.absoluteString))"))
            }
            return Text(text)

        case .accentLink(_, let text):
            return Text(text).foregroundColor(.accentColor)
        }
    }
}
