# WanderPost 📬

> An iOS app for documenting your 20s — one postcard at a time.

WanderPost lets young adults turn their most ordinary photos into personalized digital postcards. Your 20s are the most formative years of your life — WanderPost gives you a simple, creative way to capture how those moments, and you yourself, change over time.

---

## Screenshots

<!-- Add your screenshots here -->
| Home | Editor | Map | Postcard |
|------|--------|-----|---------|
| ![Home](screenshots/home.png) | ![Editor](screenshots/editor.png) | ![Map](screenshots/map.png) | ![Postcard](screenshots/postcard.png) |

---

## Features

- **📸 Photo Selection** — Pick any photo from your device gallery. No filters, no cropping — just the moment as it was.
- **✏️ Postcard Editor** — Add a city, short note, and date. CoreLocation auto-detects your current city, and live weather is pulled in automatically from OpenWeatherMap.
- **🗺️ World Map** — Every postcard pins your city on a full-screen MapKit map with a custom photo pin. Tap a city stamp to fly the map to that location.
- **📬 Save & Share** — Postcards are composed into a shareable image using `UIGraphicsImageRenderer` and exported via the native iOS share sheet, saved to Photos, or uploaded to Firebase.
- **☁️ Cloud Sync** — Postcards are stored locally with `Codable` + `FileManager` for offline access, and optionally synced to Firebase Storage and Firestore.

---

## Tech Stack

| Category | Technologies |
|----------|-------------|
| Language & UI | Swift 5, SwiftUI, UIKit |
| Architecture | MVVM, ObservableObject, EnvironmentObject, Combine |
| Maps & Location | MapKit, CoreLocation, CLGeocoder |
| APIs & Cloud | OpenWeatherMap REST API, Firebase Storage, Firebase Firestore |
| Data & Persistence | Codable, FileManager, Firestore |
| Media & Sharing | UIGraphicsImageRenderer, UIActivityViewController, PhotoKit, UIImagePickerController |

---

## Architecture

WanderPost follows **MVVM** with a dedicated **Managers layer** for all external services:

```
PostcardApp/
├── Model/
│   └── Postcard.swift             # Codable data model
├── ViewModel/
│   └── PostcardViewModel.swift    # CRUD + local persistence
├── View/
│   ├── HomePage.swift             # Postcard collection list
│   ├── PhotoPickerPage.swift      # Photo selection
│   ├── EditorPage.swift           # Postcard editor + map preview
│   ├── SaveSharePage.swift        # Share, save, upload
│   └── StampsPage.swift           # World map with pins
├── Managers/
│   ├── WeatherManager.swift       # OpenWeatherMap API
│   ├── CoreLocationManager.swift  # Device location + geocoding
│   ├── FirebaseManager.swift      # Storage + Firestore upload
│   └── TabRouter.swift            # Navigation state
└── ContentView.swift              # Root navigation with AppRoute enum
```

---

## Requirements

- iOS 16.0+
- Xcode 15+
- Swift 5.9+
- Firebase project with Storage and Firestore enabled
- OpenWeatherMap API key

---

## Setup

### 1. Clone the repo

```bash
git clone https://github.com/kdvasquez/wanderpost.git
cd wanderpost
```

### 2. Add Firebase

1. Create a project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Firestore Database** and **Storage** (requires Blaze plan as of Oct 2024)
3. Download `GoogleService-Info.plist` and add it to the Xcode project
4. Set Firestore and Storage rules to allow read/write for development:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if true;
    }
  }
}
```

### 3. Add your OpenWeatherMap API key

In `WeatherManager.swift`, replace the `apiKey` value with your key from [openweathermap.org](https://openweathermap.org/api):

```swift
let apiKey = "YOUR_API_KEY_HERE"
```

### 4. Build and run

Open `PostcardApp.xcodeproj` in Xcode, select a simulator or your device, and press **Cmd + R**.

---

## Key Technical Decisions

**Debounced API calls** — Weather and geocoding use Combine's `PassthroughSubject` with a 600ms debounce so APIs only fire when the user stops typing, not on every keystroke.

**Typed navigation** — Uses a typed `AppRoute` enum with a shared `[AppRoute]` path array instead of the deprecated `NavigationLink(isActive:)`, allowing any view to call `navPath.removeAll()` to reliably unwind back to the home screen.

**Dual persistence** — Local `Codable` JSON storage ensures the app works offline. Firebase sync is optional and additive — existing postcards remain safe if Firebase is unavailable.

**UIKit image compositor** — `UIGraphicsImageRenderer` draws all postcard elements (photo, city, message, stamp, postmark, weather tag) onto a single canvas and exports a `UIImage` for sharing.

---

## Roadmap

- [ ] Firebase Authentication (Sign in with Apple)
- [ ] Custom fonts and sticker overlays
- [ ] Stamp collection with country facts
- [ ] Decade archive — timeline view grouped by year
- [ ] Home screen widget (WidgetKit)

---

## Author

**Karla Vasquez**  
B.S. Computer Engineering & Computer Science — USC Viterbi  
[kdvasquez.github.io](https://kdvasquez.github.io) · [LinkedIn](https://linkedin.com/in/kdvasquez)

---

## License

This project is for portfolio and educational purposes.
