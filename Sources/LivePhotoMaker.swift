import Foundation
import AVFoundation
import UIKit
import ImageIO
import UniformTypeIdentifiers
import Photos
import CoreMedia

/// 把视频转成真正的 Apple Live Photo 保存到相册。
///
/// 关键点：Photos 要求静态图与配对视频带**同一 assetIdentifier**，否则报
/// PHPhotosErrorDomain 330（无效资源）。做法参考开源实现 TouSC/Video2LivePhoto：
/// - 静态图写成 HEIC，元数据 MakerApple["17"] = assetIdentifier
/// - 视频 mux 成 MOV，写入 com.apple.quicktime.content.identifier = 同一 assetIdentifier
enum LivePhotoMaker {

    private static let contentIdentifierKey = "com.apple.quicktime.content.identifier"
    private static let makerAppleAssetIDKey = "17"

    /// 视频 -> Live Photo，成功后清理临时文件
    static func saveLivePhoto(fromVideo videoURL: URL) async throws {
        let assetID = UUID().uuidString

        let keyPhoto = try await writeKeyPhoto(videoURL: videoURL, assetIdentifier: assetID)
        let liveVideo = try await muxLiveVideo(videoURL: videoURL, assetIdentifier: assetID)

        do {
            try await PhotoSaver.saveLivePhoto(image: keyPhoto, video: liveVideo)
        }

        try? FileManager.default.removeItem(at: keyPhoto)
        try? FileManager.default.removeItem(at: liveVideo)
    }

    // MARK: 关键帧 -> HEIC

    private static func writeKeyPhoto(videoURL: URL, assetIdentifier: String) async throws -> URL {
        let asset = AVURLAsset(url: videoURL)
        let duration = try await asset.load(.duration)
        let total = duration.seconds

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        let seconds = min(max(total * 0.5, 0.05), max(total - 0.05, 0.05))
        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        let cgImage = try generator.copyCGImage(at: time, actualTime: nil)

        guard let heic = UIImage(cgImage: cgImage).heicData() else {
            throw APIError.message("无法生成实况静态图")
        }

        let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent("vp_key_\(UUID().uuidString).heic")

        guard let imageDest = CGImageDestinationCreateWithURL(
            dest as CFURL, UTType.heic.identifier as CFString, 1, nil
        ) else {
            throw APIError.message("无法写入实况静态图")
        }

        let source = CGImageSourceCreateWithData(heic as CFData, nil)
        var meta: [String: Any] = source.flatMap {
            CGImageSourceCopyPropertiesAtIndex($0, 0, nil) as? [String: Any]
        } ?? [:]

        var maker = (meta[kCGImagePropertyMakerAppleDictionary as String] as? [String: Any]) ?? [:]
        maker[makerAppleAssetIDKey] = assetIdentifier
        meta[kCGImagePropertyMakerAppleDictionary as String] = maker

        if let source {
            CGImageDestinationAddImageFromSource(imageDest, source, 0, meta as CFDictionary)
        }
        guard CGImageDestinationFinalize(imageDest) else {
            throw APIError.message("实况静态图写入失败")
        }
        return dest
    }

    // MARK: 视频 mux（带 content.identifier 元数据）

    private static func muxLiveVideo(videoURL: URL, assetIdentifier: String) async throws -> URL {
        guard let metaURL = Bundle.main.url(forResource: "metadata", withExtension: "mov") else {
            throw APIError.message("缺少实况元数据模板")
        }

        let asset = AVURLAsset(url: videoURL)
        let metaAsset = AVURLAsset(url: metaURL)

        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        guard let videoTrack = videoTracks.first else {
            throw APIError.message("视频没有画面轨道")
        }
        let metaTracks = try await metaAsset.loadTracks(withMediaType: .metadata)
        guard let metaTrack = metaTracks.first else {
            throw APIError.message("元数据模板无效")
        }

        let outURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("vp_live_\(UUID().uuidString).mov")
        try? FileManager.default.removeItem(at: outURL)

        let readerVideo = try AVAssetReader(asset: asset)
        let readerMeta = try AVAssetReader(asset: metaAsset)
        let writer = try AVAssetWriter(outputURL: outURL, fileType: .mov)

        // 视频轨：重编码为 H.264
        let readerOutput = AVAssetReaderTrackOutput(
            track: videoTrack,
            outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA as UInt32)]
        )
        readerVideo.add(readerOutput)

        let natural = try await videoTrack.load(.naturalSize)
        let transform = try await videoTrack.load(.preferredTransform)
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: natural.width,
            AVVideoHeightKey: natural.height,
        ])
        videoInput.transform = transform
        videoInput.expectsMediaDataInRealTime = true
        writer.add(videoInput)

        // 元数据轨：沿用模板（含 still-image-time 等实况所需字段）
        let metaOutput = AVAssetReaderTrackOutput(track: metaTrack, outputSettings: nil)
        readerMeta.add(metaOutput)
        let metaInput = AVAssetWriterInput(mediaType: .metadata, outputSettings: nil)
        writer.add(metaInput)

        // 关键：写入 content.identifier，与静态图的 MakerApple["17"] 对应
        writer.metadata = [contentIdentifierItem(assetIdentifier)]

        return try await withCheckedThrowingContinuation { continuation in
            writer.startWriting()
            readerVideo.startReading()
            readerMeta.startReading()
            writer.startSession(atSourceTime: .zero)

            let group = DispatchGroup()

            group.enter()
            videoInput.requestMediaDataWhenReady(on: DispatchQueue(label: "vp.writer.video")) {
                while videoInput.isReadyForMoreMediaData {
                    if let buffer = readerOutput.copyNextSampleBuffer() {
                        videoInput.append(buffer)
                    } else {
                        videoInput.markAsFinished()
                        group.leave()
                        break
                    }
                }
            }

            group.enter()
            metaInput.requestMediaDataWhenReady(on: DispatchQueue(label: "vp.writer.meta")) {
                while metaInput.isReadyForMoreMediaData {
                    if let buffer = metaOutput.copyNextSampleBuffer() {
                        metaInput.append(buffer)
                    } else {
                        metaInput.markAsFinished()
                        group.leave()
                        break
                    }
                }
            }

            group.notify(queue: .main) {
                if readerVideo.status == .completed, readerMeta.status == .completed, writer.status == .writing {
                    writer.finishWriting {
                        if writer.status == .completed {
                            continuation.resume(returning: outURL)
                        } else {
                            continuation.resume(throwing: writer.error ?? APIError.message("视频合成失败"))
                        }
                    }
                } else {
                    let err = readerVideo.error ?? readerMeta.error ?? writer.error ?? APIError.message("视频合成失败")
                    continuation.resume(throwing: err)
                }
            }
        }
    }

    private static func contentIdentifierItem(_ id: String) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.key = contentIdentifierKey as (NSCopying & NSObjectProtocol)?
        item.keySpace = AVMetadataKeySpace.quickTimeMetadata
        item.value = id as (NSCopying & NSObjectProtocol)?
        item.dataType = "com.apple.metadata.datatype.UTF-8"
        return item
    }
}

// MARK: - UIImage HEIC

extension UIImage {
    /// 编码为 HEIC（实况静态图需要 HEIC 容器）
    func heicData() -> Data? {
        guard let cgImage = self.cgImage,
              let mutable = CFDataCreateMutable(kCFAllocatorDefault, 0),
              let dest = CGImageDestinationCreateWithData(mutable, UTType.heic.identifier as CFString, 1, nil)
        else { return nil }
        CGImageDestinationAddImage(dest, cgImage, nil)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return mutable as Data
    }
}
