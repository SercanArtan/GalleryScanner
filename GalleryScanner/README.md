# Gallery Scanner

---

## Description

Gallery Scanner is a basic photo gallery scanner app built with **SwiftUI** and **UIKit**.  
Users can upload images from their phone gallery and view them within the app.

---

## Features

- Authorization handling: full or limited access for uploading images.  
- If an image is removed from the local gallery, it is also removed from the app.  
- For limited access, the app prompts users to update their selection each time it runs. The app continues background uploads based on previous selections.  
- Images are efficiently stored in a JSON file on the home page. When a group is tapped, only that group’s images are fetched and displayed.  
- App state persistence: fetched images, groups, and progress continue from where they were left in the previous session.  
- Uses **Publisher** to maintain connection between `HomeViewModel`, `HomeViewController`, and `PhotoScanner`.  
- Custom title modifier for consistent view headers in SwiftUI.  
- Navigation is implemented via `UINavigationController`. SwiftUI views are embedded in UIKit using `UIHostingController`.  
- Heavy asynchronous tasks run in the background using `Task`.  
- MVVM architecture followed for maintainable code.  
- **UICollectionView** is used to build the home page.  
- Images are grouped efficiently on the home screen.  
- Responsive grid layout with `LazyVGrid`.  
- Tap an image to view full-screen using `NavigationLink`.  
- State management using `@State`, `@Published`, `@ObservableObject`, and `@ObservedObject`.  
- Smooth navigation between **Group Detail** and **Image Detail** views.  
- Swipe left-to-right scrolling for images in full-screen mode.  

---

## Project Structure

CodeWay/
├── Helpers/                # Helper methods to scan and store images
├── Models/                 # Data models
├── Modifier/               # Custom modifiers for protocols
├── Modules/                # Pages
│ ├── GroupDetail/          # Group Detail page with its view and view model
│ ├── Home/                 # Home page and its requirements
│ └── ImageDetail/          # Image Detail page
├── App.swift               # App entry point
├── Info.plist              # Photo access permissions
└── README.md               # Project documentation

---

## Technologies / Tools

- SwiftUI  
- UIKit  
- Photos framework  
- CryptoKit  
- Combine  
- Foundation  
- iOS 17+ (may have issues on iPad)  

---

## Navigation Flow

1. **Home page** → Displays image groups  
2. Tap a group → **Group Detail page**  
3. Tap an image → **Image Detail page**  

---

## Future Improvements

- Integrate Core Data for persistence  
- Add delete and update functionality for images  
- Implement splash screen and app icon  
- Add dark mode support  
- Implement long-press gestures  
- Improve UI/UX for all pages  

---

## Author

**Sercan Artan**  
Boğaziçi University — Physics & Industrial Engineering  
Mobile & Web Developer  
