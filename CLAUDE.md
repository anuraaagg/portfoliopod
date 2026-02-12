# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**PortfolioPod** is a creative iOS portfolio app that simulates a classic iPod interface (6th generation style) with modern SwiftUI. The app showcases work, projects, experiments, and personal content through an interactive click wheel interface with authentic physics-based scrolling.

**Key Features:**
- Authentic iPod Classic UI with click wheel navigation
- Physics-based rotation and momentum scrolling
- Integrated Apple Music/iTunes library access
- Interactive experiments (PodBreaker game, Cover Flow)
- Custom wallpaper system
- Sticker layer for device customization
- Metal-based reflections driven by device motion

## Build & Run

This is an Xcode project targeting iOS 26.1+, macOS 26.1+, and visionOS 26.1+.

**Open & Build:**
```bash
open portfoliopod.xcodeproj
```
Then use Xcode's standard build commands (Cmd+B to build, Cmd+R to run).

**Deployment:**
- iOS Deployment Target: 26.1
- Supported Platforms: iPhone, iPad, Mac (Catalyst), visionOS
- Development Team: SLH68RB69S

**Important:** There's a `build_error.txt` in the root directory documenting previous build issues.

## Architecture

### Core Navigation System

The app uses a **hierarchical menu structure** defined in `ContentModel.swift`:

- **`MenuNode`**: Represents each item in the navigation tree. Can be a menu (with children) or leaf content (text, project, experiment, etc.)
- **`ContentStore`**: Singleton-like store containing the root menu and all content data. Provides methods like `getTextContent()`, `getProjectContent()`, etc.
- **`ContentType`**: Enum defining content types: `.text`, `.project`, `.experiment`, `.writing`, `.utility`, `.media`, `.menu`

Navigation is stack-based using `@State var navigationStack: [MenuNode]` in `DeviceShellView.swift`.

### Physics-Driven Interaction

