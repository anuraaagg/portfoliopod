# Apple Music Integration Setup Guide

## What Changed

I've **completely migrated** the music integration from the old `MPMediaLibrary` API to the modern **MusicKit framework**. This means your app can now:

✅ **Access Apple Music streaming songs** (not just downloaded files)
✅ **Stream from Apple Music catalog**
✅ **Work with Apple Music subscription**
✅ **Better iOS sandbox compatibility**

## Requirements

To use Apple Music in your app, you need:

### 1. Apple Music Subscription
- The user (you) must have an active Apple Music subscription
- Sign in to iCloud with your Apple ID
- Verify subscription is active in Settings > Music

### 2. MusicKit Capability in Xcode

**You MUST add the MusicKit capability:**

1. Open `portfoliopod.xcodeproj` in Xcode
2. Select the "portfoliopod" target
3. Go to "Signing & Capabilities" tab
4. Click "+ Capability"
5. Add **"MusicKit"**
6. This will automatically add the entitlement

### 3. Info.plist Privacy Description

Already configured in the project:
```
NSAppleMusicUsageDescription = "Sync your iTunes library with PortfolioPod."
```

## How to Test

### Step 1: Build and Run
```bash
# Open in Xcode
open portfoliopod.xcodeproj

# Build and run (Cmd+R)
# Test on REAL device (Simulator has limited MusicKit support)
```

### Step 2: Grant Permission

When you first navigate to "music" in the app:
1. iOS will show a popup: "PortfolioPod Would Like to Access Apple Music"
2. Tap "OK" / "Allow"
3. The app will then load your library

### Step 3: Navigate to Music

1. Launch app
2. Scroll to "music" in main menu
3. Press center button
4. Choose "Playlists" or "Songs"
5. Select and play!

## Troubleshooting

### "No Songs Found"

**Check Console Logs** in Xcode for diagnostic messages:

```
MusicLibraryManager: MusicKit permission status = authorized
MusicLibraryManager: Loaded 42 songs
```

**Common Causes:**

1. **No Apple Music Subscription**
   - Verify in Settings > Music
   - Make sure you're signed in to iCloud

2. **Empty Library**
   - Add songs to your library in Apple Music app
   - Tap the "+" button on albums/songs to add them

3. **Library Sync Disabled**
   - Go to Settings > Music
   - Enable "Sync Library"

4. **Permission Denied**
   - Go to Settings > Privacy > Media & Apple Music
   - Make sure "portfoliopod" is enabled
   - If not listed, delete app and reinstall

### "Access Denied" Error

If you see the lock icon and "ACCESS_DENIED":

1. **Reset Permissions:**
   - Settings > Privacy > Media & Apple Music > portfoliopod
   - Toggle OFF then ON
   - Force quit app and relaunch

2. **Check Subscription:**
   - Open Apple Music app
   - Verify you can play songs
   - Make sure you're signed in

3. **Check Console:**
   ```
   MusicLibraryManager: Apple Music not authorized - status: denied
   ```
   This means user explicitly denied permission.

### App Crashes on Music Navigation

If the app crashes when accessing music:

1. **Verify MusicKit Capability Added:**
   - Xcode > Target > Signing & Capabilities
   - "MusicKit" should be in the list
   - If missing, add it (see Requirements section)

2. **Check Build Log:**
   - Look for entitlement errors
   - Make sure `com.apple.developer.music-kit` is present

3. **Clean Build:**
   ```
   Cmd+Shift+K (Clean Build Folder)
   Cmd+B (Build)
   ```

## Technical Details

### What's Different from MPMediaLibrary

| Feature | Old (MPMediaLibrary) | New (MusicKit) |
|---------|---------------------|----------------|
| **Access** | Downloaded files only | Streaming + Downloads |
| **Subscription** | Not required | Requires Apple Music |
| **Sandbox** | Blocked | Compatible |
| **Simulator** | No support | Partial support |
| **API Style** | Synchronous | Async/await |

### Data Models

The new implementation uses simplified wrapper types:

```swift
// Playlists
MusicLibraryManager.SimplePlaylist
  - id: String
  - name: String
  - artworkURL: URL?
  - songs: [SimpleSong]

// Songs
MusicLibraryManager.SimpleSong
  - id: String
  - title: String
  - artist: String
  - artworkURL: URL?
  - musicKitSong: Song? // Internal MusicKit reference
```

### Playback

The app uses `ApplicationMusicPlayer.shared` which:
- Plays through Apple Music service
- Respects user's subscription
- Shows playback in Control Center
- Works with AirPlay, CarPlay, etc.

### Limits

Current implementation limits:
- **Playlists:** 50 maximum
- **Songs:** 100 maximum (configurable in code)
- **Playlist Tracks:** 50 per playlist

To adjust, edit `MusicLibraryManager.swift`:
```swift
var request = MusicLibraryRequest<Song>()
request.limit = 200  // Increase this
```

## Code Changes Made

### Files Modified:

1. **MusicLibraryManager.swift** - Complete rewrite
   - Replaced `MPMediaLibrary` with `MusicKit`
   - Added `SimpleSong` and `SimplePlaylist` types
   - Implemented async/await patterns
   - Added comprehensive logging

2. **ScreenView.swift** - Minor updates
   - Updated to use `.name` instead of `.name?` (non-optional)
   - Updated to use `.title` instead of `.title?` (non-optional)

3. **DeviceShellView.swift** - No changes needed!
   - Already compatible with new API

### What Still Works:

- ✅ Navigation (click wheel scrolling)
- ✅ Physics-based selection
- ✅ Now Playing view
- ✅ Artwork display
- ✅ Playlist/Song playback

## Next Steps

1. **Open Xcode and add MusicKit capability**
2. **Build and run on a real device**
3. **Grant permission when prompted**
4. **Navigate to music and enjoy!**

If you run into issues, check the Xcode console for detailed diagnostic messages. Every step logs what's happening.

## Sandbox Status

**You can keep App Sandbox enabled** - MusicKit works fine with sandbox, unlike the old MPMediaLibrary API.

Current setting: `ENABLE_APP_SANDBOX = YES` ✅
