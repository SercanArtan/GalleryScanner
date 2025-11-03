# Gallery Scanner

---

## Description

Gallery Scanner is a hybrid SwiftUI + UIKit application that scans the user's photo library, groups assets with a deterministic hash algorithm, and presents them in a responsive gallery experience. The scanning pipeline runs asynchronously, keeps UI state in sync with Combine publishers, and stores progress so interrupted scans can resume.

---

## Features

- Guided authorization flow for photo-library access with actionable alerts that deep-link to Settings when access is limited or denied.
- Incremental photo scanning driven by `PhotoScanner`, using structured concurrency, task groups, and hashing to classify assets into letter-based buckets.
- Real-time progress reporting to the home screen via Combine, with diffable data sources keeping the UIKit collection view in sync.
- Swift concurrency actors (`PersistenceManager`, `GroupDataManager`, `ImageLoader`) that serialize disk access, cache management, and Photos framework requests.
- Persistent scan state saved to JSON so the app can resume from the prior progress after restarts or background termination.
- Bridged navigation stack: a `UINavigationController` hosts SwiftUI views, enabling UIKit compositional layouts on the home screen while downstream views stay in SwiftUI.
- Lazy loading and caching for thumbnails and full-resolution images, including prefetching of neighboring assets inside the detail view's paged carousel.
- Graceful handling of asset deletions—removed items disappear from the app because the scanner reconciles library changes using `PHPhotoLibraryChangeObserver`.
- Registers as a `PHPhotoLibraryChangeObserver`, restarting scans when the photo library mutates so the local state mirrors device storage.
- Loads any previously serialized `ScanPersistence` snapshot, prunes deleted assets, and resumes incremental progress counts before scheduling new work.
- Builds a concurrent task group capped at 10 workers; each worker processes a `PHAsset`, computes a deterministic hash, and maps it into a `PhotoGroup` range (`CaseHelper`).
- Streams progress through `progressPublisher` and freshly processed batches through `scannedBatchesPublisher`, allowing UIKit collection views and SwiftUI grids to animate updates.
- Persists the running state every 25 assets via `PersistenceManager` so that force quits or background suspension do not lose work.
- Coordinates with `ImageLoader` and downstream data managers, ensuring that newly scanned identifiers are available for thumbnail prefetching and detail-page rendering.

---

## Project Structure

GalleryScanner/
├── App.swift # SwiftUI entry point embedding the home flow
├── Core/
│ └── Photo/ # PhotoScanner + image loading infrastructure
├── Helpers/ # Hashing utilities, persistence helpers, shared enums
├── Models/ # Codable scan models and image state definitions
├── Modifier/ # Reusable SwiftUI view modifiers
├── Modules/ # Feature modules
│ ├── Home/ # Home screen UIKit host + SwiftUI bridge, view models
│ ├── GroupDetail/ # Group detail grid, thumbnail pipelines, data managers
│ └── ImageDetail/ # Fullscreen pager, image prefetching, data managers
├── info.plist # App configuration + photo usage descriptions
└── README.md # Project documentation

---

## Technologies / Tools

- SwiftUI
- UIKit
- Combine
- Swift Concurrency (async/await, TaskGroup, actors)
- Photos framework
- CryptoKit
- Foundation
- iOS 17+

---

## Navigation Flow

1. **Home page** → Lists photo groups with progress feedback
2. Tap a group → **Group Detail page** showing grid-based thumbnails
3. Tap an image → **Image Detail page** with swipeable full-resolution viewer

---

## Future Improvements

- Extend grouping logic with user-defined collections or intelligent clustering beyond deterministic hashing.
- Add editing affordances (delete, favorite, hide) that synchronize back to the Photos library.
- Introduce haptic feedback, contextual menus, and richer empty states to elevate UX.
- Provide optimized layouts and multitasking support for iPad and macOS Catalyst builds.
- Add dark mode support
- Implement long-press gestures
- Integrate Core Data for persistence

---

## Author

**Sercan Artan**  
Boğaziçi University — Physics & Industrial Engineering  
Mobile & Web Developer
