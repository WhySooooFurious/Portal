//
//  ProfileImageCropperSheet.swift
//  Feather
//
//  Created by Anmol Singh on 24/1/2026.
//


import SwiftUI
import UIKit

struct ProfileImageCropperSheet: View {
    let image: UIImage
    let onCancel: () -> Void
    let onSave: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var minScale: CGFloat = 1
    @State private var baseScale: CGFloat = 1
    @State private var pinchScale: CGFloat = 1

    @State private var baseOffset: CGSize = .zero
    @State private var dragOffset: CGSize = .zero

    @State private var cropSide: CGFloat = 320

    private var totalScale: CGFloat {
        let v = baseScale * pinchScale
        return max(minScale, min(8, v))
    }

    private var totalOffset: CGSize {
        CGSize(width: baseOffset.width + dragOffset.width, height: baseOffset.height + dragOffset.height)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack {
                    Spacer(minLength: 0)

                    GeometryReader { geo in
                        let side = min(geo.size.width, geo.size.height)

                        ZStack {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: side, height: side)
                                .scaleEffect(totalScale, anchor: .center)
                                .offset(liveClampedOffset(side: side, scale: totalScale))
                                .clipShape(Circle())
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            dragOffset = value.translation
                                        }
                                        .onEnded { value in
                                            let proposed = CGSize(
                                                width: baseOffset.width + value.translation.width,
                                                height: baseOffset.height + value.translation.height
                                            )
                                            baseOffset = clampOffset(proposed: proposed, side: side, scale: totalScale)
                                            dragOffset = .zero
                                        }
                                )
                                .simultaneousGesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            pinchScale = value
                                        }
                                        .onEnded { value in
                                            baseScale = max(minScale, min(8, baseScale * value))
                                            pinchScale = 1
                                            baseOffset = clampOffset(proposed: baseOffset, side: side, scale: baseScale)
                                        }
                                )

                            Circle()
                                .strokeBorder(Color.white.opacity(0.9), lineWidth: 2)
                                .frame(width: side, height: side)
                                .allowsHitTesting(false)
                        }
                        .frame(width: side, height: side)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onAppear {
                            cropSide = side
                            minScale = minimumFillScale(side: side)
                            baseScale = minScale
                            pinchScale = 1
                            baseOffset = .zero
                            dragOffset = .zero
                        }
                        .onChange(of: side) { newSide in
                            cropSide = newSide
                            minScale = minimumFillScale(side: newSide)
                            baseScale = max(minScale, baseScale)
                            baseOffset = clampOffset(proposed: baseOffset, side: newSide, scale: baseScale)
                        }
                    }
                    .frame(height: 420)
                    .padding(.horizontal, 18)

                    Spacer(minLength: 0)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        onCancel()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        let result = cropResult(outputSide: 1024)
                        onSave(result)
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
    }

    private func minimumFillScale(side: CGFloat) -> CGFloat {
        let iw = image.size.width
        let ih = image.size.height
        guard iw > 0, ih > 0 else { return 1 }
        return max(side / iw, side / ih)
    }

    private func clampOffset(proposed: CGSize, side: CGFloat, scale: CGFloat) -> CGSize {
        let iw = image.size.width
        let ih = image.size.height
        guard iw > 0, ih > 0 else { return .zero }

        let scaleToFill = max(side / iw, side / ih)
        let displayedW = iw * scaleToFill * scale
        let displayedH = ih * scaleToFill * scale

        let maxX = max(0, (displayedW - side) / 2)
        let maxY = max(0, (displayedH - side) / 2)

        return CGSize(
            width: min(max(proposed.width, -maxX), maxX),
            height: min(max(proposed.height, -maxY), maxY)
        )
    }

    private func liveClampedOffset(side: CGFloat, scale: CGFloat) -> CGSize {
        clampOffset(proposed: totalOffset, side: side, scale: scale)
    }

    private func cropResult(outputSide: CGFloat) -> UIImage {
        let iw = image.size.width
        let ih = image.size.height
        guard iw > 0, ih > 0 else { return image }

        let previewSide = cropSide
        let scaleToFillPreview = max(previewSide / iw, previewSide / ih)

        let displayedW = iw * scaleToFillPreview * totalScale
        let displayedH = ih * scaleToFillPreview * totalScale

        let clamped = clampOffset(proposed: totalOffset, side: previewSide, scale: totalScale)

        let originX = (previewSide - displayedW) / 2 + clamped.width
        let originY = (previewSide - displayedH) / 2 + clamped.height

        let xInImage = (0 - originX) / (scaleToFillPreview * totalScale)
        let yInImage = (0 - originY) / (scaleToFillPreview * totalScale)
        let wInImage = previewSide / (scaleToFillPreview * totalScale)
        let hInImage = previewSide / (scaleToFillPreview * totalScale)

        let normalized = image.nbNormalized()
        let cropRect = CGRect(x: xInImage, y: yInImage, width: wInImage, height: hInImage)
            .intersection(CGRect(x: 0, y: 0, width: normalized.size.width, height: normalized.size.height))

        guard let cg = normalized.cgImage else { return normalized }

        let scale = normalized.scale
        let pixelRect = CGRect(
            x: cropRect.origin.x * scale,
            y: cropRect.origin.y * scale,
            width: cropRect.size.width * scale,
            height: cropRect.size.height * scale
        ).integral

        guard let croppedCG = cg.cropping(to: pixelRect) else { return normalized }
        let square = UIImage(cgImage: croppedCG, scale: 1, orientation: .up)

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: outputSide, height: outputSide))
        return renderer.image { _ in
            square.draw(in: CGRect(x: 0, y: 0, width: outputSide, height: outputSide))
        }
    }
}

extension UIImage {
    func nbNormalized() -> UIImage {
        if imageOrientation == .up { return self }
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
