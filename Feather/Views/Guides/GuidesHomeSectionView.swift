import SwiftUI

private func sf(_ name: String, fallback: String) -> String {
    UIImage(systemName: name) == nil ? fallback : name
}

struct GuidesHomeSectionView: View {
    @StateObject var store: GuideStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Guides").font(.title2).bold()
                Spacer()
                if store.isLoadingIndex { ProgressView().scaleEffect(0.9) }
            }

            if let err = store.indexError, store.guides.isEmpty {
                Text(err).foregroundStyle(.secondary)
                Button("Retry") { Task { await store.loadIndex() } }
            } else {
                VStack(spacing: 10) {
                    ForEach(store.guides) { guide in
                        NavigationLink {
                            GuideDetailView(store: store, guide: guide)
                        } label: {
                            GuideRow(title: guide.title, subtitle: guide.filename)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .task {
            if store.guides.isEmpty && !store.isLoadingIndex {
                await store.loadIndex()
            }
        }
    }
}

private struct GuideRow: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor.opacity(0.12))
                Image(systemName: sf("book.pages", fallback: "book"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.primary.opacity(0.10), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(Rectangle())
    }
}
