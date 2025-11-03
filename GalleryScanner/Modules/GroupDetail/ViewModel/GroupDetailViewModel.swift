import Foundation
import Combine
import UIKit
import SwiftUI

@MainActor
final class GroupDetailViewModel: ObservableObject {
    @Published var assetIDs: [String] = []
    @Published private(set) var thumbnails: [String: ImageState] = [:]

    let groupRaw: String
    let imageDetailDataManager = ImageDetailDataManager()
    
    private let dataManager = GroupDataManager()
    private var cancellables = Set<AnyCancellable>()
    private var thumbnailTasks: [String: Task<Void, Never>] = [:]
    private let thumbnailSize = CGSize(width: 150, height: 150)

    init(groupRaw: String) {
        self.groupRaw = groupRaw
        loadAssetIDs(prefetchCount: 12)
        observeNewAssets()
    }

    func onAppear() {
        if assetIDs.isEmpty {
            loadAssetIDs(prefetchCount: 12)
        }
    }
    
    func onDisappear() {
        cancelAllTasks()
        Task { await dataManager.clearCaches() }
    }
    
    func clearCaches() {
        cancelAllTasks()
        Task { await dataManager.clearCaches() }
    }

    func imageState(for assetID: String) -> ImageState {
        thumbnails[assetID] ?? .none
    }

    func ensureThumbnailLoaded(for assetID: String) {
        if case .thumbnail = thumbnails[assetID] ?? .none { return }
        if case .full = thumbnails[assetID] ?? .none { return }
        guard thumbnailTasks[assetID] == nil else { return }

        let task = Task { [weak self] in
            guard let self else { return }
            let image = await self.dataManager.fetchThumbnailImage(for: assetID, size: self.thumbnailSize)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                if let image { 
                    self.thumbnails[assetID] = .thumbnail(image) 
                }
                self.thumbnailTasks[assetID] = nil
            }
        }

        thumbnailTasks[assetID] = task
    }

    private func loadAssetIDs(prefetchCount: Int? = nil) {
        Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            let ids = await self.dataManager.fetchAssets(for: self.groupRaw)

            if let limit = prefetchCount {
                let initial = Array(ids.prefix(limit))
                if !initial.isEmpty {
                    await self.dataManager.prefetchThumbnails(for: initial, size: self.thumbnailSize)
                }
            }

            await MainActor.run {
                self.assetIDs = ids
            }
        }
    }

    private func observeNewAssets() {
        PhotoScanner.shared.scannedBatchesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] batch in
                guard let self else { return }
                let newIDs = batch
                    .filter { $0.group == self.groupRaw }
                    .map(\.id)
                    .filter { !self.assetIDs.contains($0) }

                guard !newIDs.isEmpty else { return }

                self.assetIDs.append(contentsOf: newIDs)
            }
            .store(in: &cancellables)
    }

    private func cancelAllTasks() {
        thumbnailTasks.values.forEach { $0.cancel() }
        thumbnailTasks.removeAll()
    }
}
