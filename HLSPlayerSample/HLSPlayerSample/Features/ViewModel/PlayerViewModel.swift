//
//  PlayerViewModel.swift
//  HLSPlayerSample
//
//  Created by mohamed hassan on 26/04/2025.
//

import Foundation
import AVFoundation
import SwiftUI

class PlayerViewModel: ObservableObject {
    let player = AVPlayer()
    private var playerItem: AVPlayerItem?
    
    private let hlsURL = URL(string: "https://hls-streams-stage.s3.eu-central-1.amazonaws.com/out_streams_video_crop_test_from_stream_1/stream_1/streams.m3u8")!
    
    @Published var isHighQuality = true
    @Published var currentAudioTrackName: String = ""

    private var audioGroup: AVMediaSelectionGroup?
    
    private var deviceType: DeviceType {
        UIDevice.current.userInterfaceIdiom == .pad ? .iPad : .iPhone
    }
    
    enum DeviceType {
        case iPhone, iPad
    }
    
    @MainActor
    func setupPlayer() {
        let asset = AVURLAsset(url: hlsURL)
        let item = AVPlayerItem(asset: asset)
        self.playerItem = item

        player.replaceCurrentItem(with: item)
        player.play()
        observeAudioTracks()
    }

    func toggleQuality() {
        isHighQuality.toggle()
        adjustBitrate()
    }

    private func adjustBitrate() {
        if isHighQuality {
            player.currentItem?.preferredPeakBitRate = 5_000_000 //5 mega
        } else {
            player.currentItem?.preferredPeakBitRate = 1_000_000 // 1 mega
        }
    }

    @MainActor
    private func observeAudioTracks() {
        guard let item = playerItem else { return }
        let asset = item.asset

        Task {
            do {
                _ = try await asset.load(.availableMediaCharacteristicsWithMediaSelectionOptions)
                let group = try await asset.loadMediaSelectionGroup(for: .audible)
                self.audioGroup = group

                if let audioGroup = self.audioGroup,
                   let current = item.currentMediaSelection.selectedMediaOption(in: audioGroup) {
                    if let item = current.commonMetadata.first(where: { $0.commonKey?.rawValue == "title" }) {
                        if let title = try? await item.load(.stringValue) {
                            self.currentAudioTrackName = title
                        } else {
                            self.currentAudioTrackName = current.displayName
                        }
                    }
                } else {
                    self.currentAudioTrackName = "Unknown"
                }

            } catch {
                print("Failed to load audio tracks:", error.localizedDescription)
            }
        }
    }

    func toggleAudioTrack() {
        guard let group = audioGroup,
              let item = player.currentItem else { return }

        let options = group.options
        if let current = item.currentMediaSelection.selectedMediaOption(in: group),
           let next = options.first(where: { $0 != current }) {
            item.select(next, in: group)

            Task {
                if let titleItem = next.commonMetadata.first(where: { $0.commonKey?.rawValue == "title" }),
                   let title = try? await titleItem.load(.stringValue) {
                    await MainActor.run {
                        self.currentAudioTrackName = title
                    }
                } else {
                    await MainActor.run {
                        self.currentAudioTrackName = next.displayName
                    }
                }
            }
        } else if let first = options.first {
            item.select(first, in: group)

            Task {
                if let titleItem = first.commonMetadata.first(where: { $0.commonKey?.rawValue == "title" }),
                   let title = try? await titleItem.load(.stringValue) {
                    await MainActor.run {
                        self.currentAudioTrackName = title
                    }
                } else {
                    await MainActor.run {
                        self.currentAudioTrackName = first.displayName
                    }
                }
            }
        }
    }
}
