//
//  AVAsset+Extensions.swift
//  min
//
//  Created by Michael Jach on 09/07/2024.
//

import AVKit

extension AVAsset {
  func createExportSession() -> AVAssetExportSession? {
    guard let track = self.tracks(withMediaType: AVMediaType.video).first else { return nil }
    let size = track.naturalSize.applying(track.preferredTransform)
    let naturalWidth = abs(size.width)
    let naturalHeight = abs(size.height)
    
    let exportSession = AVAssetExportSession(asset: self, presetName: AVAssetExportPresetHEVC1920x1080)
    let cropRect = CGRect(x: (naturalWidth / 2) - (naturalHeight * 9 / 16/2), y: 0, width: naturalHeight * 9 / 16, height: naturalHeight)
    let cropScaleComposition = AVMutableVideoComposition(asset: self, applyingCIFiltersWithHandler: { request in
      let cropFilter = CIFilter(name: "CICrop")!
      cropFilter.setValue(request.sourceImage, forKey: kCIInputImageKey)
      cropFilter.setValue(CIVector(cgRect: cropRect), forKey: "inputRectangle")
      let imageAtOrigin = cropFilter.outputImage!.transformed(by: CGAffineTransform(translationX: -cropRect.origin.x, y: -cropRect.origin.y))
      request.finish(with: imageAtOrigin, context: nil)
    })
    
    let renderHeight = naturalHeight >= 1920 ? 1920 : naturalHeight
    let renderWidth = renderHeight * 9 / 16
    cropScaleComposition.renderSize = CGSize(width: renderWidth, height: renderHeight)
    exportSession?.videoComposition = cropScaleComposition
    let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + "_compressed.mp4")
    exportSession?.outputURL = compressedURL
    exportSession?.outputFileType = .mp4
    exportSession?.shouldOptimizeForNetworkUse = true
    
    return exportSession
  }
  
  func createThumbnail() async -> UIImage? {
    let generator = AVAssetImageGenerator(asset: self)
    generator.appliesPreferredTrackTransform = true
    generator.maximumSize = CGSize(width: 600, height: 0)
    generator.requestedTimeToleranceBefore = .zero
    do {
      let (image, _) = try await generator.image(at: .zero)
      return UIImage(cgImage: image)
    } catch {
      return nil
    }
  }
}
