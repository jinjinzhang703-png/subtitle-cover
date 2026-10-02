# Subtitle Cover 🎬

> A lightweight native utility that helps you cover subtitles without interrupting your viewing experience.

Subtitle Cover lets you place an adjustable overlay over subtitles in videos that cannot hide them.

Built with **Swift** and native platform APIs, Subtitle Cover focuses on being simple, lightweight, and easy to control.

---

## ✨ Features

- 🪟 **Always-on-top overlay**  
  Keep the cover above other windows while watching videos.

- 🎯 **Free positioning**  
  Drag the overlay to wherever the subtitles appear.

- 📐 **Freely resizable**  
  Drag any edge or any corner. Pinch on the trackpad to scale. Control-drag to draw a new area.

- 🎨 **Custom colors**  
  Choose a color that better matches the video.

- 🌗 **Adjustable opacity**  
  Fine-tune transparency from 10% to 100%.

- 💾 **Persistent settings**  
  Save position, size, color, and opacity for future sessions.

- 🖥️ **Universal macOS build**  
  Supports both Apple Silicon and Intel Macs.

---

## 🚀 Download

Download the installer from the latest release:

[Subtitle-Cover-1.1.0.pkg](https://github.com/jinjinzhang703-png/subtitle-cover/releases/download/v1.1.0/Subtitle-Cover-1.1.0.pkg)

Double-click the package. It installs Subtitle Cover into the Applications folder.

### Requirements

- macOS 13 or later
- Apple Silicon or Intel Mac

> ⚠️ The installer is not notarized by Apple. The first time you open it, macOS may say it cannot verify the developer. Open **System Settings → Privacy & Security** and click **Open Anyway**, or right-click the package and choose **Open**.

---

## ⚡ Quick Start

1. Download `Subtitle-Cover-1.1.0.pkg`.
2. Double-click it and follow the installer.
3. Open Subtitle Cover from the Applications folder.
4. Drag the overlay onto the subtitle area.

---

## 🕹️ Controls

### Basic controls

| Action | Function |
|---|---|
| Drag the middle of the overlay | Move the cover |
| Drag any edge | Resize width or height |
| Drag any corner | Resize width and height together |
| Double-click | Open settings |
| Right-click the overlay | Open the menu |

### MacBook trackpad

| Action | Function |
|---|---|
| Control + drag | Draw a new covering area |
| Single-finger drag on the middle | Move the cover |
| Drag an edge or a corner | Resize freely |
| Pinch | Scale the cover from its center |
| Double-click | Open settings |
| Right-click / Control-click | Open the menu |

---

## 🎨 Why Subtitle Cover?

Some videos have subtitles that cannot be disabled, or subtitles may simply be distracting when watching content in another language.

Instead of modifying the original video, Subtitle Cover provides a lightweight overlay that sits on top of the subtitle area.

No video re-rendering.  
No complicated editing workflow.  
Just place it where you need it.

---

## 🛠️ Built With

### macOS

- Swift
- AppKit
- Swift Package Manager

### Windows

- Swift
- Win32 / WinSDK

The project uses native platform APIs rather than a cross-platform runtime.

---

## 🔧 Build From Source

### macOS

Install Swift / Xcode Command Line Tools:

```bash
xcode-select --install
```

Build the app bundle (Apple Silicon, the machine you are building on):

```bash
./scripts/build-macos-app.sh
```

The script writes `Subtitle Cover.app` in the repository root. Move it to `/Applications` and launch it. Saved position, size, color, and opacity stay in the existing `subtitle_cover.overlay_settings` preference, so an older install keeps its place on screen.