The click wheel is controlled by **`ClickWheelPhysics`** ([ClickWheelPhysics.swift:1](ClickWheelPhysics.swift#L1)):
- Tracks angular drag gestures on the wheel
- Maintains angular momentum with friction decay
- Uses a `rotationBuffer` (in degrees) to determine when to advance the selection index
- Drives both menu navigation AND content scrolling via `scrollOffset`
- CADisplayLink-based 60fps animation loop

**Click Wheel Constants:**
- `degreesPerStep: 36.0` - rotation threshold before advancing selection
- `inertia: 0.90` - momentum retention
- `friction: 0.70` - decay rate

### Device Shell & UI Hierarchy

**`DeviceShellView.swift`** ([DeviceShellView.swift:1](DeviceShellView.swift#L1)) is the main container:
1. **Background Layer**: Dynamic wallpaper system + Metal reflection overlay
2. **RealisticIPodShell**: The physical device body
   - **ScreenView** ([ScreenView.swift:1](ScreenView.swift#L1)): Displays menus and content
   - **ClickWheelView** ([ClickWheelView.swift:1](ClickWheelView.swift#L1)): Circular gesture area with center button + cardinal buttons
3. **StickerLayer**: User-customizable stickers on device surface

**Navigation Flow:**
- Menu Press: `navigationStack.removeLast()` (go back)
- Center Press: Push selected item onto stack
- Wheel Drag: Update physics, which updates `selectionIndex`, which updates UI

### Content Rendering

**`ScreenView.swift`** handles all screen content:
- Split-screen layout for menus (left: list, right: preview)
- Status bar with time and battery
- Dynamic content views based on `node.contentType`:
  - **Text**: Simple bullet-point layout
  - **Project**: Overview + outcome sections
  - **Experiment**: Special views like PodBreaker game or Cover Flow
  - **Utility**: Clock, Notes, Browser, Settings
  - **Media**: Music library integration + Now Playing view

### Music Integration (MusicKit)

**`MusicLibraryManager.swift`** ([MusicLibraryManager.swift:1](MusicLibraryManager.swift#L1)):
- Uses modern **MusicKit framework** for Apple Music streaming support
- Singleton with `ApplicationMusicPlayer.shared` for playback
- Async/await based API calls
- Custom data models: `SimpleSong` and `SimplePlaylist` for UI compatibility
- Supports Apple Music subscription streaming (not just downloaded files)
- Provides play methods: `playPlaylist()`, `playSong()`

**Requirements:**
- MusicKit capability must be added in Xcode (Signing & Capabilities)
- User must have active Apple Music subscription
- `NSAppleMusicUsageDescription` in Info.plist (auto-generated)

**Data Models:**
- `SimpleSong`: `id`, `title`, `artist`, `artworkURL`, `musicKitSong`
- `SimplePlaylist`: `id`, `name`, `artworkURL`, `songs`

**See [APPLE_MUSIC_SETUP.md](APPLE_MUSIC_SETUP.md) for complete setup guide.**

### Theme & Settings System

**`SettingsStore.shared`** ([SettingsView.swift:4](SettingsView.swift#L4)) is a global settings manager:
- `hapticIntensity: Double` - Controls UIImpactFeedbackGenerator intensity
- `clickVolume: Double` - Audio feedback volume (via `SoundManager.shared`)
- `themeIndex: Int` - Theme selector (0 = Industrial/Red, 1 = Classic/Blue)
- `selectedWallpaperID: String` - Active wallpaper
- `availableWallpapers: [Wallpaper]` - Built-in gradients + user-added photos

All settings are persisted to `UserDefaults`.

**Theme Colors:**
- Industrial: Red accent (default)
- Classic: iPod Blue (#3399E6)

### Metal Rendering & Motion

**`MetalRenderer.swift`** + **`Shaders.metal`**:
- Renders a subtle metallic reflection effect over the device shell
- Uses `MotionManager` to track device tilt (gyroscope)
- Updates `lightAngle` uniform in Metal shader based on device orientation

**`MotionManager.swift`**:
- Wraps `CMMotionManager`
- Publishes `@Published var tilt: Double`
- Publishes `@Published var shakeDetected: Bool` (triggers random navigation on shake)

### Experiments

**PodBreaker** ([PodBreaker.swift:1](PodBreaker.swift#L1)):
- Brick breaker game controlled entirely by click wheel rotation
- Paddle position mapped directly to `physics.currentAngle`
- Listens to `physics.centerPressSubject` to launch ball
- 60fps game loop with collision detection

**Cover Flow** ([CoverFlowView.swift:1](CoverFlowView.swift#L1)):
- 3D perspective carousel of menu items
- Uses SwiftUI's `rotation3DEffect` and `offset` transforms

## Common Development Patterns

### Adding New Content

To add a new project/article/experiment:

1. Add node to `ContentStore.createDefaultContent()` in [ContentModel.swift:99](ContentModel.swift#L99)
2. Add content data to appropriate store method (`getTextContent()`, `getProjectContent()`, etc.)
3. If new content type: extend `ContentType` enum and add view builder case in `NavigationContentView.contentView` ([ScreenView.swift:329](ScreenView.swift#L329))

### Haptics & Audio

**Haptics:**
- Use `SettingsStore.shared.hapticIntensity` for intensity
- Pre-initialized generators in `ClickWheelPhysics` for performance

**Audio:**
- `SoundManager.shared.playClick()` for click wheel ticks
- Volume controlled by `SettingsStore.shared.clickVolume`

### Working with Physics

**Reset physics when changing context:**
```swift
physics.reset(to: 0)
```

**Update item count when menu changes:**
```swift
physics.numberOfItems = currentMenuItems.count
```

**Physics drives two things:**
1. `physics.selectionIndex` → menu item selection
2. `physics.scrollOffset` → content scroll position

### Stickers

**`StickerStore`** manages user-placed stickers on device shell:
- Stickers are `Draggable` views
- Positions stored as normalized coordinates (0-1 range)
- Long-press background to enter wallpaper edit mode

## Key Files Reference

- [portfoliopodApp.swift:10](portfoliopodApp.swift#L10) - App entry point
- [DeviceShellView.swift:10](DeviceShellView.swift#L10) - Main container, navigation logic
- [ScreenView.swift:1](ScreenView.swift#L1) - All screen content rendering
- [ContentModel.swift:1](ContentModel.swift#L1) - Content structure and data
- [ClickWheelPhysics.swift:1](ClickWheelPhysics.swift#L1) - Interaction physics engine
- [ClickWheelView.swift:1](ClickWheelView.swift#L1) - Gesture handling
- [SettingsView.swift:1](SettingsView.swift#L1) - Settings UI and SettingsStore
- [MusicLibraryManager.swift:1](MusicLibraryManager.swift#L1) - Apple Music integration
- [WallpaperSwitcher.swift:1](WallpaperSwitcher.swift#L1) - Wallpaper picker UI
- [MetalRenderer.swift:1](MetalRenderer.swift#L1) + [Shaders.metal:1](Shaders.metal#L1) - Reflection effects
- [PodBreaker.swift:1](PodBreaker.swift#L1) - Brick breaker game
- [BootLoaderView.swift:1](BootLoaderView.swift#L1) - Boot animation

## Design Philosophy

This project emphasizes **authentic iPod-era interaction patterns**:
- No direct touch on screen content (wheel-only navigation)
- Physics-based momentum scrolling
- Monospaced fonts, brutalist UI aesthetic
- System-level audio/haptic feedback
- Gestural "long press to edit" patterns

**Styling:**
- Heavy use of `.monospaced` design
- Uppercase text for headers
- Bracket notation `[ ITEM ]` for selection states
- Comment-style labels `// SECTION`
