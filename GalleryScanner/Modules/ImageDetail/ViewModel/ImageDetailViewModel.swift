import Foundation
import SwiftUI
import UIKit

@MainActor
final class ImageDetailViewModel: ObservableObject {
    @Published private(set) var images: [String: ImageState] = [:]
    @Published private(set) var currentIndex: Int

    let assetIDs: [String]

    private var loadTasks: [String: Task<Void, Never>] = [:]
    private let dataManager = ImageDetailDataManager()
    private let thumbnailSize = CGSize(width: 300, height: 300)

    init(assetIDs: [String], startIndex: Int) {
        self.assetIDs = assetIDs
        self.currentIndex = startIndex
    }

    func onAppear() {
        guard let initialID = assetID(at: currentIndex) else { return }
        ensureImageLoaded(for: initialID)
        prefetchNeighbors(from: currentIndex, direction: 1)
    }

    func onDisappear() {
        cancelAllTasks()
        Task {
            await dataManager.clearCaches()
        }
    }

    func bindingForCurrentIndex() -> Binding<Int> {
        Binding(
            get: { self.currentIndex },
            set: { [weak self] newValue in
                guard let self else { return }
                self.updateCurrentIndex(from: self.currentIndex, to: newValue)
            }
        )
    }

    func imageState(for assetID: String) -> ImageState {
        images[assetID] ?? .none
    }

    func ensureImageLoaded(for assetID: String) {
        if case .full = images[assetID] ?? .none { return }
        guard loadTasks[assetID] == nil else { return }

        let currentState = images[assetID] ?? .none
        let task = Task { [weak self] in
            guard let self else { return }
            
            if case .none = currentState {
                if let thumb = await self.dataManager.fetchThumbnailImage(for: assetID, size: self.thumbnailSize) {
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        self.images[assetID] = .thumbnail(thumb)
                    }
                }
            }

            if let full = await self.dataManager.fetchFullImage(for: assetID) {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.images[assetID] = .full(full)
                }
            }

            await MainActor.run {
                self.loadTasks[assetID] = nil
            }
        }

        loadTasks[assetID] = task
    }

    private func updateCurrentIndex(from oldValue: Int, to newValue: Int) {
        guard newValue != oldValue else { return }
        guard assetIDs.indices.contains(newValue) else { return }

        currentIndex = newValue
        let assetID = assetIDs[newValue]
        ensureImageLoaded(for: assetID)

        let direction = (newValue - oldValue).signum()
        prefetchNeighbors(from: newValue, direction: direction == 0 ? 1 : direction)
        pruneStaleTasks(around: newValue)
    }

    private func prefetchNeighbors(from index: Int, direction: Int) {
        let direction = direction == 0 ? 1 : direction
        let targetIndex = index + direction
        guard let neighborID = assetID(at: targetIndex) else { return }

        switch images[neighborID] ?? .none {
        case .none:
            ensureImageLoaded(for: neighborID)
        case .thumbnail:
            Task { [weak self] in
                guard let self else { return }
                await self.dataManager.prefetchFullImages(for: [neighborID])
            }
        case .full:
            break
        }
    }

    private func pruneStaleTasks(around index: Int) {
        let validRange = (index - 1)...(index + 1)
        let validIDs = Set(validRange.compactMap(assetID(at:)))

        for (key, task) in loadTasks where !validIDs.contains(key) {
            task.cancel()
            loadTasks[key] = nil
        }
    }

    private func cancelAllTasks() {
        loadTasks.values.forEach { $0.cancel() }
        loadTasks.removeAll()
    }

    private func assetID(at index: Int) -> String? {
        guard assetIDs.indices.contains(index) else { return nil }
        return assetIDs[index]
    }
}
